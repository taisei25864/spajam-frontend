class FrequencyFilter {
  final double minFrequency;
  final double maxFrequency;
  final double maxDelta;
  final List<double> _history = [];

  FrequencyFilter({
    this.minFrequency = 80.0,
    this.maxFrequency = 1500.0,
    this.maxDelta = 200.0,
  });

  /// フィルタリングされた周波数を返す
  double filter(double frequency) {
    double filtered = frequency;

    // 80Hz以下は最小値に置き換え
    if (frequency < minFrequency) {
      filtered = minFrequency;
    }
    // 周波数のしきい値でフィルタリング
    else if (frequency > maxFrequency) {
      filtered = _shortAverage();
    }
    // 急激な変化を検知して短い平均で無効化
    else if (_history.isNotEmpty && (frequency - _history.last).abs() > maxDelta) {
      filtered = _shortAverage();
    }

    // 履歴更新
    _history.add(filtered);
    if (_history.length > 10) _history.removeAt(0);

    return filtered;
  }

  /// 直近3件の平均値（履歴がなければminFrequency）
  double _shortAverage() {
    if (_history.isEmpty) return minFrequency;
    int n = _history.length < 10 ? _history.length : 10;
    return _history.sublist(_history.length - n).reduce((a, b) => a + b) / n;
  }

  /// 履歴をクリア
  void reset() {
    _history.clear();
  }
}