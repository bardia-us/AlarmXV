import 'dart:convert';

import 'package:alarm_xv/main.dart';
import 'package:alarm_xv/widgets/frosted_surface.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const channel = MethodChannel('alarm_xv/alarm_manager');
  late Map<String, dynamic> settings;
  setUp(() {
    settings = {'themeMode': 'light', 'language': 'fa'};
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          switch (call.method) {
            case 'getAppInfo':
              return {'versionName': 'test', 'lastSeenVersion': 'test'};
            case 'loadAppSettings':
              return jsonEncode(settings);
            case 'saveAppSettings':
              settings =
                  jsonDecode(call.arguments as String) as Map<String, dynamic>;
              return null;
            case 'loadAlarms':
              return jsonEncode([
                {
                  'id': 'a',
                  'hour': 7,
                  'minute': 0,
                  'weekdays': [1, 2, 3, 4, 5],
                  'label': 'صبح من',
                  'isEnabled': true,
                  'challenges': ['math'],
                },
              ]);
            case 'reschedule':
            case 'permissionStatus':
              return {
                'scheduledCount': 1,
                'exactAlarm': true,
                'notifications': true,
                'fullScreen': true,
                'overlay': true,
              };
          }
          return null;
        });
  });
  tearDown(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null),
  );

  for (final dark in [false, true]) {
    testWidgets(
      'settings scrolls behind clipped frosted chrome (${dark ? 'dark' : 'light'})',
      (tester) async {
        settings['themeMode'] = dark ? 'dark' : 'light';
        await tester.pumpWidget(const AlarmXvApp());
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip('تنظیمات'));
        await tester.pumpAndSettle();
        final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).last);
        expect(scaffold.extendBodyBehindAppBar, isTrue);
        final appBar = find.byType(AppBar).last;
        expect(
          find.descendant(of: appBar, matching: find.byType(BackdropFilter)),
          findsOneWidget,
        );
        final list = find.byType(ListView).last;
        final first = tester.getTopLeft(find.text('ظاهر برنامه'));
        final barBottom = tester.getBottomLeft(appBar).dy;
        expect(first.dy, greaterThanOrEqualTo(barBottom));
        await tester.drag(list, Offset(0, -(first.dy - barBottom + 50)));
        await tester.pumpAndSettle();
        expect(
          tester.getTopLeft(find.text('ظاهر برنامه')).dy,
          lessThan(barBottom),
        );
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      },
    );
  }

  testWidgets('settled alarm cards do not crop their rounded outer shadows', (
    tester,
  ) async {
    await tester.pumpWidget(const AlarmXvApp());
    await tester.pumpAndSettle();
    expect(
      find.ancestor(
        of: find.text('صبح من').last,
        matching: find.byType(SizeTransition),
      ),
      findsNothing,
    );
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('sort menu has one frosted panel and closes as a whole', (
    tester,
  ) async {
    await tester.pumpWidget(const AlarmXvApp());
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byTooltip('مرتب‌سازی'));
    await tester.tap(find.byTooltip('مرتب‌سازی'));
    await tester.pumpAndSettle();
    expect(
      find.ancestor(
        of: find.text('نام زنگ'),
        matching: find.byType(BackdropFilter),
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('نام زنگ'));
    await tester.pumpAndSettle();
    expect(find.text('نام زنگ'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('system language resolves English/Persian with matching layout', (
    tester,
  ) async {
    settings.remove('language');
    for (final language in ['en', 'fa']) {
      tester.platformDispatcher.localesTestValue = [Locale(language)];
      await tester.pumpWidget(AlarmXvApp(key: ValueKey(language)));
      await tester.pumpAndSettle();
      final label = find.text(language == 'fa' ? 'زنگ‌های من' : 'My alarms');
      expect(label, findsOneWidget);
      expect(
        Directionality.of(tester.element(label)),
        language == 'fa' ? TextDirection.rtl : TextDirection.ltr,
      );
      await tester.pumpWidget(const SizedBox());
    }
    tester.platformDispatcher.clearLocalesTestValue();
  });

  testWidgets('language override persists and can return to the system', (
    tester,
  ) async {
    tester.platformDispatcher.localesTestValue = const [Locale('fa')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    await tester.pumpWidget(const AlarmXvApp());
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('تنظیمات'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('زبان برنامه'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();
    expect(settings['language'], 'en');
    expect(find.text('Settings'), findsOneWidget);
    await tester.tap(find.text('App language'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Automatic (system)'));
    await tester.pumpAndSettle();
    expect(settings['language'], 'system');
    expect(find.text('تنظیمات'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('back button stretches on press and returns to Home', (
    tester,
  ) async {
    await tester.pumpWidget(const AlarmXvApp());
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('تنظیمات'));
    await tester.pumpAndSettle();
    final back = find.byType(ElasticBackButton);
    final transforms = find.descendant(
      of: back,
      matching: find.byType(Transform),
    );
    final before = tester
        .widget<Transform>(transforms.first)
        .transform
        .storage
        .toList();
    final gesture = await tester.startGesture(tester.getCenter(back));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
    expect(
      tester.widget<Transform>(transforms.first).transform.storage.toList(),
      isNot(before),
    );
    await gesture.up();
    await tester.pumpAndSettle();
    expect(find.text('زنگ‌های من'), findsOneWidget);
    expect(find.byType(ElasticBackButton), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });
}
