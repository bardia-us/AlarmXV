import 'dart:ui' as ui;

import 'package:flutter/material.dart';

bool _reducedEffects(BuildContext context) =>
    MediaQuery.disableAnimationsOf(context) ||
    MediaQuery.accessibleNavigationOf(context) ||
    MediaQuery.highContrastOf(context);

/// Ordinary frosted translucency, adapted from niraNG's FrostedSurface.
/// Only the real backdrop is filtered; foreground content stays sharp.
class FrostedSurface extends StatelessWidget {
  const FrostedSurface({
    super.key,
    required this.child,
    this.borderRadius = BorderRadius.zero,
    this.sigma = 8,
    this.tintAlpha,
    this.opaque = false,
  });

  final Widget child;
  final BorderRadius borderRadius;
  final double sigma;
  final double? tintAlpha;
  final bool opaque;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final solid = opaque || _reducedEffects(context);
    final surface = ColoredBox(
      color: scheme.surfaceContainerHigh.withValues(
        alpha: solid
            ? 1
            : (tintAlpha ?? (scheme.brightness == Brightness.dark ? .45 : .64)),
      ),
      child: Material(type: MaterialType.transparency, child: child),
    );
    // No grouped BackdropKey: chrome and menus may overlap.
    return ClipRRect(
      borderRadius: borderRadius,
      child: solid
          ? surface
          : BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
              child: surface,
            ),
    );
  }
}

class FrostedAppBar extends StatelessWidget implements PreferredSizeWidget {
  const FrostedAppBar({
    super.key,
    required this.title,
    this.toolbarHeight = kToolbarHeight,
  });
  final Widget title;
  final double toolbarHeight;
  @override
  Size get preferredSize => Size.fromHeight(toolbarHeight);
  @override
  Widget build(BuildContext context) => AppBar(
    toolbarHeight: toolbarHeight,
    backgroundColor: Colors.transparent,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    scrolledUnderElevation: 0,
    automaticallyImplyLeading: false,
    leading: ModalRoute.of(context)?.canPop == true
        ? const ElasticBackButton()
        : null,
    titleSpacing: 22,
    title: title,
    flexibleSpace: const FrostedSurface(child: SizedBox.expand()),
  );
}

/// A short elastic press; the navigation action still uses Material semantics.
class ElasticBackButton extends StatefulWidget {
  const ElasticBackButton({super.key});
  @override
  State<ElasticBackButton> createState() => _ElasticBackButtonState();
}

class _ElasticBackButtonState extends State<ElasticBackButton> {
  bool _pressed = false;
  void _press(bool value) {
    if (mounted && _pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsetsDirectional.only(start: 8, top: 5, bottom: 5),
    child: Listener(
      onPointerDown: (_) => _press(true),
      onPointerUp: (_) => _press(false),
      onPointerCancel: (_) => _press(false),
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: _pressed ? 1 : 0),
        duration: _reducedEffects(context)
            ? Duration.zero
            : Duration(milliseconds: _pressed ? 110 : 380),
        curve: _pressed ? Curves.easeOutCubic : Curves.easeOutBack,
        builder: (context, value, child) => Transform.scale(
          scaleX: 1 + value * .09,
          scaleY: 1 - value * .10,
          child: child,
        ),
        child: IconButton.filledTonal(
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          style: IconButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary
                .withValues(alpha: .12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back_rounded, size: 23),
        ),
      ),
    ),
  );
}

Future<T?> showFrostedBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
}) => showModalBottomSheet<T>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  backgroundColor: Colors.transparent,
  elevation: 0,
  barrierColor: Theme.of(context).colorScheme.scrim.withValues(alpha: .18),
  builder: (context) => FrostedSurface(
    borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
    sigma: 14,
    tintAlpha: Theme.of(context).brightness == Brightness.dark ? .64 : .78,
    child: builder(context),
  ),
);
