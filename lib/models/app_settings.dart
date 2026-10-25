import 'package:flutter/material.dart';

import 'alarm_group.dart';

enum AccentPalette {
  ocean,
  emerald,
  sunset,
  coral,
  lavender,
  rose,
  teal,
  amber,
}

class AppSettings {
  const AppSettings({
    this.language = 'system',
    this.themeMode = ThemeMode.system,
    this.accent = AccentPalette.ocean,
    this.groups = const [],
    this.defaultSnoozeMinutes = 5,
  });

  final ThemeMode themeMode;

  /// Missing legacy values follow the system; unsupported languages use English.
  final String language;
  final AccentPalette accent;
  final List<AlarmGroup> groups;
  final int defaultSnoozeMinutes;

  AppSettings copyWith({
    String? language,
    ThemeMode? themeMode,
    AccentPalette? accent,
    List<AlarmGroup>? groups,
    int? defaultSnoozeMinutes,
  }) => AppSettings(
    language: language ?? this.language,
    themeMode: themeMode ?? this.themeMode,
    accent: accent ?? this.accent,
    groups: groups == null ? this.groups : List.unmodifiable(groups),
    defaultSnoozeMinutes: defaultSnoozeMinutes ?? this.defaultSnoozeMinutes,
  );

  Map<String, Object> toJson() => {
    'schemaVersion': 2,
    'language': language,
    'themeMode': themeMode.name,
    'accent': accent.name,
    'groups': groups.map((group) => group.toJson()).toList(),
    'defaultSnoozeMinutes': defaultSnoozeMinutes,
  };

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    final groups =
        (json['groups'] as List<dynamic>? ?? [])
            .whereType<Map<String, dynamic>>()
            .map(AlarmGroup.fromJson)
            .toList()
          ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return AppSettings(
      language: const {'system', 'fa', 'en'}.contains(json['language'])
          ? json['language'] as String
          : 'system',
      themeMode:
          ThemeMode.values
              .where((mode) => mode.name == json['themeMode'])
              .firstOrNull ??
          ThemeMode.system,
      accent:
          AccentPalette.values
              .where((color) => color.name == json['accent'])
              .firstOrNull ??
          AccentPalette.ocean,
      groups: List.unmodifiable(groups),
      defaultSnoozeMinutes:
          const {0, 5, 10, 15}.contains(json['defaultSnoozeMinutes'])
          ? json['defaultSnoozeMinutes'] as int
          : 5,
    );
  }
}
