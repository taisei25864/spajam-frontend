import 'dart:collection';

/// 検出された周波数のノイズを除去し、安定させるためのフィルタークラス
class FrequencyFilter {
  // --- 移動平均フィルタ用の設定 ---
  final int _windowSize = 5; // 過去5回分のデータを平均化する
  final Queue<double> _frequencyHistory = Queue<double>();

  // --- 安定性カウンター用の設定 ---
  final int _stabilityThreshold = 3; // 3回連続で安定したら更新
  final double _pitchTolerance = 10.0; // 10Hz以内の変動は「同じ音」と見なす
  double _stableFrequency = 0.0;
  double _lastDetectedFrequency = 0.0;
  int _stabilityCounter = 0;

  // --- ▼▼▼ ここからが今回の修正の核心 ▼▼▼ ---
  /// この周波数以下の入力はノイズと見なして無視する
  final double _minimumFrequencyThreshold = 150.0; // 150Hz
  // --- ▲▲▲ 修正の核心 ▲▲▲ ---

  /// 生の周波数データを受け取り、フィルタリングして安定した周波数を返す
  double filter(double rawFrequency) {
    // 1. 最低周波数チェック：80Hzのような低周波ノイズをここで除去する
    if (rawFrequency < _minimumFrequencyThreshold) {
      rawFrequency = 0.0; // ノイズは無音(0Hz)として扱う
    }

    // 2. 移動平均フィルタを適用して、周波数の揺らぎを滑らかにする
    final smoothedFrequency = _applyMovingAverage(rawFrequency);

    // 3. 安定性カウンターを適用して、偶発的なノイズを除去する
    return _applyStabilityCheck(smoothedFrequency);
  }

  /// 移動平均フィルタを適用する内部メソッド
  double _applyMovingAverage(double newFrequency) {
    _frequencyHistory.addLast(newFrequency);
    if (_frequencyHistory.length > _windowSize) {
      _frequencyHistory.removeFirst();
    }

    if (_frequencyHistory.isEmpty) {
      return 0.0;
    }

    final sum = _frequencyHistory.reduce((a, b) => a + b);
    return sum / _frequencyHistory.length;
  }

  /// 安定性カウンターを適用する内部メソッド
  double _applyStabilityCheck(double currentFrequency) {
    // 声が検出されなかった場合 (0Hz)、すべての状態をリセットしてゲージを落とす
    if (currentFrequency == 0.0) {
      _stabilityCounter = 0;
      _lastDetectedFrequency = 0.0;
      _stableFrequency = 0.0;
      return _stableFrequency;
    }

    // 声が検出された場合、前回の周波数と比較
    if ((currentFrequency - _lastDetectedFrequency).abs() < _pitchTolerance) {
      _stabilityCounter++; // 近ければカウンターを増やす
    } else {
      _stabilityCounter = 0; // 遠ければリセット
    }

    _lastDetectedFrequency = currentFrequency;

    // カウンターが閾値を超えたら、その周波数を「安定した周波数」として採用する
    if (_stabilityCounter >= _stabilityThreshold) {
      _stableFrequency = currentFrequency;
    }

    // 安定していない間は、最後に安定した周波数を返すことで、ゲージの急な落下を防ぐ
    return _stableFrequency;
  }
}

