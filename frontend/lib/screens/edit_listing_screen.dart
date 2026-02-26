// frontend/lib/screens/edit_listing_screen.dart
import 'package:flutter/material.dart';
import '../models/listing.dart';
import '../services/listing_service.dart';

class EditListingScreen extends StatefulWidget {
  final Listing listing;
  const EditListingScreen({super.key, required this.listing});

  @override
  State<EditListingScreen> createState() => _EditListingScreenState();
}

class _EditListingScreenState extends State<EditListingScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;
  late TextEditingController _exchangeController;
  late TextEditingController _categoryController;
  late String _tradeType;
  bool _isSubmitting = false;

  final ListingService _listingService = ListingService();

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.listing.title);
    _descriptionController = TextEditingController(text: widget.listing.description);
    _priceController = TextEditingController(text: widget.listing.cashPrice?.toString() ?? '');
    _exchangeController = TextEditingController(text: widget.listing.exchangeItem);
    _categoryController = TextEditingController(text: widget.listing.category);
    _tradeType = widget.listing.tradeType ?? 'Both';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _exchangeController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Edit Listing'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Item Name',
                  prefixIcon: Icon(Icons.title_rounded),
                ),
                validator: (v) => v!.isEmpty ? 'Please enter item name' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _tradeType,
                decoration: const InputDecoration(
                  labelText: 'Accepting',
                  prefixIcon: Icon(Icons.swap_horiz_rounded),
                ),
                items: ['Both', 'Cash Only', 'Barter Only']
                    .map((label) => DropdownMenuItem(
                          value: label,
                          child: Text(label),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _tradeType = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              if (_tradeType != 'Barter Only')
                TextFormField(
                  controller: _priceController,
                  decoration: const InputDecoration(
                    labelText: 'Cash Price',
                    prefixIcon: Icon(Icons.attach_money_rounded),
                  ),
                  keyboardType: TextInputType.number,
                ),
              if (_tradeType != 'Cash Only') ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: _exchangeController,
                  decoration: const InputDecoration(
                    labelText: 'Looking to Barter For...',
                    prefixIcon: Icon(Icons.shopping_bag_outlined),
                  ),
                  validator: (v) => (_tradeType == 'Barter Only' && (v == null || v.isEmpty))
                      ? 'Please specify what you want to barter for'
                      : null,
                ),
              ],
              const SizedBox(height: 16),
              TextFormField(
                controller: _categoryController,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  prefixIcon: Icon(Icons.category_rounded),
                ),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  alignLabelWithHint: true,
                  prefixIcon: Padding(
                    padding: EdgeInsets.only(bottom: 60),
                    child: Icon(Icons.description_rounded),
                  ),
                ),
                maxLines: 4,
                validator: (v) => v!.isEmpty ? 'Please enter a description' : null,
              ),
              const SizedBox(height: 32),
              if (_isSubmitting)
                const Center(child: CircularProgressIndicator())
              else
                ElevatedButton(
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      setState(() => _isSubmitting = true);
                      try {
                        await _listingService.updateListing(
                          widget.listing.id,
                          title: _titleController.text,
                          description: _descriptionController.text,
                          cashPrice: double.tryParse(_priceController.text),
                          exchangeItem: _exchangeController.text,
                          tradeType: _tradeType,
                          category: _categoryController.text,
                        );
                        if (context.mounted) {
                          Navigator.pop(context, true);
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(e.toString())),
                          );
                        }
                      } finally {
                        if (mounted) {
                          setState(() => _isSubmitting = false);
                        }
                      }
                    }
                  },
                  child: const Text('Update Listing'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
