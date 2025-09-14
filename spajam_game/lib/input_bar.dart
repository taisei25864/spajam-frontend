import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class InputBar extends PositionComponent with HasGameReference {
  late final RectangleComponent valueBar;
  late final TextComponent targetValueText;
  late final RectangleComponent targetRangeBar;
  final Color barColor = Colors.cyan;

  final double displayHeight;
  final double maxValue;

  InputBar({
    required this.displayHeight,
    required this.maxValue,
  });

  double targetValue = 0;

  @override
  Future<void> onLoad() async {
    final barWidth = 50.0;
    size = Vector2(barWidth + 20, displayHeight);
    anchor = Anchor.centerRight;

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

    final targetRangeWidth = barWidth + 10.0;
    targetRangeBar = RectangleComponent(
      position: Vector2((barWidth - targetRangeWidth) / 2, 0),
      size: Vector2(targetRangeWidth, 0),
      paint: Paint()..color = Colors.green.withAlpha(100),
    );
    await add(targetRangeBar);

    targetValueText = TextComponent(
      text: 'Target',
      anchor: Anchor.topCenter,
      position: Vector2(barWidth / 2, -30),
      textRenderer: TextPaint(style: const TextStyle(color: Colors.white, fontSize: 20)),
    );
    await add(targetValueText);
  }

  void updateValue(double currentValue) {
    final normalizedValue = (currentValue / maxValue).clamp(0.0, 1.0);
    valueBar.size.y = displayHeight * normalizedValue;
  }

  /// 目標を設定し、許容範囲（緑のバー）とテキストを更新する
  void setTarget(String noteName, double targetHz, double rangeStartHz, double rangeEndHz) {
    targetValue = targetHz;
    // テキストを「ド (262 Hz)」のような形式に変更
    targetValueText.text = '$noteName (${targetHz.round()} Hz)';

    final normalizedStart = (rangeStartHz / maxValue).clamp(0.0, 1.0);
    final normalizedEnd = (rangeEndHz / maxValue).clamp(0.0, 1.0);

    targetRangeBar.position.y = displayHeight * (1.0 - normalizedEnd);
    targetRangeBar.size.y = displayHeight * (normalizedEnd - normalizedStart);
  }
}

