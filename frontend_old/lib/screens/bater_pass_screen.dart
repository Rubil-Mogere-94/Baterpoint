import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:ui';
import '../constants/theme.dart';
import '../widgets/holographic_background.dart';

class BaterPassScreen extends StatefulWidget {
  const BaterPassScreen({super.key});

  @override
  State<BaterPassScreen> createState() => _BaterPassScreenState();
}

class _BaterPassScreenState extends State<BaterPassScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  final int _currentXP = 4250;
  final int _nextTierXP = 5000;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final progress = _currentXP / _nextTierXP;
    const tierColor = Colors.amber;
    const tierColorAlt = Colors.orange;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Bater-Pass',
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: -0.5),
        ),
        centerTitle: true,
      ),
      body: HolographicBackground(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Top padding for AppBar
            const SliverToBoxAdapter(child: SizedBox(height: 120)),

            // Season header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: ClipRRect(
                  borderRadius: AppRadius.roundedXXL,
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
                        borderRadius: AppRadius.roundedXXL,
                        border: Border.all(
                          color: Colors.amber.withOpacity(0.25),
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        children: [
                          // Tier Badge with animated glow
                          AnimatedBuilder(
                            animation: _pulseController,
                            builder: (context, child) {
                              return Container(
                                padding: const EdgeInsets.all(28),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: const RadialGradient(
                                    colors: [Color(0xFFFFD700), Colors.orange],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.amber.withOpacity(
                                          0.4 + (_pulseController.value * 0.3)),
                                      blurRadius: 40 + (_pulseController.value * 20),
                                      spreadRadius: 8,
                                    ),
                                    BoxShadow(
                                      color: Colors.orange.withOpacity(0.2),
                                      blurRadius: 15,
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.workspace_premium_rounded,
                                  size: 64,
                                  color: Colors.white,
                                ),
                              );
                            },
                          ).animate().scale(
                                curve: Curves.easeOutBack,
                                duration: 800.ms,
                              ),
                          const SizedBox(height: AppSpacing.lg),

                          // Tier name
                          Text(
                            'GOLD TIER',
                            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                                  color: tierColor,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 5.0,
                                ),
                          ).animate().fadeIn(delay: 400.ms),

                          const SizedBox(height: 4),
                          Text(
                            'Season 1  ·  2026',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.grey,
                                  letterSpacing: 1.0,
                                ),
                          ).animate().fadeIn(delay: 500.ms),

                          const SizedBox(height: AppSpacing.xl),

                          // XP Progress
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '$_currentXP XP',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 20,
                                      color: Colors.amber,
                                    ),
                                  ),
                                  const Text(
                                    'Current',
                                    style: TextStyle(color: Colors.grey, fontSize: 12),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '$_nextTierXP XP',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
                                      color: isDark ? Colors.white60 : Colors.black38,
                                    ),
                                  ),
                                  const Text(
                                    'Diamond',
                                    style: TextStyle(color: Colors.grey, fontSize: 12),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.md),

                          // Progress bar
                          Stack(
                            children: [
                              Container(
                                height: 12,
                                decoration: BoxDecoration(
                                  color: Colors.black12,
                                  borderRadius: AppRadius.roundedPill,
                                ),
                              ),
                              AnimatedFractionallySizedBox(
                                duration: 1200.ms,
                                curve: Curves.easeOutExpo,
                                widthFactor: progress,
                                child: Container(
                                  height: 12,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Colors.orange, Colors.amberAccent],
                                    ),
                                    borderRadius: AppRadius.roundedPill,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.amber.withOpacity(0.6),
                                        blurRadius: 10,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: AppSpacing.sm),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              '${(progress * 100).toStringAsFixed(0)}% to Diamond',
                              style: TextStyle(
                                fontSize: 11,
                                color: tierColorAlt,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ).animate().slideY(begin: 0.15, end: 0, delay: 200.ms, duration: 600.ms, curve: Curves.easeOutCubic).fadeIn(delay: 200.ms),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),

            // Section header
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              sliver: SliverToBoxAdapter(
                child: Row(
                  children: [
                    const Icon(Icons.stars_rounded, color: Colors.amber, size: 20),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'Unlockable Perks',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),

            // Perks
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final perks = [
                    {
                      'icon': Icons.local_shipping_rounded,
                      'title': 'Free Instant Delivery',
                      'subtitle': 'Skip shipping fees on every trade.',
                      'tier': 'Diamond',
                      'tierColor': const Color(0xFF818CF8),
                      'locked': true,
                    },
                    {
                      'icon': Icons.auto_awesome_rounded,
                      'title': 'Profile Neon Halo',
                      'subtitle': 'Stand out with a glowing profile ring.',
                      'tier': 'Gold',
                      'tierColor': Colors.amber,
                      'locked': false,
                    },
                    {
                      'icon': Icons.discount_rounded,
                      'title': '5% Fee Reduction',
                      'subtitle': 'Reduced platform fees on all trades.',
                      'tier': 'Silver',
                      'tierColor': Colors.blueGrey,
                      'locked': false,
                    },
                    {
                      'icon': Icons.chat_bubble_rounded,
                      'title': 'Premium Chat Stickers',
                      'subtitle': 'Express yourself with exclusive stickers.',
                      'tier': 'Bronze',
                      'tierColor': const Color(0xFFCD7F32),
                      'locked': false,
                    },
                  ];

                  final perk = perks[index];
                  final isLocked = perk['locked'] as bool;
                  final perkTierColor = perk['tierColor'] as Color;

                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.xs,
                    ),
                    child: ClipRRect(
                      borderRadius: AppRadius.roundedXL,
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                        child: Container(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: (isDark ? Colors.white : Colors.black)
                                .withOpacity(isLocked ? 0.03 : 0.06),
                            borderRadius: AppRadius.roundedXL,
                            border: Border.all(
                              color: isLocked
                                  ? Colors.grey.withOpacity(0.15)
                                  : perkTierColor.withOpacity(0.35),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isLocked
                                      ? Colors.grey.withOpacity(0.1)
                                      : perkTierColor.withOpacity(0.15),
                                  shape: BoxShape.circle,
                                  boxShadow: isLocked
                                      ? null
                                      : [
                                          BoxShadow(
                                            color: perkTierColor.withOpacity(0.3),
                                            blurRadius: 12,
                                          ),
                                        ],
                                ),
                                child: Icon(
                                  perk['icon'] as IconData,
                                  color: isLocked ? Colors.grey : perkTierColor,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      perk['title'] as String,
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                            color: isLocked ? Colors.grey : null,
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      perk['subtitle'] as String,
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            color: Colors.grey,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.sm,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: perkTierColor.withOpacity(isLocked ? 0.08 : 0.15),
                                  borderRadius: AppRadius.roundedSM,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (isLocked)
                                      const Icon(Icons.lock_rounded, size: 12, color: Colors.grey)
                                    else
                                      Icon(Icons.check_rounded, size: 12, color: perkTierColor),
                                    const SizedBox(width: 4),
                                    Text(
                                      perk['tier'] as String,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        color: isLocked ? Colors.grey : perkTierColor,
                                      ),
                                    ),
                                  ],
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
                        delay: Duration(milliseconds: 600 + (index * 80)),
                        duration: 400.ms,
                        curve: Curves.easeOutCubic,
                      ).fadeIn(delay: Duration(milliseconds: 600 + (index * 80)));
                },
                childCount: 4,
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }
}
