import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:math' as math;
import '../models/listing.dart';
import '../constants/theme.dart';

class ARShowcaseScreen extends StatefulWidget {
  final Listing listing;

  const ARShowcaseScreen({super.key, required this.listing});

  @override
  State<ARShowcaseScreen> createState() => _ARShowcaseScreenState();
}

class _ARShowcaseScreenState extends State<ARShowcaseScreen> with SingleTickerProviderStateMixin {
  double _pitch = 0.0;
  double _roll = 0.0;
  
  @override
  void initState() {
    super.initState();
    accelerometerEventStream().listen((AccelerometerEvent event) {
      if (!mounted) return;
      setState(() {
        // Simple complimentary filter/smoothing for the fake 3D effect
        _pitch = (_pitch * 0.8) + (event.y * 0.2); 
        _roll = (_roll * 0.8) + (event.x * 0.2);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    // Clamp values so the image doesn't fly off screen
    final clampedPitch = _pitch.clamp(-4.0, 4.0);
    final clampedRoll = _roll.clamp(-4.0, 4.0);
    
    // Calculate 3D transforms
    final transform = Matrix4.identity()
      ..setEntry(3, 2, 0.001) // perspective
      ..rotateX(clampedPitch * -0.1)
      ..rotateY(clampedRoll * 0.1);

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.white),
            onPressed: () {
               ScaffoldMessenger.of(context).showSnackBar(
                 const SnackBar(content: Text("Tilt your phone to inspect the item from all angles!"))
               );
            },
          )
        ],
      ),
      body: Stack(
        children: [
          // Cyber Grid Background
          Positioned.fill(
            child: CustomPaint(
              painter: _GridPainter(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                pitch: clampedPitch,
                roll: clampedRoll,
              ),
            ),
          ),
          
          // The Interactive Item
          Center(
            child: Hero(
              tag: 'listing_image_${widget.listing.id}',
              child: Transform(
                transform: transform,
                alignment: FractionalOffset.center,
                child: Container(
                  width: 320,
                  height: 480,
                  decoration: BoxDecoration(
                    borderRadius: AppRadius.roundedXL,
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).colorScheme.secondary.withOpacity(0.4),
                        blurRadius: 50,
                        spreadRadius: 10,
                        offset: Offset(clampedRoll * 10, clampedPitch * 10),
                      ),
                      BoxShadow(
                        color: Colors.black.withOpacity(0.8),
                        blurRadius: 20,
                        spreadRadius: -5,
                        offset: Offset(-clampedRoll * 5, -clampedPitch * 5),
                      )
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: AppRadius.roundedXL,
                    child: widget.listing.imageUrl != null
                        ? CachedNetworkImage(
                            imageUrl: widget.listing.imageUrl!,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                            errorWidget: (context, url, error) => const Icon(Icons.broken_image, size: 50, color: Colors.white54),
                          )
                        : Container(color: Colors.grey[900]),
                  ),
                ),
              ),
            ),
          ),
          
          // Overlay UI
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: Column(
              children: [
                const Icon(Icons.360_rounded, color: Colors.white, size: 32),
                const SizedBox(height: 8),
                Text(
                  "TILT TO INSPECT",
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Colors.white,
                    letterSpacing: 4.0,
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}

// A simple painter to draw a perspective grid that moves with the gyro
class _GridPainter extends CustomPainter {
  final Color color;
  final double pitch;
  final double roll;

  _GridPainter({required this.color, required this.pitch, required this.roll});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final cellWidth = size.width / 10;
    final cellHeight = size.height / 20;

    // Offset the grid based on the tilt
    final offsetX = roll * 20;
    final offsetY = pitch * 20;

    for (var i = -5; i <= 15; i++) {
      canvas.drawLine(
        Offset(i * cellWidth + offsetX, 0),
        Offset(i * cellWidth + offsetX, size.height),
        paint,
      );
    }
    for (var i = -5; i <= 25; i++) {
        canvas.drawLine(
        Offset(0, i * cellHeight + offsetY),
        Offset(size.width, i * cellHeight + offsetY),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter oldDelegate) {
    return oldDelegate.pitch != pitch || oldDelegate.roll != roll;
  }
}
