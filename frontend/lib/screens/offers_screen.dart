import 'package:flutter/material.dart';
import '../models/offer.dart';
import '../services/offer_service.dart';

class OffersScreen extends StatefulWidget {
  const OffersScreen({super.key});

  @override
  State<OffersScreen> createState() => _OffersScreenState();
}

class _OffersScreenState extends State<OffersScreen> with SingleTickerProviderStateMixin {
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
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Offers'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: theme.colorScheme.primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: theme.colorScheme.primary,
          tabs: const [
            Tab(text: 'My Offers'),
            Tab(text: 'Received'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOffersList(_myOffersFuture, isReceived: false),
          _buildOffersList(_receivedOffersFuture, isReceived: true),
        ],
      ),
    );
  }

  Widget _buildOffersList(Future<List<Offer>> future, {required bool isReceived}) {
    return FutureBuilder<List<Offer>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                const Text('Failed to load offers'),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: () => _refreshOffers(),
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
                Icon(Icons.local_offer_outlined, size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text(
                  isReceived ? "No offers received yet." : "You haven't made any offers.",
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                ),
              ],
            ),
          );
        }

        final offers = snapshot.data!;
        return RefreshIndicator(
          onRefresh: () async => _refreshOffers(),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: offers.length,
            itemBuilder: (context, index) {
              final offer = offers[index];
              return _OfferCard(
                offer: offer, 
                isReceived: isReceived, 
                onStatusUpdated: _refreshOffers,
                offerService: _offerService,
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

  const _OfferCard({
    required this.offer,
    required this.isReceived,
    required this.onStatusUpdated,
    required this.offerService,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    Color statusColor;
    if (offer.status == 'accepted') statusColor = Colors.green;
    else if (offer.status == 'rejected') statusColor = Colors.red;
    else statusColor = Colors.orange;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: offer.listing?.imageUrl != null
                      ? Image.network(offer.listing!.imageUrl!, width: 60, height: 60, fit: BoxFit.cover)
                      : Container(width: 60, height: 60, color: Colors.grey.shade200, child: const Icon(Icons.image, color: Colors.grey)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(offer.listing?.title ?? 'Unknown Listing', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              offer.status.toUpperCase(),
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(),
            ),
            Text(isReceived ? 'They Offered:' : 'You Offered:', style: theme.textTheme.labelMedium?.copyWith(color: Colors.grey.shade600)),
            const SizedBox(height: 8),
            if (offer.offeredPrice != null)
              Text('\$${offer.offeredPrice}', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: Colors.green.shade700)),
            if (offer.offeredItem != null)
              Row(
                children: [
                  Icon(Icons.swap_horiz_rounded, size: 18, color: theme.colorScheme.secondary),
                  const SizedBox(width: 8),
                  Expanded(child: Text(offer.offeredItem!, style: TextStyle(fontWeight: FontWeight.w600, color: theme.colorScheme.secondary))),
                ],
              ),
            
            if (offer.status == 'accepted') ...[
              const SizedBox(height: 16),
              if (isReceived) ...[
                // Seller View
                if (!offer.sellerConfirmed)
                  ElevatedButton.icon(
                    onPressed: () => _confirmHandshake(context),
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text("I've Handed Over Item"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 45),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  )
                else
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle, color: Colors.green.shade700, size: 20),
                        const SizedBox(width: 8),
                        Text("You've confirmed handover", style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                if (!offer.buyerConfirmed)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Center(
                      child: Text("Waiting for buyer to confirm receipt...", style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontStyle: FontStyle.italic)),
                    ),
                  ),
              ] else ...[
                // Buyer View
                if (!offer.buyerConfirmed)
                  ElevatedButton.icon(
                    onPressed: () => _confirmHandshake(context),
                    icon: const Icon(Icons.shopping_bag_outlined),
                    label: const Text("I've Received Item"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.secondary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 45),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  )
                else
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle, color: Colors.blue.shade700, size: 20),
                        const SizedBox(width: 8),
                        Text("You've confirmed receipt", style: TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                if (!offer.sellerConfirmed)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Center(
                      child: Text("Waiting for seller to confirm handover...", style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontStyle: FontStyle.italic)),
                    ),
                  ),
              ],
            ] else if (isReceived && offer.status == 'pending') ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _updateStatus(context, 'rejected'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Reject'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _updateStatus(context, 'accepted'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Accept'),
                    ),
                  ),
                ],
              )
            ] else if (offer.status == 'completed') ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [Colors.green.shade400, Colors.teal.shade400]),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: Colors.green.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))],
                ),
                child: const Column(
                  children: [
                    Icon(Icons.handshake_rounded, color: Colors.white, size: 32),
                    SizedBox(height: 4),
                    Text(
                      "TRADE COMPLETED",
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                    ),
                  ],
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }

  Future<void> _updateStatus(BuildContext context, String newStatus) async {
    try {
      await offerService.updateOfferStatus(offer.id, newStatus);
      onStatusUpdated();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Offer $newStatus')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _confirmHandshake(BuildContext context) async {
    try {
      await offerService.confirmTrade(offer.id);
      onStatusUpdated();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Trade confirmation successful!'),
          backgroundColor: Colors.green,
        ));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }
}
