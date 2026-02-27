// frontend/lib/screens/listing_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/listing.dart';
import '../providers/auth_provider.dart';
import '../services/listing_service.dart';
import '../services/offer_service.dart';
import 'chat_screen.dart';
import 'edit_listing_screen.dart';
import 'checkout_screen.dart';

class ListingDetailScreen extends StatefulWidget {
  final Listing listing;

  const ListingDetailScreen({super.key, required this.listing});

  @override
  State<ListingDetailScreen> createState() => _ListingDetailScreenState();
}

class _ListingDetailScreenState extends State<ListingDetailScreen> {
  late Listing _currentListing;
  bool _isLoading = false;
  final ListingService _listingService = ListingService();
  final OfferService _offerService = OfferService();

  @override
  void initState() {
    super.initState();
    _currentListing = widget.listing;
  }

  Future<void> _refreshListing() async {
    setState(() => _isLoading = true);
    try {
      final updated = await _listingService.fetchListingById(_currentListing.id);
      setState(() {
        _currentListing = updated;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      // Handle error
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isOwner = authProvider.user?.id == _currentListing.userId;

    return Scaffold(
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300.0,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Hero(
                tag: 'listing_image_${_currentListing.id}',
                child: _currentListing.imageUrl != null
                    ? Image.network(
                        _currentListing.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            Container(color: Colors.grey.shade300, child: const Icon(Icons.broken_image, size: 64)),
                      )
                    : Container(
                        color: theme.colorScheme.surfaceContainerHighest,
                        child: Icon(Icons.image_not_supported, size: 64, color: theme.colorScheme.onSurfaceVariant),
                      ),
              ),
            ),
            leading: IconButton(
              icon: const CircleAvatar(
                backgroundColor: Colors.white54,
                child: Icon(Icons.arrow_back_rounded, color: Colors.black),
              ),
              onPressed: () => Navigator.pop(context, true), // Signal refresh to parent
            ),
            actions: [
              if (isOwner) ...[
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: CircleAvatar(
                    backgroundColor: Colors.white54,
                    child: IconButton(
                      icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                      onPressed: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EditListingScreen(listing: _currentListing),
                          ),
                        );
                        if (result == true) {
                          _refreshListing();
                        }
                      },
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: CircleAvatar(
                    backgroundColor: Colors.white54,
                    child: IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                      onPressed: () => _showDeleteDialog(context, _listingService),
                    ),
                  ),
                ),
              ],
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          _currentListing.title,
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (_currentListing.cashPrice != null && _currentListing.cashPrice! > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '\$${_currentListing.cashPrice}',
                            style: TextStyle(
                              color: theme.colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.bold,
                              fontSize: 22,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _currentListing.category.toUpperCase(),
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(Icons.visibility_outlined, size: 16, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Text(
                        '${_currentListing.viewCount} views',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  
                  // Seller Info Block
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: theme.dividerColor),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: theme.colorScheme.secondaryContainer,
                          child: Text(
                            (_currentListing.ownerUsername ?? 'U').substring(0, 1).toUpperCase(),
                            style: TextStyle(color: theme.colorScheme.onSecondaryContainer, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    _currentListing.ownerUsername ?? 'User',
                                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(Icons.verified_rounded, color: Colors.blue.shade400, size: 16),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  ...List.generate(5, (index) {
                                    return Icon(
                                      index < _currentListing.ownerRating.floor() 
                                        ? Icons.star_rounded 
                                        : (index < _currentListing.ownerRating ? Icons.star_half_rounded : Icons.star_outline_rounded),
                                      color: Colors.amber,
                                      size: 16,
                                    );
                                  }),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${_currentListing.ownerRating} (${_currentListing.ownerReviews} reviews)',
                                    style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  if (_currentListing.exchangeItem != null && _currentListing.exchangeItem!.isNotEmpty) ...[
                    Text(
                      'Looking For:',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.secondary.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: theme.colorScheme.secondary.withOpacity(0.2)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.swap_horiz_rounded, color: theme.colorScheme.secondary),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _currentListing.exchangeItem!,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: theme.colorScheme.secondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  Text(
                    'Description',
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _currentListing.description ?? 'No description provided.',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: Colors.grey.shade700,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 60), // Spacer
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: isOwner ? null : SafeArea(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatScreen(tradeId: _currentListing.id),
                      ),
                    );
                  },
                  icon: const Icon(Icons.chat_bubble_outline_rounded),
                  label: const Text('Chat'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: () => _showMakeOfferModal(context),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: const Text('Make Offer', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
              // Buy Now button, shown only if cash price is available
              if (_currentListing.cashPrice != null && _currentListing.cashPrice! > 0)
                const SizedBox(width: 8),
              if (_currentListing.cashPrice != null && _currentListing.cashPrice! > 0)
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CheckoutScreen(listing: _currentListing),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: const Text('Buy Now', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMakeOfferModal(BuildContext context) {
    final priceController = TextEditingController();
    final itemController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 24,
              right: 24,
              top: 24,
            ),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Make an Offer', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('Propose a price or an item to trade for this listing.', style: TextStyle(color: Colors.grey.shade600)),
                  const SizedBox(height: 24),
                  if (_currentListing.tradeType == 'Sale' || _currentListing.tradeType == 'Both') ...[
                    TextFormField(
                      controller: priceController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Offer Price (\$)',
                        prefixIcon: const Icon(Icons.attach_money),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (value) {
                         if ((_currentListing.tradeType == 'Sale') && (value == null || value.isEmpty)) {
                            return 'Please enter a price';
                         }
                         if (value != null && value.isNotEmpty && double.tryParse(value) == null) {
                            return 'Please enter a valid number';
                         }
                         return null;
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (_currentListing.tradeType == 'Trade' || _currentListing.tradeType == 'Both') ...[
                    TextFormField(
                      controller: itemController,
                      decoration: InputDecoration(
                        labelText: 'Offer Item',
                        prefixIcon: const Icon(Icons.swap_horiz_rounded),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (value) {
                         if ((_currentListing.tradeType == 'Trade') && (value == null || value.isEmpty)) {
                            return 'Please offer an item';
                         }
                         return null;
                      },
                    ),
                    const SizedBox(height: 24),
                  ],
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isSubmitting ? null : () async {
                        if (formKey.currentState!.validate()) {
                          // Require at least one if it's 'Both'
                          if (_currentListing.tradeType == 'Both' && priceController.text.isEmpty && itemController.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please offer a price or an item.')));
                            return;
                          }
                          
                          setModalState(() => isSubmitting = true);
                          try {
                            await _offerService.makeOffer(
                              _currentListing.id,
                              offeredPrice: priceController.text.isNotEmpty ? double.parse(priceController.text) : null,
                              offeredItem: itemController.text.isNotEmpty ? itemController.text : null,
                            );
                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Offer sent successfully!')));
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                            }
                          } finally {
                            if (mounted) setModalState(() => isSubmitting = false);
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: isSubmitting 
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Submit Offer', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, ListingService listingService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Listing'),
        content: const Text('Are you sure you want to delete this listing? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await listingService.deleteListing(_currentListing.id);
                if (context.mounted) {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context, true); // Close detail screen and signal refresh
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error deleting listing: $e')),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
