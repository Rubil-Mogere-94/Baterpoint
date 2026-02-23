// frontend/lib/screens/create_listing_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/listing_service.dart';

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
  final _categoryController = TextEditingController();
  final _tradeTypeController = TextEditingController();
  File? _image;
  bool _isSubmitting = false;

  final ListingService _listingService = ListingService();

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Listing')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
              ),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(labelText: 'Price'),
                keyboardType: TextInputType.number,
              ),
              TextFormField(
                controller: _categoryController,
                decoration: const InputDecoration(labelText: 'Category'),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: _tradeTypeController,
                decoration: const InputDecoration(labelText: 'Trade Type (Cash/Trade)'),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              _image == null
                  ? ElevatedButton(onPressed: _pickImage, child: const Text('Pick Image'))
                  : Image.file(_image!, height: 100),
              const SizedBox(height: 24),
              _isSubmitting
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: () async {
                        if (_formKey.currentState!.validate() && _image != null) {
                          setState(() => _isSubmitting = true);
                          try {
                            await _listingService.createListing(
                              title: _titleController.text,
                              description: _descriptionController.text,
                              price: double.tryParse(_priceController.text) ?? 0,
                              tradeType: _tradeTypeController.text,
                              category: _categoryController.text,
                              image: _image!,
                            );
                            Navigator.pop(context, true);
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(e.toString())),
                            );
                          } finally {
                            setState(() => _isSubmitting = false);
                          }
                        } else if (_image == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please pick an image')),
                          );
                        }
                      },
                      child: const Text('Create'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
