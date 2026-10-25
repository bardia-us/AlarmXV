import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/alarm.dart';
import '../models/app_settings.dart';

class AlarmPermissionStatus {
  const AlarmPermissionStatus({
    required this.exactAlarm,
    required this.notifications,
    required this.fullScreen,
    required this.overlay,
  });

  final bool exactAlarm;
  final bool notifications;
  final bool fullScreen;
  final bool overlay;

  bool get allGranted => exactAlarm && notifications && fullScreen && overlay;
  bool get normalGranted => exactAlarm && notifications;

  factory AlarmPermissionStatus.fromMap(Map<Object?, Object?> map) {
    return AlarmPermissionStatus(
      exactAlarm: map['exactAlarm'] as bool? ?? false,
      notifications: map['notifications'] as bool? ?? false,
      fullScreen: map['fullScreen'] as bool? ?? false,
      overlay: map['overlay'] as bool? ?? false,
    );
  }
}

class AlarmSyncResult {
  const AlarmSyncResult({
    required this.scheduledCount,
    required this.permissions,
    this.scheduleError,
  });

  final int scheduledCount;
  final AlarmPermissionStatus permissions;
  final String? scheduleError;

  factory AlarmSyncResult.fromMap(Map<Object?, Object?> map) {
    return AlarmSyncResult(
      scheduledCount: map['scheduledCount'] as int? ?? 0,
      permissions: AlarmPermissionStatus.fromMap(map),
      scheduleError: map['scheduleError'] as String?,
    );
  }
}

class AlarmSoundChoice {
  const AlarmSoundChoice({required this.uri, required this.name});

  final String uri;
  final String name;

  factory AlarmSoundChoice.fromMap(Map<Object?, Object?> map) {
    return AlarmSoundChoice(
      uri: map['uri'] as String? ?? '',
      name: map['name'] as String? ?? 'System alarm sound',
    );
  }
}

class AlarmStorage {
  const AlarmStorage();

  static const _channel = MethodChannel('alarm_xv/alarm_manager');

  Future<AppSettings> loadAppSettings() async {
    final encoded =
        await _channel.invokeMethod<String>('loadAppSettings') ?? '{}';
    return AppSettings.fromJson(jsonDecode(encoded) as Map<String, dynamic>);
  }

  Future<void> saveAppSettings(AppSettings settings) => _channel
      .invokeMethod<void>('saveAppSettings', jsonEncode(settings.toJson()));

  Future<List<Alarm>> load() async {
    final encoded = await _channel.invokeMethod<String>('loadAlarms') ?? '[]';
    final items = jsonDecode(encoded) as List<dynamic>;
    return items
        .map((item) => Alarm.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<AlarmSyncResult> saveAndSync(List<Alarm> alarms) async {
    final encoded = jsonEncode(alarms.map((alarm) => alarm.toJson()).toList());
    final result = await _channel.invokeMethod<Map<Object?, Object?>>(
      'saveAndSync',
      encoded,
    );
    return AlarmSyncResult.fromMap(result ?? const {});
  }

  Future<AlarmPermissionStatus> permissionStatus() async {
    final result = await _channel.invokeMethod<Map<Object?, Object?>>(
      'permissionStatus',
    );
    return AlarmPermissionStatus.fromMap(result ?? const {});
  }

  Future<AlarmSyncResult> reschedule() async {
    final result = await _channel.invokeMethod<Map<Object?, Object?>>(
      'reschedule',
    );
    return AlarmSyncResult.fromMap(result ?? const {});
  }

  Future<void> requestNotificationPermission() {
    return _channel.invokeMethod<void>('requestNotificationPermission');
  }

  Future<void> openExactAlarmSettings() {
    return _channel.invokeMethod<void>('openExactAlarmSettings');
  }

  Future<void> openFullScreenSettings() {
    return _channel.invokeMethod<void>('openFullScreenSettings');
  }

  Future<void> openNotificationSettings() {
    return _channel.invokeMethod<void>('openNotificationSettings');
  }

  Future<void> openOverlaySettings() {
    return _channel.invokeMethod<void>('openOverlaySettings');
  }

  Future<AlarmSoundChoice?> pickAlarmSound(String? currentUri) async {
    final result = await _channel.invokeMethod<Map<Object?, Object?>>(
      'pickAlarmSound',
      <String, Object?>{'currentUri': currentUri},
    );
    return result == null ? null : AlarmSoundChoice.fromMap(result);
  }
}
