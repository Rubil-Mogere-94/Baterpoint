import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/auth_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          _buildSectionHeader(context, 'Account'),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('Edit Profile'),
            onTap: () {
              // Nav to EditProfileScreen if it exists
              // For now, it's just a placeholder
            },
          ),
          ListTile(
            leading: const Icon(Icons.lock_outline),
            title: const Text('Change Password'),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip),
            title: const Text('Privacy Settings'),
            onTap: () {},
          ),
          _buildSectionHeader(context, 'Preferences'),
          SwitchListTile(
            secondary: const Icon(Icons.dark_mode_outlined),
            title: const Text('Dark Mode'),
            value: themeProvider.isDarkMode,
            onChanged: (value) {
              themeProvider.toggleTheme(value);
            },
          ),
          ListTile(
            leading: const Icon(Icons.notifications_none_rounded),
            title: const Text('Notification Preferences'),
            onTap: () {},
          ),
           ListTile(
            leading: const Icon(Icons.language_rounded),
            title: const Text('Language'),
            trailing: const Text('English (US)'),
            onTap: () {},
          ),
          _buildSectionHeader(context, 'About'),
          ListTile(
            leading: const Icon(Icons.info_outline_rounded),
            title: const Text('App Information'),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: const Text('Terms of Service'),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.policy_outlined),
            title: const Text('Privacy Policy'),
            onTap: () {},
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: ElevatedButton(
              onPressed: () {
                authProvider.logout();
                Navigator.popUntil(context, (route) => route.isFirst);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade50,
                foregroundColor: Colors.red,
                side: BorderSide(color: Colors.red.shade200),
                elevation: 0,
              ),
              child: const Text('Log Out'),
            ),
          ),
          const SizedBox(height: 48),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          letterSpacing: 1.2,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
