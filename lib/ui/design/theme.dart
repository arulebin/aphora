import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'tokens.dart';

/// Builds the single app-wide theme. Screens should read styles from
/// `Theme.of(context).textTheme` so that the OS text-size setting and the
/// in-app "Larger text" preference both scale everything consistently.
abstract final class AphTheme {
  static List<String> get _fallback => [
        GoogleFonts.notoSansTamil().fontFamily!,
        GoogleFonts.notoSans().fontFamily!,
      ];

  static TextTheme _textTheme() {
    // Body is 18 rather than 16: the audience is older and many have
    // reduced acuity after stroke. Line height 1.45 for readability.
    TextStyle f(double size, FontWeight w, {double h = 1.3, Color? c}) =>
        GoogleFonts.figtree(
          fontSize: size,
          fontWeight: w,
          height: h,
          color: c ?? AphColors.ink,
        ).copyWith(fontFamilyFallback: _fallback);

    return TextTheme(
      displayLarge: f(40, FontWeight.w700, h: 1.1),
      displayMedium: f(34, FontWeight.w700, h: 1.15),
      displaySmall: f(30, FontWeight.w700, h: 1.2),
      headlineLarge: f(28, FontWeight.w700, h: 1.2),
      headlineMedium: f(25, FontWeight.w700, h: 1.25),
      headlineSmall: f(22, FontWeight.w700, h: 1.3),
      titleLarge: f(20, FontWeight.w600),
      titleMedium: f(18, FontWeight.w600),
      titleSmall: f(16, FontWeight.w600),
      bodyLarge: f(18, FontWeight.w400, h: 1.45),
      bodyMedium: f(16, FontWeight.w400, h: 1.45, c: AphColors.inkMuted),
      bodySmall: f(14, FontWeight.w500, h: 1.4, c: AphColors.inkMuted),
      labelLarge: f(18, FontWeight.w600, h: 1.2),
      labelMedium: f(15, FontWeight.w600, h: 1.2),
      labelSmall: f(13, FontWeight.w600, h: 1.2, c: AphColors.inkMuted),
    );
  }

  /// High-contrast variant: all secondary text becomes full ink, borders
  /// darken, so low-vision users get maximum separation.
  static ThemeData highContrast() {
    final base = light();
    TextStyle? ink(TextStyle? s) => s?.copyWith(color: AphColors.ink);
    final tt = base.textTheme;
    return base.copyWith(
      scaffoldBackgroundColor: Colors.white,
      textTheme: tt.copyWith(
        bodyMedium: ink(tt.bodyMedium),
        bodySmall: ink(tt.bodySmall),
        labelSmall: ink(tt.labelSmall),
      ),
      colorScheme: base.colorScheme.copyWith(
        onSurfaceVariant: AphColors.ink,
        outline: AphColors.ink,
        outlineVariant: AphColors.inkMuted,
        primary: AphColors.primaryPressed,
      ),
      cardTheme: base.cardTheme.copyWith(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AphRadius.lg),
          side: const BorderSide(color: AphColors.ink, width: 1.5),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AphColors.inkMuted,
        thickness: 1.5,
        space: 1.5,
      ),
    );
  }

  static ThemeData light() {
    final text = _textTheme();
    const scheme = ColorScheme(
      brightness: Brightness.light,
      primary: AphColors.primary,
      onPrimary: AphColors.onPrimary,
      primaryContainer: AphColors.primarySoft,
      onPrimaryContainer: AphColors.primaryPressed,
      secondary: AphColors.accent,
      onSecondary: Colors.white,
      secondaryContainer: AphColors.accentSoft,
      onSecondaryContainer: AphColors.accent,
      error: AphColors.danger,
      onError: Colors.white,
      errorContainer: AphColors.dangerSoft,
      onErrorContainer: AphColors.danger,
      surface: AphColors.surface,
      onSurface: AphColors.ink,
      onSurfaceVariant: AphColors.inkMuted,
      surfaceContainerLowest: AphColors.surface,
      surfaceContainerLow: AphColors.background,
      surfaceContainer: AphColors.surfaceSunken,
      outline: AphColors.borderStrong,
      outlineVariant: AphColors.border,
    );

    final buttonShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AphRadius.md),
    );
    const buttonSize = Size(AphSize.minTap, AphSize.button);

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AphColors.background,
      textTheme: text,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      visualDensity: VisualDensity.standard,
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: AphColors.background,
        surfaceTintColor: Colors.transparent,
        foregroundColor: AphColors.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: text.titleLarge,
        iconTheme: const IconThemeData(color: AphColors.ink, size: 26),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: buttonSize,
          shape: buttonShape,
          textStyle: text.labelLarge,
          backgroundColor: AphColors.primary,
          foregroundColor: AphColors.onPrimary,
          disabledBackgroundColor: AphColors.surfaceSunken,
          disabledForegroundColor: AphColors.inkSubtle,
          padding: const EdgeInsets.symmetric(horizontal: AphSpace.lg),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: buttonSize,
          shape: buttonShape,
          textStyle: text.labelLarge,
          foregroundColor: AphColors.ink,
          side: const BorderSide(color: AphColors.borderStrong, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: AphSpace.lg),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(AphSize.minTap, AphSize.minTap),
          textStyle: text.labelLarge,
          foregroundColor: AphColors.primary,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size(AphSize.minTap, AphSize.minTap),
          iconSize: 26,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AphColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AphSpace.md,
          vertical: 18,
        ),
        labelStyle: text.bodyLarge?.copyWith(color: AphColors.inkMuted),
        floatingLabelStyle: text.bodyMedium?.copyWith(
          color: AphColors.primary,
          fontWeight: FontWeight.w600,
        ),
        hintStyle: text.bodyLarge?.copyWith(color: AphColors.inkSubtle),
        helperStyle: text.bodySmall,
        errorStyle: text.bodySmall?.copyWith(color: AphColors.danger),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AphRadius.md),
          borderSide: const BorderSide(color: AphColors.borderStrong),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AphRadius.md),
          borderSide: const BorderSide(color: AphColors.borderStrong),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AphRadius.md),
          borderSide: const BorderSide(color: AphColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AphRadius.md),
          borderSide: const BorderSide(color: AphColors.danger, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AphRadius.md),
          borderSide: const BorderSide(color: AphColors.danger, width: 2),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 76,
        backgroundColor: AphColors.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: AphColors.primarySoft,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (s) => text.labelMedium?.copyWith(
            color: s.contains(WidgetState.selected)
                ? AphColors.primary
                : AphColors.inkMuted,
            fontWeight: s.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w600,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (s) => IconThemeData(
            size: 28,
            color: s.contains(WidgetState.selected)
                ? AphColors.primary
                : AphColors.inkMuted,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: AphColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AphRadius.lg),
          side: const BorderSide(color: AphColors.border),
        ),
      ),
      chipTheme: ChipThemeData(
        labelStyle: text.labelMedium,
        side: const BorderSide(color: AphColors.border),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AphRadius.pill),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      ),
      dividerTheme: const DividerThemeData(
        color: AphColors.border,
        thickness: 1,
        space: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AphColors.ink,
        contentTextStyle: text.bodyLarge?.copyWith(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AphRadius.md),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AphColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AphRadius.lg),
        ),
        titleTextStyle: text.headlineSmall,
        contentTextStyle: text.bodyLarge,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AphColors.surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AphRadius.lg),
          ),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AphColors.primary,
        linearTrackColor: AphColors.surfaceSunken,
        circularTrackColor: AphColors.surfaceSunken,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? Colors.white : null,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? AphColors.primary : null,
        ),
      ),
      focusColor: AphColors.primary.withValues(alpha: 0.16),
    );
  }
}
