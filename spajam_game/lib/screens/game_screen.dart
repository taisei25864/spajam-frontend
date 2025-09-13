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
    // MyGameインスタンスを作成する際に、onExitコールバックを渡す
    _game = MyGame(
      onExit: () {
        // メニュー画面に戻り、それまでの画面をすべて削除する
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
      body: GameWidget(game: _game),
    );
  }
}