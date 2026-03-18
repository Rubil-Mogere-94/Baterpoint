import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'dart:ui';
import 'package:http/http.dart' as http;
import '../constants/theme.dart';
import '../widgets/holographic_background.dart';
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
    FocusScope.of(context).unfocus();

    setState(() {
      _isScanning = true;
      _result = null;
      _error = null;
    });

    try {
      final apiUrl = EnvironmentConfig.apiUrl;
      final uri = Uri.parse('$apiUrl/api/v1/ai/evaluate?item_name=${Uri.encodeComponent(_itemController.text)}&description=${Uri.encodeComponent(_descController.text)}');
      
      final response = await http.post(uri);

      if (response.statusCode == 200) {
        setState(() => _result = json.decode(response.body));
      } else {
        setState(() => _error = "AI got confused. Try again.");
      }
    } catch (e) {
      setState(() => _error = "Connection error. Is the AI server running?");
    } finally {
      setState(() => _isScanning = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('AI VALUATOR', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900, letterSpacing: 2)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          const HolographicBackground(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 12),
                  Text(
                    "Discover the hidden value of your items.",
                    style: textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ).animate().fadeIn(duration: 500.ms).slideY(begin: -0.2, end: 0),
                  const SizedBox(height: 40),

                  // Input Card
                  _buildInputCard(colorScheme),
                  
                  const SizedBox(height: 40),

                  // Results Area
                  _buildResultsArea(colorScheme, textTheme),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputCard(ColorScheme colorScheme) {
    return ClipRRect(
      borderRadius: AppRadius.roundedXXL,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: colorScheme.surface.withOpacity(0.4),
            borderRadius: AppRadius.roundedXXL,
            border: Border.all(color: Colors.white.withOpacity(0.2)),
            boxShadow: [
              BoxShadow(
                color: colorScheme.primary.withOpacity(0.1),
                blurRadius: 30,
              )
            ],
          ),
          child: Column(
            children: [
              TextField(
                controller: _itemController,
                style: const TextStyle(fontWeight: FontWeight.w700),
                decoration: InputDecoration(
                  hintText: 'What is it? (e.g. vintage camera)',
                  prefixIcon: Icon(Icons.search, color: colorScheme.primary),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.05),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _descController,
                maxLines: 2,
                style: const TextStyle(fontWeight: FontWeight.w500),
                decoration: InputDecoration(
                  hintText: 'Condition? Brand? Add details...',
                  prefixIcon: Icon(Icons.description, color: colorScheme.primary),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.05),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isScanning ? null : _evaluateItem,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: AppRadius.roundedLG),
                    elevation: 10,
                    shadowColor: colorScheme.primary.withOpacity(0.3),
                  ),
                  child: _isScanning
                      ? const SizedBox(
                          height: 24, width: 24, 
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                        )
                      : const Text('SCAN & VALUATE', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2)),
                ),
              ),
            ],
          ),
        ),
      ).animate().fadeIn(delay: 200.ms).scale(begin: const Offset(0.95, 0.95)),
    );
  }

  Widget _buildResultsArea(ColorScheme colorScheme, TextTheme textTheme) {
    if (_isScanning) {
      return Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.05),
                  shape: BoxShape.circle,
                  border: Border.all(color: colorScheme.primary.withOpacity(0.1)),
                ),
                child: Icon(Icons.document_scanner_rounded, size: 80, color: colorScheme.primary)
                    .animate(onPlay: (controller) => controller.repeat())
                    .shimmer(duration: 1500.ms, color: Colors.white54)
                    .scale(begin: const Offset(0.9, 0.9), end: const Offset(1.05, 1.05), duration: 800.ms, curve: Curves.easeInOut)
                    .then().scale(begin: const Offset(1.05, 1.05), end: const Offset(0.9, 0.9), duration: 800.ms, curve: Curves.easeInOut),
              ),
              // Scanning Line Animation
              SizedBox(
                width: 160,
                height: 160,
                child: CustomPaint(
                  painter: _ScanningLinePainter(color: colorScheme.primary),
                ),
              ).animate(onPlay: (controller) => controller.repeat())
                .shimmer(duration: 1.seconds, color: Colors.white24),
            ],
          ),
          const SizedBox(height: 32),
          Text(
            "SYNTHESIZING MARKET DATA",
            style: textTheme.labelLarge?.copyWith(
              color: colorScheme.primary, 
              fontWeight: FontWeight.w900,
              letterSpacing: 2.0,
            ),
          ).animate(onPlay: (controller) => controller.repeat()).shimmer(duration: 2.seconds),
          const SizedBox(height: 12),
          Text(
            "Accessing global price indices...",
            style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant.withOpacity(0.6)),
          ).animate().fadeIn(delay: 400.ms),
        ],
      );
    }

    if (_error != null) {
      return Center(
        child: Text(_error!, style: TextStyle(color: colorScheme.error, fontWeight: FontWeight.w700)).animate().shake(),
      );
    }

    if (_result != null) {
      return ClipRRect(
        borderRadius: AppRadius.roundedXXL,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: theme.brightness == Brightness.dark ? Colors.white.withOpacity(0.05) : Colors.white.withOpacity(0.6),
              borderRadius: AppRadius.roundedXXL,
              border: Border.all(color: colorScheme.primary.withOpacity(0.3), width: 1),
              boxShadow: [
                BoxShadow(color: colorScheme.primary.withOpacity(0.1), blurRadius: 40, spreadRadius: 10)
              ],
            ),
            child: Column(
              children: [
                const Text("ESTIMATED MARKET VALUE", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 2.0, color: Colors.grey)),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text("\$", style: textTheme.headlineSmall?.copyWith(color: colorScheme.primary, fontWeight: FontWeight.w300)),
                    ),
                    Text(
                      "${_result!['estimated_value']}",
                      style: textTheme.displayLarge?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w900,
                        fontSize: 72,
                        letterSpacing: -2,
                      ),
                    ),
                  ],
                ).animate().scale(delay: 200.ms, duration: 400.ms, curve: Curves.easeOutBack),
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.04),
                    borderRadius: AppRadius.roundedXL,
                    border: Border.all(color: colorScheme.primary.withOpacity(0.08)),
                  ),
                  child: Text(
                    '"${_result!['ai_comment']}"',
                    style: textTheme.bodyLarge?.copyWith(fontStyle: FontStyle.italic, height: 1.5, fontWeight: FontWeight.w500),
                    textAlign: TextAlign.center,
                  ),
                ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.1),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: LinearProgressIndicator(
                          value: (_result!['confidence_score'] as num).toDouble(),
                          minHeight: 10,
                          backgroundColor: colorScheme.primary.withOpacity(0.1),
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      "${((_result!['confidence_score'] as num) * 100).toStringAsFixed(0)}%",
                      style: textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w900, color: colorScheme.primary),
                    ),
                  ],
                ).animate().fadeIn(delay: 800.ms),
                const SizedBox(height: 8),
                Text(
                  "AI CONFIDENCE SCORE",
                  style: textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w900, fontSize: 8, letterSpacing: 1.5, color: Colors.grey),
                ).animate().fadeIn(delay: 800.ms),
              ],
            ),
          ),
        ),
      ).animate().scale(curve: Curves.easeOutCirc, duration: 600.ms).fadeIn();
    }

    return const SizedBox.shrink();
  }
}

class _ScanningLinePainter extends CustomPainter {
  final Color color;
  _ScanningLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.5)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final progress = DateTime.now().millisecondsSinceEpoch % 2000 / 2000;
    final y = size.height * progress;

    // Draw the scanning line
    canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);

    // Draw a slight glow/gradient below the line
    final gradientPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color.withOpacity(0.2), Colors.transparent],
      ).createShader(Rect.fromLTWH(0, y - 20, size.width, 20));
    
    if (y > 20) {
      canvas.drawRect(Rect.fromLTWH(0, y - 20, size.width, 20), gradientPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
