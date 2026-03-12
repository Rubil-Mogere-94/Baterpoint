import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/theme.dart';
import '../services/environment_config.dart';

class AiValuatorScreen extends StatefulWidget {
  const AiValuatorScreen({super.key});

  @override
  State<AiValuatorScreen> createState() => _AiValuatorScreenState();
}

class _AiValuatorScreenState extends State<AiValuatorScreen> {
  final TextEditingController _itemController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  bool _isScanning = false;
  Map<String, dynamic>? _result;
  String? _error;

  Future<void> _evaluateItem() async {
    if (_itemController.text.trim().isEmpty) return;

    setState(() {
      _isScanning = true;
      _result = null;
      _error = null;
    });

    try {
      final apiUrl = EnvironmentConfig.apiUrl;
      // In a real app, handle URI encoding properly. 
      final uri = Uri.parse('$apiUrl/api/v1/ai/evaluate?item_name=${Uri.encodeComponent(_itemController.text)}&description=${Uri.encodeComponent(_descController.text)}');
      
      final response = await http.post(uri);

      if (response.statusCode == 200) {
        setState(() {
          _result = json.decode(response.body);
        });
      } else {
        setState(() {
          _error = "AI got confused. Try again.";
        });
      }
    } catch (e) {
      setState(() {
        _error = "Connection error. Is the AI server running?";
      });
    } finally {
      setState(() {
        _isScanning = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('AI Valuator'),
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [const Color(0xFF0F172A), const Color(0xFF1E1B4B)]
                : [const Color(0xFFEEF2FF), const Color(0xFFE0E7FF)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppSpacing.md),
                Text(
                  "Discover the hidden value of your items.",
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: isDark ? Colors.white70 : AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ).animate().fadeIn(duration: 500.ms).slideY(begin: -0.2, end: 0),
                const SizedBox(height: AppSpacing.xl),

                // Input Card (Glassmorphism effect)
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor.withOpacity(isDark ? 0.3 : 0.7),
                    borderRadius: AppRadii.radiusXl,
                    border: Border.all(
                      color: isDark ? Colors.white12 : Colors.black12,
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isDark ? Colors.indigo.withOpacity(0.1) : Colors.indigo.withOpacity(0.05),
                        blurRadius: 30,
                        spreadRadius: 5,
                      )
                    ],
                  ),
                  child: Column(
                    children: [
                      TextField(
                        controller: _itemController,
                        decoration: InputDecoration(
                          hintText: 'What is it? (e.g. vintage camera)',
                          prefixIcon: Icon(Icons.search, color: Theme.of(context).colorScheme.primary),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextField(
                        controller: _descController,
                        maxLines: 2,
                        decoration: InputDecoration(
                          hintText: 'Condition? Brand? Add details...',
                          prefixIcon: Icon(Icons.description, color: Theme.of(context).colorScheme.primary),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isScanning ? null : _evaluateItem,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            shape: RoundedRectangleBorder(borderRadius: AppRadii.radiusLg)
                          ),
                          child: _isScanning
                              ? const SizedBox(
                                  height: 24, width: 24, 
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                                )
                              : const Text('Scan & Evaluate', style: TextStyle(fontSize: 16)),
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 200.ms).scale(begin: const Offset(0.95, 0.95)),

                const SizedBox(height: AppSpacing.xxl),

                // Results Area
                Expanded(
                  child: Center(
                    child: _buildResultsArea(isDark),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResultsArea(bool isDark) {
    if (_isScanning) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.document_scanner, size: 80, color: Theme.of(context).colorScheme.primary)
              .animate(onPlay: (controller) => controller.repeat())
              .shimmer(duration: 1500.ms, color: Colors.white54)
              .scale(begin: const Offset(0.9, 0.9), end: const Offset(1.1, 1.1), duration: 800.ms, curve: Curves.easeInOut)
              .then().scale(begin: const Offset(1.1, 1.1), end: const Offset(0.9, 0.9), duration: 800.ms, curve: Curves.easeInOut),
          const SizedBox(height: AppSpacing.lg),
          Text(
            "Analyzing market trends...",
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
          ).animate(onPlay: (controller) => controller.repeat()).shimmer(duration: 2.seconds),
        ],
      );
    }

    if (_error != null) {
      return Text(
        _error!,
        style: TextStyle(color: Theme.of(context).colorScheme.error),
      ).animate().shake();
    }

    if (_result != null) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: AppRadii.radiusXl,
          border: Border.all(color: Theme.of(context).colorScheme.secondary.withOpacity(0.5), width: 2),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.secondary.withOpacity(0.2),
              blurRadius: 40,
              spreadRadius: 10,
            )
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Estimated Value",
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.monetization_on, color: Theme.of(context).colorScheme.secondary, size: 40),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  "${_result!['estimated_value']}",
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    color: Theme.of(context).colorScheme.secondary,
                    fontSize: 48,
                  ),
                ),
              ],
            ).animate().scale(delay: 200.ms, duration: 400.ms, curve: Curves.easeOutBack),
            const SizedBox(height: AppSpacing.lg),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: AppRadii.radiusMd,
              ),
              child: Text(
                '"${_result!['ai_comment']}"',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontStyle: FontStyle.italic,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ).animate().fadeIn(delay: 600.ms),
            const SizedBox(height: AppSpacing.md),
            Text(
              "Confidence: ${(_result!['confidence_score'] * 100).toStringAsFixed(1)}%",
              style: Theme.of(context).textTheme.labelMedium,
            ).animate().fadeIn(delay: 800.ms),
          ],
        ),
      ).animate().scale(curve: Curves.easeOutCirc, duration: 500.ms).fadeIn();
    }

    return const SizedBox.shrink();
  }
}
