import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:ui';
import '../models/offer.dart';
import '../services/offer_service.dart';
import '../widgets/shimmer_loading.dart';
import '../constants/theme.dart';
import '../widgets/holographic_background.dart';

class OffersScreen extends StatefulWidget {
  const OffersScreen({super.key});

  @override
  State<OffersScreen> createState() => _OffersScreenState();
}

class _OffersScreenState extends State<OffersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final OfferService _offerService = OfferService();

  late Future<List<Offer>> _myOffersFuture;
  late Future<List<Offer>> _receivedOffersFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _refreshOffers();
  }

  void _refreshOffers() {
    setState(() {
      _myOffersFuture = _offerService.getMyOffers();
      _receivedOffersFuture = _offerService.getReceivedOffers();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Offers', style: TextStyle(fontWeight: FontWeight.w900)),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: ClipRRect(
              borderRadius: AppRadius.roundedPill,
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: Container(
                  decoration: BoxDecoration(
                    color: (isDark ? Colors.white : Colors.black).withOpacity(0.07),
                    borderRadius: AppRadius.roundedPill,
                    border: Border.all(
                      color: (isDark ? Colors.white : Colors.black).withOpacity(0.1),
                    ),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: AppRadius.roundedPill,
                    ),
                    dividerColor: Colors.transparent,
                    labelColor: isDark ? Colors.black : Colors.white,
                    unselectedLabelColor: Colors.grey,
                    labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                    tabs: const [
                      Tab(text: 'My Offers'),
                      Tab(text: 'Received'),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      body: HolographicBackground(
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildOffersList(_myOffersFuture, isReceived: false),
            _buildOffersList(_receivedOffersFuture, isReceived: true),
          ],
        ),
      ),
    );
  }

  Widget _buildOffersList(Future<List<Offer>> future, {required bool isReceived}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return FutureBuilder<List<Offer>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, 120, AppSpacing.lg, AppSpacing.lg),
            itemCount: 4,
            itemBuilder: (context, index) =>
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: ShimmerLoading.rectangular(height: 140),
                ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: ClipRRect(
                borderRadius: AppRadius.roundedXXL,
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    decoration: BoxDecoration(
                      color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
                      borderRadius: AppRadius.roundedXXL,
                      border: Border.all(color: Colors.redAccent.withOpacity(0.2)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline_rounded, size: 48, color: Colors.redAccent),
                        const SizedBox(height: AppSpacing.md),
                        const Text('Failed to load offers', style: TextStyle(fontWeight: FontWeight.w700)),
                        const SizedBox(height: AppSpacing.md),
                        ElevatedButton.icon(
                          onPressed: _refreshOffers,
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: ClipRRect(
                borderRadius: AppRadius.roundedXXL,
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    decoration: BoxDecoration(
                      color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
                      borderRadius: AppRadius.roundedXXL,
                      border: Border.all(
                        color: (isDark ? Colors.white : Colors.black).withOpacity(0.08),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.local_offer_outlined,
                          size: 64,
                          color: Colors.grey.shade400,
                        ).animate().scale(curve: Curves.easeOutBack, duration: 600.ms),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          isReceived ? 'No offers received yet' : 'No offers made yet',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                        ).animate().fadeIn(delay: 200.ms),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          isReceived
                              ? 'Offers from other traders will appear here.'
                              : 'Start exploring and make your first offer!',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                          textAlign: TextAlign.center,
                        ).animate().fadeIn(delay: 300.ms),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        }

        final offers = snapshot.data!;
        return RefreshIndicator(
          onRefresh: () async => _refreshOffers(),
          child: ListView.builder(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, 120, AppSpacing.lg, AppSpacing.xl),
            itemCount: offers.length,
            itemBuilder: (context, index) {
              return _OfferCard(
                offer: offers[index],
                isReceived: isReceived,
                onStatusUpdated: _refreshOffers,
                offerService: _offerService,
                index: index,
              );
            },
          ),
        );
      },
    );
  }
}

class _OfferCard extends StatelessWidget {
  final Offer offer;
  final bool isReceived;
  final VoidCallback onStatusUpdated;
  final OfferService offerService;
  final int index;

  const _OfferCard({
    required this.offer,
    required this.isReceived,
    required this.onStatusUpdated,
    required this.offerService,
    required this.index,
  });

  Color get _statusColor {
    switch (offer.status) {
      case 'accepted': return const Color(0xFF10B981);
      case 'rejected': return Colors.redAccent;
      case 'completed': return const Color(0xFF4F46E5);
      default: return Colors.orange;
    }
  }

  IconData get _statusIcon {
    switch (offer.status) {
      case 'accepted': return Icons.check_circle_rounded;
      case 'rejected': return Icons.cancel_rounded;
      case 'completed': return Icons.handshake_rounded;
      default: return Icons.schedule_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final statusColor = _statusColor;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: ClipRRect(
        borderRadius: AppRadius.roundedXL,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            decoration: BoxDecoration(
              color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
              borderRadius: AppRadius.roundedXL,
              border: Border.all(
                color: statusColor.withOpacity(0.25),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row with image + title + status
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    children: [
                      // Listing image
                      ClipRRect(
                        borderRadius: AppRadius.roundedMD,
                        child: offer.listing?.imageUrl != null
                            ? CachedNetworkImage(
                                imageUrl: offer.listing!.imageUrl!,
                                width: 64,
                                height: 64,
                                fit: BoxFit.cover,
                                placeholder: (_, __) => Container(
                                  width: 64,
                                  height: 64,
                                  color: Colors.grey.withOpacity(0.15),
                                  child: const Center(
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                ),
                                errorWidget: (_, __, ___) => Container(
                                  width: 64,
                                  height: 64,
                                  color: Colors.grey.withOpacity(0.1),
                                  child: const Icon(Icons.image_not_supported_rounded, color: Colors.grey),
                                ),
                              )
                            : Container(
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(
                                  color: Colors.grey.withOpacity(0.1),
                                  borderRadius: AppRadius.roundedMD,
                                ),
                                child: const Icon(Icons.image_rounded, color: Colors.grey),
                              ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              offer.listing?.title ?? 'Unknown Listing',
                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            // Status badge
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.sm, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: statusColor.withOpacity(0.15),
                                    borderRadius: AppRadius.roundedSM,
                                    border: Border.all(color: statusColor.withOpacity(0.3)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(_statusIcon, size: 11, color: statusColor),
                                      const SizedBox(width: 4),
                                      Text(
                                        offer.status.toUpperCase(),
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          color: statusColor,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Divider
                Divider(height: 1, color: statusColor.withOpacity(0.15)),

                // Offer details
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isReceived ? 'They Offered:' : 'You Offered:',
                        style: theme.textTheme.labelMedium?.copyWith(color: Colors.grey),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      if (offer.offeredPrice != null)
                        Text(
                          '\$${offer.offeredPrice}',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF10B981),
                          ),
                        ),
                      if (offer.offeredItem != null)
                        Row(
                          children: [
                            Icon(Icons.swap_horiz_rounded,
                                size: 20,
                                color: theme.colorScheme.secondary),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                offer.offeredItem!,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: theme.colorScheme.secondary,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ],
                        ),

                      // Action buttons
                      if (offer.status == 'accepted') ...[
                        const SizedBox(height: AppSpacing.md),
                        if (isReceived) ...[
                          if (!offer.sellerConfirmed)
                            _ActionButton(
                              label: "I've Handed Over Item",
                              icon: Icons.check_circle_outline_rounded,
                              color: theme.colorScheme.primary,
                              onPressed: () => _confirmHandshake(context),
                            )
                          else
                            _ConfirmedBadge(label: "You've confirmed handover", color: const Color(0xFF10B981)),
                          if (!offer.buyerConfirmed)
                            Padding(
                              padding: const EdgeInsets.only(top: AppSpacing.sm),
                              child: Center(
                                child: Text(
                                  'Waiting for buyer to confirm receipt…',
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic),
                                ),
                              ),
                            ),
                        ] else ...[
                          if (!offer.buyerConfirmed)
                            _ActionButton(
                              label: "I've Received Item",
                              icon: Icons.shopping_bag_outlined,
                              color: theme.colorScheme.secondary,
                              onPressed: () => _confirmHandshake(context),
                            )
                          else
                            _ConfirmedBadge(label: "You've confirmed receipt", color: const Color(0xFF4F46E5)),
                          if (!offer.sellerConfirmed)
                            Padding(
                              padding: const EdgeInsets.only(top: AppSpacing.sm),
                              child: Center(
                                child: Text(
                                  'Waiting for seller to confirm handover…',
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic),
                                ),
                              ),
                            ),
                        ],
                      ] else if (isReceived && offer.status == 'pending') ...[
                        const SizedBox(height: AppSpacing.md),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _updateStatus(context, 'rejected'),
                                icon: const Icon(Icons.close_rounded, size: 18),
                                label: const Text('Reject'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.redAccent,
                                  side: const BorderSide(color: Colors.redAccent),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: AppRadius.roundedPill),
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _updateStatus(context, 'accepted'),
                                icon: const Icon(Icons.check_rounded, size: 18),
                                label: const Text('Accept'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF10B981),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: AppRadius.roundedPill),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ] else if (offer.status == 'completed') ...[
                        const SizedBox(height: AppSpacing.md),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF4F46E5), Color(0xFF10B981)],
                            ),
                            borderRadius: AppRadius.roundedLG,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF4F46E5).withOpacity(0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.handshake_rounded, color: Colors.white, size: 22),
                              SizedBox(width: AppSpacing.sm),
                              Text(
                                'TRADE COMPLETED',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    )
        .animate()
        .slideY(
          begin: 0.1,
          end: 0,
          delay: Duration(milliseconds: 100 + (index * 70)),
          duration: 400.ms,
          curve: Curves.easeOutCubic,
        )
        .fadeIn(delay: Duration(milliseconds: 100 + (index * 70)));
  }

  Future<void> _updateStatus(BuildContext context, String newStatus) async {
    try {
      await offerService.updateOfferStatus(offer.id, newStatus);
      onStatusUpdated();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Offer $newStatus'),
            backgroundColor:
                newStatus == 'accepted' ? const Color(0xFF10B981) : Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: AppRadius.roundedLG),
            margin: const EdgeInsets.all(AppSpacing.md),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _confirmHandshake(BuildContext context) async {
    try {
      await offerService.confirmTrade(offer.id);
      onStatusUpdated();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Trade confirmation successful!'),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: AppRadius.roundedLG),
            margin: const EdgeInsets.all(AppSpacing.md),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.roundedPill),
        ),
      ),
    );
  }
}

class _ConfirmedBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _ConfirmedBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: AppRadius.roundedLG,
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_rounded, color: color, size: 18),
          const SizedBox(width: AppSpacing.sm),
          Text(
            label,
            style: TextStyle(color: color, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
