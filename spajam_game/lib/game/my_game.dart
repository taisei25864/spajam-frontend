import 'dart:async';
import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/game.dart';
import 'package:flame/particles.dart';
import 'package:flutter/material.dart';

// ユーザー指定のインポートパス
import '../cat_container.dart';
import '../input_bar.dart';

enum GameState { playing, stageClear, gameOver }

class MyGame extends FlameGame {
  final catContainers = <CatContainer>[];
  late final InputBar inputBar;
  late final RectangleComponent screenFlash;
  late final TextComponent timerText;

  final List<List<double>> stageTargetValues = [
    [13.0, 18.0, 20.0],
    [5.0, 15.0, 25.0],
    [10.0, 15.0, 20.0],
  ];
  late List<double> currentTargetValues;
  final double maxInputValue = 30.0;
  final double gameDuration = 20.0;
  final double gracePeriod = 5.0;

  double _time = 0;
  late int playerIndex;
  GameState _gameState = GameState.playing;
  double _timeInRange = 0.0;
  int _stage = 0;
  late String randomColorKey;

  List<double> playerInputs = [0.0, 0.0, 0.0];

  final VoidCallback onExit;
  final VoidCallback onStageClear;

  MyGame({
    required this.onExit,
    required this.onStageClear,
  });

  final Map<String, List<String>> catGroups = {
    'blue': ['blue_cat_1.png', 'blue_cat_2.png', 'blue_cat_3.png'],
    'normal': ['normal_cat_1.png', 'normal_cat_2.png', 'normal_cat_3.png'],
    'yellow': ['yellow_cat_1.png', 'yellow_cat_2.png', 'yellow_cat_3.png'],
    'purple': ['purple_cat_1.png', 'purple_cat_2.png', 'purple_cat_3.png'],
    'green': ['green_cat_1.png', 'green_cat_2.png', 'green_cat_3.png'],
  };

  final Map<String, String> combinedCatImages = {
    'blue': 'blue_cat.png',
    'normal': 'normal_cat.png',
    'yellow': 'yellow_cat.png',
    'purple': 'purple_cat.png',
    'green': 'green_cat.png',
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

    final colorKeys = catGroups.keys.toList();
    randomColorKey = colorKeys[Random().nextInt(colorKeys.length)];
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
  }

  void updatePlayerInput(int index, double value) {
    if (index >= 0 && index < playerInputs.length) {
      playerInputs[index] = value;
    }
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
      _gameState = GameState.gameOver;
      overlays.add('gameOver');
      return;
    }
    timerText.text = 'Time: ${remainingTime.toStringAsFixed(1)}';

    if (catContainers.isEmpty) return;

    // ★★★ ステージクリア確認用：目標値を直接入力値に設定 ★★★
    for (var i = 0; i < currentTargetValues.length; i++) {
      updatePlayerInput(i, currentTargetValues[i]);
    }

    for (var i = 0; i < catContainers.length; i++) {
      catContainers[i].updateState(playerInputs[i]);
    }
    inputBar.updateValue(playerInputs[playerIndex]);

    final isPlayerOutOfRange = (playerInputs[playerIndex] - currentTargetValues[playerIndex]).abs() > 0.5;
    if (_time > gracePeriod && isPlayerOutOfRange) {
      final opacity = (sin(_time * 8) + 1) / 2;
      screenFlash.paint.color = Colors.red.withAlpha((opacity * 64).round());
    } else {
      screenFlash.paint.color = Colors.transparent;
    }

    bool allPlayersInRange = true;
    for (var i = 0; i < playerInputs.length; i++) {
      if ((playerInputs[i] - currentTargetValues[i]).abs() > 0.5) {
        allPlayersInRange = false;
        break;
      }
    }

    if (allPlayersInRange) {
      _timeInRange += dt;
      if (_timeInRange >= 2.0) {
        _gameState = GameState.stageClear;
        unawaited(_goToNextStage());
      }
    } else {
      _timeInRange = 0;
    }
  }

  Future<void> _goToNextStage() async {
    _stage++;
    _gameState = GameState.stageClear;

    final clearText = TextComponent(
      text: 'STAGE CLEAR!',
      position: size / 2, anchor: Anchor.center,
      textRenderer: TextPaint(style: const TextStyle(fontSize: 48, color: Colors.yellow)),
      priority: 12,
    );
    add(clearText);

    if (catContainers.length < 3) return;

    final animatorCat = catContainers[1];

    catContainers[0].removeFromParent();
    catContainers[2].removeFromParent();
    inputBar.removeFromParent();

    final combinedImageFile = combinedCatImages[randomColorKey]!;
    animatorCat.catImage.sprite = await Sprite.load(combinedImageFile);

    final moveEffect = MoveEffect.to(
      size / 2,
      EffectController(duration: 1.5, curve: Curves.easeOut),
    );
    final scaleEffect = ScaleEffect.to(
      Vector2.all(3.0),
      EffectController(duration: 1.5, curve: Curves.easeOut),
    );

    await animatorCat.add(moveEffect);
    await animatorCat.add(scaleEffect);

    animatorCat.removeFromParent();
    final particle = ParticleSystemComponent(
      particle: Particle.generate(
        count: 30,
        lifespan: 1.0,
        generator: (i) => AcceleratedParticle(
          speed: Vector2(Random().nextDouble() * 400 - 200, Random().nextDouble() * -400),
          child: CircleParticle(
            radius: Random().nextDouble() * 4 + 2,
            paint: Paint()..color = Colors.primaries[Random().nextInt(Colors.primaries.length)],
          ),
        ),
      ),
      position: size / 2,
    );
    add(particle);

    await Future.delayed(const Duration(seconds: 2));
    onStageClear();
  }

  void resetStage() {
    _stage = 0;
  }

  void exitToMenu() {
    onExit();
  }
}