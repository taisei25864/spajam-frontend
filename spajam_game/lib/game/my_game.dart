import 'dart:async';
import 'dart:math';
import 'dart:typed_data'; // エラー解決のため、正しいUint8Listをインポート
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/game.dart';
import 'package:flame/particles.dart';
import 'package:flutter/material.dart';

// ユーザー指定のインポートパス
import '../cat_container.dart';
import '../input_bar.dart';
import 'note_frequencies.dart';
import '../sounds/audio_input.dart';
import '../sounds/audio_analyzer.dart';
import '../sounds/frequency_filter.dart';

enum GameState { playing, stageClear, gameOver }

class MyGame extends FlameGame {
  // --- コンポーネント ---
  final List<CatContainer> catContainers = [];
  late final InputBar inputBar;
  late int playerIndex;
  late final RectangleComponent screenFlash;
  late final TextComponent timerText;
  late final TextComponent stageText;
  CatContainer? animatorCat;
  // --- ▼▼▼ 変更点: デバッグ用テキストを追加 ▼▼▼ ---
  late final TextComponent _debugFrequencyText;
  // --- ▲▲▲ 変更点 ▲▲▲ ---

  // --- 音声処理関連 ---
  final AudioInput _audioInput = AudioInput();
  final AudioAnalyzer _analyzer = AudioAnalyzer();
  final FrequencyFilter _filter = FrequencyFilter();
  StreamSubscription<Uint8List>? _streamSubscription;
  double _currentFrequency = 0.0;

  // --- 設定値 ---
  final List<String> stageDisplayNames = ['壱枚目', '弐枚目', '参枚目', '肆枚目', '伍枚目'];

  final List<List<int>> stageTargetNoteIndices = [
    [0, 4, 7], // ステージ1: C, E, G (ドミソ)
    [2, 5, 9], // ステージ2: D, F, A (レファラ)
    [4, 7, 11], // ステージ3: E, G, B (ミソシ)
    [0, 5, 9], // ステージ4: C, F, A (ドファラ)
    [2, 7, 12], // ステージ5: D, G, C5 (レソ高いド)
  ];

  late List<double> currentTargetValues;
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

  // --- アセット定義 ---
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
    // 最初にUIなどの視覚要素を初期化
    await initializeStage();
    // 次に音声入力の準備を開始
    await _startAudioProcessing();
  }

  @override
  void onRemove() {
    // ゲーム終了時に必ずストリームを停止してリソースを解放
    _streamSubscription?.cancel();
    super.onRemove();
  }

  /// 音声処理を開始するメソッド
  Future<void> _startAudioProcessing() async {
    try {
      await _audioInput.checkPermission();
      // AudioInputのstartメソッドがStreamを返すことを想定
      final audioStream = await _audioInput.start(sampleRate: 44100, numChannels: 1);

      // audioStreamがnullでないことを確認してからlistenする
      if (audioStream != null) {
        _streamSubscription = audioStream.listen((data) {
          // マイクからの音声データをリアルタイムで処理
          final rawFrequency = _analyzer.detectFrequency(data);
          _currentFrequency = _filter.filter(rawFrequency);
        }, onError: (err) {
          debugPrint("Audio Stream Error: $err");
        });
      } else {
        debugPrint("Audio stream is null. Could not start listening.");
      }
    } catch (e) {
      debugPrint("Could not start audio processing: $e");
    }
  }


  Future<void> initializeStage() async {
    _stage = stage;
    overlays.clear();
    removeAll(children.whereType<Component>());
    catContainers.clear();
    _time = 0;
    _timeInRange = 0;
    _gameState = GameState.playing;

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

    final playerTargetNoteIndex = targetIndices[playerIndex];
    final playerNote = NoteFrequencies.notes[playerTargetNoteIndex];
    inputBar.setTarget(playerNote.japaneseName, playerNote.frequency, playerNote.minHz, playerNote.maxHz);

    final norenSprite = await Sprite.load('norenn.png');
    const norenColor = Color(0xFF4B3A2F); // 暖簾に合うように濃い茶色に戻す

    // 1. ステージ表示
    final stageNoren = SpriteComponent(
      sprite: norenSprite,
      size: Vector2(200, 70),
      position: Vector2(10, 10),
      anchor: Anchor.topLeft,
      priority: 11,
    );
    stageText = TextComponent(
      text: stageDisplayNames[_stage],
      position: stageNoren.size / 2,
      anchor: Anchor.center,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: norenColor,
          fontSize: 28,
          fontFamily: 'YujiBoku',
        ),
      ),
    );
    stageNoren.add(stageText);
    await add(stageNoren);

    // 2. 時間表示
    final timeNoren = SpriteComponent(
      sprite: norenSprite,
      size: Vector2(180, 70),
      position: Vector2(size.x / 2, 10),
      anchor: Anchor.topCenter,
      priority: 11,
    );
    timerText = TextComponent(
      text: '時: ${gameDuration.toStringAsFixed(1)}',
      position: timeNoren.size / 2,
      anchor: Anchor.center,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: norenColor,
          fontSize: 28,
          fontFamily: 'YujiBoku',
        ),
      ),
    );
    timeNoren.add(timerText);
    await add(timeNoren);

    // --- ▼▼▼ 変更点: デバッグ用テキストを初期化して追加 ▼▼▼ ---
    _debugFrequencyText = TextComponent(
      text: 'Freq: 0.0 Hz',
      position: Vector2(10, size.y - 30),
      anchor: Anchor.bottomLeft,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          backgroundColor: Colors.black54,
        ),
      ),
      priority: 20, // 他のUIより手前に表示
    );
    await add(_debugFrequencyText);
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
    timerText.text = '時: ${remainingTime.toStringAsFixed(1)}';

    if (catContainers.isEmpty) return;

    // --- ▼▼▼ 変更点: デバッグ用テキストを更新 ▼▼▼ ---
    _debugFrequencyText.text = 'Freq: ${_currentFrequency.toStringAsFixed(2)} Hz';
    // --- ▲▲▲ 変更点 ▲▲▲ ---

    // --- 実際の音声入力でプレイヤーを操作 ---
    final currentInput = playerInputs[playerIndex];
    final targetFrequency = _currentFrequency;
    final smoothedInput = currentInput + (targetFrequency - currentInput) * 0.1;
    updatePlayerInput(playerIndex, smoothedInput);

    // 他のプレイヤー(NPC)は、テストのため目標値に固定
    for (var i = 0; i < currentTargetValues.length; i++) {
      if (i != playerIndex) {
        updatePlayerInput(i, currentTargetValues[i]);
      }
    }

    for (var i = 0; i < catContainers.length; i++) {
      catContainers[i].updateState(playerInputs[i]);
    }

    inputBar.updateValue(playerInputs[playerIndex]);

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
      text: 'CLEAR!',
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

