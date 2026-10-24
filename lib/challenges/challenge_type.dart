enum ChallengeType { math, memory, shake, typing, order }

extension ChallengeTypeLabel on ChallengeType {
  String get label => switch (this) {
    ChallengeType.math => 'Math',
    ChallengeType.memory => 'Memory',
    ChallengeType.shake => 'Shake',
    ChallengeType.typing => 'Typing',
    ChallengeType.order => 'Number order',
  };
}
