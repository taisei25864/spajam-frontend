import 'package:flutter/material.dart';
import 'package:flame/game.dart';

import '../game/my_game.dart';

class GameScreen extends StatelessWidget {
  static const routeName = '/game';
  GameScreen({super.key});

  final MyGame _game = MyGame(); // 1回だけ生成

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GameWidget(game: _game),
    );
  }
}