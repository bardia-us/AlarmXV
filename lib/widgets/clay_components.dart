import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/clay_theme.dart';

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
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: shape,
        boxShadow: elevated ? tokens.depth : null,
      ),
      child: Material(
        color: color ?? tokens.surface,
        shape: RoundedRectangleBorder(
          borderRadius: shape,
          side: BorderSide(color: tokens.border.withValues(alpha: .7)),
        ),
        clipBehavior: Clip.antiAlias,
        child: onTap == null
            ? Padding(padding: padding, child: child)
            : InkWell(
                borderRadius: shape,
                onTap: () {
                  if (!reduceMotion(context)) HapticFeedback.selectionClick();
                  onTap!();
                },
                child: Padding(padding: padding, child: child),
              ),
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
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
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
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: tint,
                fontWeight: FontWeight.w700,
              ),
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
              tooltip: 'کم‌کردن $label',
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
              tooltip: 'زیادکردن $label',
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
            child: const Text('انصراف'),
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
