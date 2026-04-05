import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:math' as math;
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

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
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isYellow = themeProvider.accentColorType == AccentColorType.yellow;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Define consistent color sets
    final Color darkBlue = isDarkMode ? const Color(0xFF000814) : const Color(0xFF001A3D);
    final Color lightBlue = isDarkMode ? Colors.blue[300]!.withOpacity(0.5) : Colors.blue[100]!;
    final Color darkYellow = isDarkMode ? const Color(0xFFB8860B) : const Color(0xFF996600);
    final Color lightYellow = isDarkMode ? Colors.amber[200]!.withOpacity(0.5) : Colors.amber[100]!;
    final Color accentGold = isDarkMode ? Colors.amber[400]! : const Color(0xFFB8860B);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
      height: widget.height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          transform: const GradientRotation(math.pi / 6), // 30 degrees right
          colors: [
            darkBlue,                             // Outside left
            isYellow ? lightBlue : lightYellow,   // Mid-left (complementary)
            isYellow ? lightYellow : lightBlue,   // Center (accent)
            isYellow ? lightBlue : lightYellow,   // Mid-right (complementary)
            darkBlue,                             // Outside right
          ],
          stops: const [0.0, 0.3, 0.5, 0.7, 1.0],
        ),
      ),
      child: Stack(
        children: [
          // Grid Overlay
          Positioned.fill(
            child: CustomPaint(
              painter: _GridPainter(isDarkMode: isDarkMode),
            ),
          ),
          // Floating Text Animation (CNVGA)
          Positioned.fill(
             child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return CustomPaint(
                  painter: _FloatingTextPainter(progress: _controller.value, isDarkMode: isDarkMode),
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
  final bool isDarkMode;
  _GridPainter({required this.isDarkMode});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isDarkMode ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)
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
  final bool isDarkMode;
  _FloatingTextPainter({required this.progress, required this.isDarkMode});

  @override
  void paint(Canvas canvas, Size size) {
    final textColor = isDarkMode ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.08);
    final textStyle = TextStyle(
      color: textColor,
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
