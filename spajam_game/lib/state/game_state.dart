import 'dart:async';
import 'package:flutter/material.dart';

class PlayerInfo {
  final String id;
  final String name;
  PlayerInfo(this.id, this.name);
}

class GameState extends ChangeNotifier {
  String roomId = '';
  String userName = '';
  List<PlayerInfo> players = [];
  bool gameStarted = false;
  int wallIndex = 1; // 1〜3
  final int wallMax = 3;

  // ダミー: 各プレイヤーのゲージ値(0~1)
  final Map<String, double> pitchValues = {};
  Timer? _dummyTimer;

  bool combining = false;
  bool doorOpening = false;
  double doorOpenProgress = 0.0; // 0(閉)→1(開)
  Timer? _doorTimer;

  void setRoomId(String v) {
    roomId = v;
    notifyListeners();
  }

  void setUserName(String v) {
    userName = v;
    notifyListeners();
  }

  bool get canEnterRoom => roomId.isNotEmpty && userName.isNotEmpty;

  void enterRoom() {
    if (!canEnterRoom) return;
    // 自分＋ダミー2人
    players = [
      PlayerInfo('self', userName),
      PlayerInfo('p2', 'ねこA'),
      PlayerInfo('p3', 'ねこB'),
    ];
    for (final p in players) {
      pitchValues[p.id] = 0.5;
    }
    notifyListeners();
  }

  void leaveRoom() {
    players = [];
    notifyListeners();
  }

  void resetAll() {
    roomId = '';
    userName = '';
    players = [];
    gameStarted = false;
    wallIndex = 1;
    combining = false;
    doorOpening = false;
    doorOpenProgress = 0;
    _dummyTimer?.cancel();
    notifyListeners();
  }

  void startGame() {
    gameStarted = true;
    wallIndex = 1;
    _startDummyLoop();
    notifyListeners();
  }

  void _startDummyLoop() {
    _dummyTimer?.cancel();
    _dummyTimer = Timer.periodic(const Duration(milliseconds: 480), (_) {
      pitchValues.updateAll((key, value) {
        final noise = (DateTime.now().microsecond % 1000) / 1000.0;
        final target = 0.45 + 0.1 * noise; // 中央寄り
        return (value + (target - value) * 0.5).clamp(0.0, 1.0);
      });
      notifyListeners();
    });
  }

  void triggerCombine() {
    if (combining) return;
    combining = true;
    notifyListeners();
    Future.delayed(const Duration(milliseconds: 900), () {
      combining = false;
      _openDoor();
    });
  }

  void _openDoor() {
    doorOpening = true;
    doorOpenProgress = 0;
    _doorTimer?.cancel();
    _doorTimer = Timer.periodic(const Duration(milliseconds: 30), (t) {
      doorOpenProgress += 0.05;
      if (doorOpenProgress >= 1) {
        doorOpenProgress = 1;
        t.cancel();
        Future.delayed(const Duration(milliseconds: 400), () {
          _advanceWall();
        });
      }
      notifyListeners();
    });
  }

  void _advanceWall() {
    doorOpening = false;
    doorOpenProgress = 0;
    if (wallIndex < wallMax) {
      wallIndex++;
    } else {
      endGame();
    }
    notifyListeners();
  }

  void completeWall() {
    // ここでは combine 演出を開始
    triggerCombine();
  }

  void endGame() {
    _dummyTimer?.cancel();
    gameStarted = false;
    notifyListeners();
  }

  void resetToMenu() {
    _dummyTimer?.cancel();
    players = [];
    gameStarted = false;
    wallIndex = 1;
    combining = false;
    doorOpening = false;
    doorOpenProgress = 0;
    notifyListeners();
  }
}