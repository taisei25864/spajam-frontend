import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class CatContainer extends PositionComponent with HasGameReference {
  final String fileName;
  final double targetValue;
  final double baseX;
  final double maxInputValue;

  late final SpriteComponent catImage;
  late final RectangleComponent background;

  CatContainer({
    required this.fileName,
    required this.targetValue,
    required this.baseX,
    required this.maxInputValue,
  });

  @override
  Future<void> onLoad() async {
    final containerHeight = game.size.y * 0.25;
    final containerWidth = containerHeight * (100 / 335);
    size = Vector2(containerWidth, containerHeight);
    anchor = Anchor.center;

    position = Vector2(baseX + 30, game.size.y / 2);

    catImage = SpriteComponent(
      sprite: await Sprite.load(fileName),
      size: size,
      anchor: Anchor.center,
    );
    background = RectangleComponent(
      size: size,
      paint: Paint()..color = Colors.transparent,
      anchor: Anchor.center,
    );

    await add(background);
    await add(catImage);
  }

  void updateState(double currentValue) {
    final difference = currentValue - targetValue;
    final verticalScale = (game.size.y / 2) / (maxInputValue / 2);

    y = (game.size.y / 2) - (difference * verticalScale);

    // ★★★ ここからが修正部分 ★★★
    // 上下の余白をさらに大きくして、移動範囲を狭める
    final margin = 170.0; // 170.0 から 250.0 に変更

    // 上限値と下限値の計算式をシンプルで確実な形に修正
    final upperLimit = (size.y / 2) + margin;
    final lowerLimit = game.size.y - (size.y / 1.2) + margin;

    y = y.clamp(upperLimit, lowerLimit);
    // ★★★ ここまでが修正部分 ★★★
  }

  void setAsPlayer(Color color) {
    background.paint.color = color.withAlpha(77);
  }
}