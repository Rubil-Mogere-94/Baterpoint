// frontend/lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/listing.dart';
import '../services/listing_service.dart';
import '../providers/auth_provider.dart';
import 'create_listing_screen.dart';
import 'chat_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ListingService _listingService = ListingService();
  late Future<List<Listing>> _listingsFuture;

  @override
  void initState() {
    super.initState();
    _listingsFuture = _listingService.fetchListings();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Baterpoint'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => Provider.of<AuthProvider>(context, listen: false).logout(),
          ),
        ],
      ),
      body: FutureBuilder<List<Listing>>(
        future: _listingsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No listings found.'));
          }

          final listings = snapshot.data!;
          return ListView.builder(
            itemCount: listings.length,
            itemBuilder: (context, index) {
              final listing = listings[index];
              return Card(
                margin: const EdgeInsets.all(8.0),
                child: ListTile(
                  leading: listing.imageUrl != null
                      ? Image.network(listing.imageUrl!, width: 50, height: 50, fit: BoxFit.cover)
                      : const Icon(Icons.image),
                  title: Text(listing.title),
                  subtitle: Text(listing.description ?? ''),
                  trailing: Text('\$${listing.price ?? 0}'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatScreen(tradeId: listing.id),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateListingScreen()),
          );
          if (result == true) {
            setState(() {
              _listingsFuture = _listingService.fetchListings();
            });
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
