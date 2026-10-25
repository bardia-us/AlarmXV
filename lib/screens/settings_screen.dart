import 'package:flutter/material.dart';

import '../models/app_settings.dart';
import '../theme/clay_theme.dart';
import '../theme/settings_controller.dart';
import '../widgets/app_info_section.dart';
import '../widgets/clay_components.dart';
import '../widgets/theme_toggle_button.dart';

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
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'حالت نمایش',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? 'آرامش شب، با عمق نرم'
                                        : 'روشن و سبک، مثل صبح',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 14),
                            ClayThemeToggle(controller: controller),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('هماهنگ با سیستم'),
                          subtitle: Text(
                            settings.themeMode == ThemeMode.system
                                ? 'حالت روشن و تیره با گوشی تغییر می‌کنه.'
                                : 'انتخاب دستی فعاله؛ با دکمهٔ ماه و خورشید عوضش کن.',
                          ),
                          value: settings.themeMode == ThemeMode.system,
                          onChanged: controller.isSaving
                              ? null
                              : (enabled) => _update(
                                  context,
                                  settings.copyWith(
                                    themeMode: enabled
                                        ? ThemeMode.system
                                        : Theme.of(context).brightness ==
                                              Brightness.dark
                                        ? ThemeMode.dark
                                        : ThemeMode.light,
                                  ),
                                ),
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
