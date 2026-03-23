import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import '../providers/theme_provider.dart';
import '../providers/auth_provider.dart';
import '../constants/theme.dart';
import '../widgets/holographic_background.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final themeProvider = Provider.of<ThemeProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.w900)),
        centerTitle: true,
      ),
      body: HolographicBackground(
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            AppSpacing.lg,
            MediaQuery.of(context).padding.top + kToolbarHeight + AppSpacing.md,
            AppSpacing.lg,
            MediaQuery.of(context).padding.bottom + AppSpacing.xxl,
          ),
          children: [
            // Account section
            _SettingsSectionHeader(label: 'Account', delay: 0),
            _GlassSettingsGroup(
              isDark: isDark,
              delay: 100,
              children: [
                _SettingsTile(
                  icon: Icons.person_outline_rounded,
                  label: 'Edit Profile',
                  onTap: () {},
                ),
                _SettingsDivider(isDark: isDark),
                _SettingsTile(
                  icon: Icons.lock_outline_rounded,
                  label: 'Change Password',
                  onTap: () {},
                ),
                _SettingsDivider(isDark: isDark),
                _SettingsTile(
                  icon: Icons.privacy_tip_outlined,
                  label: 'Privacy Settings',
                  onTap: () {},
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.lg),

            // Preferences section
            _SettingsSectionHeader(label: 'Preferences', delay: 200),
            _GlassSettingsGroup(
              isDark: isDark,
              delay: 300,
              children: [
                _SettingsSwitchTile(
                  icon: Icons.dark_mode_outlined,
                  label: 'Dark Mode',
                  value: themeProvider.isDarkMode,
                  onChanged: (val) => themeProvider.toggleTheme(val),
                ),
                _SettingsDivider(isDark: isDark),
                _SettingsTile(
                  icon: Icons.notifications_none_rounded,
                  label: 'Notification Preferences',
                  onTap: () {},
                ),
                _SettingsDivider(isDark: isDark),
                _SettingsTile(
                  icon: Icons.language_rounded,
                  label: 'Language',
                  trailingLabel: 'English (US)',
                  onTap: () {},
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.lg),

            // About section
            _SettingsSectionHeader(label: 'About', delay: 400),
            _GlassSettingsGroup(
              isDark: isDark,
              delay: 500,
              children: [
                _SettingsTile(
                  icon: Icons.info_outline_rounded,
                  label: 'App Information',
                  trailingLabel: 'v2.0.0',
                  onTap: () {},
                ),
                _SettingsDivider(isDark: isDark),
                _SettingsTile(
                  icon: Icons.description_outlined,
                  label: 'Terms of Service',
                  onTap: () {},
                ),
                _SettingsDivider(isDark: isDark),
                _SettingsTile(
                  icon: Icons.policy_outlined,
                  label: 'Privacy Policy',
                  onTap: () {},
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.xl),

            // Logout button
            ClipRRect(
              borderRadius: AppRadius.roundedPill,
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: SizedBox(
                  height: 54,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      authProvider.logout();
                      Navigator.popUntil(context, (route) => route.isFirst);
                    },
                    icon: const Icon(Icons.logout_rounded),
                    label: const Text(
                      'Sign Out',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                      side: const BorderSide(color: Colors.redAccent, width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: AppRadius.roundedPill),
                      backgroundColor: Colors.redAccent.withOpacity(0.06),
                    ),
                  ),
                ),
              ),
            ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.15, end: 0),
          ],
        ),
      ),
    );
  }
}

class _SettingsSectionHeader extends StatelessWidget {
  final String label;
  final int delay;

  const _SettingsSectionHeader({required this.label, required this.delay});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm, left: AppSpacing.xs),
      child: Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              letterSpacing: 2.0,
              fontWeight: FontWeight.w800,
              color: Theme.of(context).colorScheme.secondary,
            ),
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: delay));
  }
}

class _GlassSettingsGroup extends StatelessWidget {
  final List<Widget> children;
  final bool isDark;
  final int delay;

  const _GlassSettingsGroup({
    required this.children,
    required this.isDark,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: AppRadius.roundedXL,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          decoration: BoxDecoration(
            color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
            borderRadius: AppRadius.roundedXL,
            border: Border.all(
              color: (isDark ? Colors.white : Colors.black).withOpacity(0.08),
              width: 1,
            ),
          ),
          child: Column(children: children),
        ),
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: delay)).slideY(begin: 0.1, end: 0);
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? trailingLabel;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.label,
    this.trailingLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 2,
      ),
      leading: Icon(icon, color: theme.colorScheme.secondary, size: 22),
      title: Text(
        label,
        style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailingLabel != null)
            Text(
              trailingLabel!,
              style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
            ),
          const SizedBox(width: 4),
          Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400, size: 20),
        ],
      ),
    );
  }
}

class _SettingsSwitchTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingsSwitchTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SwitchListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 2,
      ),
      secondary: Icon(icon, color: theme.colorScheme.secondary, size: 22),
      title: Text(
        label,
        style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
      ),
      value: value,
      onChanged: onChanged,
      activeThumbColor: theme.colorScheme.secondary,
    );
  }
}

class _SettingsDivider extends StatelessWidget {
  final bool isDark;
  const _SettingsDivider({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      indent: 54,
      endIndent: AppSpacing.md,
      color: (isDark ? Colors.white : Colors.black).withOpacity(0.07),
    );
  }
}
