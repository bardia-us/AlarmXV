import 'package:alarm_xv/challenges/challenge_type.dart';
import 'package:alarm_xv/models/alarm.dart';
import 'package:alarm_xv/models/wake_check_settings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('alarm survives a JSON round trip with scheduling fields', () {
    const alarm = Alarm(
      id: 'alarm-1',
      label: 'Wake up',
      hour: 7,
      minute: 30,
      weekdays: {1, 3, 5},
      isEnabled: true,
      challenges: {ChallengeType.math, ChallengeType.shake},
      snoozeMinutes: 10,
      maxSnoozes: 2,
      preventVolumeReduction: true,
      alarmSoundUri: 'content://media/internal/audio/media/42',
      alarmSoundName: 'Morning bell',
      wakeCheck: WakeCheckSettings(
        enabled: true,
        delayMinutes: 5,
        timeoutSeconds: 60,
        checkCount: 3,
      ),
    );

    final restored = Alarm.fromJson(alarm.toJson());

    expect(restored.id, alarm.id);
    expect(restored.label, alarm.label);
    expect(restored.hour, alarm.hour);
    expect(restored.minute, alarm.minute);
    expect(restored.weekdays, alarm.weekdays);
    expect(restored.isEnabled, isTrue);
    expect(restored.challenges, alarm.challenges);
    expect(restored.snoozeMinutes, 10);
    expect(restored.maxSnoozes, 2);
    expect(restored.preventVolumeReduction, isTrue);
    expect(restored.alarmSoundUri, alarm.alarmSoundUri);
    expect(restored.alarmSoundName, alarm.alarmSoundName);
    expect(restored.wakeCheck.enabled, isTrue);
    expect(restored.wakeCheck.delayMinutes, 5);
    expect(restored.wakeCheck.checkCount, 3);
  });

  test('old version alarms migrate to a safe math challenge', () {
    final restored = Alarm.fromJson({
      'id': 'old-alarm',
      'hour': 6,
      'minute': 0,
      'weekdays': [1, 2, 3, 4, 5],
      'isEnabled': true,
      'challenge': 'none',
    });

    expect(restored.label, 'Alarm');
    expect(restored.challenges, {ChallengeType.math});
    expect(restored.snoozeMinutes, 5);
    expect(restored.maxSnoozes, 3);
    expect(restored.preventVolumeReduction, isTrue);
    expect(restored.wakeCheck.enabled, isFalse);
  });
}
