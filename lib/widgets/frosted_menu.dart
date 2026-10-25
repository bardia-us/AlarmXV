import 'dart:math' as math;
import 'dart:ui' show SemanticsRole;

import 'package:flutter/material.dart';

import 'clay_components.dart' show reduceMotion;
import 'frosted_surface.dart';

/// A single clipped panel, with a single geometry transition for its material
/// and all entries. Standard PopupMenuItem retains keyboard/tap semantics.
Future<T?> showFrostedMenu<T>({
  required BuildContext context,
  required List<PopupMenuEntry<T>> items,
  T? initialValue,
}) {
  final navigator = Navigator.of(context);
  final anchor = context.findRenderObject()! as RenderBox;
  final overlay = navigator.overlay!.context.findRenderObject()! as RenderBox;
  return navigator.push<T>(
    _FrostedMenuRoute<T>(
      anchor:
          anchor.localToGlobal(Offset.zero, ancestor: overlay) & anchor.size,
      items: items,
      initialValue: initialValue,
      direction: Directionality.of(context),
      label: MaterialLocalizations.of(context).popupMenuLabel,
      dismissLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      themes: InheritedTheme.capture(from: context, to: navigator.context),
      duration: reduceMotion(context)
          ? Duration.zero
          : const Duration(milliseconds: 200),
    ),
  );
}

class FrostedMenuButton<T> extends StatelessWidget {
  const FrostedMenuButton({
    super.key,
    required this.itemBuilder,
    this.onSelected,
    this.tooltip,
    this.enabled = true,
    this.icon = const Icon(Icons.more_vert_rounded),
    this.padding = const EdgeInsets.all(8),
    this.initialValue,
  });
  final List<PopupMenuEntry<T>> Function(BuildContext) itemBuilder;
  final ValueChanged<T>? onSelected;
  final String? tooltip;
  final bool enabled;
  final Widget icon;
  final EdgeInsetsGeometry padding;
  final T? initialValue;
  @override
  Widget build(BuildContext context) => Builder(
    builder: (context) => IconButton(
      tooltip: tooltip,
      padding: padding,
      onPressed: !enabled
          ? null
          : () async {
              final value = await showFrostedMenu<T>(
                context: context,
                items: itemBuilder(context),
                initialValue: initialValue,
              );
              if (value != null && context.mounted) onSelected?.call(value);
            },
      icon: icon,
    ),
  );
}

class _FrostedMenuRoute<T> extends PopupRoute<T> {
  _FrostedMenuRoute({
    required this.anchor,
    required this.items,
    this.initialValue,
    required this.direction,
    required this.label,
    required this.dismissLabel,
    required this.themes,
    required this.duration,
  });
  final Rect anchor;
  final List<PopupMenuEntry<T>> items;
  final T? initialValue;
  final TextDirection direction;
  final String label, dismissLabel;
  final CapturedThemes themes;
  final Duration duration;
  @override
  Color get barrierColor => Colors.transparent;
  @override
  bool get barrierDismissible => true;
  @override
  String get barrierLabel => dismissLabel;
  @override
  Duration get transitionDuration => duration;
  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    final padding = MediaQuery.paddingOf(context);
    return themes.wrap(
      Directionality(
        textDirection: direction,
        child: CustomSingleChildLayout(
          delegate: _MenuLayout(anchor, padding, direction),
          child: ScaleTransition(
            alignment: direction == TextDirection.rtl
                ? Alignment.topLeft
                : Alignment.topRight,
            scale: animation
                .drive(CurveTween(curve: Curves.easeOutCubic))
                .drive(Tween(begin: .94, end: 1.0)),
            child: Semantics(
              role: SemanticsRole.menu,
              scopesRoute: true,
              namesRoute: true,
              explicitChildNodes: true,
              label: label,
              child: FrostedSurface(
                borderRadius: BorderRadius.circular(22),
                sigma: 14,
                tintAlpha: Theme.of(context).brightness == Brightness.dark
                    ? .64
                    : .78,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final item in items)
                        ColoredBox(
                          color:
                              initialValue != null &&
                                  item.represents(initialValue)
                              ? Theme.of(context).colorScheme.primary
                                    .withValues(alpha: .12)
                              : Colors.transparent,
                          child: item,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // No global opacity: the backdrop remains live for the whole transition.
  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => child;
}

class _MenuLayout extends SingleChildLayoutDelegate {
  _MenuLayout(this.anchor, this.padding, this.direction);
  final Rect anchor;
  final EdgeInsets padding;
  final TextDirection direction;
  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) =>
      BoxConstraints(
        minWidth: math
            .min(196.0, constraints.maxWidth - padding.horizontal - 16)
            .clamp(0, double.infinity),
        maxWidth: math
            .min(300.0, constraints.maxWidth - padding.horizontal - 16)
            .clamp(0, double.infinity),
        maxHeight: (constraints.maxHeight - padding.vertical - 16).clamp(
          0,
          double.infinity,
        ),
      );
  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final x = direction == TextDirection.rtl
        ? anchor.left
        : anchor.right - childSize.width;
    final y = anchor.bottom + 4;
    return Offset(
      x.clamp(
        padding.left + 8,
        math.max(
          padding.left + 8,
          size.width - padding.right - childSize.width - 8,
        ),
      ),
      y.clamp(
        padding.top + 8,
        math.max(
          padding.top + 8,
          size.height - padding.bottom - childSize.height - 8,
        ),
      ),
    );
  }

  @override
  bool shouldRelayout(_MenuLayout oldDelegate) =>
      anchor != oldDelegate.anchor ||
      padding != oldDelegate.padding ||
      direction != oldDelegate.direction;
}
