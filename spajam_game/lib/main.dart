import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'state/game_state.dart';
import 'screens/menu_screen.dart';
import 'screens/lobby_screen.dart';
import 'theme/app_theme.dart';

import 'package:flame/game.dart';
import 'package:flutter/widgets.dart';
import 'cat.dart'; // 作成した cat.dart ファイルを読み込む

void main() {
  runApp(const SpanyanApp());
}

class SpanyanApp extends StatelessWidget {
  const SpanyanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => GameState(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'ハモってGO！',
        theme: AppTheme.build(),
        initialRoute: MenuScreen.routeName,
        routes: {
          MenuScreen.routeName: (_) => const MenuScreen(),
          LobbyScreen.routeName: (_) => const LobbyScreen(),
        },
      ),
    );

class MyGame extends FlameGame {
  @override
  Future<void> onLoad() async {
    // 青い猫を (x: 50, y: 150) の位置に1匹だけ表示
    add(Cat(color: 'blue', position: Vector2(10, 150)));
  }
}
