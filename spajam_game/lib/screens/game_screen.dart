import 'package:flutter/material.dart';
import 'package:flame/game.dart';

import '../game/my_game.dart';
import 'menu_screen.dart';

class GameScreen extends StatefulWidget {
  static const routeName = '/game';
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  // Keyを使ってゲームウィジェットを再生成できるようにする
  Key _gameWidgetKey = UniqueKey();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GameWidget(
        key: _gameWidgetKey,
        game: MyGame(
          // 終了ボタンが押されたときの処理
          onExit: () {
            if (!mounted) return;
            Navigator.of(context).pushNamedAndRemoveUntil(
              MenuScreen.routeName,
                  (route) => false,
            );
          },
          // ステージクリア時に呼ばれる処理
          onStageClear: () {
            setState(() {
              // Keyを変更してGameWidgetを再生成し、次のステージに進む
              _gameWidgetKey = UniqueKey();
            });
          },
        ),
        // ゲームオーバー時に表示するUI
        overlayBuilderMap: {
          'gameOver': (context, game) {
            final myGame = game as MyGame;
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
                      // リスタートボタンが押されたら、Keyを変更して再生成
                      onPressed: () {
                        setState(() {
                          myGame.resetStage(); // ステージ番号をリセット
                          _gameWidgetKey = UniqueKey();
                        });
                      },
                      child: const Text('リスタート'),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: myGame.exitToMenu,
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