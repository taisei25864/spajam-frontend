import 'package:flame/game.dart';
import 'package:flutter/widgets.dart';
import 'cat.dart'; // 作成した cat.dart ファイルを読み込む

void main() {
  final game = MyGame();
  runApp(GameWidget(game: game));
}

// 四角形オブジェクトのためのクラス
class Player extends PositionComponent {
  // Paint オブジェクトをここで定義しておくと効率的です
  final paint = Paint()..color = Colors.blue;

  // このコンポーネントがゲームに追加されるときに一度だけ呼ばれます
  @override
  Future<void> onLoad() async {
    // コンポーネントのサイズと位置を設定します
    size = Vector2(50, 50);       // 幅50, 高さ50の正方形
    position = Vector2(100, 100); // 画面の(x:100, y:100)の位置
  }

  // 描画を行うメソッド。毎フレーム呼ばれます。
  @override
  void render(Canvas canvas) {
    // 設定したサイズで四角形を描画します
    canvas.drawRect(size.toRect(), paint);
  }
}

class MyGame extends FlameGame {
  @override
  Future<void> onLoad() async {
    // Playerクラスのインスタンスを作成してゲームに追加します
    add(Player());
  }
}