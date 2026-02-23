// frontend/lib/screens/inbox_screen.dart
import 'package:flutter/material.dart';
import '../models/listing.dart';
import '../services/listing_service.dart';
import 'chat_screen.dart';

class InboxScreen extends StatefulWidget {
  const InboxScreen({super.key});

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
  final ListingService _listingService = ListingService();
  late Future<List<Listing>> _chatsFuture;

  @override
  void initState() {
    super.initState();
    _chatsFuture = _listingService.fetchMyChats();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Trades'),
      ),
      body: FutureBuilder<List<Listing>>(
        future: _chatsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble_outline_rounded, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'No active trades yet',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                  ),
                ],
              ),
            );
          }

          final listings = snapshot.data!;
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: listings.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final listing = listings[index];
              return Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: listing.imageUrl != null
                        ? Image.network(listing.imageUrl!, width: 60, height: 60, fit: BoxFit.cover)
                        : Container(width: 60, height: 60, color: Colors.grey.shade200, child: const Icon(Icons.image)),
                  ),
                  title: Text(listing.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(listing.description ?? '', maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (listing.cashPrice != null && listing.cashPrice! > 0)
                            Text('\$${listing.cashPrice} ', style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.bold)),
                          if (listing.exchangeItem != null && listing.exchangeItem!.isNotEmpty)
                            Expanded(child: Text('↔ ${listing.exchangeItem}', style: TextStyle(color: theme.colorScheme.secondary, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
                        ],
                      ),
                    ],
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ChatScreen(tradeId: listing.id)),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
