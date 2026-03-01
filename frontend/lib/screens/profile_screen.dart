// frontend/lib/screens/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/listing.dart';
import '../services/listing_service.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import 'edit_profile_screen.dart';
import 'listing_detail_screen.dart';
import 'loyalty_shop_screen.dart';
import 'wallet_screen.dart';
import 'wishlist_screen.dart';
import 'settings_screen.dart';
import 'support_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ListingService _listingService = ListingService();
  late Future<List<Listing>> _myListingsFuture;
  late Future<List<Listing>> _myFavoritesFuture;

  @override
  void initState() {
    super.initState();
    _refreshMyListings();
  }

  void _refreshMyListings() {
    setState(() {
      _myListingsFuture = _listingService.fetchMyListings();
      _myFavoritesFuture = _listingService.fetchFavorites();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final theme = Theme.of(context);
    final user = auth.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const EditProfileScreen()),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _refreshMyListings();
          await auth.refreshUser();
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: theme.colorScheme.primary,
                      child: Text(
                        user?.username != null && user!.username.isNotEmpty ? user.username[0].toUpperCase() : '?',
                        style: const TextStyle(fontSize: 40, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(user?.username ?? 'Username', style: theme.textTheme.headlineSmall),
                    Text(user?.email ?? 'Email', style: theme.textTheme.bodyMedium),
                    const SizedBox(height: 8),
                    Chip(
                      label: Text(user?.subscriptionStatus?.toUpperCase() ?? 'BASIC'),
                      backgroundColor: theme.colorScheme.secondary.withOpacity(0.1),
                      labelStyle: TextStyle(color: theme.colorScheme.secondary, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 24),
                    
                    // Stats Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStatItem(
                          context,
                          'Trades',
                          '${user?.successfulTrades ?? 0}',
                          Icons.handshake_rounded,
                          Colors.blue,
                        ),
                        _buildStatItem(
                          context,
                          'Reputation',
                          '${user?.tradeReputation?.toStringAsFixed(1) ?? '5.0'}',
                          Icons.shield_rounded,
                          Colors.green,
                        ),
                        _buildStatItem(
                          context,
                          'Rating',
                          '${user?.overallRating ?? 0.0}',
                          Icons.star_rounded,
                          Colors.amber,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    // Premium Menu Grid
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.5,
                      children: [
                        _buildMenuCard(
                          context,
                          'My Wallet',
                          '${user?.loyaltyPoints ?? 0} pts',
                          Icons.account_balance_wallet_rounded,
                          Colors.blue,
                          () => Navigator.push(context, MaterialPageRoute(builder: (context) => const WalletScreen())),
                        ),
                        _buildMenuCard(
                          context,
                          'Wishlist',
                          'Saved items',
                          Icons.favorite_rounded,
                          Colors.red,
                          () => Navigator.push(context, MaterialPageRoute(builder: (context) => const WishlistScreen())),
                        ),
                        _buildMenuCard(
                          context,
                          'Loyalty Shop',
                          'Redeem rewards',
                          Icons.shopping_basket_rounded,
                          Colors.orange,
                          () => Navigator.push(context, MaterialPageRoute(builder: (context) => const LoyaltyShopScreen())).then((_) => auth.refreshUser()),
                        ),
                        _buildMenuCard(
                          context,
                          'Support',
                          'Get help',
                          Icons.support_agent_rounded,
                          Colors.teal,
                          () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SupportScreen())),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      leading: const Icon(Icons.settings_outlined),
                      title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.bold)),
                      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen()));
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Text('My Trade Items', style: theme.textTheme.titleLarge),
              const SizedBox(height: 16),
              FutureBuilder<List<Listing>>(
                future: _myListingsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(
                      child: Column(
                        children: [
                          const SizedBox(height: 24),
                          Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey.shade400),
                          const SizedBox(height: 8),
                          Text("You haven't posted any trades yet.", style: TextStyle(color: Colors.grey.shade600)),
                        ],
                      ),
                    );
                  }

                  final listings = snapshot.data!;
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: listings.length,
                    itemBuilder: (context, index) {
                      final listing = listings[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: listing.imageUrl != null
                                ? Image.network(listing.imageUrl!, width: 50, height: 50, fit: BoxFit.cover)
                                : Container(width: 50, height: 50, color: Colors.grey.shade200),
                          ),
                          title: Text(listing.title),
                          subtitle: Text('${listing.category} • \$${listing.cashPrice}'),
                          trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                          onTap: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => ListingDetailScreen(listing: listing)),
                            );
                            if (result == true) {
                              _refreshMyListings();
                            }
                          },
                        ),
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 32),
              Text('My Favorites', style: theme.textTheme.titleLarge),
              const SizedBox(height: 16),
              FutureBuilder<List<Listing>>(
                future: _myFavoritesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(
                      child: Column(
                        children: [
                          const SizedBox(height: 24),
                          Icon(Icons.favorite_border_rounded, size: 48, color: Colors.grey.shade400),
                          const SizedBox(height: 8),
                          Text("You haven't favorited any trades yet.", style: TextStyle(color: Colors.grey.shade600)),
                        ],
                      ),
                    );
                  }

                  final listings = snapshot.data!;
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: listings.length,
                    itemBuilder: (context, index) {
                      final listing = listings[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: listing.imageUrl != null
                                ? Image.network(listing.imageUrl!, width: 50, height: 50, fit: BoxFit.cover)
                                : Container(width: 50, height: 50, color: Colors.grey.shade200),
                          ),
                          title: Text(listing.title),
                          subtitle: Text('${listing.category} • \$${listing.cashPrice}'),
                          trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                          onTap: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => ListingDetailScreen(listing: listing)),
                            );
                            if (result == true) {
                              _refreshMyListings();
                            }
                          },
                        ),
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => auth.logout(),
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Logout'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade50,
                  foregroundColor: Colors.red.shade700,
                  elevation: 0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String label, String value, IconData icon, Color color) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildMenuCard(BuildContext context, String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: color, size: 28),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(fontSize: 10, color: Colors.grey.shade600),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
