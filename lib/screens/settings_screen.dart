import 'package:flutter/material.dart';
import '../models/app_settings.dart';
import '../theme/clay_theme.dart';
import '../theme/settings_controller.dart';
import '../widgets/app_info_section.dart';
import '../widgets/clay_components.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.controller});
  final SettingsController controller;
  Future<void> _update(BuildContext context, AppSettings settings) async {
    try {
      await controller.update(settings);
    } catch (_) {
      if (context.mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تنظیمات ذخیره نشد؛ حالت قبلی حفظ شد.')),
        );
    }
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    builder: (context, _) {
      final settings = controller.settings;
      return Scaffold(
        appBar: AppBar(title: const Text('تنظیمات')),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: ListView(
                padding: const EdgeInsets.all(22),
                physics: const BouncingScrollPhysics(),
                children: [
                  const SectionHeading(
                    'ظاهر برنامه',
                    subtitle: 'عمق نرم، رنگ دلخواه و آرامش بیشتر.',
                  ),
                  ClaySurface(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'حالت نمایش',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final mode in ThemeMode.values)
                              ChoiceChip(
                                avatar: Icon(switch (mode) {
                                  ThemeMode.system =>
                                    Icons.brightness_auto_rounded,
                                  ThemeMode.light => Icons.light_mode_outlined,
                                  ThemeMode.dark => Icons.dark_mode_outlined,
                                }, size: 18),
                                label: Text(switch (mode) {
                                  ThemeMode.system => 'همراه سیستم',
                                  ThemeMode.light => 'روشن',
                                  ThemeMode.dark => 'تیره',
                                }),
                                selected: settings.themeMode == mode,
                                onSelected: controller.isSaving
                                    ? null
                                    : (_) => _update(
                                        context,
                                        settings.copyWith(themeMode: mode),
                                      ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 22),
                        const Text(
                          'رنگ اصلی',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 10,
                          children: [
                            for (final accent in AccentPalette.values)
                              ChoiceChip(
                                avatar: Container(
                                  width: 18,
                                  height: 18,
                                  decoration: BoxDecoration(
                                    color: accent.color,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                label: Text(accent.label),
                                selected: settings.accent == accent,
                                onSelected: controller.isSaving
                                    ? null
                                    : (_) => _update(
                                        context,
                                        settings.copyWith(accent: accent),
                                      ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 26),
                  const SectionHeading(
                    'پیش‌فرض زنگ جدید',
                    subtitle: 'این تغییر، زنگ‌های قبلی رو عوض نمی‌کنه.',
                  ),
                  ClaySurface(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('مدت تعویق'),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final minutes in [0, 5, 10, 15])
                              ChoiceChip(
                                label: Text(
                                  minutes == 0
                                      ? 'بدون تعویق'
                                      : '$minutes دقیقه',
                                ),
                                selected:
                                    settings.defaultSnoozeMinutes == minutes,
                                onSelected: controller.isSaving
                                    ? null
                                    : (_) => _update(
                                        context,
                                        settings.copyWith(
                                          defaultSnoozeMinutes: minutes,
                                        ),
                                      ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 26),
                  const SectionHeading('حرکت و دسترس‌پذیری'),
                  ClaySurface(
                    elevated: false,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.accessibility_new_rounded,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Text(
                            'اندازه متن و کاهش حرکت از تنظیمات گوشی پیروی می‌کنن. با روشن‌بودن کاهش حرکت، بازخورد لرزشی و انیمیشن‌های تزئینی خاموش می‌شن.',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 26),
                  const SectionHeading('درباره و به‌روزرسانی'),
                  const AppInfoSection(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}
