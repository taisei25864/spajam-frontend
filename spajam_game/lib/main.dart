import 'dart:math';
import 'package:flame/game.dart';
import 'package:flutter/widgets.dart';

import 'cat_container.dart';
import 'input_bar.dart';

void main() {
  runApp(GameWidget(game: MyGame()));
}

class MyGame extends FlameGame {
  final catContainers = <CatContainer>[];
  late final InputBar inputBar;

  // 各猫の目標値を設定 (0.0 ~ 100.0)
  final targetValues = [30.0, 85.0, 60.0];
  double _time = 0;

  @override
  Future<void> onLoad() async {
    // 3匹の猫を生成
    for (var i = 0; i < 3; i++) {
      final cat = CatContainer(
        fileName: 'blue_cat_${i + 1}.png',
        targetValue: targetValues[i],
        // 画面の横幅の30%を最大ズレ幅とする
        maxHorizontalShift: size.x * 0.3,
      );
      catContainers.add(cat);
    }
    await addAll(catContainers);

    // 棒グラフを配置
    inputBar = InputBar();
    await add(inputBar);

    // 1番目の猫をプレイヤーが操作する猫として設定
    catContainers[0].setAsPlayer(inputBar.barColor);
    // プレイヤーの目標値を棒グラフに設定
    inputBar.setTarget(targetValues[0]);
  }

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;

    // --- 自分の入力値をsin波でシミュレート (0.0 ~ 100.0) ---
    final myInputValue = (sin(_time) + 1) * 50;

    // --- 他のプレイヤーの入力値もシミュレート（初期はずれた状態）---
    final otherPlayerValue1 = 20.0;
    final otherPlayerValue2 = 95.0;

    // 各猫の状態を更新
    catContainers[0].updateState(myInputValue);
    catContainers[1].updateState(otherPlayerValue1); // 今は固定値
    catContainers[2].updateState(otherPlayerValue2); // 今は固定値

    // 自分の入力値だけを棒グラフに反映
    inputBar.updateValue(myInputValue);
  }
}