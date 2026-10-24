import 'package:alarm_xv/challenges/challenge_type.dart';
import 'package:alarm_xv/models/alarm.dart';
import 'package:alarm_xv/models/alarm_group.dart';
import 'package:alarm_xv/models/app_settings.dart';
import 'package:alarm_xv/models/mission_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Map<String, dynamic> legacy() => {
    'id': 'v12', 'hour': 7, 'minute': 30, 'weekdays': [1, 5],
    'isEnabled': true, 'alarmSoundUri': 'content://alarm/42',
    'wakeCheck': {'enabled': true, 'checkCount': 1, 'delayMinutes': 3},
  };

  test('legacy alarms migrate without changing scheduling or sound', () {
    final alarm = Alarm.fromJson(legacy());
    expect(alarm.id, 'v12');
    expect(alarm.groupId, isNull);
    expect(alarm.missionSettings.mathQuestions, 3);
    expect(alarm.alarmSoundUri, 'content://alarm/42');
    expect(alarm.wakeCheck.checkCount, 1);
    expect(alarm.nextOccurrence(DateTime(2026, 10, 26, 7, 29)),
        DateTime(2026, 10, 26, 7, 30));
  });

  test('extended alarm settings and ordered missions round trip', () {
    final alarm = Alarm.fromJson(legacy()).copyWith(
      groupId: 'work',
      challenges: {ChallengeType.typing, ChallengeType.math, ChallengeType.order},
      missionSettings: const MissionSettings(
        mathDifficulty: 'custom', mathOperations: {'multiply', 'divide'},
        mathQuestions: 8, memoryRounds: 3, shakeCount: 24,
        typingPhrase: 'صبح بخیر', numberCount: 8,
      ),
    );
    final restored = Alarm.fromJson(alarm.toJson());
    expect(restored.groupId, 'work');
    expect(restored.challenges.toList(), alarm.challenges.toList());
    expect(restored.missionSettings.toJson(), alarm.missionSettings.toJson());
    expect(restored.copyWith(clearGroup: true).groupId, isNull);
    expect(restored.copyWith(id: 'copy').id, 'copy');
    expect(restored.id, 'v12');
  });

  test('next occurrence rolls across week and excludes past minute', () {
    final alarm = Alarm.fromJson(legacy());
    expect(alarm.nextOccurrence(DateTime(2026, 10, 26, 7, 30)),
        DateTime(2026, 10, 30, 7, 30));
    expect(alarm.copyWith(isEnabled: false).nextOccurrence(DateTime.now()), isNull);
    expect(alarm.copyWith(weekdays: {}).nextOccurrence(DateTime.now()), isNull);
    expect(alarm.nextOccurrence(DateTime(2026, 10, 30, 8)),
        DateTime(2026, 11, 2, 7, 30));
  });

  test('malformed mission limits normalize to solvable values', () {
    final settings = MissionSettings.fromJson({
      'mathQuestions': 100, 'mathOperations': ['unknown'],
      'memoryGridSize': 3, 'memoryTargets': 900, 'memoryRounds': -1,
      'shakeThreshold': 0.0, 'typingPhrase': ' ', 'numberCount': 900,
    });
    expect(settings.mathQuestions, 20);
    expect(settings.mathOperations, {'add', 'subtract'});
    expect(settings.memoryTargets, 8);
    expect(settings.memoryRounds, 1);
    expect(settings.shakeThreshold, 1.5);
    expect(settings.typingPhrase.trim(), isNotEmpty);
    expect(settings.numberCount, 12);
  });

  test('settings persist theme and groups with safe legacy defaults', () {
    const settings = AppSettings(
      themeMode: ThemeMode.light, accent: AccentPalette.emerald,
      groups: [AlarmGroup(id: 'school', name: 'مدرسه', color: 0xff12ab89,
        icon: 'school', sortOrder: 2)],
      defaultSnoozeMinutes: 10,
    );
    final restored = AppSettings.fromJson(settings.toJson());
    expect(restored.toJson(), settings.toJson());
    expect(AppSettings.fromJson({}).themeMode, ThemeMode.system);
    expect(AppSettings.fromJson({'accent': 'missing'}).accent, AccentPalette.ocean);
    expect(restored.groups.single.name, 'مدرسه');
  });
}
