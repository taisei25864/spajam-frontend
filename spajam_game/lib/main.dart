import 'dart:math';
// ★★★ ここを修正 ★★★
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

  final targetValues = [30.0, 85.0, 60.0];
  double _time = 0;

  @override
  Future<void> onLoad() async {
    final screenWidth = size.x;
    final catAreaWidth = screenWidth * 0.7;
    final spacing = catAreaWidth / (targetValues.length + 1);

    final catHeight = size.y * 0.8;

    for (var i = 0; i < targetValues.length; i++) {
      final baseX = spacing * (i + 1);
      final cat = CatContainer(
        fileName: 'blue_cat_${i + 1}.png',
        targetValue: targetValues[i],
        baseX: baseX,
      );
      catContainers.add(cat);
    }
    await addAll(catContainers);

    inputBar = InputBar(displayHeight: catHeight);
    inputBar.position = Vector2(screenWidth - 10, size.y / 2);
    await add(inputBar);

    catContainers[0].setAsPlayer(inputBar.barColor);
    inputBar.setTarget(targetValues[0]);
  }

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;

    final myInputValue = (sin(_time) + 1) * 50;
    final otherPlayerValue1 = 10.0;
    final otherPlayerValue2 = 95.0;

    catContainers[0].updateState(myInputValue);
    catContainers[1].updateState(otherPlayerValue1);
    catContainers[2].updateState(otherPlayerValue2);

    inputBar.updateValue(myInputValue);
  }
}