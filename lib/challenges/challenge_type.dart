enum ChallengeType { math, memory, shake }

extension ChallengeTypeLabel on ChallengeType {
  String get label => switch (this) {
    ChallengeType.math => 'Math',
    ChallengeType.memory => 'Memory',
    ChallengeType.shake => 'Shake',
  };
}
