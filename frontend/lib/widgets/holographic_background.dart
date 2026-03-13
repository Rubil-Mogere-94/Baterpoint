import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter_animate/flutter_animate.dart';

class HolographicBackground extends StatefulWidget {
  final Widget child;
  
  const HolographicBackground({super.key, required this.child});

  @override
  State<HolographicBackground> createState() => _HolographicBackgroundState();
}

class _HolographicBackgroundState extends State<HolographicBackground> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Very subtle base color depending on theme
    final baseColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    
    return Stack(
      fit: StackFit.expand,
      children: [
        // Base Solid Background
        Container(color: baseColor),
        
        // Animated Mesh Gradient Bubbles
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
             return CustomPaint(
               painter: _MeshGradientPainter(
                 progress: _controller.value,
                 isDark: isDark,
               ),
             );
          },
        ),
        
        // Heavy Glass Blur over the bright gradients
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
          child: Container(color: Colors.transparent),
        ),
        
        // The actual content of the screen
        widget.child,
      ],
    );
  }
}

class _MeshGradientPainter extends CustomPainter {
  final double progress;
  final bool isDark;

  _MeshGradientPainter({required this.progress, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    
    // Define 4 animated points
    // Using sine/cosine to make them orbit slighly
    
    final p1 = Offset(
      w * 0.2 + math.sin(progress * math.pi * 2) * w * 0.3,
      h * 0.2 + math.cos(progress * math.pi * 2) * h * 0.3,
    );
    
    final p2 = Offset(
      w * 0.8 + math.cos(progress * math.pi * 2) * w * 0.2,
      h * 0.3 + math.sin(progress * math.pi * 2) * h * 0.4,
    );
    
    final p3 = Offset(
      w * 0.5 + math.sin(progress * math.pi * 2 + math.pi) * w * 0.4,
      h * 0.8 + math.cos(progress * math.pi * 2) * h * 0.2,
    );
    
    final p4 = Offset(
      w * 0.2 + math.cos(progress * math.pi * 2 + math.pi / 2) * w * 0.3,
      h * 0.9 + math.sin(progress * math.pi * 2) * h * 0.1,
    );

    // These colors form the holographic "oil slick" / cyber vibe
    final c1 = isDark ? const Color(0xFF4F46E5).withOpacity(0.6) : const Color(0xFF818CF8).withOpacity(0.4); // Indigo
    final c2 = isDark ? const Color(0xFF10B981).withOpacity(0.5) : const Color(0xFF34D399).withOpacity(0.4); // Emerald
    final c3 = isDark ? const Color(0xFFEC4899).withOpacity(0.4) : const Color(0xFFF472B6).withOpacity(0.3); // Pink
    final c4 = isDark ? const Color(0xFF8B5CF6).withOpacity(0.5) : const Color(0xFFA78BFA).withOpacity(0.4); // Violet

    // Draw the glowing orbs
    _drawOrb(canvas, p1, c1, w * 0.6);
    _drawOrb(canvas, p2, c2, w * 0.7);
    _drawOrb(canvas, p3, c3, w * 0.8);
    _drawOrb(canvas, p4, c4, w * 0.9);
  }
  
  void _drawOrb(Canvas canvas, Offset center, Color color, double radius) {
     final paint = Paint()
       ..shader = RadialGradient(
         colors: [color, color.withOpacity(0.0)],
         stops: const [0.0, 1.0],
       ).createShader(Rect.fromCircle(center: center, radius: radius));
       
     canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant _MeshGradientPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.isDark != isDark;
  }
}
