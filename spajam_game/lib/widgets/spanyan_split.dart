import 'package:flutter/material.dart';

class SpanyanSplit extends StatelessWidget {
  final List<String> playerNames;
  final List<double> pitchValues; // 0~1
  final bool combining;
  const SpanyanSplit({
    super.key,
    required this.playerNames,
    required this.pitchValues,
    required this.combining,
  });

  @override
  Widget build(BuildContext context) {
    if (combining) {
      return SizedBox(
        height: 200,
        child: Stack(
          alignment: Alignment.center,
          children: [
            AnimatedScale(
              scale: combining ? 1.08 : 1.0,
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeInOut,
              child: Stack(
                children: [
                  _glowCircle(const Color(0xFF55E6C1), 160, 0.55),
                  _glowCircle(const Color(0xFFFB9AF4), 200, 0.35),
                  _glowCircle(const Color(0xFFFFD479), 240, 0.25),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.asset(
                      'assets/images/spanyan_full.png',
                      height: 180,
                      fit: BoxFit.contain,
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: 8,
              child: ShaderMask(
                shaderCallback: (rect) => const LinearGradient(
                  colors: [Color(0xFF55E6C1), Color(0xFFFB9AF4), Color(0xFFFFD479)],
                ).createShader(rect),
                child: const Text(
                  '合  体 !',
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 4,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      height: 200,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(3, (i) {
          final active = i < playerNames.length;
          final pitch = active ? pitchValues[i] : 0.5;
          final dy = (pitch - 0.5) * 26; // 揺れ
            final imgPath = switch (i) {
              0 => 'assets/images/spanyan_top.png',
              1 => 'assets/images/spanyan_mid.png',
              _ => 'assets/images/spanyan_bottom.png',
            };
          return Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 320),
              curve: Curves.easeOut,
              margin: EdgeInsets.only(
                left: i == 0 ? 0 : 6,
                right: i == 2 ? 0 : 6,
                top: 12 + dy,
                bottom: 12 - dy,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: active ? const Color(0xFFFB9AF4) : Colors.grey.shade600,
                  width: 2,
                ),
                gradient: LinearGradient(
                  colors: active
                      ? [const Color(0xFF3C2A40), const Color(0xFF251C28)]
                      : [const Color(0xFF353535), const Color(0xFF212121)],
                ),
                boxShadow: [
                  if (active)
                    BoxShadow(
                      color: const Color(0xFFFB9AF4).withOpacity(0.35),
                      blurRadius: 16,
                      spreadRadius: 1,
                      offset: const Offset(0, 4),
                    ),
                ],
              ),
              child: Stack(
                children: [
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Image.asset(
                        imgPath,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  Positioned(
                    left: 6,
                    top: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.35),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        active ? playerNames[i] : '---',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _glowCircle(Color c, double size, double opacity) {
    return Positioned(
      left: 0,
      right: 0,
      top: 0,
      bottom: 0,
      child: Center(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: c.withOpacity(0.08),
            boxShadow: [
              BoxShadow(
                color: c.withOpacity(opacity),
                blurRadius: size * 0.35,
                spreadRadius: size * 0.10,
              ),
            ],
          ),
        ),
      ),
    );
  }
}