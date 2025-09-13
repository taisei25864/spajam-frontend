import 'dart:async';
import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flutter/material.dart';

import '../cat_container.dart';
import '../input_bar.dart';

enum GameState { playing, stageClear, gameOver }

class MyGame extends FlameGame {
  // --- コンポーネント ---
  final catContainers = <CatContainer>[];
  late final InputBar inputBar;
  late final RectangleComponent screenFlash;
  late final TextComponent timerText;
  // ★★★ UIコンポーネントを late ではなく Optional に変更 ★★★
  SpriteButtonComponent? restartButton;
  SpriteButtonComponent? exitButton;

  // --- 設定値 ---
  final List<List<double>> stageTargetValues = [
    [13.0, 18.0, 20.0], [5.0, 15.0, 25.0], [10.0, 15.0, 20.0],
  ];
  late List<double> currentTargetValues;
  final double maxInputValue = 30.0;
  final double gameDuration = 20.0;
  final double gracePeriod = 5.0;

  // --- 状態変数 ---
  double _time = 0;
  late int playerIndex;
  GameState _gameState = GameState.playing;
  double _timeInRange = 0.0;
  int _stage = 0;

  // --- Flutter側から渡されるコールバック ---
  final VoidCallback onExit;
  MyGame({required this.onExit});

  // ★★★ 猫のファイル名をグループ化 ★★★
  final Map<String, List<String>> catGroups = {
    'blue': ['blue_cat_1.png', 'blue_cat_2.png', 'blue_cat_3.png'],
    'normal': ['normal_cat_1.png', 'normal_cat_2.png', 'normal_cat_3.png'],
    'yellow': ['yellow_cat_1.png', 'yellow_cat_2.png', 'yellow_cat_3.png'],
    'purple': ['purple_cat_1.png', 'purple_cat_2.png', 'purple_cat_3.png'],
    'green': ['green_cat_1.png', 'green_cat_2.png', 'green_cat_3.png'],
  };

  @override
  Future<void> onLoad() async {
    await initializeStage();
  }

  Future<void> initializeStage() async {
    overlays.clear();
    removeAll(children.whereType<Component>());
    catContainers.clear();
    _time = 0;
    _timeInRange = 0;
    _gameState = GameState.playing;

    currentTargetValues = stageTargetValues[_stage % stageTargetValues.length];

    // --- UI要素の準備 ---
    await _setupUI();
  }

  // ★★★ UI要素のセットアップを別メソッドに分離 ★★★
  Future<void> _setupUI() async {
    final background = SpriteComponent()
      ..sprite = await Sprite.load('background.png')
      ..size = size ..position = Vector2.zero() ..priority = -1;
    await add(background);

    playerIndex = Random().nextInt(currentTargetValues.length);

    screenFlash = RectangleComponent(size: size, paint: Paint()..color = Colors.transparent, priority: 10);
    await add(screenFlash);

    final screenWidth = size.x;
    final catAreaWidth = screenWidth * 0.7;
    final spacing = catAreaWidth / (currentTargetValues.length + 1);
    final displayHeight = size.y * 0.8;

    final playerZoneBackground = RectangleComponent(
      position: Vector2(spacing * (playerIndex + 1), size.y / 2),
      size: Vector2(catAreaWidth / (currentTargetValues.length + 1), size.y * 0.9),
      anchor: Anchor.center,
      paint: Paint()..color = Colors.white.withAlpha(50),
    );
    await add(playerZoneBackground);

    // ★★★ ランダムな色の猫を順番に選択するロジック ★★★
    final colorKeys = catGroups.keys.toList();
    final randomColorKey = colorKeys[Random().nextInt(colorKeys.length)];
    final selectedCatFiles = catGroups[randomColorKey]!;

    for (var i = 0; i < currentTargetValues.length; i++) {
      final cat = CatContainer(
        fileName: selectedCatFiles[i],
        targetValue: currentTargetValues[i],
        baseX: spacing * (i + 1),
        maxInputValue: maxInputValue,
      );
      catContainers.add(cat);
    }
    await addAll(catContainers);

    inputBar = InputBar(displayHeight: displayHeight, maxValue: maxInputValue);
    inputBar.position = Vector2(screenWidth - 10, size.y / 2);
    await add(inputBar);

    catContainers[playerIndex].setAsPlayer(inputBar.barColor);
    inputBar.setTarget(currentTargetValues[playerIndex]);

    timerText = TextComponent(
      text: 'Time: ${gameDuration.toStringAsFixed(1)}',
      position: Vector2(size.x / 2, 20),
      anchor: Anchor.topCenter,
      textRenderer: TextPaint(style: const TextStyle(color: Colors.white, fontSize: 32)),
      priority: 11,
    );
    await add(timerText);

    restartButton = SpriteButtonComponent(
      button: await Sprite.load('restart_button.png'),
      size: Vector2(200, 100), position: Vector2(size.x / 2, size.y / 2 - 60),
      anchor: Anchor.center, onPressed: restartGame, priority: 12,
    );
    exitButton = SpriteButtonComponent(
      button: await Sprite.load('exit_button.png'),
      size: Vector2(200, 100), position: Vector2(size.x / 2, size.y / 2 + 60),
      anchor: Anchor.center, onPressed: exitToMenu, priority: 12,
    );
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_gameState == GameState.playing) {
      _updatePlaying(dt);
    }
  }

  void _updatePlaying(double dt) {
    _time += dt;
    final remainingTime = gameDuration - _time;

    if (remainingTime <= 0) {
      timerText.text = 'Time: 0.0';
      _gameState = GameState.gameOver;
      _showGameOverUI();
      return;
    }
    timerText.text = 'Time: ${remainingTime.toStringAsFixed(1)}';

    if (catContainers.isEmpty) return;

    final myInputValue = ((sin(_time * 1.0) + 1) / 2) * maxInputValue;
    final otherPlayerValue1 = ((sin(_time * 1.3 + 1) + 1) / 2) * maxInputValue;
    final otherPlayerValue2 = ((sin(_time * 1.6 + 2) + 1) / 2) * maxInputValue;

    catContainers[0].updateState(myInputValue);
    catContainers[1].updateState(otherPlayerValue1);
    catContainers[2].updateState(otherPlayerValue2);
    inputBar.updateValue(myInputValue);

    final isOutOfRange = (myInputValue - currentTargetValues[playerIndex]).abs() > 5.0;

    if (_time > gracePeriod && isOutOfRange) {
      final opacity = (sin(_time * 8) + 1) / 2;
      screenFlash.paint.color = Colors.red.withAlpha((opacity * 64).round());
    } else {
      screenFlash.paint.color = Colors.transparent;
    }

    if (!isOutOfRange) {
      _timeInRange += dt;
      if (_timeInRange >= 2.0) {
        _gameState = GameState.stageClear;
        unawaited(_goToNextStage());
      }
    } else {
      _timeInRange = 0;
    }
  }

  void _showGameOverUI() {
    if (restartButton != null) add(restartButton!);
    if (exitButton != null) add(exitButton!);
  }

  Future<void> _goToNextStage() async {
    _stage++;
    final clearText = TextComponent(
      text: 'STAGE CLEAR!',
      position: size / 2, anchor: Anchor.center,
      textRenderer: TextPaint(style: const TextStyle(fontSize: 48, color: Colors.yellow)),
      priority: 12,
    );
    add(clearText);

    await Future.delayed(const Duration(seconds: 2));
    await initializeStage();
  }

  Future<void> restartGame() async {
    _stage = 0;
    await initializeStage();
  }

  void exitToMenu() {
    onExit();
  }
}