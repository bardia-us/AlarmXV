import '../l10n/app_strings.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/clay_theme.dart';
import 'frosted_surface.dart';

bool reduceMotion(BuildContext context) =>
    MediaQuery.disableAnimationsOf(context) ||
    MediaQuery.accessibleNavigationOf(context);

class ClaySurface extends StatelessWidget {
  const ClaySurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.color,
    this.onTap,
    this.radius = ClayTokens.radius,
    this.elevated = true,
  });
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final VoidCallback? onTap;
  final double radius;
  final bool elevated;
  @override
  Widget build(BuildContext context) {
    final tokens = ClayTokens.of(context);
    final shape = BorderRadius.circular(radius);
    final content = onTap == null
        ? Padding(padding: padding, child: child)
        : InkWell(
            borderRadius: shape,
            onTap: () {
              if (!reduceMotion(context)) HapticFeedback.selectionClick();
              onTap!();
            },
            child: Padding(padding: padding, child: child),
          );
    final base = color ?? tokens.surface;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: shape,
        boxShadow: elevated ? tokens.depth : null,
      ),
      child: Material(
        color: base,
        shape: RoundedRectangleBorder(
          borderRadius: shape,
          side: BorderSide(color: tokens.border.withValues(alpha: .7)),
        ),
        clipBehavior: Clip.antiAlias,
        child: tokens.isDark && elevated
            ? Ink(
                decoration: BoxDecoration(
                  borderRadius: shape,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color.alphaBlend(
                        Colors.white.withValues(alpha: .055),
                        base,
                      ),
                      base,
                      Color.alphaBlend(
                        Colors.black.withValues(alpha: .06),
                        base,
                      ),
                    ],
                  ),
                ),
                child: content,
              )
            : content,
      ),
    );
  }
}

class ClayPress extends StatefulWidget {
  const ClayPress({super.key, required this.child});
  final Widget child;
  @override
  State<ClayPress> createState() => _ClayPressState();
}

class _ClayPressState extends State<ClayPress> {
  bool _pressed = false;
  @override
  Widget build(BuildContext context) => Listener(
    onPointerDown: (_) {
      if (!reduceMotion(context)) setState(() => _pressed = true);
    },
    onPointerUp: (_) => setState(() => _pressed = false),
    onPointerCancel: (_) => setState(() => _pressed = false),
    child: AnimatedScale(
      scale: _pressed ? .975 : 1,
      duration: reduceMotion(context) ? Duration.zero : ClayTokens.motion,
      curve: Curves.easeOutBack,
      child: widget.child,
    ),
  );
}

class SectionHeading extends StatelessWidget {
  const SectionHeading(this.title, {super.key, this.subtitle, this.trailing});
  final String title;
  final String? subtitle;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 8, bottom: 14),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 5),
                Text(
                  subtitle!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    ),
  );
}

class StatusPill extends StatelessWidget {
  const StatusPill(this.label, {super.key, this.icon, this.color});
  final String label;
  final IconData? icon;
  final Color? color;
  @override
  Widget build(BuildContext context) {
    final tint = color ?? Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tint.withValues(alpha: .14)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 15, color: tint),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelMedium
                  ?.copyWith(color: tint, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class NumberControl extends StatelessWidget {
  const NumberControl({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.min = 1,
    this.max = 20,
    this.step = 1,
    this.suffix = '',
  });
  final String label, suffix;
  final int value, min, max, step;
  final ValueChanged<int> onChanged;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final controls = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton.filledTonal(
              tooltip: context.tr("کم‌کردن {p0}", {'p0': label}),
              onPressed: value > min
                  ? () => onChanged((value - step).clamp(min, max))
                  : null,
              icon: const Icon(Icons.remove_rounded, size: 18),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                '$value$suffix',
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            IconButton.filledTonal(
              tooltip: context.tr("زیادکردن {p0}", {'p0': label}),
              onPressed: value < max
                  ? () => onChanged((value + step).clamp(min, max))
                  : null,
              icon: const Icon(Icons.add_rounded, size: 18),
            ),
          ],
        );
        if (constraints.maxWidth < 330 ||
            MediaQuery.textScalerOf(context).scale(1) > 1.3)
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [Text(label), const SizedBox(height: 8), controls],
          );
        return Row(
          children: [
            Expanded(child: Text(label)),
            controls,
          ],
        );
      },
    ),
  );
}

/// A floating action edge. Place above scroll content in a Stack and reserve
/// equivalent bottom scroll padding. A single clipped filter samples the list.
class ClayActionFooter extends StatelessWidget {
  const ClayActionFooter({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final tokens = ClayTokens.of(context);
    return FrostedSurface(
      child: SafeArea(
        top: false,
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 16, 22, 14),
              child: SizedBox(
                width: double.infinity,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(ClayTokens.smallRadius),
                    boxShadow: tokens.depth,
                  ),
                  child: child,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ClaySelectionOption<T> {
  const ClaySelectionOption({
    required this.value,
    required this.label,
    this.icon,
    this.description,
  });
  final T value;
  final String label;
  final IconData? icon;
  final String? description;
}

/// Selection uses the app's rounded sheet and clipped surfaces, including RTL
/// and large text, instead of the platform dropdown route.
class ClaySelectionTile<T> extends StatelessWidget {
  const ClaySelectionTile({
    super.key,
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });
  final String label;
  final T value;
  final List<ClaySelectionOption<T>> options;
  final ValueChanged<T>? onChanged;

  Future<void> _choose(BuildContext context) async {
    FocusManager.instance.primaryFocus?.unfocus();
    final selected = await showFrostedBottomSheet<T>(
      context: context,
      builder: (context) => ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * .76,
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 12, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        label,
                        style: Theme.of(context).textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ),
                    IconButton(
                      tooltip: context.tr("بستن انتخاب"),
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.fromLTRB(22, 4, 22, 24),
                  physics: const BouncingScrollPhysics(),
                  itemCount: options.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final option = options[index];
                    final active = option.value == value;
                    final scheme = Theme.of(context).colorScheme;
                    return Semantics(
                      selected: active,
                      button: true,
                      child: ClaySurface(
                        elevated: active,
                        radius: 22,
                        color: scheme.primary.withValues(
                          alpha: active ? .12 : .025,
                        ),
                        onTap: () => Navigator.pop(context, option.value),
                        padding: const EdgeInsets.all(18),
                        child: Row(
                          children: [
                            if (option.icon != null) ...[
                              Icon(option.icon, color: scheme.primary),
                              const SizedBox(width: 14),
                            ],
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    option.label,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall,
                                  ),
                                  if (option.description != null) ...[
                                    const SizedBox(height: 5),
                                    Text(
                                      option.description!,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: scheme.onSurfaceVariant,
                                          ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Icon(
                              active
                                  ? Icons.check_circle_rounded
                                  : Icons.radio_button_unchecked_rounded,
                              color: active ? scheme.primary : scheme.outline,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (selected != null && context.mounted) onChanged?.call(selected);
  }

  @override
  Widget build(BuildContext context) {
    final selected = options
        .where((option) => option.value == value)
        .firstOrNull;
    final scheme = Theme.of(context).colorScheme;
    return ClaySurface(
      radius: ClayTokens.smallRadius,
      elevated: false,
      color: ClayTokens.of(context).inset,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      onTap: onChanged == null ? null : () => _choose(context),
      child: Row(
        children: [
          if (selected?.icon != null) ...[
            Icon(selected!.icon, color: scheme.primary),
            const SizedBox(width: 14),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: scheme.onSurfaceVariant),
                ),
                const SizedBox(height: 6),
                Text(
                  selected?.label ?? '',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Icon(Icons.unfold_more_rounded, color: scheme.onSurfaceVariant),
        ],
      ),
    );
  }
}

Future<bool> confirmAction(
  BuildContext context, {
  required String title,
  required String message,
  required String action,
  bool destructive = false,
}) async =>
    await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.tr("انصراف")),
          ),
          FilledButton(
            style: destructive
                ? FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error,
                    foregroundColor: Theme.of(context).colorScheme.onError,
                  )
                : null,
            onPressed: () => Navigator.pop(context, true),
            child: Text(action),
          ),
        ],
      ),
    ) ??
    false;
