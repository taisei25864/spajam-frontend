import 'dart:math'; // sin関数を使うために必要
import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

// --- 猫の各パーツを管理するクラス ---
class CatPart extends SpriteComponent {
  final String fileName;
  double _time = 0; // 動きの計算に使う時間

  CatPart({required this.fileName});

  @override
  Future<void> onLoad() async {
    sprite = await Sprite.load(fileName);
    size = Vector2(100,335); // 各パーツの表示サイズ
    anchor = Anchor.topCenter; // 上下運動の基準点を上部中央に
  }

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt; // 経過時間を加算

    // sin関数を使って滑らかな上下運動を表現
    // 振幅10ピクセル、周期2秒でふわふわ動く
    y = sin(_time * pi) * 10;
  }
}


// --- CatPartを3つ連結する親クラス ---
class Cat extends PositionComponent {
  final String color;
  Cat({required this.color, required Vector2 position}) {
    this.position = position;
    size = Vector2(60, 60);
  }

  final _paint = Paint()..color = const Color(0xFFFFC107);

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    canvas.drawRect(size.toRect(), _paint);
  }

  @override
  Future<void> onLoad() async {
    double currentX = 0;
    const partWidth = 100.0; // 各パーツの幅

    for (int i = 1; i <= 3; i++) {
      final fileName = '${color}_cat_$i.png';

      final part = CatPart(fileName: fileName)
        ..position = Vector2(currentX + (partWidth / 2), 0); // 各パーツを横に並べる

      add(part); // 親コンポーネントにパーツを追加
      currentX += partWidth;
    }
  }
}