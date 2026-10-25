import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'english_messages.dart';

/// Persian source messages and their English translations live in one catalog.
/// Parameters use named placeholders, so word order can differ by language.
class AppStrings {
  const AppStrings(this.locale);
  final Locale locale;
  static const supportedLocales = [Locale('en'), Locale('fa')];
  static const delegate = _AppStringsDelegate();

  String text(String message, [Map<String, Object?> parameters = const {}]) {
    var result = locale.languageCode == 'fa'
        ? message
        : englishMessages[message] ?? message;
    return result.replaceAllMapped(RegExp(r'\{(\w+)\}'), (match) {
      final key = match.group(1)!;
      return parameters.containsKey(key)
          ? '${parameters[key] ?? ''}'
          : match.group(0)!;
    });
  }
}

extension LocalizedContext on BuildContext {
  String tr(String message, [Map<String, Object?> parameters = const {}]) =>
      Localizations.of<AppStrings>(this, AppStrings)!.text(message, parameters);
}

class _AppStringsDelegate extends LocalizationsDelegate<AppStrings> {
  const _AppStringsDelegate();
  @override
  bool isSupported(Locale locale) => AppStrings.supportedLocales.any(
    (supported) => supported.languageCode == locale.languageCode,
  );
  @override
  Future<AppStrings> load(Locale locale) =>
      SynchronousFuture(AppStrings(locale));
  @override
  bool shouldReload(_AppStringsDelegate old) => false;
}
