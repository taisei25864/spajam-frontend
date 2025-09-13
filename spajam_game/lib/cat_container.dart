import 'package:flame/components.dart';
import 'package:flutter/material.dart';

// ★★★ extends PositionComponent with HasGameReference を確認 ★★★
class CatContainer extends PositionComponent with HasGameReference {
  final String fileName;
  final double targetValue;
  final double baseX;

  late final SpriteComponent catImage;
  late final RectangleComponent background;

  CatContainer({
    required this.fileName,
    required this.targetValue,
    required this.baseX,
  });

  @override
  Future<void> onLoad() async {
    final containerHeight = game.size.y * 0.8;
    final containerWidth = containerHeight * (100 / 335);
    size = Vector2(containerWidth, containerHeight);
    anchor = Anchor.center;

    x = baseX;

    catImage = SpriteComponent(
      sprite: await Sprite.load(fileName),
      size: size,
    );
    background = RectangleComponent(
      size: size,
      paint: Paint()..color = Colors.transparent,
    );

    await add(background);
    await add(catImage);
  }

  void updateState(double currentValue) {
    final normalizedValue = (currentValue / 100.0).clamp(0.0, 1.0);
    y = game.size.y - (size.y / 2) - ((game.size.y - size.y) * normalizedValue);
  }

  void setAsPlayer(Color color) {
    background.paint.color = color.withAlpha(77);
  }
}