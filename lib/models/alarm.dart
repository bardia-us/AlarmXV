import '../challenges/challenge_type.dart';
import 'wake_check_settings.dart';

class Alarm {
  const Alarm({
    required this.id,
    required this.hour,
    required this.minute,
    required this.weekdays,
    required this.isEnabled,
    this.label = 'Alarm',
    this.challenges = const {ChallengeType.math},
    this.snoozeMinutes = 5,
    this.maxSnoozes = 3,
    this.preventVolumeReduction = true,
    this.alarmSoundUri,
    this.alarmSoundName = 'Default alarm sound',
    this.wakeCheck = const WakeCheckSettings(),
  });

  final String id;
  final String label;
  final int hour;
  final int minute;
  final Set<int> weekdays;
  final bool isEnabled;
  final Set<ChallengeType> challenges;
  final int snoozeMinutes;
  final int maxSnoozes;
  final bool preventVolumeReduction;
  final String? alarmSoundUri;
  final String alarmSoundName;
  final WakeCheckSettings wakeCheck;

  Alarm copyWith({
    String? label,
    int? hour,
    int? minute,
    Set<int>? weekdays,
    bool? isEnabled,
    Set<ChallengeType>? challenges,
    int? snoozeMinutes,
    int? maxSnoozes,
    bool? preventVolumeReduction,
    String? alarmSoundUri,
    String? alarmSoundName,
    WakeCheckSettings? wakeCheck,
  }) {
    return Alarm(
      id: id,
      label: label ?? this.label,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      weekdays: weekdays ?? this.weekdays,
      isEnabled: isEnabled ?? this.isEnabled,
      challenges: challenges ?? this.challenges,
      snoozeMinutes: snoozeMinutes ?? this.snoozeMinutes,
      maxSnoozes: maxSnoozes ?? this.maxSnoozes,
      preventVolumeReduction:
          preventVolumeReduction ?? this.preventVolumeReduction,
      alarmSoundUri: alarmSoundUri ?? this.alarmSoundUri,
      alarmSoundName: alarmSoundName ?? this.alarmSoundName,
      wakeCheck: wakeCheck ?? this.wakeCheck,
    );
  }

  Map<String, Object> toJson() {
    return {
      'id': id,
      'label': label,
      'hour': hour,
      'minute': minute,
      'weekdays': weekdays.toList()..sort(),
      'isEnabled': isEnabled,
      'challenges': challenges.map((item) => item.name).toList(),
      'snoozeMinutes': snoozeMinutes,
      'maxSnoozes': maxSnoozes,
      'preventVolumeReduction': preventVolumeReduction,
      'alarmSoundUri': alarmSoundUri ?? '',
      'alarmSoundName': alarmSoundName,
      'wakeCheck': wakeCheck.toJson(),
    };
  }

  factory Alarm.fromJson(Map<String, dynamic> json) {
    final challengeNames = switch (json['challenges']) {
      final List<dynamic> values => values.cast<String>(),
      _ => <String>[json['challenge'] as String? ?? 'math'],
    };
    final challenges = challengeNames
        .map(
          (name) => ChallengeType.values
              .where((item) => item.name == name)
              .firstOrNull,
        )
        .whereType<ChallengeType>()
        .toSet();

    final soundUri = json['alarmSoundUri'] as String?;
    return Alarm(
      id: json['id'] as String,
      label: (json['label'] as String?)?.trim().isNotEmpty == true
          ? json['label'] as String
          : 'Alarm',
      hour: json['hour'] as int,
      minute: json['minute'] as int,
      weekdays: (json['weekdays'] as List<dynamic>).cast<int>().toSet(),
      isEnabled: json['isEnabled'] as bool,
      challenges: challenges.isEmpty ? {ChallengeType.math} : challenges,
      snoozeMinutes: json['snoozeMinutes'] as int? ?? 5,
      maxSnoozes: json['maxSnoozes'] as int? ?? 3,
      preventVolumeReduction: json['preventVolumeReduction'] as bool? ?? true,
      alarmSoundUri: soundUri?.isNotEmpty == true ? soundUri : null,
      alarmSoundName:
          (json['alarmSoundName'] as String?)?.trim().isNotEmpty == true
          ? json['alarmSoundName'] as String
          : 'Default alarm sound',
      wakeCheck: WakeCheckSettings.fromJson(
        json['wakeCheck'] as Map<String, dynamic>?,
      ),
    );
  }
}
