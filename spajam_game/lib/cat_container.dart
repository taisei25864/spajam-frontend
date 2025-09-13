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
    // 現在の入力値と目標値との差を計算
    final difference = currentValue - targetValue;

    // 差を画面上のピクセル移動量に変換する係数
    // この値を大きくすると、少しの差で大きく動く
    final verticalScale = 15.0;

    // ★★★ 修正: 画面中央を基準に、差の分だけY座標をずらす ★★★
    // Y軸は下が正なので、差に-1を掛けて直感的な動きにする
    y = (game.size.y / 2) - (difference * verticalScale);

    // 上下の移動範囲の制限
    final margin = 20.0;
    final upperLimit = (size.y / 2) + margin;
    final lowerLimit = game.size.y - (size.y / 2) - margin;
    y = y.clamp(upperLimit, lowerLimit);
  }

// ...

  void setAsPlayer(Color color) {
    background.paint.color = color.withAlpha(77);
  }
}