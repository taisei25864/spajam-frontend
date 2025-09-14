import 'dart:async';
import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/game.dart';
import 'package:flame/particles.dart';
import 'package:flutter/material.dart';

// ユーザー指定のインポートパス
import '../cat_container.dart';
import '../input_bar.dart'; // input_bar.dartのパス
import 'note_frequencies.dart'; // note_frequencies.dartのパス
import '../sounds/audio_input.dart';

enum GameState { playing, stageClear, gameOver }

enum GameState { playing, stageClear, gameOver }

class MyGame extends FlameGame {
  // --- コンポーネント ---
  final List<CatContainer> catContainers = [];
  late final InputBar inputBar;
  late int playerIndex;
  late final RectangleComponent screenFlash;
  late final TextComponent timerText;

  late final TextComponent stageText; // stageTextをクラス変数に
  CatContainer? animatorCat;

  // --- 設定値 ---
  // --- ▼▼▼ 変更点: ステージ表示用のテキストリストを追加 ▼▼▼ ---
  final List<String> stageDisplayNames = ['壱枚目', '弐枚目', '参枚目', '肆枚目', '伍枚目'];
  // --- ▲▲▲ 変更点 ▲▲▲ ---

  // ステージの目標値を音階のインデックスに変更
  final List<List<int>> stageTargetNoteIndices = [
    [0, 4, 7], // ステージ1: C, E, G (ドミソ)
    [2, 5, 9], // ステージ2: D, F, A (レファラ)
    [4, 7, 11], // ステージ3: E, G, B (ミソシ)
    [0, 5, 9], // ステージ4: C, F, A (ドファラ)
    [2, 7, 12], // ステージ5: D, G, C5 (レソ高いド)
  ];

  late List<double> currentTargetValues; // ここには実際の周波数(Hz)が入る
  // 最大入力値を音階の最大周波数に設定
  final double maxInputValue = NoteFrequencies.notes.last.maxHz;
  final double gameDuration = 20.0;
  final double gracePeriod = 5.0;

  final double requiredTimeInRange = 2.0;
  final double stageClearAnimationDuration = 1.5;

  // --- 状態変数 ---
  double _time = 0;
  GameState _gameState = GameState.playing;
  double _timeInRange = 0.0;

  int _stage = 0;
  late String randomColorKey;

  List<double> playerInputs = [0.0, 0.0, 0.0];

  // --- コールバック ---
  final VoidCallback onExit;
  final VoidCallback onStageClear;

  final int stage;


  MyGame({
    required this.stage,
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

    overlays.clear();
    removeAll(children.whereType<Component>());
    catContainers.clear();
    _time = 0;
    _timeInRange = 0;
    _gameState = GameState.playing;


    // ステージの目標周波数を設定
    final targetIndices = stageTargetNoteIndices[_stage % stageTargetNoteIndices.length];
    currentTargetValues = targetIndices.map((index) => NoteFrequencies.notes[index].frequency).toList();


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


    // InputBarに音階名と周波数範囲を渡す
    final playerTargetNoteIndex = targetIndices[playerIndex];
    final playerNote = NoteFrequencies.notes[playerTargetNoteIndex];
    inputBar.setTarget(playerNote.japaneseName, playerNote.frequency, playerNote.minHz, playerNote.maxHz);


    timerText = TextComponent(
      text: 'Time: ${gameDuration.toStringAsFixed(1)}',
      position: Vector2(size.x / 2, 20),
      anchor: Anchor.topCenter,

      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 32,
          fontFamily: 'YujiBoku',
        ),
      ),

      priority: 11,
    );
    await add(timerText);


    // --- ▼▼▼ 変更点: ステージテキストの表示内容を変更 ▼▼▼ ---
    stageText = TextComponent(
      // _stage番号をインデックスとして使い、リストから対応する文字列を取得
      text: stageDisplayNames[_stage],
      position: Vector2(20, 20),
      anchor: Anchor.topLeft,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 32,
          fontFamily: 'YujiBoku',
        ),
      ),
      priority: 11,
    );
    await add(stageText);
    // --- ▲▲▲ 変更点 ▲▲▲ ---

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


    // ステージクリアテストのため、全入力を目標値に固定
    for (var i = 0; i < currentTargetValues.length; i++) {
      updatePlayerInput(i, currentTargetValues[i]);
    }

    for (var i = 0; i < catContainers.length; i++) {
      catContainers[i].updateState(playerInputs[i]);
    }

    inputBar.updateValue(playerInputs[playerIndex]);

    // 現実の周波数範囲に基づいたクリア判定
    bool allPlayersInRange = true;
    final targetIndices = stageTargetNoteIndices[_stage % stageTargetNoteIndices.length];
    for (var i = 0; i < playerInputs.length; i++) {
      final targetNote = NoteFrequencies.notes[targetIndices[i]];
      final inputFrequency = playerInputs[i];

      if (inputFrequency < targetNote.minHz || inputFrequency > targetNote.maxHz) {
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
      final flashOpacity = (sin(_time * pi * 2) + 1) / 2;

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

      textRenderer: TextPaint(style: const TextStyle(fontSize: 48, color: Colors.yellow, fontFamily: 'YujiBoku')),

      priority: 12,
    ));

    if (catContainers.isEmpty) return;


    for (final cat in catContainers) {
      cat.removeFromParent();
    }
    inputBar.removeFromParent();


    final combinedImageFile = combinedCatImages[randomColorKey]!;
    final combinedCat = SpriteComponent(
      sprite: await Sprite.load(combinedImageFile),
      position: size / 2,
      anchor: Anchor.center,
      scale: Vector2.zero(),
    );
    await add(combinedCat);


    final scaleEffect = ScaleEffect.to(
      Vector2.all(3.0),
      EffectController(
        duration: stageClearAnimationDuration,
        curve: Curves.easeOut,
      ),
      onComplete: () {

        if (combinedCat.isMounted) {
          _shatterAndContinue(combinedCat);
        }
      },
    );

    combinedCat.add(scaleEffect);

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

