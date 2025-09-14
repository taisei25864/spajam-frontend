// このファイルを lib/game/note_frequencies.dart として新しく作成してください

class Note {
  final String name;
  final double frequency;
  final double minHz;
  final double maxHz;

  const Note(this.name, this.frequency, this.minHz, this.maxHz);
}

class NoteFrequencies {
  static final List<Note> notes = [
    const Note('C4', 261.63, 254.78, 269.41),   // 0: ド
    const Note('C#4', 277.18, 269.41, 285.42),  // 1: ド#
    const Note('D4', 293.66, 285.42, 302.40),   // 2: レ
    const Note('D#4', 311.13, 302.40, 320.38),  // 3: レ#
    const Note('E4', 329.63, 320.38, 339.43),   // 4: ミ
    const Note('F4', 349.23, 339.43, 359.61),   // 5: ファ
    const Note('F#4', 369.99, 359.61, 381.00),  // 6: ファ#
    const Note('G4', 392.00, 381.00, 403.65),   // 7: ソ
    const Note('G#4', 415.30, 403.65, 427.65),  // 8: ソ#
    const Note('A4', 440.00, 427.65, 453.08),   // 9: ラ
    const Note('A#4', 466.16, 453.08, 480.02),  // 10: ラ#
    const Note('B4', 493.88, 480.02, 508.57),   // 11: シ
    const Note('C5', 523.25, 508.57, 537.91),   // 12: 高いド
  ];
}