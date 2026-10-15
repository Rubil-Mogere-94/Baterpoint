import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../constants.dart';
import '../../services/api_service.dart';

class CreateListingScreen extends StatefulWidget {
  const CreateListingScreen({super.key});

  @override
  State<CreateListingScreen> createState() => _CreateListingScreenState();
}

class _CreateListingScreenState extends State<CreateListingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _exchangeController = TextEditingController();
  final _apiService = ApiService();
  final _picker = ImagePicker();
  String _category = 'Electronics';
  String _tradeType = 'Both';
  XFile? _image;
  Future<Uint8List>? _imageBytes;
  bool _saving = false;

  static const _categories = [
    'Electronics', 'Furniture', 'Vehicles', 'Services', 'Fashion',
    'Home & Garden', 'Sports', 'Books', 'Other',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _exchangeController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked == null || !mounted) return;
    setState(() {
      _image = picked;
      _imageBytes = picked.readAsBytes();
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add a photo so traders can see your item.')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await _apiService.createListing(
        title: _titleController.text,
        description: _descriptionController.text,
        category: _category,
        tradeType: _tradeType,
        image: _image!,
        cashPrice: _tradeType == 'Barter' ? null : _priceController.text,
        exchangeItem: _tradeType == 'Sale' ? null : _exchangeController.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your listing is live.')),
      );
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not publish listing: ${error.toString().replaceFirst('Exception: ', '')}')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final needsCash = _tradeType != 'Barter';
    final needsExchange = _tradeType != 'Sale';
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(title: const Text('List an item')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(kDefaultPadding),
          children: [
            Text('Show traders what you have', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            const Text('Add clear details and choose whether you want cash, barter, or either.', style: TextStyle(color: kTextLightColor, height: 1.45)),
            const SizedBox(height: 18),
            InkWell(
              onTap: _saving ? null : _pickImage,
              borderRadius: BorderRadius.circular(18),
              child: Container(
                height: 190,
                decoration: BoxDecoration(
                  color: kSurfaceColor,
                  border: Border.all(color: kBorderColor),
                  borderRadius: BorderRadius.circular(18),
                ),
                clipBehavior: Clip.antiAlias,
                child: _imageBytes == null
                    ? const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_photo_alternate_outlined, size: 44, color: kPrimaryColor),
                          SizedBox(height: 8),
                          Text('Add item photo', style: TextStyle(fontWeight: FontWeight.w600)),
                          SizedBox(height: 4),
                          Text('A clear photo helps build trust', style: TextStyle(color: kTextLightColor, fontSize: 12)),
                        ],
                      )
                    : FutureBuilder<Uint8List>(
                        future: _imageBytes,
                        builder: (context, snapshot) => snapshot.hasData
                            ? Image.memory(snapshot.data!, fit: BoxFit.cover, width: double.infinity)
                            : const Center(child: CircularProgressIndicator()),
                      ),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _titleController,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Item title', hintText: 'e.g. Wireless headphones'),
              validator: (value) => value == null || value.trim().isEmpty ? 'Enter an item title' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descriptionController,
              minLines: 3,
              maxLines: 5,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Description', hintText: 'Describe condition, age and anything a trader should know.'),
              validator: (value) => value == null || value.trim().isEmpty ? 'Add a short description' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _category,
              decoration: const InputDecoration(labelText: 'Category'),
              items: _categories.map((category) => DropdownMenuItem(value: category, child: Text(category))).toList(),
              onChanged: _saving ? null : (value) { if (value != null) setState(() => _category = value); },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _tradeType,
              decoration: const InputDecoration(labelText: 'How would you trade it?'),
              items: const [
                DropdownMenuItem(value: 'Barter', child: Text('Barter only')),
                DropdownMenuItem(value: 'Sale', child: Text('Cash only')),
                DropdownMenuItem(value: 'Both', child: Text('Barter or cash')),
              ],
              onChanged: _saving ? null : (value) { if (value != null) setState(() => _tradeType = value); },
            ),
            if (needsCash) ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: _priceController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Cash price', prefixText: '\$ ', helperText: 'Use the currency configured for your marketplace.'),
                validator: (value) {
                  if (!needsCash) return null;
                  final price = double.tryParse((value ?? '').trim());
                  return price == null || price <= 0 ? 'Enter a price greater than zero' : null;
                },
              ),
            ],
            if (needsExchange) ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: _exchangeController,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(labelText: 'What would you accept in exchange?', hintText: 'e.g. A tablet, bicycle, or similar-value item'),
                validator: (value) => needsExchange && (value == null || value.trim().isEmpty) ? 'Describe what you would accept' : null,
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _saving ? null : _submit,
                icon: _saving
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.publish_rounded),
                label: Text(_saving ? 'Publishing…' : 'Publish listing'),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
