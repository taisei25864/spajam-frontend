import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'state/game_state.dart';
import 'screens/menu_screen.dart';
import 'screens/lobby_screen.dart';
import 'screens/game_screen.dart';
import 'theme/app_theme.dart';
import 'services/webrtc_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SpanyanApp());
}

class SpanyanApp extends StatelessWidget {
  const SpanyanApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => GameState()),
        ChangeNotifierProvider(create: (_) => WebRTCService()), // 追加
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'ハモってGO！',
        theme: AppTheme.build(),
        initialRoute: MenuScreen.routeName,
        routes: {
          MenuScreen.routeName: (_) => const MenuScreen(),
          LobbyScreen.routeName: (_) => const LobbyScreen(),
          GameScreen.routeName: (_) => GameScreen(),
        },
      ),
    );
  }
}
// MyGame は別ファイルへ移動済み