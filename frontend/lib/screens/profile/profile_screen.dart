import 'package:flutter/material.dart';
import '../../constants.dart';
import '../../services/auth_service.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(kDefaultPadding),
        children: [
          // Profile header card
          Card(
            elevation: 0,
            surfaceTintColor: Colors.transparent,
            color: kSurfaceColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: BorderSide(color: kBorderColor, width: 1),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: kPrimaryColor.withValues(alpha: 0.1),
                    child: Icon(
                      Icons.person_rounded,
                      size: 50,
                      color: kPrimaryColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Trader',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'trader@baterpoint.com',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: kTextLightColor,
                        ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Stats row
          Row(
            children: [
              Expanded(child: _StatCard(value: '24', label: 'Listings', icon: Icons.list_alt_rounded)),
              const SizedBox(width: 12),
              Expanded(child: _StatCard(value: '12', label: 'Trades', icon: Icons.swap_horiz_rounded)),
              const SizedBox(width: 12),
              Expanded(child: _StatCard(value: '98%', label: 'Success', icon: Icons.check_circle_rounded)),
            ],
          ),
          const SizedBox(height: 24),
          // Menu items
          Card.outlined(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.history_rounded, color: kPrimaryColor),
                  title: const Text('My Orders'),
                  trailing: Icon(Icons.arrow_forward_ios_rounded, size: 16),
                  onTap: () {},
                ),
                Divider(height: 1, indent: 56),
                ListTile(
                  leading: Icon(Icons.favorite_rounded, color: kBarterColor),
                  title: const Text('Favorites'),
                  trailing: Icon(Icons.arrow_forward_ios_rounded, size: 16),
                  onTap: () {},
                ),
                Divider(height: 1, indent: 56),
                ListTile(
                  leading: Icon(Icons.stars_rounded, color: Colors.amber),
                  title: const Text('Loyalty Shop'),
                  trailing: Icon(Icons.arrow_forward_ios_rounded, size: 16),
                  onTap: () {},
                ),
                Divider(height: 1, indent: 56),
                ListTile(
                  leading: Icon(Icons.settings_rounded, color: kTextLightColor),
                  title: const Text('Settings'),
                  trailing: Icon(Icons.arrow_forward_ios_rounded, size: 16),
                  onTap: () {},
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => AuthService.logout(),
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Sign Out'),
              style: OutlinedButton.styleFrom(
                foregroundColor: kErrorColor,
                side: const BorderSide(color: kErrorColor),
              ),
            ),
          ),
        ],
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
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      color: kSurfaceColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: kBorderColor, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: kPrimaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: kPrimaryColor, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: kTextColor,
                  ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: kTextLightColor,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}