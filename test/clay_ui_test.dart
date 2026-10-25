import 'dart:convert';

import 'package:alarm_xv/main.dart';
import 'package:alarm_xv/challenges/challenge_type.dart';
import 'package:alarm_xv/models/alarm.dart';
import 'package:alarm_xv/models/alarm_group.dart';
import 'package:alarm_xv/models/app_settings.dart';
import 'package:alarm_xv/theme/clay_theme.dart';
import 'package:alarm_xv/widgets/alarm_editor_sheet.dart';
import 'package:alarm_xv/widgets/clay_components.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('alarm_xv/alarm_manager');
  late List<dynamic> alarms;
  late Map<String, dynamic> settings;
  var failSave = false;
  var failSettingsSave = false;
  var failScheduling = false;
  const permissions = {
    'scheduledCount': 1,
    'exactAlarm': true,
    'notifications': true,
    'fullScreen': true,
    'overlay': true,
  };

  setUp(() {
    alarms = [
      {
        'id': 'legacy',
        'label': 'صبح زود',
        'hour': 7,
        'minute': 30,
        'weekdays': [1, 2, 3, 4, 5],
        'isEnabled': true,
        'challenge': 'math',
      },
    ];
    settings = {};
    failSave = false;
    failSettingsSave = false;
    failScheduling = false;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          switch (call.method) {
            case 'getAppInfo':
              return {
                'versionName': '2.0.0-preview.1',
                'lastSeenVersion': '2.0.0-preview.1',
                'supportedAbis': ['arm64-v8a'],
              };
            case 'loadAlarms':
              return jsonEncode(alarms);
            case 'loadAppSettings':
              return jsonEncode(settings);
            case 'saveAppSettings':
              if (failSettingsSave)
                throw PlatformException(code: 'settings', message: 'ذخیره نشد');
              settings =
                  jsonDecode(call.arguments as String) as Map<String, dynamic>;
              return null;
            case 'saveAndSync':
              if (failSave) {
                throw PlatformException(code: 'save', message: 'ذخیره نشد');
              }
              alarms = jsonDecode(call.arguments as String) as List<dynamic>;
              if (failScheduling)
                return {
                  ...permissions,
                  'saved': true,
                  'scheduledCount': 0,
                  'scheduleError': 'schedule_failed',
                };
              return permissions;
            case 'reschedule':
            case 'permissionStatus':
              return permissions;
          }
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  testWidgets('legacy alarm renders and duplicate keeps mission settings', (
    tester,
  ) async {
    await tester.pumpWidget(const AlarmXvApp());
    await tester.pumpAndSettle();
    expect(find.text('07:30'), findsWidgets);
    expect(find.text('صبح زود'), findsWidgets);
    await tester.scrollUntilVisible(
      find.byTooltip('گزینه‌های صبح زود'),
      180,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('گزینه‌های صبح زود'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ساخت کپی'));
    await tester.pumpAndSettle();
    expect(alarms, hasLength(2));
    expect(alarms.last['id'], isNot('legacy'));
    expect(alarms.last['weekdays'], [1, 2, 3, 4, 5]);
    expect(alarms.last['missionSettings'], isNotNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('native save failure keeps enabled state', (tester) async {
    await tester.pumpWidget(const AlarmXvApp());
    await tester.pumpAndSettle();
    failSave = true;
    await tester.scrollUntilVisible(
      find.byType(Switch),
      180,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Switch).first);
    await tester.pumpAndSettle();
    expect(tester.widget<Switch>(find.byType(Switch).first).value, isTrue);
    expect(alarms.single['isEnabled'], isTrue);
    expect(find.textContaining('ذخیره نشد'), findsWidgets);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'persisted save with failed scheduling publishes saved state and warning',
    (tester) async {
      alarms.single['isEnabled'] = false;
      await tester.pumpWidget(const AlarmXvApp());
      await tester.pumpAndSettle();
      failScheduling = true;
      await tester.scrollUntilVisible(
        find.byType(Switch),
        180,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      expect(alarms.single['isEnabled'], isTrue);
      expect(tester.widget<Switch>(find.byType(Switch)).value, isTrue);
      expect(find.textContaining('زمان‌بندی کامل نشد'), findsWidgets);
      expect(find.text('آماده زنگ'), findsNothing);
      expect(find.text('نیاز به بررسی'), findsOneWidget);
      await tester.ensureVisible(find.text('تلاش دوباره برای زمان‌بندی'));
      await tester.tap(find.text('تلاش دوباره برای زمان‌بندی'));
      await tester.pumpAndSettle();
      expect(find.text('آماده زنگ'), findsOneWidget);
      expect(find.text('نیاز به بررسی'), findsNothing);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('small RTL layout with large text stays usable', (tester) async {
    tester.view.physicalSize = const Size(640, 1136);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(const AlarmXvApp());
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.byTooltip('تنظیمات'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('ظاهر برنامه'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'editor preserves legacy snooze and saves group and typing mission',
    (tester) async {
      Alarm? result;
      const legacy = Alarm(
        id: 'edit',
        hour: 6,
        minute: 15,
        weekdays: {1, 3},
        isEnabled: true,
        label: 'درس',
        snoozeMinutes: 10,
        maxSnoozes: 2,
        preventVolumeReduction: false,
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: buildClayTheme(Brightness.light, AccentPalette.ocean),
          builder: (context, child) =>
              Directionality(textDirection: TextDirection.rtl, child: child!),
          home: Builder(
            builder: (context) => Scaffold(
              body: FilledButton(
                onPressed: () async {
                  result = await showModalBottomSheet<Alarm>(
                    context: context,
                    isScrollControlled: true,
                    useSafeArea: true,
                    builder: (_) => const AlarmEditorSheet(
                      alarm: legacy,
                      groups: [
                        AlarmGroup(
                          id: 'study',
                          name: 'مطالعه',
                          color: 0xff4c70da,
                        ),
                      ],
                    ),
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      final groupSelector = find.byWidgetPredicate(
        (widget) =>
            widget is ClaySelectionTile<String> && widget.label == 'گروه زنگ',
      );
      await tester.ensureVisible(groupSelector);
      await tester.tap(groupSelector);
      await tester.pumpAndSettle();
      await tester.tap(find.text('مطالعه').last);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('تایپ عبارت'));
      await tester.tap(find.text('تایپ عبارت'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byType(TextFormField).last);
      await tester.enterText(
        find.byType(TextFormField).last,
        'امروز یک شروع تازه است',
      );
      await tester.tap(find.text('ذخیره تغییرات'));
      await tester.pumpAndSettle();
      expect(result?.id, 'edit');
      expect(result?.groupId, 'study');
      expect(result?.snoozeMinutes, 10);
      expect(result?.maxSnoozes, 2);
      expect(result?.preventVolumeReduction, isFalse);
      expect(
        result?.challenges,
        [ChallengeType.math, ChallengeType.typing].toSet(),
      );
      expect(result?.missionSettings.typingPhrase, 'امروز یک شروع تازه است');
    },
  );

  testWidgets('theme and accent selection persist through native settings', (
    tester,
  ) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    await tester.pumpWidget(const AlarmXvApp());
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('تنظیمات'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('رفتن به حالت تیره'));
    await tester.pumpAndSettle();
    expect(settings['themeMode'], 'dark');
    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
      ThemeMode.dark,
    );
    await tester.ensureVisible(find.text('مرجانی'));
    await tester.tap(find.text('مرجانی'));
    await tester.pumpAndSettle();
    expect(settings['accent'], 'coral');
    final automaticTheme = find.widgetWithText(
      SwitchListTile,
      'هماهنگ با سیستم',
    );
    await tester.ensureVisible(automaticTheme);
    await tester.tap(automaticTheme);
    await tester.pumpAndSettle();
    expect(settings['themeMode'], 'system');
    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
      ThemeMode.system,
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('group deletion failure restores alarm membership', (
    tester,
  ) async {
    settings = {
      'groups': [
        {'id': 'work', 'name': 'کار', 'color': 0xff4c70da},
      ],
    };
    alarms.single['groupId'] = 'work';
    await tester.pumpWidget(const AlarmXvApp());
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.widgetWithText(ActionChip, 'گروه‌ها'));
    await tester.tap(find.widgetWithText(ActionChip, 'گروه‌ها'));
    await tester.pumpAndSettle();
    failSettingsSave = true;
    await tester.tap(find.byTooltip('گزینه‌های گروه کار'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('حذف گروه'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('حذف گروه'));
    await tester.pumpAndSettle();
    expect(alarms.single['groupId'], 'work');
    expect(settings['groups'], hasLength(1));
    expect(find.text('کار'), findsWidgets);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('group bulk toggle needs confirmation and keeps alarms', (
    tester,
  ) async {
    settings = {
      'groups': [
        {'id': 'work', 'name': 'کار', 'color': 0xff4c70da},
      ],
    };
    alarms.single['groupId'] = 'work';
    await tester.pumpWidget(const AlarmXvApp());
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.widgetWithText(ActionChip, 'گروه‌ها'));
    await tester.tap(find.widgetWithText(ActionChip, 'گروه‌ها'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Switch).last);
    await tester.pumpAndSettle();
    expect(alarms.single['isEnabled'], isTrue);
    await tester.tap(find.text('انصراف'));
    await tester.pumpAndSettle();
    expect(alarms.single['isEnabled'], isTrue);
    await tester.tap(find.byType(Switch).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('تأیید'));
    await tester.pumpAndSettle();
    expect(alarms, hasLength(1));
    expect(alarms.single['isEnabled'], isFalse);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'editor handles large RTL text with keyboard and reduced motion',
    (tester) async {
      tester.view.physicalSize = const Size(640, 1136);
      tester.view.devicePixelRatio = 2;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetViewInsets);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      await tester.pumpWidget(const AlarmXvApp());
      await tester.pumpAndSettle();
      await tester.tap(find.text('زنگ جدید'));
      await tester.pumpAndSettle();
      tester.view.viewInsets = const FakeViewPadding(bottom: 400);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byType(TextFormField).first);
      await tester.enterText(
        find.byType(TextFormField).first,
        'تست دسترس‌پذیری',
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(
        tester
            .widget<MaterialApp>(find.byType(MaterialApp))
            .themeAnimationDuration,
        Duration.zero,
      );
      await tester.pumpWidget(const SizedBox());
    },
  );
}
