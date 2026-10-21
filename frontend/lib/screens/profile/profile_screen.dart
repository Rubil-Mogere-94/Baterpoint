import 'package:flutter/material.dart';
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
                          backgroundImage: NetworkImage(getDiceBearAvatar(username)),
                          onBackgroundImageError: (_, __) {},
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
