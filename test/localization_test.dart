import 'package:alarm_xv/models/app_settings.dart';
import 'package:alarm_xv/l10n/app_strings.dart';
import 'package:alarm_xv/l10n/english_messages.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'language settings migrate to system and preserve explicit overrides',
    () {
      expect(AppSettings.fromJson({}).toJson()['language'], 'system');
      for (final language in ['fa', 'en']) {
        expect(
          AppSettings.fromJson({'language': language}).toJson()['language'],
          language,
        );
      }
      expect(
        AppSettings.fromJson({'language': 'unknown'}).toJson()['language'],
        'system',
      );
    },
  );

  test(
    'translations preserve parameter names and never rewrite user values',
    () {
      const fa = AppStrings(Locale('fa'));
      const en = AppStrings(Locale('en'));
      for (final entry in englishMessages.entries) {
        final placeholders = RegExp(r'\{\w+\}');
        expect(
          placeholders.allMatches(entry.value).map((m) => m.group(0)).toSet(),
          placeholders.allMatches(entry.key).map((m) => m.group(0)).toSet(),
          reason: entry.key,
        );
      }
      expect(
        en.text('«{p0}» از زنگ‌ها حذف می‌شه.', {'p0': 'ساعت من'}),
        contains('ساعت من'),
      );
      expect(fa.text('تنظیمات'), 'تنظیمات');
      expect(en.text('تنظیمات'), 'Settings');
    },
  );
}
