import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:math' as math;

class HeroBackground extends StatefulWidget {
  final double height;
  const HeroBackground({super.key, required this.height});

  @override
  State<HeroBackground> createState() => _HeroBackgroundState();
}

class _HeroBackgroundState extends State<HeroBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).colorScheme.secondary,
          ],
        ),
      ),
      child: Stack(
        children: [
          // Grid Overlay
          Positioned.fill(
            child: CustomPaint(
              painter: _GridPainter(),
            ),
          ),
          // Floating Text Animation (CNVGA)
          Positioned.fill(
             child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return CustomPaint(
                  painter: _FloatingTextPainter(progress: _controller.value),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..strokeWidth = 1.0;

    const double step = 40.0;
    
    // Draw diagonal grid
    for (double i = -size.height; i < size.width; i += step) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i + size.height, size.height),
        paint,
      );
      canvas.drawLine(
        Offset(i + size.height, 0),
        Offset(i, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _FloatingTextPainter extends CustomPainter {
  final double progress;
  _FloatingTextPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final textStyle = TextStyle(
      color: Colors.white.withOpacity(0.08),
      fontSize: 54,
      fontWeight: FontWeight.bold,
      letterSpacing: 20,
    );
    final textSpan = TextSpan(
      text: 'CNVGA  CNVGA  CNVGA  CNVGA  CNVGA  CNVGA  CNVGA',
      style: textStyle,
    );
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    canvas.save();
    
    // Fade at edges
    final rect = Offset.zero & size;
    final gradient = RadialGradient(
      center: Alignment.center,
      radius: 1.8,
      colors: [Colors.black, Colors.transparent],
    ).createShader(rect);
    final paint = Paint()..shader = gradient..blendMode = BlendMode.dstIn;
    
    canvas.saveLayer(rect, Paint());
    
    canvas.rotate(-math.pi / 6); // -30 degrees
    
    // Conveyor belt effect
    final double offset = -(progress * textPainter.width * 0.5);
    for (int i = -4; i < 12; i++) {
        textPainter.paint(
          canvas,
          Offset(offset, i * 110.0 - 150),
        );
    }
    
    canvas.restore(); // restore to before saveLayer
    canvas.drawRect(rect, paint);
    canvas.restore(); // restore base
  }

  @override
  bool shouldRepaint(covariant _FloatingTextPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
