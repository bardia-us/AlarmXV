/// Missing configuration migrates v1.2; partial v2 fields use safe v2 defaults.
class MissionSettings {
  const MissionSettings({
    this.mathDifficulty = 'medium',
    this.mathQuestions = 3,
    this.mathOperations = const {'add', 'subtract'},
    this.mathMaxOperand = 90,
    this.memoryGridSize = 3,
    this.memoryTargets = 3,
    this.memoryRounds = 1,
    this.shakeCount = 12,
    this.shakeThreshold = 2.4,
    this.typingPhrase = 'I am awake and ready',
    this.numberCount = 6,
  });

  final String mathDifficulty;
  final int mathQuestions;
  final Set<String> mathOperations;
  final int mathMaxOperand;
  final int memoryGridSize;
  final int memoryTargets;
  final int memoryRounds;
  final int shakeCount;
  final double shakeThreshold;
  final String typingPhrase;
  final int numberCount;

  MissionSettings copyWith({
    String? mathDifficulty,
    int? mathQuestions,
    Set<String>? mathOperations,
    int? mathMaxOperand,
    int? memoryGridSize,
    int? memoryTargets,
    int? memoryRounds,
    int? shakeCount,
    double? shakeThreshold,
    String? typingPhrase,
    int? numberCount,
  }) => MissionSettings.fromJson({
    ...toJson(),
    if (mathDifficulty != null) 'mathDifficulty': mathDifficulty,
    if (mathQuestions != null) 'mathQuestions': mathQuestions,
    if (mathOperations != null) 'mathOperations': mathOperations.toList(),
    if (mathMaxOperand != null) 'mathMaxOperand': mathMaxOperand,
    if (memoryGridSize != null) 'memoryGridSize': memoryGridSize,
    if (memoryTargets != null) 'memoryTargets': memoryTargets,
    if (memoryRounds != null) 'memoryRounds': memoryRounds,
    if (shakeCount != null) 'shakeCount': shakeCount,
    if (shakeThreshold != null) 'shakeThreshold': shakeThreshold,
    if (typingPhrase != null) 'typingPhrase': typingPhrase,
    if (numberCount != null) 'numberCount': numberCount,
  });

  Map<String, Object> toJson() => {
    'mathDifficulty': mathDifficulty,
    'mathQuestions': mathQuestions,
    'mathOperations': mathOperations.toList(),
    'mathMaxOperand': mathMaxOperand,
    'memoryGridSize': memoryGridSize,
    'memoryTargets': memoryTargets,
    'memoryRounds': memoryRounds,
    'shakeCount': shakeCount,
    'shakeThreshold': shakeThreshold,
    'typingPhrase': typingPhrase,
    'numberCount': numberCount,
  };

  factory MissionSettings.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const MissionSettings(
        memoryGridSize: 4,
        memoryTargets: 5,
        shakeCount: 10,
      );
    }
    int bounded(String key, int fallback, int low, int high) =>
        ((json[key] as num?)?.toInt() ?? fallback).clamp(low, high);
    final difficulty = json['mathDifficulty'] as String? ?? 'medium';
    final grid = bounded('memoryGridSize', 3, 3, 5);
    final operations =
        (json['mathOperations'] as List<dynamic>? ?? ['add', 'subtract'])
            .whereType<String>()
            .where({'add', 'subtract', 'multiply', 'divide'}.contains)
            .toSet();
    final phrase = (json['typingPhrase'] as String? ?? '').trim();
    final threshold = (json['shakeThreshold'] as num?)?.toDouble() ?? 2.4;
    return MissionSettings(
      mathDifficulty: {'easy', 'medium', 'hard', 'custom'}.contains(difficulty)
          ? difficulty
          : 'medium',
      mathQuestions: bounded('mathQuestions', 3, 1, 20),
      mathOperations: Set.unmodifiable(
        operations.isEmpty ? {'add', 'subtract'} : operations,
      ),
      mathMaxOperand: bounded('mathMaxOperand', 90, 5, 999),
      memoryGridSize: grid,
      memoryTargets: bounded('memoryTargets', 3, 1, grid * grid - 1),
      memoryRounds: bounded('memoryRounds', 1, 1, 10),
      shakeCount: bounded('shakeCount', 12, 3, 100),
      shakeThreshold: threshold.isFinite ? threshold.clamp(1.5, 4.0) : 2.4,
      typingPhrase: phrase.isEmpty
          ? 'I am awake and ready'
          : phrase.substring(0, phrase.length.clamp(0, 120)),
      numberCount: bounded('numberCount', 6, 4, 12),
    );
  }
}
