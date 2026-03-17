// frontend/lib/screens/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/listing.dart';
import '../services/listing_service.dart';
import '../providers/auth_provider.dart';
import '../constants/ui_constants.dart';
import 'edit_profile_screen.dart';
import 'listing_detail_screen.dart';

import 'wallet_screen.dart';
import 'wishlist_screen.dart';
import 'settings_screen.dart';
import 'orders_screen.dart';
import 'cart_screen.dart';
import 'admin_dashboard_screen.dart';
import '../widgets/holographic_background.dart';


class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ListingService _listingService = ListingService();
  late Future<List<Listing>> _myListingsFuture;

  @override
  void initState() {
    super.initState();
    _refreshMyListings();
  }

  void _refreshMyListings() {
    setState(() {
      _myListingsFuture = _listingService.fetchMyListings();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final user = auth.user;

    return HolographicBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Premium Header
            SliverAppBar(
              expandedHeight: 220,
              pinned: true,
              stretch: true,
              backgroundColor: Colors.transparent,
              elevation: 0,
              flexibleSpace: FlexibleSpaceBar(
                background: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Hero(
                        tag: 'profile_avatar',
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
                          child: CircleAvatar(
                            radius: 45,
                            backgroundColor: colorScheme.surface,
                            backgroundImage: user?.avatarUrl != null 
                                ? CachedNetworkImageProvider(user!.avatarUrl!) 
                                : null,
                            child: user?.avatarUrl == null 
                                ? Text(user?.username[0].toUpperCase() ?? 'U', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold))
                                : null,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        user?.username ?? 'Trader',
                        style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.verified_rounded, color: colorScheme.primary, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            'Verified Citizen',
                            style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                IconButton(
                  icon: Icon(Icons.settings_outlined, color: colorScheme.onSurface),
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen())),
                ),
              ],
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Impact Dashboard Card (Glassy)
                    _buildSocialStats(context),
                    const SizedBox(height: 16),
                    // Instagram-style Edit Profile Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const EditProfileScreen())),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: (Theme.of(context).brightness == Brightness.dark) ? Colors.white12 : Colors.black.withOpacity(0.05),
                          foregroundColor: (Theme.of(context).brightness == Brightness.dark) ? Colors.white : Colors.black,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                        child: const Text('Edit Profile', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      ),
                    ),
                    const SizedBox(height: 24),

                    _buildImpactCard(context),
                    const SizedBox(height: 24),

                    // Stats Grid (Glassy)
                    Row(
                      children: [
                        Expanded(child: _buildMiniStat(context, 'Trust Score', '9.8', Icons.shield_rounded, Colors.green)),
                        const SizedBox(width: 16),
                        Expanded(child: _buildMiniStat(context, 'Trades', '${user?.successfulTrades ?? 0}', Icons.handshake_rounded, colorScheme.primary)),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Menu Section
                    Text('Trading Tools', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 16),
                    _buildMenuItem(context, 'Your Orders', 'Track and manage purchases', Icons.receipt_long_rounded, Colors.blue, () => Navigator.push(context, MaterialPageRoute(builder: (context) => OrdersScreen()))),
                    _buildMenuItem(context, 'Your Cart', 'Items ready for checkout', Icons.shopping_cart_rounded, Colors.green, () => Navigator.push(context, MaterialPageRoute(builder: (context) => CartScreen()))),
                    _buildMenuItem(context, 'My Wallet', 'Manage tokens and rewards', Icons.account_balance_wallet_rounded, Colors.orange, () => Navigator.push(context, MaterialPageRoute(builder: (context) => const WalletScreen()))),
                    _buildMenuItem(context, 'Wishlist', 'Items you are tracking', Icons.favorite_rounded, Colors.red, () => Navigator.push(context, MaterialPageRoute(builder: (context) => const WishlistScreen()))),
                    _buildMenuItem(context, 'Sustainability Report', 'Your personal eco-contribution', Icons.eco_rounded, Colors.teal, () {}),

                    if (user?.role == 'admin') ...[
                      const SizedBox(height: 32),
                      Text('Admin Platform', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900, color: Colors.deepPurple)),
                      const SizedBox(height: 16),
                      _buildMenuItem(context, 'Admin Dashboard', 'Platform analytics and management', Icons.admin_panel_settings_rounded, Colors.deepPurple, () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminDashboardScreen()))),
                    ],

                    const SizedBox(height: 32),
                    Text('My Active Trades', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 12),
                    _buildMyListingsGrid(context),
                    
                    const SizedBox(height: 48),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => auth.logout(),
                        icon: const Icon(Icons.logout_rounded),
                        label: const Text('Sign Out'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: colorScheme.error,
                          side: BorderSide(color: colorScheme.error.withOpacity(0.5)),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: AppRadius.roundedLG),
                        ),
                      ),
                    ),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImpactCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: AppRadius.roundedXXL,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer.withOpacity(0.15),
            borderRadius: AppRadius.roundedXXL,
            border: Border.all(color: Colors.white.withOpacity(0.2)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('PLANET IMPACT', style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1.2)),
                      const SizedBox(height: 4),
                      const Text('42kg CO2 Saved', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), shape: BoxShape.circle),
                    child: const Icon(Icons.eco_rounded, color: Colors.green, size: 32),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: 0.7,
                  minHeight: 8,
                  backgroundColor: colorScheme.outline.withOpacity(0.1),
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'You are in the top 5% of sustainable traders this month!',
                style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniStat(BuildContext context, String label, String value, IconData icon, Color color) {
    final colorScheme = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: AppRadius.roundedXL,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.05),
            borderRadius: AppRadius.roundedXL,
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(height: 12),
              Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
              Text(label, style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 11, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, color: color),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      subtitle: Text(subtitle, style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12)),
      trailing: const Icon(Icons.chevron_right_rounded),
    );
  }

  Widget _buildMyListingsGrid(BuildContext context) {
    return FutureBuilder<List<Listing>>(
      future: _myListingsFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }
        final listings = snapshot.data!;
        
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 2,
            mainAxisSpacing: 2,
            childAspectRatio: 1,
          ),
          itemCount: listings.length,
          itemBuilder: (context, index) {
            final listing = listings[index];
            return GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ListingDetailScreen(listing: listing)),
              ),
              child: Container(
                decoration: BoxDecoration(
                  image: listing.imageUrl != null
                      ? DecorationImage(image: CachedNetworkImageProvider(listing.imageUrl!), fit: BoxFit.cover)
                      : null,
                  color: Colors.grey[900],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSocialStats(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildStatItem('Posts', '12'),
        _buildStatItem('Followers', '1.2k'),
        _buildStatItem('Following', '482'),
      ],
    );
  }

  Widget _buildStatItem(String label, String count) {
    return Column(
      children: [
        Text(count, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _buildMyListings(BuildContext context) {
    // Keeping for reference or removing if purely grid
    return const SizedBox.shrink();
  }
}
