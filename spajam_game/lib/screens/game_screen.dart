import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/game_state.dart';
import '../widgets/pitch_bar.dart';
import '../widgets/spanyan_split.dart';
import '../widgets/fusuma_layer.dart';
import 'result_screen.dart';

class GameScreen extends StatelessWidget {
  static const routeName = '/game';
  const GameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<GameState>();
    final players = state.players;
    final pitchValues = players.map((p) => state.pitchValues[p.id] ?? 0.5).toList();
    return Scaffold(
      body: Stack(
        children: [
          // 背景
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF110F0F), Color(0xFF1C1A1A)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // 上部バー
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        icon: const Icon(Icons.close),
                      ),
                      const Spacer(),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E2A28),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
                        onPressed: () {
                          state.completeWall();
                          if (!state.gameStarted) {
                            Future.delayed(const Duration(milliseconds: 900), () {
                              Navigator.pushReplacementNamed(context, ResultScreen.routeName);
                            });
                          }
                        },
                        child: const Text('壁突破(デモ)'),
                      ),
                    ],
                  ),
                ),
                // 合体 or 分割
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
                  child: SpanyanSplit(
                    playerNames: players.map((e) => e.name).toList(),
                    pitchValues: pitchValues,
                    combining: state.combining,
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
                    child: Row(
                      children: List.generate(players.length, (i) {
                        final p = players[i];
                        final v = state.pitchValues[p.id] ?? 0.5;
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Column(
                              children: [
                                Expanded(child: PitchBar(value: v)),
                                const SizedBox(height: 8),
                                Text(
                                  p.name,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
          // ふすまレイヤ
          IgnorePointer(
            child: AnimatedOpacity(
              opacity: 1,
              duration: const Duration(milliseconds: 400),
              child: FusumaLayer(
                open: state.doorOpenProgress,
                wallIndex: state.wallIndex,
                maxWall: state.wallMax,
              ),
            ),
          ),
        ],
      ),
    );
  }
}