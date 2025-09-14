import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/game_state.dart';
import 'menu_screen.dart';
import 'lobby_screen.dart';
import 'dart:math' as math; // 追加

class ResultScreen extends StatefulWidget {
  static const routeName = '/result';
  const ResultScreen({super.key});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 6))..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<GameState>();
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF201515), Color(0xFF120E0E)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          AnimatedBuilder(
            animation: _ctrl,
            builder: (_, __) => CustomPaint(
              painter: _ConfettiPainter(_ctrl.value),
              size: Size.infinite,
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 60),
                AnimatedScale(
                  scale: 1 + 0.04 * (_ctrl.value),
                  duration: const Duration(milliseconds: 600),
                  child: ShaderMask(
                    shaderCallback: (rect) => const LinearGradient(
                      colors: [Color(0xFF55E6C1), Color(0xFFFB9AF4), Color(0xFFFFD479)],
                    ).createShader(rect),
                    child: const Text(
                      'ク リ ア ！',
                      style: TextStyle(
                        fontSize: 54,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 6,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 220,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Positioned.fill(
                        child: AnimatedBuilder(
                          animation: _ctrl,
                          builder: (_, __) {
                            final glow = 0.5 + 0.5 * math.sin(_ctrl.value * math.pi * 2);
                            return Opacity(
                              opacity: 0.6,
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF55E6C1).withOpacity(0.35 * glow),
                                      blurRadius: 42,
                                      spreadRadius: 4,
                                    ),
                                    BoxShadow(
                                      color: const Color(0xFFFB9AF4).withOpacity(0.25 * glow),
                                      blurRadius: 64,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      Image.asset(
                        'assets/images/06_下呂.png',
                        fit: BoxFit.contain,
                        height: 200,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const Text('ハーモニー成功！', style: TextStyle(fontSize: 18)),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                  child: Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            state.resetToMenu();
                            Navigator.popUntil(context, (r) => r.isFirst);
                          },
                          child: const Text('退出'),
                        ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () {
                            state.enterRoom();
                            Navigator.popUntil(context, (r) => r.isFirst);
                            Navigator.pushNamed(context, LobbyScreen.routeName);
                          },
                          child: const Text('続ける'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  final double t;
  _ConfettiPainter(this.t);
  @override
  void paint(Canvas canvas, Size size) {
    final rndColors = [
      const Color(0xFF55E6C1),
      const Color(0xFFFB9AF4),
      const Color(0xFFFFD479),
      const Color(0xFF8EC5FF),
    ];
    final paint = Paint()..style = PaintingStyle.fill;
    const count = 70;
    for (int i = 0; i < count; i++) {
      final seed = (i * 37) % 997;
      final progress = (t + seed / 997) % 1;
      final x = size.width * ((seed * 13) % 100) / 100;
      final y = size.height * progress;
      final w = 6 + (seed % 5);
      paint.color = rndColors[seed % rndColors.length].withOpacity(1 - progress * 0.6);
      final rect = Rect.fromCenter(center: Offset(x, y), width: w.toDouble(), height: (w * 2).toDouble());
      final r = RRect.fromRectAndCorners(rect, topLeft: const Radius.circular(2), bottomRight: const Radius.circular(2));
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(progress * 6.28);
      canvas.translate(-x, -y);
      canvas.drawRRect(r, paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) => oldDelegate.t != t;
}