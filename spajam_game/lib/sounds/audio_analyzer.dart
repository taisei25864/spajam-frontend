import 'dart:typed_data';
import 'dart:math';
import 'package:fftea/fftea.dart';

class AudioAnalyzer {
  final int sampleRate;
  final int fftSize;

  AudioAnalyzer({this.sampleRate = 44100, this.fftSize = 4096});

  /// PCM16のUint8Listデータから最も強い周波数を返す
  double detectFrequency(Uint8List data) {
    final samples = Float64List(data.lengthInBytes ~/ 2);
    final byteData = data.buffer.asByteData();
    for (int i = 0; i < samples.length; i++) {
      final sample = byteData.getInt16(i * 2, Endian.little);
      samples[i] = sample / 32768.0;
    }

    // FFTサイズに合わせてパディング
    Float64List fftSamples;
    if (samples.length < fftSize) {
      fftSamples = Float64List(fftSize)..setAll(0, samples);
    } else {
      fftSamples = samples.sublist(0, fftSize);
    }

    final fft = FFT(fftSize);
    final freq = fft.realFft(fftSamples);

    double maxMagnitude = 0;
    int maxIndex = 0;
    for (int i = 0; i < (fftSize / 2).floor(); i++) {
      final real = freq[i].x;
      final imag = freq[i].y;
      final mag = sqrt(real * real + imag * imag);
      if (mag > maxMagnitude) {
        maxMagnitude = mag;
        maxIndex = i;
      }
    }

    return maxIndex * sampleRate / fftSize;
  }
}