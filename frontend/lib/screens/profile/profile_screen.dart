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
          Center(
            child: CircleAvatar(
              radius: 50,
              backgroundColor: kPrimaryColor.withValues(alpha: 0.1),
              child: Icon(
                Icons.person_rounded,
                size: 50,
                color: kPrimaryColor,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              'Trader',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          const SizedBox(height: 4),
          Center(
            child: Text(
              'trader@baterpoint.com',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: kTextLightColor,
                  ),
            ),
          ),
          const SizedBox(height: 32),
          _buildStatCard(context, '24', 'Listings', Icons.list_alt_rounded),
          const SizedBox(height: 12),
          _buildStatCard(context, '12', 'Trades', Icons.swap_horiz_rounded),
          const SizedBox(height: 12),
          _buildStatCard(context, '98%', 'Success', Icons.check_circle_rounded),
          const SizedBox(height: 32),
          ListTile(
            leading: Icon(Icons.history_rounded, color: kPrimaryColor),
            title: const Text('My Orders'),
            trailing: Icon(Icons.arrow_forward_ios_rounded, size: 16),
            onTap: () {},
          ),
          const Divider(),
          ListTile(
            leading: Icon(Icons.favorite_rounded, color: kBarterColor),
            title: const Text('Favorites'),
            trailing: Icon(Icons.arrow_forward_ios_rounded, size: 16),
            onTap: () {},
          ),
          const Divider(),
          ListTile(
            leading: Icon(Icons.stars_rounded, color: Colors.amber),
            title: const Text('Loyalty Shop'),
            trailing: Icon(Icons.arrow_forward_ios_rounded, size: 16),
            onTap: () {},
          ),
          const Divider(),
          ListTile(
            leading: Icon(Icons.settings_rounded, color: kTextLightColor),
            title: const Text('Settings'),
            trailing: Icon(Icons.arrow_forward_ios_rounded, size: 16),
            onTap: () {},
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

  Widget _buildStatCard(
      BuildContext context, String value, String label, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: kPrimaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: kPrimaryColor, size: 24),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: kTextColor,
                      ),
                ),
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: kTextLightColor,
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}