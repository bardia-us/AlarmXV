import 'package:flutter/foundation.dart';
import '../models/app_settings.dart';
import '../services/alarm_storage.dart';

class SettingsController extends ChangeNotifier {
  SettingsController({this.storage = const AlarmStorage()});
  final AlarmStorage storage;
  AppSettings _settings = const AppSettings();
  AppSettings get settings => _settings;
  bool isLoaded = false, isSaving = false, isLoading = false;
  bool _disposed = false;
  String? error;
  Future<void> load() async {
    if (isLoading) return;
    isLoading = true;
    error = null;
    if (!_disposed) notifyListeners();
    try {
      _settings = await storage.loadAppSettings();
      isLoaded = true;
    } catch (_) {
      error = 'تنظیمات خوانده نشد. دوباره تلاش کن.';
    }
    isLoading = false;
    if (!_disposed) notifyListeners();
  }

  /// Persist before publishing; failed native writes retain the previous state.
  Future<void> update(AppSettings next) async {
    if (isSaving) throw StateError('ذخیره‌سازی قبلی هنوز تمام نشده.');
    isSaving = true;
    if (!_disposed) notifyListeners();
    try {
      await storage.saveAppSettings(next);
      _settings = next;
      error = null;
    } finally {
      isSaving = false;
      if (!_disposed) notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
