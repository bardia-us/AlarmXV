import 'package:flutter/material.dart';

import '../models/app_settings.dart';

extension AccentAppearance on AccentPalette {
  String get label => switch (this) {
    AccentPalette.ocean => 'اقیانوس',
    AccentPalette.emerald => 'زمرد',
    AccentPalette.sunset => 'غروب',
    AccentPalette.coral => 'مرجانی',
    AccentPalette.lavender => 'اسطوخودوس',
    AccentPalette.rose => 'رز',
    AccentPalette.teal => 'فیروزه',
    AccentPalette.amber => 'کهربا',
  };
  Color get color => switch (this) {
    AccentPalette.ocean => const Color(0xFF4C70DA),
    AccentPalette.emerald => const Color(0xFF247C61),
    AccentPalette.sunset => const Color(0xFFB85D2C),
    AccentPalette.coral => const Color(0xFFBC5157),
    AccentPalette.lavender => const Color(0xFF8063BC),
    AccentPalette.rose => const Color(0xFFAB5181),
    AccentPalette.teal => const Color(0xFF257B86),
    AccentPalette.amber => const Color(0xFF9F731D),
  };
}

@immutable
class ClayTokens extends ThemeExtension<ClayTokens> {
  const ClayTokens({
    required this.canvas,
    required this.surface,
    required this.inset,
    required this.border,
    required this.highlight,
    required this.shadow,
    required this.success,
  });
  final Color canvas, surface, inset, border, highlight, shadow, success;
  static const double radius = 28, smallRadius = 18;
  static const Duration motion = Duration(milliseconds: 280);
  static ClayTokens of(BuildContext context) =>
      Theme.of(context).extension<ClayTokens>()!;
  List<BoxShadow> get depth => [
    BoxShadow(color: shadow, offset: const Offset(5, 7), blurRadius: 16),
    BoxShadow(color: highlight, offset: const Offset(-3, -3), blurRadius: 10),
  ];
  @override
  ClayTokens copyWith({
    Color? canvas,
    Color? surface,
    Color? inset,
    Color? border,
    Color? highlight,
    Color? shadow,
    Color? success,
  }) => ClayTokens(
    canvas: canvas ?? this.canvas,
    surface: surface ?? this.surface,
    inset: inset ?? this.inset,
    border: border ?? this.border,
    highlight: highlight ?? this.highlight,
    shadow: shadow ?? this.shadow,
    success: success ?? this.success,
  );
  @override
  ClayTokens lerp(covariant ClayTokens? other, double t) {
    if (other == null) return this;
    return ClayTokens(
      canvas: Color.lerp(canvas, other.canvas, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      inset: Color.lerp(inset, other.inset, t)!,
      border: Color.lerp(border, other.border, t)!,
      highlight: Color.lerp(highlight, other.highlight, t)!,
      shadow: Color.lerp(shadow, other.shadow, t)!,
      success: Color.lerp(success, other.success, t)!,
    );
  }
}

ThemeData buildClayTheme(Brightness brightness, AccentPalette accent) {
  final dark = brightness == Brightness.dark;
  final scheme = ColorScheme.fromSeed(
    seedColor: accent.color,
    brightness: brightness,
    surface: dark ? const Color(0xFF232733) : const Color(0xFFF4F5FB),
  );
  final tokens = ClayTokens(
    canvas: dark ? const Color(0xFF1B1F29) : const Color(0xFFECEDF5),
    surface: dark ? const Color(0xFF272C39) : const Color(0xFFF5F6FC),
    inset: dark ? const Color(0xFF1F2430) : const Color(0xFFE6E9F3),
    border: dark ? const Color(0xFF3B4151) : const Color(0xFFFEFEFF),
    highlight: dark ? const Color(0x243F4659) : const Color(0xC9FFFFFF),
    shadow: dark ? const Color(0x660B0D14) : const Color(0x26A3ADC6),
    success: dark ? const Color(0xFF8CD9B4) : const Color(0xFF246B4E),
  );
  final rounded = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(ClayTokens.smallRadius),
  );
  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: tokens.canvas,
    extensions: [tokens],
    visualDensity: VisualDensity.standard,
    splashFactory: InkRipple.splashFactory,
    appBarTheme: AppBarTheme(
      backgroundColor: tokens.canvas,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
    ),
    cardTheme: CardThemeData(
      color: tokens.surface,
      margin: EdgeInsets.zero,
      shape: rounded,
      elevation: 0,
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: tokens.canvas,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      clipBehavior: Clip.antiAlias,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: tokens.surface,
      surfaceTintColor: Colors.transparent,
      shape: rounded,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: tokens.inset,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(
          color: scheme.outlineVariant.withValues(alpha: .35),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: scheme.primary, width: 1.5),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(48, 52),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        shape: rounded,
        textStyle: const TextStyle(
          fontFamily: 'Roboto',
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(48, 48),
        shape: rounded,
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        minimumSize: const Size(48, 48),
        shape: rounded,
      ),
    ),
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      side: BorderSide(color: scheme.outlineVariant.withValues(alpha: .5)),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 7),
      backgroundColor: tokens.surface,
      selectedColor: scheme.primaryContainer,
      showCheckmark: false,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: rounded,
    ),
  );
}
