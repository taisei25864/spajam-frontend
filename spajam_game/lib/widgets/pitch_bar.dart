import 'package:flutter/material.dart';

class PitchBar extends StatelessWidget {
  final double value; // 0~1
  const PitchBar({super.key, required this.value});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: value, end: value),
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
      builder: (context, animated, _) {
        return LayoutBuilder(
          builder: (c, constraints) {
            final h = constraints.maxHeight;
            final markerY = (1 - animated) * h;
            final greenTop = h * 0.35;
            final greenHeight = h * 0.30;
            final inZone = animated > 0.35 && animated < 0.65;
            return Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white10),
                borderRadius: BorderRadius.circular(10),
                gradient: const LinearGradient(
                  colors: [Color(0xFF262525), Color(0xFF1A1919)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: greenTop,
                    left: 4,
                    right: 4,
                    height: greenHeight,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        gradient: LinearGradient(
                          colors: inZone
                              ? [const Color(0xFF4BF7C6), const Color(0xFF1E8E77)]
                              : [Colors.green.withOpacity(0.25), Colors.green.withOpacity(0.05)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        boxShadow: inZone
                            ? [
                                BoxShadow(
                                  color: const Color(0xFF4BF7C6).withOpacity(0.5),
                                  blurRadius: 12,
                                  spreadRadius: 1,
                                )
                              ]
                            : [],
                      ),
                    ),
                  ),
                  Positioned(
                    top: markerY - 10,
                    left: 10,
                    right: 10,
                    child: Container(
                      height: 20,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFC36A), Color(0xFFFF7F50)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.orangeAccent.withOpacity(0.6),
                            blurRadius: 16,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}