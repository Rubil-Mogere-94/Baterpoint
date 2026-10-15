#!/usr/bin/env python3
"""Apply a focused Flutter UI/usability pass to an existing Baterpoint checkout.

Run from the repository root: python3 apply_ui_usability_patch.py
The script verifies all source anchors before writing anything, so a mismatch
stops the patch instead of silently applying a partial update.
"""
from pathlib import Path
import sys

ROOT = Path.cwd()


def read(path: str) -> str:
    file = ROOT / path
    if not file.is_file():
        raise RuntimeError(f"Required file not found: {path}. Run this from the repository root.")
    return file.read_text(encoding="utf-8")


def replace_once(source: str, old: str, new: str, path: str) -> str:
    count = source.count(old)
    if count != 1:
        raise RuntimeError(f"Expected one patch anchor in {path}, found {count}: {old[:90]!r}")
    return source.replace(old, new, 1)


def replace_first(source: str, old: str, new: str, path: str) -> str:
    count = source.count(old)
    if count < 1:
        raise RuntimeError(f"Patch anchor missing in {path}: {old[:90]!r}")
    return source.replace(old, new, 1)


def replace_last(source: str, old: str, new: str, path: str) -> str:
    count = source.count(old)
    if count < 1:
        raise RuntimeError(f"Patch anchor missing in {path}: {old[:90]!r}")
    index = source.rfind(old)
    return source[:index] + new + source[index + len(old):]

# Read and transform all existing files in memory before writing, for a safe failure.
changes = {}

# The service uses the project's existing backend routes and stores the returned access token.
changes['frontend/lib/services/api_service.dart'] = r'''import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/product.dart';
import '../constants.dart';

class ApiService {
  static const String _baseUrl = kBaseUrl;
  static const String _v1 = kApiV1;
  static const String _tokenKey = 'baterpoint_access_token';

  Future<Map<String, String>> _authHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    if (token == null || token.isEmpty) return <String, String>{};
    return <String, String>{'Authorization': 'Bearer $token'};
  }

  String _errorMessage(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map) {
        final detail = decoded['detail'] ?? decoded['message'];
        if (detail != null) return detail.toString();
      }
    } catch (_) {
      // The server may return plain text for an unexpected response.
    }
    return 'The request could not be completed. Please try again.';
  }

  Map<String, dynamic> _asMap(dynamic value) =>
      Map<String, dynamic>.from(value as Map);

  Future<List<Product>> getListings({
    String? category,
    String? search,
    String? tradeType,
  }) async {
    final query = <String, String>{};
    if (category != null && category.trim().isNotEmpty && category != 'All') {
      query['category'] = category;
    }
    if (search != null && search.trim().isNotEmpty) {
      query['search'] = search.trim();
    }
    if (tradeType != null && tradeType.trim().isNotEmpty) {
      query['tradeType'] = tradeType;
    }

    final uri = Uri.parse('$_baseUrl$_v1/listings/').replace(
      queryParameters: query.isEmpty ? null : query,
    );
    final response = await http.get(uri, headers: await _authHeaders());
    if (response.statusCode != 200) {
      throw Exception(_errorMessage(response.body));
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! List) {
      throw const FormatException('Unexpected listings response from server.');
    }
    return decoded
        .map((item) => Product.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList();
  }

  Future<Product> getListing(int id) async {
    final response = await http.get(
      Uri.parse('$_baseUrl$_v1/listings/$id'),
      headers: await _authHeaders(),
    );
    if (response.statusCode == 200) {
      return Product.fromJson(_asMap(jsonDecode(response.body)));
    }
    throw Exception(_errorMessage(response.body));
  }

  Future<Product> createListing({
    required String title,
    required String description,
    required String category,
    required String tradeType,
    required XFile image,
    String? cashPrice,
    String? exchangeItem,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$_baseUrl$_v1/listings/'),
    );
    request.headers.addAll(await _authHeaders());
    request.fields.addAll({
      'title': title.trim(),
      'description': description.trim(),
      'category': category,
      'tradeType': tradeType,
    });
    if (cashPrice != null && cashPrice.trim().isNotEmpty) {
      request.fields['cashPrice'] = cashPrice.trim();
    }
    if (exchangeItem != null && exchangeItem.trim().isNotEmpty) {
      request.fields['exchangeItem'] = exchangeItem.trim();
    }
    request.files.add(http.MultipartFile.fromBytes(
      'image',
      await image.readAsBytes(),
      filename: image.name,
    ));

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    if (response.statusCode == 200 || response.statusCode == 201) {
      return Product.fromJson(_asMap(jsonDecode(response.body)));
    }
    throw Exception(_errorMessage(response.body));
  }

  Future<Map<String, dynamic>> evaluateItem({
    required String itemName,
    String description = '',
  }) async {
    // The current backend mounts the AI router under /api/v1/ai/ai.
    final uri = Uri.parse('$_baseUrl$_v1/ai/ai/evaluate').replace(
      queryParameters: {
        'item_name': itemName.trim(),
        'description': description.trim(),
      },
    );
    final response = await http.post(uri, headers: await _authHeaders());
    if (response.statusCode == 200) return _asMap(jsonDecode(response.body));
    throw Exception(_errorMessage(response.body));
  }

  Future<Map<String, dynamic>> getCurrentUser() async {
    final response = await http.get(
      Uri.parse('$_baseUrl$_v1/users/me'),
      headers: await _authHeaders(),
    );
    if (response.statusCode == 200) return _asMap(jsonDecode(response.body));
    throw Exception(_errorMessage(response.body));
  }

  Future<List<Product>> getMyListings() async {
    final response = await http.get(
      Uri.parse('$_baseUrl$_v1/users/me/listings'),
      headers: await _authHeaders(),
    );
    if (response.statusCode != 200) throw Exception(_errorMessage(response.body));
    final decoded = jsonDecode(response.body);
    if (decoded is! List) return <Product>[];
    return decoded
        .map((item) => Product.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList();
  }

  Future<List<Map<String, dynamic>>> getInbox() async {
    final response = await http.get(
      Uri.parse('$_baseUrl$_v1/chat/inbox'),
      headers: await _authHeaders(),
    );
    if (response.statusCode != 200) throw Exception(_errorMessage(response.body));
    final decoded = jsonDecode(response.body);
    if (decoded is! List) return <Map<String, dynamic>>[];
    return decoded.map((item) => Map<String, dynamic>.from(item as Map)).toList();
  }

  Future<Map<String, dynamic>> getCart() async {
    final response = await http.get(
      Uri.parse('$_baseUrl$_v1/cart/'),
      headers: await _authHeaders(),
    );
    if (response.statusCode == 200) return _asMap(jsonDecode(response.body));
    throw Exception(_errorMessage(response.body));
  }

  Future<Map<String, dynamic>> addToCart(int listingId) async {
    final response = await http.post(
      Uri.parse('$_baseUrl$_v1/cart/items'),
      headers: {
        ...await _authHeaders(),
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'listing_id': listingId, 'quantity': 1}),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return _asMap(jsonDecode(response.body));
    }
    throw Exception(_errorMessage(response.body));
  }

  Future<Map<String, dynamic>> removeCartItem(int itemId) async {
    final response = await http.delete(
      Uri.parse('$_baseUrl$_v1/cart/items/$itemId'),
      headers: await _authHeaders(),
    );
    if (response.statusCode == 200) return _asMap(jsonDecode(response.body));
    throw Exception(_errorMessage(response.body));
  }

  Future<Map<String, dynamic>> createOffer(
    int listingId, {
    String? offeredItem,
    double? offeredPrice,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl$_v1/offers/$listingId'),
      headers: {
        ...await _authHeaders(),
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        if (offeredItem != null && offeredItem.trim().isNotEmpty)
          'offered_item': offeredItem.trim(),
        if (offeredPrice != null) 'offered_price': offeredPrice,
      }),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return _asMap(jsonDecode(response.body));
    }
    throw Exception(_errorMessage(response.body));
  }

  Future<Map<String, dynamic>> createOrder() async {
    final response = await http.post(
      Uri.parse('$_baseUrl$_v1/orders/'),
      headers: {
        ...await _authHeaders(),
        'Content-Type': 'application/json',
      },
      body: jsonEncode(<String, dynamic>{}),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return _asMap(jsonDecode(response.body));
    }
    throw Exception(_errorMessage(response.body));
  }
}
'''

# Add token persistence; login's returned token is now actually used by authenticated UI screens.
changes['frontend/lib/services/auth_service.dart'] = read('frontend/lib/services/auth_service.dart')
old = "import 'package:http/http.dart' as http;\nimport '../constants.dart';"
new = "import 'package:http/http.dart' as http;\nimport 'package:shared_preferences/shared_preferences.dart';\nimport '../constants.dart';"
changes['frontend/lib/services/auth_service.dart'] = replace_once(changes['frontend/lib/services/auth_service.dart'], old, new, 'frontend/lib/services/auth_service.dart')
s = changes['frontend/lib/services/auth_service.dart']
s = replace_first(s,
"      if (token is String && token.isNotEmpty) return token;\n      throw AuthException('Invalid response from server', response.statusCode);",
"      if (token is String && token.isNotEmpty) {\n        final prefs = await SharedPreferences.getInstance();\n        await prefs.setString('baterpoint_access_token', token);\n        return token;\n      }\n      throw AuthException('Invalid response from server', response.statusCode);",
'frontend/lib/services/auth_service.dart')
reg_start = s.index('  static Future<String> register({')
reg_end = s.index('\n  static Future<String> refreshToken(', reg_start)
register_method = r'''  static Future<void> register({
    required String username,
    required String email,
    required String password,
  }) async {
    final response = await _post(
      Uri.parse('$_baseUrl$_v1/register/'),
      {'username': username, 'email': email, 'password': password},
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      // The current API returns a User object, not an access token.
      return;
    }
    final body = jsonDecode(response.body);
    throw AuthException(_extractError(body), response.statusCode);
  }
'''
s = s[:reg_start] + register_method + s[reg_end:]
s = replace_once(s, '  static void logout() {}', "  static Future<void> logout() async {\n    final prefs = await SharedPreferences.getInstance();\n    await prefs.remove('baterpoint_access_token');\n  }", 'frontend/lib/services/auth_service.dart')
changes['frontend/lib/services/auth_service.dart'] = s

# Registration should return to sign-in instead of trying to use a non-existent token.
changes['frontend/lib/screens/auth/auth_screen.dart'] = read('frontend/lib/screens/auth/auth_screen.dart')
s = changes['frontend/lib/screens/auth/auth_screen.dart']
old = r'''      if (_isLogin) {
        await AuthService.login(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      } else {
        await AuthService.register(
          username: _usernameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      }
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
} catch (e) {'''
new = r'''      if (_isLogin) {
        await AuthService.login(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        }
      } else {
        await AuthService.register(
          username: _usernameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
        if (mounted) {
          setState(() {
            _isLogin = true;
            _passwordController.clear();
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Account created. Sign in to continue.')),
          );
        }
      }
    } catch (e) {'''
s = replace_once(s, old, new, 'frontend/lib/screens/auth/auth_screen.dart')
s = replace_once(s,
"                          validator: (v) => v == null || v.length < 6\n                              ? 'Enter at least 6 characters'\n                              : null,",
"                          validator: (v) => v == null || v.length < 8\n                              ? 'Enter at least 8 characters'\n                              : null,",
'frontend/lib/screens/auth/auth_screen.dart')
changes['frontend/lib/screens/auth/auth_screen.dart'] = s

# Home: working navigation, search, truthful feature strip, responsive grid and correct 'All' filter.
changes['frontend/lib/screens/home/home_screen.dart'] = read('frontend/lib/screens/home/home_screen.dart')
s = changes['frontend/lib/screens/home/home_screen.dart']
s = replace_once(s,
"import '../../services/app_config_provider.dart';",
"import '../../services/app_config_provider.dart';\nimport '../cart/cart_screen.dart';\nimport '../chat/chat_screen.dart';\nimport '../profile/profile_screen.dart';\nimport '../listing/create_listing_screen.dart';\nimport '../valuation/valuation_screen.dart';",
'frontend/lib/screens/home/home_screen.dart')
s = replace_once(s,
"class _HomeScreenState extends State<HomeScreen> {\n  final ApiService _apiService = ApiService();",
"class _HomeScreenState extends State<HomeScreen> {\n  final ApiService _apiService = ApiService();\n  int _selectedDestination = 0;",
'frontend/lib/screens/home/home_screen.dart')
# Insert navigation helpers before build.
s = replace_once(s,
"  @override\n  Widget build(BuildContext context) {\n    final config = context.watch<AppConfigProvider>();",
r'''  Future<void> _openSearch() async {
    final selected = await showSearch<Product>(
      context: context,
      delegate: _ListingSearchDelegate(apiService: _apiService),
    );
    if (!mounted || selected == null) return;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => DetailsScreen(product: selected)),
    );
  }

  Future<void> _openCreateListing() async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const CreateListingScreen()),
    );
    if (created == true && mounted) {
      setState(() => _productsFuture = _apiService.getListings());
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = context.watch<AppConfigProvider>();''',
'frontend/lib/screens/home/home_screen.dart')
s = replace_once(s,
"            onPressed: () {},\n          ),\n          IconButton(\n            icon: Container(\n              padding: const EdgeInsets.all(6),\n              decoration: BoxDecoration(\n                color: kSurfaceColor,\n                borderRadius: BorderRadius.circular(10),\n              ),\n              child: const Icon(Icons.shopping_cart_rounded),\n            ),\n            onPressed: () {},",
"            onPressed: _openSearch,\n          ),\n          IconButton(\n            tooltip: 'Cart',\n            icon: Container(\n              padding: const EdgeInsets.all(6),\n              decoration: BoxDecoration(\n                color: kSurfaceColor,\n                borderRadius: BorderRadius.circular(10),\n              ),\n              child: const Icon(Icons.shopping_cart_rounded),\n            ),\n            onPressed: () => Navigator.push(\n              context,\n              MaterialPageRoute(builder: (_) => const CartScreen()),\n            ),",
'frontend/lib/screens/home/home_screen.dart')
s = replace_once(s, '      appBar: AppBar(', '      appBar: _selectedDestination == 0 ? AppBar(', 'frontend/lib/screens/home/home_screen.dart')
s = replace_once(s, '      ),\n      body: RefreshIndicator(', '      ) : null,\n      body: _selectedDestination == 0 ? RefreshIndicator(', 'frontend/lib/screens/home/home_screen.dart')
s = replace_once(s,
"                                  label: \"List Item\",\n                                  onTap: () {},",
"                                  label: \"List Item\",\n                                  onTap: _openCreateListing,",
'frontend/lib/screens/home/home_screen.dart')
s = replace_once(s,
"                                  label: \"AI Valuator\",\n                                  onTap: () {},",
"                                  label: \"AI Valuator\",\n                                  onTap: () => Navigator.push(\n                                    context,\n                                    MaterialPageRoute(\n                                      builder: (_) => const ValuationScreen(),\n                                    ),\n                                  ),",
'frontend/lib/screens/home/home_screen.dart')
s = replace_once(s,
'''                            value: "2.4k",
                            label: "Trades",''',
'''                            value: "Barter",
                            label: "Swap items",''',
'frontend/lib/screens/home/home_screen.dart')
s = replace_once(s,
'''                            value: "1.8k",
                            label: "Traders",''',
'''                            value: "Cash",
                            label: "Buy & sell",''',
'frontend/lib/screens/home/home_screen.dart')
s = replace_once(s,
'''                            value: "98%",
                            label: "Success",''',
'''                            value: "Both",
                            label: "Choose a deal",''',
'frontend/lib/screens/home/home_screen.dart')
s = replace_once(s,
'category == "All Trades" ? null : category,',
'category == "All" ? null : category,',
'frontend/lib/screens/home/home_screen.dart')
s = replace_once(s,
'''                          onPressed: () {},
                          child: const Text("See All"),''',
'''                          onPressed: () => setState(
                            () => _productsFuture = _apiService.getListings(),
                          ),
                          child: const Text("See All"),''',
'frontend/lib/screens/home/home_screen.dart')
s = replace_once(s,
'''                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                          childAspectRatio: 0.6,
                        ),''',
'''                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: MediaQuery.sizeOf(context).width < 380
                              ? 2
                              : MediaQuery.sizeOf(context).width < 760
                                  ? 3
                                  : 4,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 0.68,
                        ),''',
'frontend/lib/screens/home/home_screen.dart')
# Replace the closing of the body and add bottom navigation.
s = replace_once(s,
'''      ),
    );
  }

  Widget _buildFeaturedCarousel() {''',
'''      )
          : _selectedDestination == 1
              ? const ChatScreen()
              : const ProfileScreen(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedDestination,
        onDestinationSelected: (index) =>
            setState(() => _selectedDestination = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.storefront_outlined),
            selectedIcon: Icon(Icons.storefront_rounded),
            label: 'Market',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline_rounded),
            selectedIcon: Icon(Icons.chat_bubble_rounded),
            label: 'Messages',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedCarousel() {''',
'frontend/lib/screens/home/home_screen.dart')

# Keep the featured carousel promotional but do not imply specific unverified deals.
s = replace_once(s, '"Trade your old phone for a MacBook Pro"', '"Explore electronics listed for cash or barter"', 'frontend/lib/screens/home/home_screen.dart')
s = replace_once(s, '"Minimalist pieces available now"', '"Browse furniture open to cash or barter"', 'frontend/lib/screens/home/home_screen.dart')
s = replace_once(s, '"Find your next ride through barter"', '"Compare vehicle listings and trade preferences"', 'frontend/lib/screens/home/home_screen.dart')

# Search delegate: server-side search with loading, empty and retry states.
s = s.rstrip() + r'''

class _ListingSearchDelegate extends SearchDelegate<Product> {
  _ListingSearchDelegate({required this.apiService});

  final ApiService apiService;
  String? _lastQuery;
  Future<List<Product>>? _searchFuture;

  Future<List<Product>> _search() {
    final normalized = query.trim();
    if (_lastQuery != normalized || _searchFuture == null) {
      _lastQuery = normalized;
      _searchFuture = normalized.isEmpty
          ? Future<List<Product>>.value(<Product>[])
          : apiService.getListings(search: normalized);
    }
    return _searchFuture!;
  }

  @override
  List<Widget> buildActions(BuildContext context) => [
        if (query.isNotEmpty)
          IconButton(
            tooltip: 'Clear search',
            onPressed: () {
              query = '';
              _lastQuery = null;
              _searchFuture = null;
              showSuggestions(context);
            },
            icon: const Icon(Icons.clear_rounded),
          ),
      ];

  @override
  Widget buildLeading(BuildContext context) => IconButton(
        tooltip: 'Close search',
        onPressed: () => close(context, null),
        icon: const Icon(Icons.arrow_back_rounded),
      );

  @override
  Widget buildResults(BuildContext context) => _results(context);

  @override
  Widget buildSuggestions(BuildContext context) => _results(context);

  Widget _results(BuildContext context) {
    if (query.trim().isEmpty) {
      return const Center(child: Text('Search by item name or description.'));
    }
    return FutureBuilder<List<Product>>(
      future: _search(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Search could not be completed.'),
                TextButton(
                  onPressed: () {
                    _lastQuery = null;
                    _searchFuture = null;
                    showResults(context);
                  },
                  child: const Text('Try again'),
                ),
              ],
            ),
          );
        }
        final products = snapshot.data ?? <Product>[];
        if (products.isEmpty) {
          return const Center(child: Text('No listings match that search yet.'));
        }
        return ListView.separated(
          itemCount: products.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final product = products[index];
            return ListTile(
              leading: const CircleAvatar(child: Icon(Icons.inventory_2_outlined)),
              title: Text(product.title, maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text(product.acceptsBarter && product.acceptsCurrency
                  ? 'Barter or cash'
                  : product.acceptsBarter
                      ? 'Barter welcome'
                      : 'Cash purchase'),
              trailing: product.acceptsCurrency
                  ? Text('\$${product.price}', style: const TextStyle(fontWeight: FontWeight.w600))
                  : const Icon(Icons.swap_horiz_rounded),
              onTap: () => close(context, product),
            );
          },
        );
      },
    );
  }
}
'''
changes['frontend/lib/screens/home/home_screen.dart'] = s + '\n'

# Real inbox state replaces hard-coded sample conversations.
changes['frontend/lib/screens/chat/chat_screen.dart'] = r'''import 'package:flutter/material.dart';
import '../../constants.dart';
import '../../services/api_service.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<Map<String, dynamic>>> _inboxFuture;

  @override
  void initState() {
    super.initState();
    _inboxFuture = _apiService.getInbox();
  }

  Future<void> _refresh() async {
    setState(() => _inboxFuture = _apiService.getInbox());
    try {
      await _inboxFuture;
    } catch (_) {
      // FutureBuilder presents the error state.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(title: const Text('Messages')),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _inboxFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return ListView(children: [
                const SizedBox(height: 120),
                const Icon(Icons.cloud_off_rounded, size: 48, color: kTextLightColor),
                const SizedBox(height: 12),
                const Center(child: Text('Messages could not be loaded.')),
                Center(
                  child: TextButton.icon(
                    onPressed: _refresh,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Try again'),
                  ),
                ),
              ]);
            }
            final conversations = snapshot.data ?? <Map<String, dynamic>>[];
            if (conversations.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(28),
                children: const [
                  SizedBox(height: 60),
                  Icon(Icons.forum_outlined, size: 64, color: kTextLightColor),
                  SizedBox(height: 16),
                  Center(
                    child: Text('No messages yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  ),
                  SizedBox(height: 8),
                  Center(
                    child: Text(
                      'When another trader messages you, the conversation will appear here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: kTextLightColor, height: 1.45),
                    ),
                  ),
                ],
              );
            }
            return ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(kDefaultPadding),
              itemCount: conversations.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final item = conversations[index];
                final name = (item['other_user_username'] ?? 'Trader').toString();
                final message = (item['last_message'] ?? 'No message preview').toString();
                final unread = (item['unread_count'] as num?)?.toInt() ?? 0;
                final avatar = (item['other_user_avatar'] ?? '').toString();
                return Card.outlined(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: CircleAvatar(
                      backgroundColor: kPrimaryColor.withValues(alpha: 0.12),
                      backgroundImage: avatar.startsWith('http') ? NetworkImage(avatar) : null,
                      child: avatar.startsWith('http')
                          ? null
                          : Text(name.isNotEmpty ? name[0].toUpperCase() : '?', style: const TextStyle(color: kPrimaryColor)),
                    ),
                    title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(message, maxLines: 2, overflow: TextOverflow.ellipsis),
                    trailing: unread > 0
                        ? CircleAvatar(
                            radius: 13,
                            backgroundColor: kPrimaryColor,
                            child: Text('$unread', style: const TextStyle(color: Colors.white, fontSize: 11)),
                          )
                        : const Icon(Icons.chevron_right_rounded, color: kTextLightColor),
                    onTap: () => showDialog<void>(
                      context: context,
                      builder: (dialogContext) => AlertDialog(
                        title: Text(name),
                        content: Text(message),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(dialogContext),
                            child: const Text('Close'),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
'''

# Live profile data; remove fictional trader identity, made-up metrics and inert menu links.
changes['frontend/lib/screens/profile/profile_screen.dart'] = r'''import 'package:flutter/material.dart';
import '../../constants.dart';
import '../../models/product.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../auth/auth_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ApiService _apiService = ApiService();
  late Future<Map<String, dynamic>> _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = _loadProfile();
  }

  Future<Map<String, dynamic>> _loadProfile() async {
    final results = await Future.wait<dynamic>([
      _apiService.getCurrentUser(),
      _apiService.getMyListings(),
    ]);
    return {
      'user': results[0] as Map<String, dynamic>,
      'listings': results[1] as List<Product>,
    };
  }

  Future<void> _signOut() async {
    await AuthService.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AuthScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(title: const Text('Your profile')),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _profileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.account_circle_outlined, size: 56, color: kTextLightColor),
                    const SizedBox(height: 12),
                    const Text('Your profile could not be loaded.', textAlign: TextAlign.center),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => setState(() => _profileFuture = _loadProfile()),
                      child: const Text('Try again'),
                    ),
                  ],
                ),
              ),
            );
          }

          final data = snapshot.data!;
          final user = data['user'] as Map<String, dynamic>;
          final listings = data['listings'] as List<Product>;
          final username = (user['username'] ?? 'Trader').toString();
          final email = (user['email'] ?? '').toString();
          final trades = (user['successful_trades'] as num?)?.toInt() ?? 0;
          final reviews = (user['total_reviews'] as num?)?.toInt() ?? 0;

          return RefreshIndicator(
            onRefresh: () async {
              setState(() => _profileFuture = _loadProfile());
              try { await _profileFuture; } catch (_) {}
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(kDefaultPadding),
              children: [
                Card(
                  elevation: 0,
                  color: kSurfaceColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                    side: const BorderSide(color: kBorderColor),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 42,
                          backgroundColor: kPrimaryColor.withValues(alpha: 0.1),
                          child: Text(
                            username.isNotEmpty ? username[0].toUpperCase() : '?',
                            style: const TextStyle(fontSize: 30, color: kPrimaryColor, fontWeight: FontWeight.w700),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(username, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                        if (email.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(email, style: const TextStyle(color: kTextLightColor)),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _StatCard(value: '${listings.length}', label: 'Listings', icon: Icons.inventory_2_outlined)),
                    const SizedBox(width: 10),
                    Expanded(child: _StatCard(value: '$trades', label: 'Trades', icon: Icons.swap_horiz_rounded)),
                    const SizedBox(width: 10),
                    Expanded(child: _StatCard(value: '$reviews', label: 'Reviews', icon: Icons.star_outline_rounded)),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('My listings', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                    Text('${listings.length}', style: const TextStyle(color: kTextLightColor)),
                  ],
                ),
                const SizedBox(height: 10),
                if (listings.isEmpty)
                  Card.outlined(
                    child: const Padding(
                      padding: EdgeInsets.all(22),
                      child: Column(
                        children: [
                          Icon(Icons.add_box_outlined, size: 42, color: kTextLightColor),
                          SizedBox(height: 8),
                          Text('You have not listed anything yet.', textAlign: TextAlign.center),
                          SizedBox(height: 4),
                          Text('Use “List item” on the Market tab to get started.', textAlign: TextAlign.center, style: TextStyle(color: kTextLightColor)),
                        ],
                      ),
                    ),
                  )
                else
                  ...listings.take(5).map((product) => Card.outlined(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: const CircleAvatar(child: Icon(Icons.inventory_2_outlined)),
                          title: Text(product.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                          subtitle: Text(product.acceptsBarter && product.acceptsCurrency
                              ? 'Barter or cash'
                              : product.acceptsBarter
                                  ? 'Barter listing'
                                  : 'Cash listing'),
                          trailing: product.acceptsCurrency
                              ? Text('\$${product.price}', style: const TextStyle(fontWeight: FontWeight.w600))
                              : const Icon(Icons.swap_horiz_rounded),
                        ),
                      )),
                const SizedBox(height: 20),
                OutlinedButton.icon(
                  onPressed: _signOut,
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('Sign out'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: kErrorColor,
                    side: const BorderSide(color: kErrorColor),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;

  const _StatCard({required this.value, required this.label, required this.icon});

  @override
  Widget build(BuildContext context) => Card(
        elevation: 0,
        color: kSurfaceColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: kBorderColor),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
          child: Column(
            children: [
              Icon(icon, color: kPrimaryColor, size: 22),
              const SizedBox(height: 8),
              Text(value, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              Text(label, style: const TextStyle(color: kTextLightColor, fontSize: 12)),
            ],
          ),
        ),
      );
}
'''

# Listing composer uses existing multipart listing endpoint and image_picker dependency.
changes['frontend/lib/screens/listing/create_listing_screen.dart'] = r'''import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../constants.dart';
import '../../services/api_service.dart';

class CreateListingScreen extends StatefulWidget {
  const CreateListingScreen({super.key});

  @override
  State<CreateListingScreen> createState() => _CreateListingScreenState();
}

class _CreateListingScreenState extends State<CreateListingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _exchangeController = TextEditingController();
  final _apiService = ApiService();
  final _picker = ImagePicker();
  String _category = 'Electronics';
  String _tradeType = 'Both';
  XFile? _image;
  Future<Uint8List>? _imageBytes;
  bool _saving = false;

  static const _categories = [
    'Electronics', 'Furniture', 'Vehicles', 'Services', 'Fashion',
    'Home & Garden', 'Sports', 'Books', 'Other',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _exchangeController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked == null || !mounted) return;
    setState(() {
      _image = picked;
      _imageBytes = picked.readAsBytes();
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add a photo so traders can see your item.')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await _apiService.createListing(
        title: _titleController.text,
        description: _descriptionController.text,
        category: _category,
        tradeType: _tradeType,
        image: _image!,
        cashPrice: _tradeType == 'Barter' ? null : _priceController.text,
        exchangeItem: _tradeType == 'Sale' ? null : _exchangeController.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your listing is live.')),
      );
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not publish listing: ${error.toString().replaceFirst('Exception: ', '')}')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final needsCash = _tradeType != 'Barter';
    final needsExchange = _tradeType != 'Sale';
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(title: const Text('List an item')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(kDefaultPadding),
          children: [
            Text('Show traders what you have', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            const Text('Add clear details and choose whether you want cash, barter, or either.', style: TextStyle(color: kTextLightColor, height: 1.45)),
            const SizedBox(height: 18),
            InkWell(
              onTap: _saving ? null : _pickImage,
              borderRadius: BorderRadius.circular(18),
              child: Container(
                height: 190,
                decoration: BoxDecoration(
                  color: kSurfaceColor,
                  border: Border.all(color: kBorderColor),
                  borderRadius: BorderRadius.circular(18),
                ),
                clipBehavior: Clip.antiAlias,
                child: _imageBytes == null
                    ? const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_photo_alternate_outlined, size: 44, color: kPrimaryColor),
                          SizedBox(height: 8),
                          Text('Add item photo', style: TextStyle(fontWeight: FontWeight.w600)),
                          SizedBox(height: 4),
                          Text('A clear photo helps build trust', style: TextStyle(color: kTextLightColor, fontSize: 12)),
                        ],
                      )
                    : FutureBuilder<Uint8List>(
                        future: _imageBytes,
                        builder: (context, snapshot) => snapshot.hasData
                            ? Image.memory(snapshot.data!, fit: BoxFit.cover, width: double.infinity)
                            : const Center(child: CircularProgressIndicator()),
                      ),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _titleController,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Item title', hintText: 'e.g. Wireless headphones'),
              validator: (value) => value == null || value.trim().isEmpty ? 'Enter an item title' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descriptionController,
              minLines: 3,
              maxLines: 5,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Description', hintText: 'Describe condition, age and anything a trader should know.'),
              validator: (value) => value == null || value.trim().isEmpty ? 'Add a short description' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _category,
              decoration: const InputDecoration(labelText: 'Category'),
              items: _categories.map((category) => DropdownMenuItem(value: category, child: Text(category))).toList(),
              onChanged: _saving ? null : (value) { if (value != null) setState(() => _category = value); },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _tradeType,
              decoration: const InputDecoration(labelText: 'How would you trade it?'),
              items: const [
                DropdownMenuItem(value: 'Barter', child: Text('Barter only')),
                DropdownMenuItem(value: 'Sale', child: Text('Cash only')),
                DropdownMenuItem(value: 'Both', child: Text('Barter or cash')),
              ],
              onChanged: _saving ? null : (value) { if (value != null) setState(() => _tradeType = value); },
            ),
            if (needsCash) ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: _priceController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Cash price', prefixText: '\$ ', helperText: 'Use the currency configured for your marketplace.'),
                validator: (value) {
                  if (!needsCash) return null;
                  final price = double.tryParse((value ?? '').trim());
                  return price == null || price <= 0 ? 'Enter a price greater than zero' : null;
                },
              ),
            ],
            if (needsExchange) ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: _exchangeController,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(labelText: 'What would you accept in exchange?', hintText: 'e.g. A tablet, bicycle, or similar-value item'),
                validator: (value) => needsExchange && (value == null || value.trim().isEmpty) ? 'Describe what you would accept' : null,
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _saving ? null : _submit,
                icon: _saving
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.publish_rounded),
                label: Text(_saving ? 'Publishing…' : 'Publish listing'),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
'''

# Valuation UX clearly identifies the API result as a demo estimate, not a reliable market valuation.
changes['frontend/lib/screens/valuation/valuation_screen.dart'] = r'''import 'package:flutter/material.dart';
import '../../constants.dart';
import '../../services/api_service.dart';

class ValuationScreen extends StatefulWidget {
  const ValuationScreen({super.key});

  @override
  State<ValuationScreen> createState() => _ValuationScreenState();
}

class _ValuationScreenState extends State<ValuationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _apiService = ApiService();
  Map<String, dynamic>? _result;
  String? _error;
  bool _loading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _evaluate() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; _result = null; });
    try {
      final result = await _apiService.evaluateItem(
        itemName: _nameController.text,
        description: _descriptionController.text,
      );
      if (mounted) setState(() => _result = result);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final value = _result?['estimated_value'];
    final confidence = _result?['confidence_score'];
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(title: const Text('AI Valuator')),
      body: ListView(
        padding: const EdgeInsets.all(kDefaultPadding),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [kPrimaryColor, kBarterColor], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 34),
                SizedBox(height: 12),
                Text('Get a starting point', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                SizedBox(height: 6),
                Text('Describe your item to see an illustrative estimate before you create a listing.', style: TextStyle(color: Colors.white, height: 1.4)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Card.outlined(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Item name', hintText: 'e.g. Used Android phone'),
                      validator: (value) => value == null || value.trim().isEmpty ? 'Enter an item name' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _descriptionController,
                      minLines: 3,
                      maxLines: 5,
                      decoration: const InputDecoration(labelText: 'Condition and details', hintText: 'Brand, age, condition and included accessories'),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: _loading ? null : _evaluate,
                        icon: _loading
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.auto_awesome_rounded),
                        label: Text(_loading ? 'Estimating…' : 'Estimate item'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: kErrorColor)),
          ],
          if (_result != null) ...[
            const SizedBox(height: 16),
            Card(
              elevation: 0,
              color: kSurfaceColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: const BorderSide(color: kBorderColor)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Illustrative estimate', style: TextStyle(color: kTextLightColor, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    Text('Value: $value barter points', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: kPrimaryColor)),
                    if (confidence != null) ...[
                      const SizedBox(height: 4),
                      Text('Demo confidence indicator: ${(confidence is num ? confidence * 100 : 0).round()}%', style: const TextStyle(color: kTextLightColor)),
                    ],
                    const SizedBox(height: 10),
                    Text((_result?['ai_comment'] ?? '').toString(), style: const TextStyle(height: 1.45)),
                    const SizedBox(height: 12),
                    const Divider(),
                    const Text(
                      'Important: the current server uses sample values, not a verified market-price model. Compare similar listings and item condition before agreeing a trade.',
                      style: TextStyle(color: kTextLightColor, fontSize: 12, height: 1.4),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
'''

# The cart is now backed by the existing cart endpoints; it has proper retry/empty/remove/checkout states.
changes['frontend/lib/screens/cart/cart_screen.dart'] = r'''import 'package:flutter/material.dart';
import '../../constants.dart';
import '../../services/api_service.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final ApiService _apiService = ApiService();
  late Future<Map<String, dynamic>> _cartFuture;
  bool _checkingOut = false;

  @override
  void initState() {
    super.initState();
    _cartFuture = _apiService.getCart();
  }

  Future<void> _reload() async {
    setState(() => _cartFuture = _apiService.getCart());
    try { await _cartFuture; } catch (_) {}
  }

  Future<void> _removeItem(int itemId) async {
    try {
      await _apiService.removeCartItem(itemId);
      if (mounted) {
        setState(() => _cartFuture = _apiService.getCart());
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Item removed from cart.')));
      }
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))));
    }
  }

  Future<void> _checkout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Place this order?'),
        content: const Text('This will create a pending order from the cash items in your cart.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Keep shopping')),
          ElevatedButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Place order')),
        ],
      ),
    );
    if (confirm != true) return;
    setState(() => _checkingOut = true);
    try {
      final order = await _apiService.createOrder();
      if (!mounted) return;
      setState(() => _cartFuture = _apiService.getCart());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Order #${order['id']} created and marked pending.')),
      );
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))));
    } finally {
      if (mounted) setState(() => _checkingOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(title: const Text('Your cart')),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _cartFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.cloud_off_rounded, size: 48, color: kTextLightColor),
                  const SizedBox(height: 12),
                  const Text('Your cart could not be loaded.'),
                  TextButton(onPressed: _reload, child: const Text('Try again')),
                ],
              ),
            );
          }
          final rawItems = snapshot.data?['items'];
          final items = rawItems is List
              ? rawItems.map((item) => Map<String, dynamic>.from(item as Map)).toList()
              : <Map<String, dynamic>>[];
          double total = 0;
          for (final item in items) {
            final listing = item['listing'];
            if (listing is Map) {
              final price = (listing['cashPrice'] as num?)?.toDouble() ?? 0;
              final quantity = (item['quantity'] as num?)?.toInt() ?? 1;
              total += price * quantity;
            }
          }
          if (items.isEmpty) {
            return RefreshIndicator(
              onRefresh: _reload,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(28),
                children: const [
                  SizedBox(height: 80),
                  Icon(Icons.shopping_bag_outlined, size: 68, color: kTextLightColor),
                  SizedBox(height: 16),
                  Center(child: Text('Your cart is empty', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600))),
                  SizedBox(height: 8),
                  Center(child: Text('Add cash listings from an item page. Barter offers are sent separately.', textAlign: TextAlign.center, style: TextStyle(color: kTextLightColor, height: 1.45))),
                ],
              ),
            );
          }
          return Column(
            children: [
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _reload,
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(kDefaultPadding),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      final listing = item['listing'] is Map
                          ? Map<String, dynamic>.from(item['listing'] as Map)
                          : <String, dynamic>{};
                      final itemId = (item['id'] as num?)?.toInt();
                      final quantity = (item['quantity'] as num?)?.toInt() ?? 1;
                      final title = (listing['title'] ?? 'Listing').toString();
                      final price = (listing['cashPrice'] as num?)?.toDouble() ?? 0;
                      final image = (listing['imageUrl'] ?? '').toString();
                      return Card.outlined(
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: SizedBox(
                              width: 56,
                              height: 56,
                              child: image.startsWith('http')
                                  ? Image.network(image, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported_outlined))
                                  : const Icon(Icons.inventory_2_outlined, color: kPrimaryColor),
                            ),
                          ),
                          title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
                          subtitle: Text('$quantity × \$${price.toStringAsFixed(2)}'),
                          trailing: IconButton(
                            tooltip: 'Remove item',
                            onPressed: itemId == null ? null : () => _removeItem(itemId),
                            icon: const Icon(Icons.delete_outline_rounded, color: kErrorColor),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              SafeArea(
                top: false,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                  decoration: const BoxDecoration(color: kSurfaceColor, border: Border(top: BorderSide(color: kBorderColor))),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Text('Subtotal', style: TextStyle(color: kTextLightColor)),
                          const Spacer(),
                          Text('\$${total.toStringAsFixed(2)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _checkingOut ? null : _checkout,
                          child: _checkingOut
                              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Text('Place order'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
'''

# Wire product actions to cart and barter offer APIs. Avoid nested Expanded widgets.
changes['frontend/lib/screens/details/components/add_to_cart.dart'] = r'''import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../utils/app_haptics.dart';
import '../../../constants.dart';
import '../../../models/product.dart';
import '../../../services/api_service.dart';

class AddToCart extends StatelessWidget {
  const AddToCart({super.key, required this.product});

  final Product product;

  Future<void> _addToCart(BuildContext context) async {
    try {
      await ApiService().addToCart(product.id);
      if (!context.mounted) return;
      AppHaptics.success();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Added to your cart.')),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Future<void> _makeOffer(BuildContext context) async {
    final itemController = TextEditingController();
    final priceController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final offer = await showDialog<Map<String, String?>>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Make a trade offer'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (product.acceptsBarter)
                  TextFormField(
                    controller: itemController,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(labelText: 'What would you offer?'),
                  ),
                if (product.acceptsCurrency) ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: priceController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Cash offer (optional)', prefixText: '\$ '),
                  ),
                ],
                const SizedBox(height: 8),
                const Text('The seller will review your offer before any trade is agreed.', style: TextStyle(color: kTextLightColor, fontSize: 12, height: 1.4)),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final offeredItem = itemController.text.trim();
              final rawPrice = priceController.text.trim();
              final price = rawPrice.isEmpty ? null : double.tryParse(rawPrice);
              if (rawPrice.isNotEmpty && (price == null || price < 0)) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(const SnackBar(content: Text('Enter a valid cash amount.')));
                return;
              }
              if (product.acceptsBarter && offeredItem.isEmpty && price == null) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(const SnackBar(content: Text('Add an item or cash amount to your offer.')));
                return;
              }
              if (!product.acceptsBarter && price == null) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(const SnackBar(content: Text('Enter a cash offer.')));
                return;
              }
              Navigator.pop(dialogContext, {
                'item': offeredItem,
                'price': rawPrice,
              });
            },
            child: const Text('Send offer'),
          ),
        ],
      ),
    );
    itemController.dispose();
    priceController.dispose();
    if (offer == null) return;

    try {
      final rawPrice = (offer['price'] ?? '').trim();
      await ApiService().createOffer(
        product.id,
        offeredItem: offer['item'],
        offeredPrice: rawPrice.isEmpty ? null : double.tryParse(rawPrice),
      );
      if (!context.mounted) return;
      AppHaptics.success();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Offer sent to the seller.')));
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasBarter = product.acceptsBarter;
    final hasCurrency = product.acceptsCurrency;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          if (hasCurrency)
            Container(
              margin: const EdgeInsets.only(right: 8),
              height: 52,
              width: 52,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: kPrimaryColor, width: 1.5),
                color: kPrimaryColor.withValues(alpha: 0.1),
              ),
              child: IconButton(
                tooltip: 'Add to cart',
                icon: SvgPicture.asset(
                  'assets/icons/add_to_cart.svg',
                  colorFilter: const ColorFilter.mode(kPrimaryColor, BlendMode.srcIn),
                ),
                onPressed: () => _addToCart(context),
              ),
            ),
          if (hasBarter)
            Expanded(
              child: _ActionButton(
                label: 'Make offer',
                color: kBarterColor,
                onTap: () => _makeOffer(context),
              ),
            ),
          if (hasBarter && hasCurrency) const SizedBox(width: 8),
          if (hasCurrency)
            Expanded(
              child: _ActionButton(
                label: 'Add · \$${product.price}',
                color: kPrimaryColor,
                onTap: () => _addToCart(context),
              ),
            ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.label, required this.color, required this.onTap});

  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          backgroundColor: color,
          elevation: 0,
          shadowColor: Colors.transparent,
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
        ),
        child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
      );
}
'''

# Validate all destination paths/anchors before writing.
existing_paths = [
    'frontend/lib/services/auth_service.dart',
    'frontend/lib/screens/auth/auth_screen.dart',
    'frontend/lib/screens/home/home_screen.dart',
]
for _path in existing_paths:
    # The transformed text for these was already read from the checkout.
    if not changes.get(_path):
        raise RuntimeError(f'No transformed contents prepared for {_path}')

new_paths = [
    'frontend/lib/screens/listing/create_listing_screen.dart',
    'frontend/lib/screens/valuation/valuation_screen.dart',
]
for _path in new_paths:
    if (ROOT / _path).exists():
        raise RuntimeError(f'Refusing to overwrite existing file: {_path}')

for path, content in changes.items():
    (ROOT / path).parent.mkdir(parents=True, exist_ok=True)
    (ROOT / path).write_text(content.rstrip() + '\n', encoding='utf-8')

print(f'Applied {len(changes)} files to {ROOT}')
print('Next: run flutter pub get, dart format frontend/lib, flutter analyze, and flutter test from frontend/.')
