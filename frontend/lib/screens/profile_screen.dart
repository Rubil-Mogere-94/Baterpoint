// frontend/lib/screens/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/listing.dart';
import '../services/listing_service.dart';
import 'edit_profile_screen.dart';
import 'listing_detail_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ListingService _listingService = ListingService();
  late Future<List<Listing>> _myListingsFuture;

  @override
  void initState() {
    super.initState();
    _refreshMyListings();
  }

  void _refreshMyListings() {
    setState(() {
      _myListingsFuture = _listingService.fetchMyListings();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final theme = Theme.of(context);
    final user = auth.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const EditProfileScreen()),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _refreshMyListings();
          await auth.refreshUser();
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: theme.colorScheme.primary,
                      child: Text(
                        user?.username != null && user!.username.isNotEmpty ? user.username[0].toUpperCase() : '?',
                        style: const TextStyle(fontSize: 40, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(user?.username ?? 'Username', style: theme.textTheme.headlineSmall),
                    Text(user?.email ?? 'Email', style: theme.textTheme.bodyMedium),
                    const SizedBox(height: 8),
                    Chip(
                      label: Text(user?.subscriptionStatus?.toUpperCase() ?? 'BASIC'),
                      backgroundColor: theme.colorScheme.secondary.withOpacity(0.1),
                      labelStyle: TextStyle(color: theme.colorScheme.secondary, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Text('My Trade Items', style: theme.textTheme.titleLarge),
              const SizedBox(height: 16),
              FutureBuilder<List<Listing>>(
                future: _myListingsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(
                      child: Column(
                        children: [
                          const SizedBox(height: 24),
                          Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey.shade400),
                          const SizedBox(height: 8),
                          Text("You haven't posted any trades yet.", style: TextStyle(color: Colors.grey.shade600)),
                        ],
                      ),
                    );
                  }

                  final listings = snapshot.data!;
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: listings.length,
                    itemBuilder: (context, index) {
                      final listing = listings[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: listing.imageUrl != null
                                ? Image.network(listing.imageUrl!, width: 50, height: 50, fit: BoxFit.cover)
                                : Container(width: 50, height: 50, color: Colors.grey.shade200),
                          ),
                          title: Text(listing.title),
                          subtitle: Text('${listing.category} • \$${listing.cashPrice}'),
                          trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                          onTap: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => ListingDetailScreen(listing: listing)),
                            );
                            if (result == true) {
                              _refreshMyListings();
                            }
                          },
                        ),
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => auth.logout(),
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Logout'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade50,
                  foregroundColor: Colors.red.shade700,
                  elevation: 0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
