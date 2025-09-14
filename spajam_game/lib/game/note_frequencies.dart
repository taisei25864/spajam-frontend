class Note {
  final String name; // C4, D4 etc.
  final String japaneseName; // ド, レ etc.
  final double frequency;
  final double minHz;
  final double maxHz;

  const Note(this.name, this.japaneseName, this.frequency, this.minHz, this.maxHz);
}

/// C4からC5までの13音階の周波数と、それぞれの許容範囲を定義したクラス。
class NoteFrequencies {
  static final List<Note> notes = [
    const Note('C4', 'ド', 261.63, 254.78, 269.41),   // 0
    const Note('C#4', 'ド#', 277.18, 269.41, 285.42),  // 1
    const Note('D4', 'レ', 293.66, 285.42, 302.40),   // 2
    const Note('D#4', 'レ#', 311.13, 302.40, 320.38),  // 3
    const Note('E4', 'ミ', 329.63, 320.38, 339.43),   // 4
    const Note('F4', 'ファ', 349.23, 339.43, 359.61),   // 5
    const Note('F#4', 'ファ#', 369.99, 359.61, 381.00),  // 6
    const Note('G4', 'ソ', 392.00, 381.00, 403.65),   // 7
    const Note('G#4', 'ソ#', 415.30, 403.65, 427.65),  // 8
    const Note('A4', 'ラ', 440.00, 427.65, 453.08),   // 9
    const Note('A#4', 'ラ#', 466.16, 453.08, 480.02),  // 10
    const Note('B4', 'シ', 493.88, 480.02, 508.57),   // 11
    const Note('C5', 'ド', 523.25, 508.57, 537.91),   // 12 (高いド)
  ];
}

