import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import 'cat_container.dart';
import 'input_bar.dart';

void main() {
  runApp(GameWidget(game: MyGame()));
}

class MyGame extends FlameGame {
  final catContainers = <CatContainer>[];
  late final InputBar inputBar;
  late final RectangleComponent screenFlash;
  late final TextComponent timerText;

  final targetValues = [13.0, 18.0, 20.0];
  final double maxInputValue = 30.0;

  final double gameDuration = 20.0;
  final double gracePeriod = 15.0;
  double _time = 0;

  late final int playerIndex;

  @override
  Future<void> onLoad() async {
    // ★★★ ここからが追加部分 ★★★
    // 背景画像用のコンポーネントを作成
    final background = SpriteComponent()
      ..sprite = await Sprite.load('background.png') // 画像ファイル名を指定
      ..size = size // 画面全体に広げる
      ..position = Vector2.zero()
      ..priority = -1; // 描画の優先度を一番低くして、常に最背面に表示
    await add(background);
    // ★★★ ここまでが追加部分 ★★★

    playerIndex = Random().nextInt(targetValues.length);

    screenFlash = RectangleComponent(
      size: size,
      paint: Paint()..color = Colors.transparent,
      priority: 10,
    );
    await add(screenFlash);

    // (以下、変更なし)
    final screenWidth = size.x;
    final catAreaWidth = screenWidth * 0.7;
    final spacing = catAreaWidth / (targetValues.length + 1);
    final displayHeight = size.y * 0.8;

    final catHeight = size.y * 0.25;
    final margin = 20.0;
    final upperLimit = (catHeight / 2) + margin;
    final lowerLimit = size.y - (catHeight / 2) - margin;
    final zoneHeight = lowerLimit - upperLimit;

    final playerZoneBackground = RectangleComponent(
      position: Vector2(spacing * (playerIndex + 1), upperLimit + zoneHeight / 2),
      size: Vector2(catAreaWidth / (targetValues.length + 1), zoneHeight),
      anchor: Anchor.center,
      paint: Paint()..color = Colors.white.withAlpha(26),
    );
    await add(playerZoneBackground);

    for (var i = 0; i < targetValues.length; i++) {
      final baseX = spacing * (i + 1);
      final cat = CatContainer(
        fileName: 'blue_cat_${i + 1}.png',
        targetValue: targetValues[i],
        baseX: baseX,
        maxInputValue: maxInputValue,
      );
      catContainers.add(cat);
    }
    await addAll(catContainers);

    inputBar = InputBar(
      displayHeight: displayHeight,
      maxValue: maxInputValue,
    );
    inputBar.position = Vector2(screenWidth - 10, size.y / 2);
    await add(inputBar);

    catContainers[playerIndex].setAsPlayer(inputBar.barColor);
    inputBar.setTarget(targetValues[playerIndex]);

    timerText = TextComponent(
      text: 'Time: ${gameDuration.toStringAsFixed(1)}',
      position: Vector2(size.x / 2, 20),
      anchor: Anchor.topCenter,
      textRenderer: TextPaint(style: const TextStyle(color: Colors.white, fontSize: 32)),
    );
    await add(timerText);
  }

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;

    final remainingTime = gameDuration - _time;
    if (remainingTime <= 0) {
      timerText.text = 'Time: 0.0';
      return;
    }
    timerText.text = 'Time: ${remainingTime.toStringAsFixed(1)}';

    final myInputValue = ((sin(_time * 1.0) + 1) / 2) * maxInputValue;
    final otherPlayerValue1 = ((sin(_time * 1.3 + 1) + 1) / 2) * maxInputValue;
    final otherPlayerValue2 = ((sin(_time * 1.6 + 2) + 1) / 2) * maxInputValue;

    catContainers[0].updateState(myInputValue);
    catContainers[1].updateState(otherPlayerValue1);
    catContainers[2].updateState(otherPlayerValue2);

    inputBar.updateValue(myInputValue);

    if (_time > gracePeriod) {
      final isOutOfRange = (myInputValue - targetValues[playerIndex]).abs() > 0.5;
      if (isOutOfRange) {
        final opacity = (sin(_time * 8) + 1) / 2;
        screenFlash.paint.color = Colors.red.withAlpha((opacity * 64).round());
      } else {
        screenFlash.paint.color = Colors.transparent;
      }
    }
  }
}