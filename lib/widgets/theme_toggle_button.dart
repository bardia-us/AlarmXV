import '../l10n/app_strings.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/settings_controller.dart';
import 'clay_components.dart';
import 'frosted_menu.dart';

/// One deliberate theme action, shared by the top bar and appearance settings.
class ClayThemeToggle extends StatelessWidget {
  const ClayThemeToggle({super.key, required this.controller});
  final SettingsController controller;

  Future<void> _save(BuildContext context, ThemeMode mode) async {
    if (controller.isSaving) return;
    if (!reduceMotion(context)) HapticFeedback.selectionClick();
    try {
      await controller.update(controller.settings.copyWith(themeMode: mode));
    } catch (_) {
      if (context.mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr("ظاهر جدید ذخیره نشد؛ دوباره تلاش کن.")),
          ),
        );
    }
  }

  Future<void> _systemMenu(BuildContext context) async {
    if (controller.isSaving) return;
    final chosen = await showFrostedMenu<ThemeMode>(
      context: context,
      items: [
        PopupMenuItem(
          value: ThemeMode.system,
          child: Text(context.tr("پیروی از سیستم")),
        ),
      ],
    );
    if (chosen != null && context.mounted) await _save(context, chosen);
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    builder: (context, _) {
      final dark = Theme.of(context).brightness == Brightness.dark;
      final automatic = controller.settings.themeMode == ThemeMode.system;
      final next = dark ? ThemeMode.light : ThemeMode.dark;
      final action = dark
          ? context.tr("رفتن به حالت روشن")
          : context.tr("رفتن به حالت تیره");
      return Semantics(
        label:
            context.tr("ظاهر فعلی: ") +
            (dark ? context.tr("تیره") : context.tr("روشن")) +
            (automatic
                ? context.tr("، هماهنگ با سیستم")
                : context.tr("، انتخاب دستی")),
        hint: context.tr("برای پیروی از سیستم نگه دار"),
        child: GestureDetector(
          onLongPress: controller.isSaving ? null : () => _systemMenu(context),
          child: ClayPress(
            child: ClaySurface(
              radius: 18,
              padding: EdgeInsets.zero,
              color: Color.alphaBlend(
                Theme.of(context).colorScheme.primary.withValues(alpha: .08),
                Theme.of(context).colorScheme.surface,
              ),
              child: IconButton(
                tooltip: action,
                onPressed: controller.isSaving
                    ? null
                    : () => _save(context, next),
                icon: AnimatedSwitcher(
                  duration: reduceMotion(context)
                      ? Duration.zero
                      : const Duration(milliseconds: 380),
                  transitionBuilder: (child, animation) {
                    final spring = animation.drive(
                      CurveTween(curve: Curves.easeOutBack),
                    );
                    return FadeTransition(
                      opacity: animation,
                      child: RotationTransition(
                        turns: Tween<double>(
                          begin: .12,
                          end: 0,
                        ).animate(spring),
                        child: ScaleTransition(
                          scale: Tween<double>(
                            begin: .72,
                            end: 1,
                          ).animate(spring),
                          child: child,
                        ),
                      ),
                    );
                  },
                  child: Icon(
                    dark ? Icons.nightlight_round : Icons.wb_sunny_rounded,
                    key: ValueKey(dark),
                    color: Theme.of(context).colorScheme.primary,
                    size: 25,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}
