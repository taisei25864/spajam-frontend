import 'package:flutter/material.dart';

class WallLayer extends StatelessWidget {
  final int current;
  final int max;
  const WallLayer({super.key, required this.current, required this.max});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.brown.shade700.withOpacity(0.8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.brown.shade300),
      ),
      child: const Text(
        '壁 0 / 0', // ここは必要なら current/max を使う
        // 例: Text('壁 $current / $max', ...)
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }
}