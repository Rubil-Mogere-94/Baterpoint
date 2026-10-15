import 'package:flutter/material.dart';
import '../../constants.dart';
import '../../services/api_service.dart';

class ValuationScreen extends StatefulWidget {
  const ValuationScreen({super.key});

  @override
  State<ValuationScreen> createState() => _ValuationScreenState();
}

class _ValuationScreenState extends State<ValuationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _apiService = ApiService();
  Map<String, dynamic>? _result;
  String? _error;
  bool _loading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _evaluate() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; _result = null; });
    try {
      final result = await _apiService.evaluateItem(
        itemName: _nameController.text,
        description: _descriptionController.text,
      );
      if (mounted) setState(() => _result = result);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final value = _result?['estimated_value'];
    final confidence = _result?['confidence_score'];
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(title: const Text('AI Valuator')),
      body: ListView(
        padding: const EdgeInsets.all(kDefaultPadding),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [kPrimaryColor, kBarterColor], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 34),
                SizedBox(height: 12),
                Text('Get a starting point', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                SizedBox(height: 6),
                Text('Describe your item to see an illustrative estimate before you create a listing.', style: TextStyle(color: Colors.white, height: 1.4)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Card.outlined(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Item name', hintText: 'e.g. Used Android phone'),
                      validator: (value) => value == null || value.trim().isEmpty ? 'Enter an item name' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _descriptionController,
                      minLines: 3,
                      maxLines: 5,
                      decoration: const InputDecoration(labelText: 'Condition and details', hintText: 'Brand, age, condition and included accessories'),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: _loading ? null : _evaluate,
                        icon: _loading
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.auto_awesome_rounded),
                        label: Text(_loading ? 'Estimating…' : 'Estimate item'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: kErrorColor)),
          ],
          if (_result != null) ...[
            const SizedBox(height: 16),
            Card(
              elevation: 0,
              color: kSurfaceColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: const BorderSide(color: kBorderColor)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Illustrative estimate', style: TextStyle(color: kTextLightColor, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    Text('Value: $value barter points', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: kPrimaryColor)),
                    if (confidence != null) ...[
                      const SizedBox(height: 4),
                      Text('Demo confidence indicator: ${(confidence is num ? confidence * 100 : 0).round()}%', style: const TextStyle(color: kTextLightColor)),
                    ],
                    const SizedBox(height: 10),
                    Text((_result?['ai_comment'] ?? '').toString(), style: const TextStyle(height: 1.45)),
                    const SizedBox(height: 12),
                    const Divider(),
                    const Text(
                      'Important: the current server uses sample values, not a verified market-price model. Compare similar listings and item condition before agreeing a trade.',
                      style: TextStyle(color: kTextLightColor, fontSize: 12, height: 1.4),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
