import 'l10n/app_strings.dart';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'screens/home_screen.dart';
import 'services/alarm_storage.dart';
import 'services/frame_recorder.dart';
import 'theme/clay_theme.dart';
import 'theme/settings_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
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
      locale: _settings.settings.language == 'system'
          ? null
          : Locale(_settings.settings.language),
      supportedLocales: AppStrings.supportedLocales,
      localizationsDelegates: const [
        AppStrings.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: buildClayTheme(Brightness.light, _settings.settings.accent),
      darkTheme: buildClayTheme(Brightness.dark, _settings.settings.accent),
      themeMode: _settings.settings.themeMode,
      themeAnimationDuration:
          WidgetsBinding
                  .instance
                  .platformDispatcher
                  .accessibilityFeatures
                  .disableAnimations ||
              WidgetsBinding
                  .instance
                  .platformDispatcher
                  .accessibilityFeatures
                  .accessibleNavigation
          ? Duration.zero
          : ClayTokens.motion,
      themeAnimationCurve: Curves.easeOutCubic,
      builder: (context, child) {
        final dark = Theme.of(context).brightness == Brightness.dark;
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: dark ? Brightness.light : Brightness.dark,
            systemNavigationBarColor: Colors.transparent,
            systemNavigationBarDividerColor: Colors.transparent,
            systemNavigationBarIconBrightness: dark
                ? Brightness.light
                : Brightness.dark,
            systemNavigationBarContrastEnforced: false,
            systemStatusBarContrastEnforced: false,
          ),
          child: child!,
        );
      },
      home: _settings.isLoaded
          ? HomeScreen(storage: widget.storage, settings: _settings)
          : Builder(
              builder: (context) => Scaffold(
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
                              Text(
                                context.tr(_settings.error!),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              FilledButton(
                                onPressed: _settings.load,
                                child: Text(context.tr("تلاش دوباره")),
                              ),
                            ],
                          ),
                        ),
                ),
              ),
            ),
    ),
  );
}
