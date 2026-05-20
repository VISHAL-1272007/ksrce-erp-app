import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HackerWelcomePage extends StatefulWidget {
  const HackerWelcomePage({super.key});

  @override
  State<HackerWelcomePage> createState() => _HackerWelcomePageState();
}

class _HackerWelcomePageState extends State<HackerWelcomePage>
    with TickerProviderStateMixin {
  late AnimationController _glitchController;
  late AnimationController _bounceController;
  late AnimationController _fadeController;
  late AnimationController _matrixController;
  late AnimationController _shakeController;
  late Animation<double> _bounceAnim;
  late Animation<double> _fadeAnim;
  late Animation<double> _shakeAnim;

  final List<_MatrixDrop> _matrixDrops = [];
  final _random = Random();

  @override
  void initState() {
    super.initState();

    _glitchController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    )..repeat(reverse: true);

    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    _bounceAnim = Tween<double>(begin: -20, end: 20).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.easeInOut),
    );

    _fadeController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..forward();
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);

    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    )..repeat(reverse: true);
    _shakeAnim = Tween<double>(begin: -5, end: 5).animate(_shakeController);

    _matrixController = AnimationController(
      duration: const Duration(milliseconds: 50),
      vsync: this,
    )..addListener(() {
        setState(() {
          for (final drop in _matrixDrops) {
            drop.y += drop.speed;
            if (drop.y > 1.2) {
              drop.y = -0.1;
              drop.char = String.fromCharCode(33 + _random.nextInt(94));
            }
          }
        });
      })..repeat();

    // Generate matrix rain drops
    for (int i = 0; i < 80; i++) {
      _matrixDrops.add(_MatrixDrop(
        x: _random.nextDouble(),
        y: _random.nextDouble() * 1.5 - 0.5,
        speed: 0.005 + _random.nextDouble() * 0.015,
        char: String.fromCharCode(33 + _random.nextInt(94)),
        opacity: 0.3 + _random.nextDouble() * 0.7,
        size: 10.0 + _random.nextDouble() * 8,
      ));
    }
  }

  @override
  void dispose() {
    _glitchController.dispose();
    _bounceController.dispose();
    _fadeController.dispose();
    _matrixController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 600;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Matrix rain background
          ..._matrixDrops.map((drop) => Positioned(
                left: drop.x * size.width,
                top: drop.y * size.height,
                child: Text(
                  drop.char,
                  style: TextStyle(
                    color: Colors.green.withValues(alpha: drop.opacity * 0.4),
                    fontSize: drop.size,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )),

          // Scanline effect
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _glitchController,
                builder: (context, child) {
                  return CustomPaint(
                    painter: _ScanlinePainter(_glitchController.value),
                  );
                },
              ),
            ),
          ),

          // Main content
          Center(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: AnimatedBuilder(
                animation: _shakeAnim,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(_shakeAnim.value, 0),
                    child: child,
                  );
                },
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: isMobile ? 20 : 40),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Skull / Hacker icon with bounce
                      AnimatedBuilder(
                        animation: _bounceAnim,
                        builder: (context, child) {
                          return Transform.translate(
                            offset: Offset(0, _bounceAnim.value),
                            child: child,
                          );
                        },
                        child: Container(
                          width: isMobile ? 100 : 140,
                          height: isMobile ? 100 : 140,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.red, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.red.withValues(alpha: 0.5),
                                blurRadius: 30,
                                spreadRadius: 10,
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.warning_amber_rounded,
                            size: isMobile ? 60 : 80,
                            color: Colors.red,
                          ),
                        ),
                      ),

                      const SizedBox(height: 30),

                      // INTRUSION DETECTED header
                      _GlitchText(
                        controller: _glitchController,
                        child: Text(
                          '⚠ INTRUSION DETECTED ⚠',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: isMobile ? 20 : 30,
                            fontWeight: FontWeight.w900,
                            color: Colors.red,
                            letterSpacing: 4,
                            fontFamily: 'monospace',
                            shadows: [
                              Shadow(
                                color: Colors.red.withValues(alpha: 0.8),
                                blurRadius: 20,
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 30),

                      // Main message
                      Container(
                        padding: EdgeInsets.all(isMobile ? 20 : 30),
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          border: Border.all(color: Colors.green, width: 2),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.green.withValues(alpha: 0.3),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Text(
                              'HI HACKER',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: isMobile ? 28 : 42,
                                fontWeight: FontWeight.w900,
                                color: Colors.greenAccent,
                                letterSpacing: 3,
                                fontFamily: 'monospace',
                                shadows: [
                                  Shadow(
                                    color: Colors.greenAccent.withValues(alpha: 0.8),
                                    blurRadius: 15,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'IF YOU WANT TO HACK',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: isMobile ? 18 : 26,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 2,
                                fontFamily: 'monospace',
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'COME AND SHOW ME YOUR BACK',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: isMobile ? 18 : 26,
                                fontWeight: FontWeight.bold,
                                color: Colors.yellow,
                                letterSpacing: 2,
                                fontFamily: 'monospace',
                                shadows: [
                                  Shadow(
                                    color: Colors.yellow.withValues(alpha: 0.5),
                                    blurRadius: 10,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'AND GO HOME',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: isMobile ? 18 : 26,
                                fontWeight: FontWeight.bold,
                                color: Colors.orangeAccent,
                                letterSpacing: 2,
                                fontFamily: 'monospace',
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              '\u{1F923}\u{1F602}\u{1F923}\u{1F602}\u{1F923}',
                              style: TextStyle(fontSize: isMobile ? 36 : 50),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 30),

                      // IP tracking fake warning
                      AnimatedBuilder(
                        animation: _glitchController,
                        builder: (context, child) {
                          return Opacity(
                            opacity: 0.6 + _glitchController.value * 0.4,
                            child: child,
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                          decoration: BoxDecoration(
                            border: Border.all(
                                color: Colors.red.withValues(alpha: 0.5)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '\u{1F6A8} YOUR ACTIVITY HAS BEEN LOGGED \u{1F6A8}\nNice try though! \u{1F609}',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: isMobile ? 12 : 14,
                              color: Colors.red.shade300,
                              fontFamily: 'monospace',
                              height: 1.5,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 30),

                      // Go back button
                      MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: () => context.go('/'),
                          child: AnimatedBuilder(
                            animation: _bounceAnim,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: 1.0 +
                                    (_bounceAnim.value.abs() / 20) * 0.05,
                                child: child,
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 32, vertical: 14),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.green.shade700,
                                    Colors.green.shade900
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(30),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.green.withValues(alpha: 0.4),
                                    blurRadius: 15,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: Text(
                                '\u{1F3E0} GO HOME SAFELY',
                                style: TextStyle(
                                  fontSize: isMobile ? 14 : 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 2,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlitchText extends StatelessWidget {
  final AnimationController controller;
  final Widget child;
  const _GlitchText({required this.controller, required this.child});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final offset = (controller.value - 0.5) * 4;
        return Stack(
          children: [
            Transform.translate(
              offset: Offset(offset, 0),
              child: Opacity(
                opacity: 0.7,
                child: ColorFiltered(
                  colorFilter:
                      const ColorFilter.mode(Colors.cyan, BlendMode.srcATop),
                  child: child,
                ),
              ),
            ),
            Transform.translate(
              offset: Offset(-offset, 0),
              child: Opacity(
                opacity: 0.7,
                child: ColorFiltered(
                  colorFilter:
                      const ColorFilter.mode(Colors.red, BlendMode.srcATop),
                  child: child,
                ),
              ),
            ),
            child,
          ],
        );
      },
    );
  }
}

class _ScanlinePainter extends CustomPainter {
  final double animValue;
  _ScanlinePainter(this.animValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.green.withValues(alpha: 0.03)
      ..style = PaintingStyle.fill;

    for (double y = 0; y < size.height; y += 4) {
      canvas.drawRect(
        Rect.fromLTWH(0, y, size.width, 1),
        paint,
      );
    }

    // Moving scanline
    final scanY = (animValue * size.height * 2) % size.height;
    final scanPaint = Paint()
      ..color = Colors.green.withValues(alpha: 0.08)
      ..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromLTWH(0, scanY, size.width, 3),
      scanPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ScanlinePainter oldDelegate) => true;
}

class _MatrixDrop {
  double x;
  double y;
  double speed;
  String char;
  double opacity;
  double size;

  _MatrixDrop({
    required this.x,
    required this.y,
    required this.speed,
    required this.char,
    required this.opacity,
    required this.size,
  });
}
