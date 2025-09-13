import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class InputBar extends PositionComponent with HasGameReference {
  late final RectangleComponent valueBar;
  late final TextComponent targetValueText;
  final Color barColor = Colors.cyan;

  // 猫の画像の高さを外部から受け取る
  final double displayHeight;

  InputBar({required this.displayHeight});

  double targetValue = 0;

  @override
  Future<void> onLoad() async {
    final barWidth = 50.0;
    // 受け取った高さを使う
    size = Vector2(barWidth + 20, displayHeight);
    anchor = Anchor.centerRight; // アンカーを中央右に

    final background = RectangleComponent(
      size: Vector2(barWidth, displayHeight),
      paint: Paint()..color = Colors.grey.shade800,
    );
    await add(background);

    valueBar = RectangleComponent(
      position: Vector2(0, displayHeight),
      size: Vector2(barWidth, 0),
      paint: Paint()..color = barColor,
      anchor: Anchor.bottomLeft,
    );
    await add(valueBar);

    for (int i = 0; i <= 10; i++) {
      final tickPosition = displayHeight * (i / 10.0);
      final tick = RectangleComponent(
        position: Vector2(barWidth, tickPosition),
        size: Vector2(10, 2),
        anchor: Anchor.centerLeft,
        paint: Paint()..color = Colors.white,
      );
      await add(tick);
    }

    targetValueText = TextComponent(
      text: 'Target: 0.0',
      anchor: Anchor.topCenter,
      position: Vector2(barWidth / 2, -30),
      textRenderer: TextPaint(style: const TextStyle(color: Colors.white, fontSize: 20)),
    );
    await add(targetValueText);
  }

  void updateValue(double currentValue) {
    final normalizedValue = (currentValue / 100.0).clamp(0.0, 1.0);
    valueBar.size.y = displayHeight * normalizedValue;
  }

  void setTarget(double newTarget) {
    targetValue = newTarget;
    targetValueText.text = 'Target: ${targetValue.toStringAsFixed(1)}';
  }
}