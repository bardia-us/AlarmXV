import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'screens/home_screen.dart';
import 'services/alarm_storage.dart';
import 'services/frame_recorder.dart';
import 'theme/clay_theme.dart';
import 'theme/settings_controller.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  LicenseRegistry.addLicense(() async* {
    yield LicenseEntryWithLineBreaks([
      'AlarmXV',
    ], await rootBundle.loadString('LICENSE'));
  });
  ProfileFrameRecorder.start();
  runApp(const AlarmXvApp());
}

class AlarmXvApp extends StatefulWidget {
  const AlarmXvApp({super.key, this.storage = const AlarmStorage()});
  final AlarmStorage storage;
  @override
  State<AlarmXvApp> createState() => _AlarmXvAppState();
}

class _AlarmXvAppState extends State<AlarmXvApp> {
  late final SettingsController _settings;
  @override
  void initState() {
    super.initState();
    _settings = SettingsController(storage: widget.storage)..load();
  }

  @override
  void dispose() {
    _settings.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _settings,
    builder: (context, _) => MaterialApp(
      title: 'AlarmXV',
      debugShowCheckedModeBanner: false,
      theme: buildClayTheme(Brightness.light, _settings.settings.accent),
      darkTheme: buildClayTheme(Brightness.dark, _settings.settings.accent),
      themeMode: _settings.settings.themeMode,
      themeAnimationDuration:
          WidgetsBinding
              .instance
              .platformDispatcher
              .accessibilityFeatures
              .disableAnimations
          ? Duration.zero
          : ClayTokens.motion,
      themeAnimationCurve: Curves.easeOutCubic,
      builder: (context, child) =>
          Directionality(textDirection: TextDirection.rtl, child: child!),
      home: _settings.isLoaded
          ? HomeScreen(storage: widget.storage, settings: _settings)
          : Scaffold(
              body: Center(
                child: _settings.error == null
                    ? const CircularProgressIndicator()
                    : Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.cloud_off_rounded, size: 48),
                            const SizedBox(height: 16),
                            Text(_settings.error!, textAlign: TextAlign.center),
                            const SizedBox(height: 16),
                            FilledButton(
                              onPressed: _settings.load,
                              child: const Text('تلاش دوباره'),
                            ),
                          ],
                        ),
                      ),
              ),
            ),
    ),
  );
}
