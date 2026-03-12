import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../constants/theme.dart';
import '../constants/ui_constants.dart';
import 'dart:math' as math;

class BaterPassScreen extends StatefulWidget {
  const BaterPassScreen({super.key});

  @override
  State<BaterPassScreen> createState() => _BaterPassScreenState();
}

class _BaterPassScreenState extends State<BaterPassScreen> with SingleTickerProviderStateMixin {
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

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Bater-Pass Season 1', style: TextStyle(fontWeight: FontWeight.w900)),
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark 
              ? [const Color(0xFF1E1B4B), const Color(0xFF0F172A)] // Deep Purple to Slate
              : [const Color(0xFFE0E7FF), const Color(0xFFF8FAFC)],
          ),
        ),
        child: SafeArea(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    children: [
                      // Current Tier Halo 
                      Center(
                        child: AnimatedBuilder(
                          animation: _pulseController,
                          builder: (context, child) {
                            return Container(
                              padding: const EdgeInsets.all(40),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.amber.withOpacity(0.3 + (_pulseController.value * 0.3)),
                                    blurRadius: 50 + (_pulseController.value * 20),
                                    spreadRadius: 10,
                                  ),
                                  BoxShadow(
                                    color: Colors.orange.withOpacity(0.2),
                                    blurRadius: 20,
                                  )
                                ],
                                gradient: const RadialGradient(
                                  colors: [Colors.amberAccent, Colors.orange],
                                ),
                              ),
                              child: const Icon(Icons.workspace_premium_rounded, size: 80, color: Colors.white),
                            );
                          },
                        ).animate().scale(curve: Curves.easeOutBack, duration: 800.ms),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      
                      Text(
                        "GOLD TIER",
                        style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          color: Colors.amber,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 4.0,
                        ),
                      ).animate().fadeIn(delay: 400.ms),
                      
                      const SizedBox(height: AppSpacing.lg),
                      
                      // Progress Bar area
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface.withOpacity(isDark ? 0.4 : 0.8),
                          borderRadius: AppRadii.radiusXl,
                          border: Border.all(color: Colors.amber.withOpacity(0.3), width: 2),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text("$_currentXP XP", style: const TextStyle(fontWeight: FontWeight.w800)),
                                Text("Diamond: $_nextTierXP XP", style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w800)),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Stack(
                              children: [
                                Container(
                                  height: 16,
                                  decoration: BoxDecoration(
                                    color: Colors.black12,
                                    borderRadius: AppRadii.radiusPill,
                                  ),
                                ),
                                AnimatedFractionallySizedBox(
                                  duration: 1.seconds,
                                  curve: Curves.easeOutExpo,
                                  widthFactor: progress,
                                  child: Container(
                                    height: 16,
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(colors: [Colors.orange, Colors.amberAccent]),
                                      borderRadius: AppRadii.radiusPill,
                                      boxShadow: [
                                        BoxShadow(color: Colors.amber.withOpacity(0.5), blurRadius: 10)
                                      ]
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ).animate().slideY(begin: 0.2, end: 0, delay: 600.ms).fadeIn(),
                    ],
                  ),
                ),
              ),
              
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                sliver: SliverToBoxAdapter(
                  child: Text(
                    "Unlockable Perks",
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                  ),
                ),
              ),
              
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final perks = [
                      {"icon": Icons.local_shipping, "title": "Free Instant Delivery", "tier": "Diamond", "locked": true},
                      {"icon": Icons.auto_awesome, "title": "Profile Neon Halo", "tier": "Gold", "locked": false},
                      {"icon": Icons.discount, "title": "5% Fee Reduction", "tier": "Silver", "locked": false},
                      {"icon": Icons.chat_bubble, "title": "Premium Chat Stickers", "tier": "Bronze", "locked": false},
                    ];
                    
                    final perk = perks[index];
                    final isLocked = perk['locked'] as bool;
                    
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface.withOpacity(isDark ? 0.3 : 0.7),
                        borderRadius: AppRadii.radiusLg,
                        border: Border.all(color: isLocked ? Colors.grey.withOpacity(0.2) : Theme.of(context).colorScheme.primary.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isLocked ? Colors.grey.withOpacity(0.1) : Theme.of(context).colorScheme.primary.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(perk['icon'] as IconData, color: isLocked ? Colors.grey : Theme.of(context).colorScheme.primary),
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
                                    fontWeight: isLocked ? FontWeight.normal : FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  "Unlocks at ${perk['tier']}",
                                  style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                          if (isLocked)
                            const Icon(Icons.lock, color: Colors.grey)
                          else
                            const Icon(Icons.check_circle, color: Colors.green),
                        ],
                      ),
                    ).animate().slideX(begin: 0.1, end: 0, delay: Duration(milliseconds: 800 + (index * 100))).fadeIn();
                  },
                  childCount: 4,
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
      ),
    );
  }
}
