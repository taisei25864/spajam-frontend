import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class CatContainer extends PositionComponent with HasGameReference {
  final String fileName;
  final double targetValue;
  final double baseX;
  final double maxInputValue;

  // 猫の大きさを調整するための係数。画面の高さに対する割合 (例: 0.2 = 20%)
  // この値を小さくすると猫が小さくなり、大きくすると大きくなります。
  static const double catSizeFactor = 0.26;
  // --- ▼▼▼ ここからが変更部分 ▼▼▼ ---
  // 猫の画像の縦横比 (幅 / 高さ)。実際の画像に合わせて調整してください。
  static const double catAspectRatio = 433 / 1450;
  // --- ▲▲▲ ここまでが変更部分 ▲▲▲ ---

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
    // 上で定義した係数を使って、猫の高さを計算
    final containerHeight = game.size.y * catSizeFactor;

    // --- ▼▼▼ ここからが変更部分 ▼▼▼ ---
    // 上で定義したアスペクト比を使って、猫の幅を計算
    final containerWidth = containerHeight * catAspectRatio;
    // --- ▲▲▲ ここまでが変更部分 ▲▲▲ ---
    size = Vector2(containerWidth, containerHeight);
    anchor = Anchor.center;

    position = Vector2(baseX, game.size.y / 2);

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

  /// 入力値に基づいて、猫の縦位置を更新するメソッド
  void updateState(double currentValue) {
    // 1. 目標周波数と現在周波数の差を計算します。
    final difference = currentValue - targetValue;

    // 2. 動きの感度を調整する係数です。
    // この値を大きくすると、猫の上下の動きがより敏感になります。
    const sensitivity = 0.8;

    // 3. 画面中央からのY座標の変位（どれだけ動くか）を計算します。
    // マイナスを掛けているのは、周波数が高い（差がプラス）ほど上（Y座標が小さい）に動かすためです。
    final displacement = -difference * sensitivity;

    // 4. 猫の新しいY座標を計算します。
    // 画面の縦中心 (game.size.y / 2) を基準に、計算した変位を加えます。
    final newY = (game.size.y / 2) + displacement;

    // 5. 画面外に飛び出さないように、Y座標を制限します。
    // 猫の高さの半分をマージンとして、画面の上端・下端に収まるようにします。
    final margin = size.y / 2;
    y = newY.clamp(margin, game.size.y - margin);
  }

  void setAsPlayer(Color color) {
    background.paint.color = color.withAlpha(77);
  }
}

