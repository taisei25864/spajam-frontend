import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import '../game/my_game.dart'; // ← このimportパスが正しいか、再度ご確認ください
import 'result_screen.dart';
import 'menu_screen.dart';

class GameScreen extends StatefulWidget {
  static const routeName = '/game';
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  // 現在のステージ番号をStateとして管理 (0から始まる)
  int _currentStage = 0;
  // 全ステージ数を定義
  final int totalStages = 5;

  void _onExit() {
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(MenuScreen.routeName, (r) => false);
  }

  void _onStageClear() {
    if (!mounted) return;


    // 現在のステージが最終ステージ (5ステージ目 = _currentStageが4) かどうかをチェック
    if (_currentStage >= totalStages - 1) {
      // 最終ステージをクリアした場合、ResultScreenに遷移
      // pushNamedAndRemoveUntilで、ゲーム画面に戻れないようにする
      Navigator.of(context).pushNamedAndRemoveUntil(ResultScreen.routeName, (r) => false);
    } else {
      // それ以外の場合は、次のステージへ進む
      setState(() {
        _currentStage++;
      });
    }

  }

  void _onRestart() {
    // ステージ番号をリセットして、再描画をトリガーする
    setState(() {
      _currentStage = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GameWidget(
        // ValueKeyに現在のステージ番号を渡すことで、ステージが変わるたびに
        // GameWidgetが新しいものとして認識され、MyGameが再生成される
        key: ValueKey(_currentStage),

        // MyGame(...) はクラスのインスタンスを生成する正しい構文です。
        // この行でエラーが発生する場合、以下の原因が考えられます。
        // 1. 上の import '../game/my_game.dart'; のパスが間違っている。
        // 2. 'my_game.dart' ファイル内に 'MyGame' という名前のクラスが正しく定義されていない。
        // 3. プロジェクトのキャッシュが古い（その場合は `flutter clean` を実行してみてください）。
        game: MyGame(
          stage: _currentStage,
          onExit: _onExit,
          onStageClear: _onStageClear,
        ),
        overlayBuilderMap: {
          'gameOver': (context, game) {

            return Center(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'GAME OVER',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _onRestart,
                      child: const Text('リスタート'),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _onExit,
                      child: const Text('終了'),
                    ),
                  ],
                ),
              ),
            );
          },
        },
      ),
    );
  }
}

