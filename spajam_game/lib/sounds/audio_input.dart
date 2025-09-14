import 'dart:async';
import 'dart:typed_data';
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';

/// 音声入力（録音）を管理するクラス
class AudioInput {
  /// 録音処理を行うインスタンス
  final AudioRecorder _audioRecorder = AudioRecorder();

  /// 音声ストリームの購読管理用
  StreamSubscription<Uint8List>? _audioStreamSubscription;

  /// マイクの権限を要求し、許可されているか返す
  Future<bool> checkPermission() async {
    final status = await Permission.microphone.request();
    return status == PermissionStatus.granted;
  }

  /// 録音の権限があるか確認する
  Future<bool> hasPermission() async {
    return await _audioRecorder.hasPermission();
  }

  /// 録音を開始し、音声データのストリームを返す
  /// [sampleRate] サンプリングレート（デフォルト: 44100Hz）→和音などで利用するなら44100以上が望ましい
  /// [numChannels] チャンネル数（デフォルト: 1）→モノラルなら1、ステレオなら2 基本的に1で良い
  Future<Stream<Uint8List>?> start({int sampleRate = 44100, int numChannels = 1}) async {
    if (!await hasPermission()) return null;
    return await _audioRecorder.startStream(
      RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: sampleRate,
        numChannels: numChannels,
      ),
    );
  }

  /// 録音を停止し、ストリームの購読も解除する
  Future<void> stop() async {
    if (await _audioRecorder.isRecording()) {
      await _audioRecorder.stop();
    }
    await _audioStreamSubscription?.cancel();
  }

  /// リソースを解放する
  void dispose() {
    _audioRecorder.dispose();
  }
}