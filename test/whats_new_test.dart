import 'package:alarm_xv/widgets/app_info_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('alarm_xv/alarm_manager');

  testWidgets(
    'release notes appear once per installed version, then again on upgrade',
    (tester) async {
      var installed = '2.0.0-preview.1';
      var seen = '1.2.0';
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            if (call.method == 'getAppInfo')
              return {
                'versionName': installed,
                'supportedAbis': ['arm64-v8a'],
                'lastSeenVersion': seen,
              };
            if (call.method == 'markWhatsNewSeen')
              seen = call.arguments as String;
            return null;
          });
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => WhatsNewSheet.showIfNeeded(context),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.text('تازه‌های AlarmXV'), findsOneWidget);
      await tester.ensureVisible(find.text('بریم سراغش'));
      await tester.tap(find.text('بریم سراغش'));
      await tester.pumpAndSettle();
      expect(seen, '2.0.0-preview.1');
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.text('تازه‌های AlarmXV'), findsNothing);
      installed = '2.0.0-preview.2';
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.text('تازه‌های AlarmXV'), findsOneWidget);
    },
  );
}
