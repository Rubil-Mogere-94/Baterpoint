import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import '../providers/auth_provider.dart';
import '../constants/theme.dart';
import '../widgets/holographic_background.dart';

class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('My Wallet', style: TextStyle(fontWeight: FontWeight.w900)),
        centerTitle: true,
      ),
      body: HolographicBackground(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            const SliverToBoxAdapter(child: SizedBox(height: 110)),

            // Balance Card
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: ClipRRect(
                  borderRadius: AppRadius.roundedXXL,
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF4F46E5).withOpacity(isDark ? 0.45 : 0.55),
                            const Color(0xFF7C3AED).withOpacity(isDark ? 0.35 : 0.45),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: AppRadius.roundedXXL,
                        border: Border.all(
                          color: Colors.white.withOpacity(0.15),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF4F46E5).withOpacity(0.3),
                            blurRadius: 30,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Card top
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Baterpoints',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1.0,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.15),
                                  borderRadius: AppRadius.roundedPill,
                                ),
                                child: const Text(
                                  'ACTIVE',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.md),

                          // Balance
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${user?.loyaltyPoints ?? 0}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 48,
                                  fontWeight: FontWeight.w900,
                                  height: 1.0,
                                  letterSpacing: -2,
                                ),
                              ),
                              const Padding(
                                padding: EdgeInsets.only(bottom: 8, left: 6),
                                child: Text(
                                  'pts',
                                  style: TextStyle(
                                    color: Colors.white60,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: AppSpacing.xl),

                          // Action buttons
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _WalletActionButton(
                                icon: Icons.add_rounded,
                                label: 'Top Up',
                                onTap: () {},
                              ),
                              _WalletActionButton(
                                icon: Icons.history_rounded,
                                label: 'History',
                                onTap: () {},
                              ),
                              _WalletActionButton(
                                icon: Icons.card_giftcard_rounded,
                                label: 'Redeem',
                                onTap: () {},
                              ),
                              _WalletActionButton(
                                icon: Icons.send_rounded,
                                label: 'Send',
                                onTap: () {},
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.15, end: 0),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),

            // Section header
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              sliver: SliverToBoxAdapter(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Recent Activity',
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                    ),
                    TextButton(
                      onPressed: () {},
                      child: const Text('See All', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.sm)),

            // Transaction list
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final transactions = [
                    {'label': 'Quest Completed', 'sub': 'Completed 3-day streak', 'pts': '+150'},
                    {'label': 'Reward Redeemed', 'sub': 'Claimed discount voucher', 'pts': '-50'},
                    {'label': 'Trade Bonus', 'sub': 'Successful trade with Alex', 'pts': '+200'},
                    {'label': 'Promo Sticker Pack', 'sub': 'Limited edition unlocked', 'pts': '-30'},
                    {'label': 'Referral Bonus', 'sub': 'Friend joined Baterpoint', 'pts': '+100'},
                  ];
                  final tx = transactions[index];
                  final positive = tx['pts']!.startsWith('+');
                  final ptColor = positive ? const Color(0xFF10B981) : Colors.orange;

                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.xs,
                    ),
                    child: ClipRRect(
                      borderRadius: AppRadius.roundedXL,
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: (isDark ? Colors.white : Colors.black).withOpacity(0.04),
                            borderRadius: AppRadius.roundedXL,
                            border: Border.all(
                              color: ptColor.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: ptColor.withOpacity(0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  positive ? Icons.add_rounded : Icons.remove_rounded,
                                  color: ptColor,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      tx['label']!,
                                      style: theme.textTheme.titleSmall?.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      tx['sub']!,
                                      style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '${tx['pts']!} pts',
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 15,
                                  color: ptColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ).animate().slideX(
                        begin: 0.1,
                        end: 0,
                        delay: Duration(milliseconds: 300 + (index * 70)),
                        duration: 400.ms,
                        curve: Curves.easeOutCubic,
                      ).fadeIn(delay: Duration(milliseconds: 300 + (index * 70)));
                },
                childCount: 5,
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }
}

class _WalletActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _WalletActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.25)),
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
