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
  // --- コンポーネント ---
  final List<CatContainer> catContainers = [];
  late final InputBar inputBar;
  late int playerIndex;
  late final RectangleComponent screenFlash;
  late final TextComponent timerText;
  CatContainer? animatorCat;

  // --- 設定値 ---
  final List<List<double>> stageTargetValues = [
    [13.0, 18.0, 20.0],
    [5.0, 15.0, 25.0],
    [10.0, 15.0, 20.0],
    // ここに新しいステージの目標値を追加できます
  ];
  late List<double> currentTargetValues;
  final double maxInputValue = 30.0;
  final double gameDuration = 20.0;
  final double gracePeriod = 5.0;
  // 許容誤差や時間を定数として定義
  final double targetTolerance = 0.5;
  final double requiredTimeInRange = 2.0;
  final double stageClearAnimationDuration = 1.5;

  // --- 状態変数 ---
  double _time = 0;
  GameState _gameState = GameState.playing;
  double _timeInRange = 0.0;
  int _stage = 0; // GameScreenから渡されたステージ番号を保持
  late String randomColorKey;
  // 3人分の入力値を保持するリスト
  List<double> playerInputs = [0.0, 0.0, 0.0];

  // --- コールバック ---
  final VoidCallback onExit;
  final VoidCallback onStageClear;

  final int stage;

  MyGame({
    required this.stage, // GameScreenから現在のステージ番号を受け取る
    required this.onExit,
    required this.onStageClear,
  });

  // --- アセット定義 (変更なし) ---
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
    _stage = stage;

    // リセット処理
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

    screenFlash = RectangleComponent(size: size, paint: Paint()..color = Colors.transparent, priority: 10);
    await add(screenFlash);

    final screenWidth = size.x;
    final catAreaWidth = screenWidth * 0.7;
    final spacing = catAreaWidth / (currentTargetValues.length + 1);
    final displayHeight = size.y * 0.8;

    playerIndex = Random().nextInt(currentTargetValues.length);

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

    final stageText = TextComponent(
      text: 'Stage: ${_stage + 1}', // 0から始まるので+1して表示
      position: Vector2(20, 20),
      anchor: Anchor.topLeft,
      textRenderer: TextPaint(style: const TextStyle(color: Colors.white, fontSize: 32)),
      priority: 11,
    );
    await add(stageText);
  }

  void updatePlayerInput(int index, double value) {
    if (index >= 0 && index < playerInputs.length) {
      playerInputs[index] = value.clamp(0.0, maxInputValue);
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

    // テストのため、現在のステージの目標値を直接入力値として設定する
    for (var i = 0; i < currentTargetValues.length; i++) {
      updatePlayerInput(i, currentTargetValues[i]);
    }

    for (var i = 0; i < catContainers.length; i++) {
      catContainers[i].updateState(playerInputs[i]);
    }

    inputBar.updateValue(playerInputs[playerIndex]);

    bool allPlayersInRange = true;
    for (var i = 0; i < playerInputs.length; i++) {
      if ((playerInputs[i] - currentTargetValues[i]).abs() > targetTolerance) {
        allPlayersInRange = false;
        break;
      }
    }

    if (allPlayersInRange) {
      _timeInRange += dt;
      if (_timeInRange >= requiredTimeInRange) {
        _gameState = GameState.stageClear;
        unawaited(_goToNextStage());
      }
    } else {
      _timeInRange = 0;
    }

    if (remainingTime <= 5.0) {
      final flashOpacity = (sin(_time * pi * 2) + 1) / 2; // 0.0 ~ 1.0
      screenFlash.paint.color = Colors.red.withAlpha((flashOpacity * 0.25 * 255).round());
    } else {
      if (_time > gracePeriod && !allPlayersInRange) {
        // screenFlash.paint.color = Colors.red.withAlpha((0.2 * 255).round());
      } else {
        screenFlash.paint.color = Colors.transparent;
      }
    }
  }

  Future<void> _goToNextStage() async {
    _gameState = GameState.stageClear;

    add(TextComponent(
      text: 'STAGE CLEAR!',
      position: size / 2,
      anchor: Anchor.center,
      textRenderer: TextPaint(style: const TextStyle(fontSize: 48, color: Colors.yellow)),
      priority: 12,
    ));

    if (catContainers.isEmpty) return;

    // --- ▼▼▼ ここからがアニメーションの変更部分 ▼▼▼ ---

    // 1. 既存の猫たちと入力バーをすべて削除
    for (final cat in catContainers) {
      cat.removeFromParent();
    }
    inputBar.removeFromParent();

    // 2. 統合された猫を画面中央に新しく生成
    final combinedImageFile = combinedCatImages[randomColorKey]!;
    final combinedCat = SpriteComponent(
      sprite: await Sprite.load(combinedImageFile),
      position: size / 2, // 最初から中央に配置
      anchor: Anchor.center,
      scale: Vector2.zero(), // 最初は大きさを0にして、拡大アニメーションで表示する
    );
    await add(combinedCat);

    // 3. 統合された猫に拡大エフェクトを追加
    final scaleEffect = ScaleEffect.to(
      Vector2.all(3.0),
      EffectController(
        duration: stageClearAnimationDuration,
        curve: Curves.easeOut,
      ),
      onComplete: () {
        // 4. アニメーション完了後に破裂エフェクトを呼び出す
        if (combinedCat.isMounted) {
          _shatterAndContinue(combinedCat);
        }
      },
    );

    combinedCat.add(scaleEffect);
    // --- ▲▲▲ ここまでがアニメーションの変更部分 ▲▲▲ ---
  }

  void _shatterAndContinue(Component catToRemove) {
    catToRemove.removeFromParent();
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

    Future.delayed(const Duration(seconds: 2), onStageClear);
  }

  void resetStage() {
    _stage = 0;
  }

  void exitToMenu() {
    onExit();
  }
}

