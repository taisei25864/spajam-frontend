import 'package:flutter/material.dart';

class FusumaLayer extends StatelessWidget {
  final double open; // 0閉〜1全開
  final int wallIndex;
  final int maxWall;
  const FusumaLayer({
    super.key,
    required this.open,
    required this.wallIndex,
    required this.maxWall,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (c, constraints) {
      final w = constraints.maxWidth / 2;
      return Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: Opacity(
                opacity: 0.10 + 0.15 * (1 - open),
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: RadialGradient(
                      colors: [Color(0x3322FFC7), Colors.transparent],
                      radius: 1.2,
                    ),
                  ),
                ),
              ),
            ),
          ),
          // 左
            Positioned(
              left: -w * open,
              top: 0,
              bottom: 0,
              width: w,
              child: _panel(context, left: true),
            ),
          // 右
          Positioned(
            right: -w * open,
            top: 0,
            bottom: 0,
            width: w,
            child: _panel(context, left: false),
          ),
          if (open < 1)
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF3F332B).withOpacity(0.75),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFBFA27A), width: 1.2),
                ),
                child: Text(
                  '壁 $wallIndex / $maxWall',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ),
        ],
      );
    });
  }

  Widget _panel(BuildContext context, {required bool left}) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: left
              ? [const Color(0xFF4A3B2F), const Color(0xFF2B221B)]
              : [const Color(0xFF2B221B), const Color(0xFF4A3B2F)],
          begin: left ? Alignment.centerLeft : Alignment.centerRight,
          end: left ? Alignment.centerRight : Alignment.centerLeft,
        ),
        border: Border(
          left: BorderSide(color: Colors.black.withOpacity(0.4), width: left ? 0 : 1),
          right: BorderSide(color: Colors.black.withOpacity(0.4), width: left ? 1 : 0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.45),
            blurRadius: 18,
            spreadRadius: 2,
          )
        ],
      ),
      child: CustomPaint(
        painter: _FusumaPatternPainter(),
      ),
    );
  }
}

class _FusumaPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x22FFDFAF)
      ..style = PaintingStyle.fill;
    for (int i = 0; i < 5; i++) {
      final r = Rect.fromLTWH(
        size.width * 0.15 * i,
        size.height * (0.1 + 0.15 * (i % 2)),
        size.width * 0.22,
        size.height * 0.55,
      );
      canvas.drawRRect(
          RRect.fromRectAndRadius(r, const Radius.circular(12)), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}