import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/reward.dart';
import '../services/quest_service.dart';
import '../providers/auth_provider.dart';
import '../widgets/shimmer_loading.dart';

class LoyaltyShopScreen extends StatefulWidget {
  const LoyaltyShopScreen({super.key});

  @override
  State<LoyaltyShopScreen> createState() => _LoyaltyShopScreenState();
}

class _LoyaltyShopScreenState extends State<LoyaltyShopScreen> {
  final QuestService _questService = QuestService();
  late Future<List<Reward>> _rewardsFuture;
  bool _isRedeeming = false;

  @override
  void initState() {
    super.initState();
    _rewardsFuture = _questService.fetchRewards();
  }

  Future<void> _redeem(Reward reward) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if ((auth.user?.loyaltyPoints ?? 0) < reward.pointsCost) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Not enough points!')),
      );
      return;
    }

    setState(() => _isRedeeming = true);
    try {
      HapticFeedback.selectionClick();
      await _questService.redeemReward(reward.id);
      await auth.refreshUser(); // Update points on UI
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Succesfully redeemed ${reward.title}!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _isRedeeming = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final theme = Theme.of(context);
    final points = auth.user?.loyaltyPoints ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Loyalty Shop'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Header Stats
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withOpacity(0.3),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
            ),
            child: Column(
              children: [
                const Icon(Icons.stars_rounded, size: 48, color: Colors.orange),
                const SizedBox(height: 8),
                Text(
                  '$points',
                  style: theme.textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                Text(
                  'Available Loyalty Points',
                  style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: FutureBuilder<List<Reward>>(
                key: ValueKey(_rewardsFuture),
                future: _rewardsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: 5,
                      itemBuilder: (context, index) => ShimmerLoading.rectangular(height: 100),
                    );
                  } else if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, size: 48, color: Colors.red),
                          const SizedBox(height: 16),
                          Text('Failed to load rewards', style: theme.textTheme.titleMedium),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            onPressed: () => setState(() { _rewardsFuture = _questService.fetchRewards(); }),
                            icon: const Icon(Icons.refresh),
                            label: const Text('Retry'),
                          ),
                        ],
                      ),
                    );
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey),
                          const SizedBox(height: 16),
                          const Text('No rewards available yet.'),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () => setState(() { _rewardsFuture = _questService.fetchRewards(); }),
                            child: const Text('Refresh'),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, index) {
                      final reward = snapshot.data![index];
                      final canAfford = points >= reward.pointsCost;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: _getRewardColor(reward.rewardType).withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  _getRewardIcon(reward.rewardType),
                                  color: _getRewardColor(reward.rewardType),
                                  size: 30,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      reward.title,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                    Text(
                                      reward.description,
                                      style: theme.textTheme.bodySmall,
                                    ),
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.orange.shade50,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.stars_rounded, size: 14, color: Colors.orange),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${reward.pointsCost} pts',
                                            style: const TextStyle(
                                              color: Colors.orange,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              SizedBox(
                                width: 80,
                                child: ElevatedButton(
                                  onPressed: (canAfford && !_isRedeeming) ? () => _redeem(reward) : null,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: theme.colorScheme.primary,
                                    foregroundColor: Colors.white,
                                    padding: EdgeInsets.zero,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  child: _isRedeeming
                                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                      : const Text('Redeem', style: TextStyle(fontSize: 12)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getRewardIcon(String type) {
    switch (type) {
      case 'status': return Icons.workspace_premium_rounded;
      case 'badge': return Icons.verified_rounded;
      case 'discount': return Icons.local_offer_rounded;
      default: return Icons.card_giftcard_rounded;
    }
  }

  Color _getRewardColor(String type) {
    switch (type) {
      case 'status': return Colors.purple;
      case 'badge': return Colors.blue;
      case 'discount': return Colors.green;
      default: return Colors.orange;
    }
  }
}
