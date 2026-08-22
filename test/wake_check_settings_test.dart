import 'package:alarm_xv/models/wake_check_settings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const settings = WakeCheckSettings(
    enabled: true,
    delayMinutes: 3,
    timeoutSeconds: 60,
    checkCount: 3,
  );

  test('next wake check is measured from the latest confirmation', () {
    final dismissedAt = DateTime.utc(2026, 8, 22, 7, 2);
    final first = settings.nextCheckAt(dismissedAt);
    final second = settings.nextCheckAt(first);

    expect(first, DateTime.utc(2026, 8, 22, 7, 5));
    expect(second, DateTime.utc(2026, 8, 22, 7, 8));
    expect(settings.hasNextCheck(0), isTrue);
    expect(settings.hasNextCheck(2), isTrue);
    expect(settings.hasNextCheck(3), isFalse);
    expect(settings.afterConfirmation(1), WakeCheckTransition.scheduleNext);
    expect(settings.afterConfirmation(3), WakeCheckTransition.complete);
  });

  test('timeout boundary restarts the real alarm', () {
    final shownAt = DateTime.utc(2026, 8, 22, 7, 5);
    final deadline = shownAt.add(const Duration(seconds: 60));

    expect(
      settings.confirmationTimedOut(
        deadline.subtract(const Duration(milliseconds: 1)),
        deadline,
      ),
      isFalse,
    );
    expect(settings.confirmationTimedOut(deadline, deadline), isTrue);
    expect(settings.afterTimeout(), WakeCheckTransition.restartAlarm);
  });
}
