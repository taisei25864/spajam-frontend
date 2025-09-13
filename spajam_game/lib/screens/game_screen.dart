import 'package:flutter/material.dart';
import 'package:flame/game.dart';

import '../game/my_game.dart';
import 'menu_screen.dart'; // MenuScreenをインポート

class GameScreen extends StatefulWidget {
  static const routeName = '/game';
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final MyGame _game;

  @override
  void initState() {
    super.initState();
    _game = MyGame(
      onExit: () {
        if (!mounted) return;
        // 終了ボタンが押されたらタイトル画面(MenuScreen)に戻る
        Navigator.of(context).pushNamedAndRemoveUntil(
          MenuScreen.routeName,
              (route) => false,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GameWidget(
        game: _game,
        // ゲームオーバー時に表示するUIをここで定義
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
                      onPressed: myGame.restartGame,
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