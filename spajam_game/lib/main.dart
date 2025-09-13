import 'package:flame/game.dart';
import 'package:flutter/widgets.dart';
import 'cat.dart'; // 作成した cat.dart ファイルを読み込む

void main() {
  final game = MyGame();
  runApp(GameWidget(game: game));
}

class MyGame extends FlameGame {
  @override
  Future<void> onLoad() async {
    // 青い猫を (x: 50, y: 150) の位置に1匹だけ表示
    add(Cat(color: 'blue', position: Vector2(10, 150)));
  }
}