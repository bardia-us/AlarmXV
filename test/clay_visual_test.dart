import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:alarm_xv/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Opt-in visual fixtures, never loaded by the application.
/// flutter test test/clay_visual_test.dart --dart-define=ALARMXV_CAPTURE_UI=true
void main() {
  testWidgets('capture clay screens for visual inspection', (tester) async {
    await tester.runAsync(() async {
      final textFont = FontLoader('Roboto')
        ..addFont(
          File('C:/Windows/Fonts/segoeui.ttf')
              .readAsBytes()
              .then(ByteData.sublistView),
        );
      final iconFont = FontLoader('MaterialIcons')
        ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
      await textFont.load();
      await iconFont.load();
    });
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var settings = <String, dynamic>{
      'themeMode': 'light',
      'language': 'fa',
      'groups': [
        {
          'id': 'work',
          'name': 'روزهای کار',
          'color': 0xff4c70da,
          'icon': 'work',
        },
      ],
    };
    const channel = MethodChannel('alarm_xv/alarm_manager');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          switch (call.method) {
            case 'getAppInfo':
              return {
                'versionName': '2.0.0-preview.1',
                'lastSeenVersion': '2.0.0-preview.1',
              };
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
                  'label': 'یک شروع زودهنگام',
                  'hour': 7,
                  'minute': 0,
                  'weekdays': [6, 7, 1, 2, 3],
                  'isEnabled': true,
                  'challenges': ['math', 'memory'],
                  'groupId': 'work',
                },
                {
                  'id': 'b',
                  'label': 'وقتِ خودم',
                  'hour': 8,
                  'minute': 30,
                  'weekdays': [4, 5],
                  'isEnabled': false,
                  'challenges': ['shake'],
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
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null),
    );
    const key = ValueKey('capture');
    Future<void> capture(String name, {bool settle = true}) async {
      if (settle) await tester.pumpAndSettle();
      final boundary = tester.renderObject<RenderRepaintBoundary>(
        find.byKey(key),
      );
      await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: 2);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        Directory('build/ui-preview').createSync(recursive: true);
        File('build/ui-preview/$name.png')
            .writeAsBytesSync(bytes!.buffer.asUint8List());
        image.dispose();
      });
    }

    await tester.pumpWidget(
      const RepaintBoundary(key: key, child: AlarmXvApp()),
    );
    await capture('home-light');
    await tester.tap(find.byTooltip('مرتب‌سازی'));
    await tester.pump(const Duration(milliseconds: 70));
    await capture('sort-menu-opening', settle: false);
    await capture('sort-menu-light');
    await tester.binding.handlePopRoute();
    await tester.pump(const Duration(milliseconds: 70));
    await capture('sort-menu-closing', settle: false);
    await tester.pumpAndSettle();
    await tester.tap(find.text('زنگ جدید'));
    await capture('editor');
    await tester.tap(find.text('برای تغییر ساعت بزن'));
    await capture('time-picker');
    await tester.tap(find.text('انصراف'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('گروه زنگ'));
    await tester.tap(find.text('گروه زنگ'));
    await capture('group-selection-light');
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await tester.drag(
      find.byType(SingleChildScrollView).last,
      const Offset(0, -400),
    );
    await capture('editor-footer');
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ActionChip, 'گروه‌ها'));
    await tester.pumpAndSettle();
    expect(find.text('گروه‌های زنگ'), findsOneWidget);
    await capture('groups');
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('تنظیمات'));
    await capture('settings-light');
    await tester.drag(find.byType(ListView).last, const Offset(0, -400));
    await capture('settings-light-scrolled');
    await tester.drag(find.byType(ListView).last, const Offset(0, 800));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('رفتن به حالت تیره'));
    await capture('settings-dark');
    await tester.drag(find.byType(ListView).last, const Offset(0, -400));
    await capture('settings-dark-scrolled');
    await tester.drag(find.byType(ListView).last, const Offset(0, 800));
    await tester.pumpAndSettle();
    await tester.tap(find.text('زبان برنامه'));
    await capture('language-selection-dark');
    await tester.tap(find.text('English'));
    await capture('settings-english-dark');
    await tester.tap(find.byTooltip('Switch to light mode'));
    await capture('settings-english-light');
    await tester.binding.handlePopRoute();
    await capture('home-english-light');
    await tester.tap(find.text('New alarm'));
    await capture('editor-english-light');
    await tester.tap(find.byTooltip('Close editor'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Switch to dark mode'));
    await capture('home-english-dark');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  }, skip: !const bool.fromEnvironment('ALARMXV_CAPTURE_UI'));
}
