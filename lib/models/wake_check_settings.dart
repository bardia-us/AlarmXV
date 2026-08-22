enum WakeCheckTransition { scheduleNext, complete, restartAlarm }

class WakeCheckSettings {
  const WakeCheckSettings({
    this.enabled = false,
    this.delayMinutes = 3,
    this.timeoutSeconds = 60,
    this.checkCount = 1,
  });

  final bool enabled;
  final int delayMinutes;
  final int timeoutSeconds;
  final int checkCount;

  DateTime nextCheckAt(DateTime confirmedOrDismissedAt) {
    return confirmedOrDismissedAt.add(Duration(minutes: delayMinutes));
  }

  bool hasNextCheck(int completedChecks) =>
      enabled && completedChecks < checkCount;

  bool confirmationTimedOut(DateTime now, DateTime deadline) {
    return !now.isBefore(deadline);
  }

  WakeCheckTransition afterConfirmation(int confirmedCheckNumber) {
    return confirmedCheckNumber < checkCount
        ? WakeCheckTransition.scheduleNext
        : WakeCheckTransition.complete;
  }

  WakeCheckTransition afterTimeout() => WakeCheckTransition.restartAlarm;

  Map<String, Object> toJson() => {
    'enabled': enabled,
    'delayMinutes': delayMinutes,
    'timeoutSeconds': timeoutSeconds,
    'checkCount': checkCount,
  };

  factory WakeCheckSettings.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const WakeCheckSettings();
    return WakeCheckSettings(
      enabled: json['enabled'] as bool? ?? false,
      delayMinutes: json['delayMinutes'] as int? ?? 3,
      timeoutSeconds: json['timeoutSeconds'] as int? ?? 60,
      checkCount: json['checkCount'] as int? ?? 1,
    );
  }
}
