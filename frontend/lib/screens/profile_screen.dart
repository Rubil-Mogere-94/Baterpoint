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

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Premium Header
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            stretch: true,
            backgroundColor: colorScheme.surface,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Animated background gradient
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [colorScheme.primary, colorScheme.secondary.withOpacity(0.8)],
                      ),
                    ),
                  ),
                  // Abstract shapes
                  Positioned(
                    top: -50,
                    right: -50,
                    child: CircleAvatar(radius: 100, backgroundColor: Colors.white.withOpacity(0.1)),
                  ),
                  
                  Padding(
                    padding: const EdgeInsets.only(top: 60),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Hero(
                          tag: 'profile_avatar',
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                            child: CircleAvatar(
                              radius: 50,
                              backgroundColor: colorScheme.surface,
                              backgroundImage: user?.avatarUrl != null 
                                  ? CachedNetworkImageProvider(user!.avatarUrl!) 
                                  : null,
                              child: user?.avatarUrl == null 
                                  ? Text(user?.username[0].toUpperCase() ?? 'U', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold))
                                  : null,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          user?.username ?? 'Trader',
                          style: theme.textTheme.headlineSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w900),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.verified_rounded, color: Colors.blue.shade200, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              'Verified Citizen',
                              style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.settings_outlined, color: Colors.white),
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen())),
              ),
            ],
          ),

          SliverToBoxAdapter(
            child: Container(
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
              ),
              transform: Matrix4.translationValues(0, -32, 0),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Impact Dashboard Card
                    _buildImpactCard(context),
                    const SizedBox(height: 32),

                    // Stats Grid
                    Row(
                      children: [
                        Expanded(child: _buildMiniStat(context, 'Trust Score', '9.8', Icons.shield_rounded, Colors.green)),
                        const SizedBox(width: 16),
                        Expanded(child: _buildMiniStat(context, 'Successful Trades', '${user?.successfulTrades ?? 0}', Icons.handshake_rounded, Colors.blue)),
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('My Active Trades', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                        OutlinedButton.icon(
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const EditProfileScreen())),
                          icon: const Icon(Icons.edit_outlined, size: 16),
                          label: const Text('Edit Profile'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            side: BorderSide(color: colorScheme.outline.withOpacity(0.3)),
                            shape: RoundedRectangleBorder(borderRadius: AppRadius.roundedMD),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildMyListings(context),
                    
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
          ),
        ],
      ),
    );
  }

  Widget _buildImpactCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colorScheme.surfaceContainerHighest, colorScheme.surface],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.outline.withOpacity(0.1)),
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
    );
  }

  Widget _buildMiniStat(BuildContext context, String label, String value, IconData icon, Color color) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outline.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
          Text(label, style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 11, fontWeight: FontWeight.w600)),
        ],
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

  Widget _buildMyListings(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return FutureBuilder<List<Listing>>(
      future: _myListingsFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
              borderRadius: AppRadius.roundedXXL,
              border: Border.all(color: colorScheme.outline.withOpacity(0.08)),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.inventory_2_outlined, size: 32, color: colorScheme.onSurfaceVariant.withOpacity(0.4)),
                  const SizedBox(height: 8),
                  Text('No active listings', style: TextStyle(color: colorScheme.onSurfaceVariant)),
                ],
              ),
            ),
          );
        }
        
        return SizedBox(
          height: 130,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final listing = snapshot.data![index];
              return GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ListingDetailScreen(listing: listing)),
                ),
                child: Container(
                  width: 110,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    borderRadius: AppRadius.roundedXL,
                    color: colorScheme.surfaceContainerHighest,
                    image: listing.imageUrl != null
                        ? DecorationImage(image: CachedNetworkImageProvider(listing.imageUrl!), fit: BoxFit.cover)
                        : null,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: AppRadius.roundedXL,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                        stops: const [0.5, 1.0],
                      ),
                    ),
                    alignment: Alignment.bottomLeft,
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      listing.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
