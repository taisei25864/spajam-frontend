import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class CatContainer extends PositionComponent with HasGameReference {
  final String fileName;
  late final SpriteComponent catImage;
  late final RectangleComponent background;

  // この猫の目標値
  final double targetValue;
  // 横方向のずれの最大幅
  final double maxHorizontalShift;

  CatContainer({
    required this.fileName,
    required this.targetValue,
    required this.maxHorizontalShift,
  });

  @override
  Future<void> onLoad() async {
    // 画面の高さに基づいてサイズを自動調整
    final containerHeight = game.size.y * 0.4; // 画面の40%の高さを基準にする
    final containerWidth = containerHeight * (100 / 335); // 元の画像の比率を保つ
    size = Vector2(containerWidth, containerHeight);
    anchor = Anchor.center;

    // 子要素もコンテナに合わせてリサイズ
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

  // 入力値と目標値に基づいて位置を更新する
  void updateState(double currentValue) {
    // --- 縦スライドの計算 ---
    final normalizedValue = (currentValue / 100.0).clamp(0.0, 1.0);
    y = game.size.y * (1.0 - normalizedValue);

    // --- 横スライドの計算 ---
    final difference = (targetValue - currentValue).abs();
    // 差が0に近いほど横ずれが小さくなる
    final shift = (difference / 50.0).clamp(0.0, 1.0) * maxHorizontalShift;

    // 目標値より大きいか小さいかで、左右どちらにずれるか決める
    if (currentValue < targetValue) {
      x = (game.size.x / 2) - shift; // 中央から左にずれる
    } else {
      x = (game.size.x / 2) + shift; // 中央から右にずれる
    }
  }

  void setAsPlayer(Color color) {
    background.paint.color = color.withAlpha(77);
  }
}