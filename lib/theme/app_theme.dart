import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Midnight + Coral palette.
/// Every color in the app comes from here — screens never hard-code hex values.
class AppColors {
  AppColors._();

  // Surfaces (darkest → lightest)
  static const bg = Color(0xFF0E1116);
  static const surface = Color(0xFF171B22);
  static const surfaceRaised = Color(0xFF1E232B);

  // Lines
  static const border = Color(0xFF2A3039);
  static const borderStrong = Color(0xFF3A414C);

  // Text
  static const text = Color(0xFFE6E8EB);
  static const textSecondary = Color(0xFFA1A8B3);
  static const textMuted = Color(0xFF7C8694);

  // Brand accent
  static const accent = Color(0xFFFF7A59);
  static const accentHover = Color(0xFFFF8F73);
  static const onAccent = Color(0xFF1A0A04);
  static const accentSoft = Color(0x1FFF7A59);

  // Semantic
  static const success = Color(0xFF3DD68C);
  static const successSoft = Color(0x1F3DD68C);
  static const info = Color(0xFF6CB6FF);
  static const infoSoft = Color(0x1F6CB6FF);
  static const warning = Color(0xFFF5B84B);
  static const warningSoft = Color(0x1FF5B84B);
  static const danger = Color(0xFFF2555A);
  static const dangerSoft = Color(0x1FF2555A);

  /// Color for an overall rating label returned by the evaluator.
  static Color forRating(String rating) {
    switch (rating) {
      case 'Excellent':
        return success;
      case 'Good':
        return info;
      case 'Average':
        return warning;
      default:
        return danger;
    }
  }

  /// Color for a per-criterion rating name ('green', 'blue', 'orange', ...).
  static Color forColorName(String name) {
    switch (name) {
      case 'green':
        return success;
      case 'blue':
        return info;
      case 'orange':
        return warning;
      default:
        return danger;
    }
  }
}

/// Shared motion tokens so every animation in the app feels like one system.
class AppMotion {
  AppMotion._();

  static const fast = Duration(milliseconds: 150);
  static const base = Duration(milliseconds: 280);
  static const slow = Duration(milliseconds: 450);
  static const emphasis = Duration(milliseconds: 1100);

  static const enter = Curves.easeOutCubic;
  static const exit = Curves.easeInCubic;
  static const stagger = Duration(milliseconds: 60);
}

class AppRadius {
  AppRadius._();
  static const sm = 10.0;
  static const md = 14.0;
  static const lg = 18.0;
}

class AppTheme {
  AppTheme._();

  static ThemeData? _dark;

  /// Built once and cached — the app rebuilds MaterialApp on language change.
  static ThemeData dark() => _dark ??= _buildDark();

  static ThemeData _buildDark() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
    );

    final textTheme = GoogleFonts.ibmPlexSansArabicTextTheme(base.textTheme)
        .apply(bodyColor: AppColors.text, displayColor: AppColors.text);

    const colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: AppColors.accent,
      onPrimary: AppColors.onAccent,
      secondary: AppColors.accent,
      onSecondary: AppColors.onAccent,
      error: AppColors.danger,
      onError: AppColors.bg,
      surface: AppColors.surface,
      onSurface: AppColors.text,
      onSurfaceVariant: AppColors.textSecondary,
      surfaceContainerLowest: AppColors.bg,
      surfaceContainerLow: AppColors.surface,
      surfaceContainer: AppColors.surface,
      surfaceContainerHigh: AppColors.surfaceRaised,
      surfaceContainerHighest: AppColors.surfaceRaised,
      outline: AppColors.borderStrong,
      outlineVariant: AppColors.border,
    );

    OutlineInputBorder inputBorder(Color c, [double w = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: BorderSide(color: c, width: w),
        );

    return base.copyWith(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.bg,
      canvasColor: AppColors.bg,
      textTheme: textTheme,
      dividerColor: AppColors.border,
      dividerTheme:
          const DividerThemeData(color: AppColors.border, thickness: 1),
      iconTheme: const IconThemeData(color: AppColors.textSecondary),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.bg,
        foregroundColor: AppColors.text,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
          fontSize: 17,
          color: AppColors.text,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: AppColors.onAccent,
          disabledBackgroundColor: AppColors.surfaceRaised,
          disabledForegroundColor: AppColors.textMuted,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md)),
          textStyle: textTheme.titleSmall
              ?.copyWith(fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.text,
          side: const BorderSide(color: AppColors.borderStrong),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md)),
          textStyle: textTheme.titleSmall
              ?.copyWith(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.accent,
          textStyle:
              textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.bg,
        hintStyle: const TextStyle(fontSize: 13, color: AppColors.textMuted),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        border: inputBorder(AppColors.border),
        enabledBorder: inputBorder(AppColors.border),
        disabledBorder: inputBorder(AppColors.border),
        focusedBorder: inputBorder(AppColors.accent, 1.5),
        errorBorder: inputBorder(AppColors.danger),
        focusedErrorBorder: inputBorder(AppColors.danger, 1.5),
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: AppColors.accent,
        selectionColor: Color(0x55FF7A59),
        selectionHandleColor: AppColors.accent,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.accent,
        linearTrackColor: AppColors.surfaceRaised,
        circularTrackColor: AppColors.surfaceRaised,
      ),
      sliderTheme: const SliderThemeData(
        activeTrackColor: AppColors.accent,
        inactiveTrackColor: AppColors.border,
        thumbColor: AppColors.accent,
        overlayColor: AppColors.accentSoft,
        trackHeight: 4,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surfaceRaised,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: AppColors.text),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm)),
      ),
      listTileTheme: const ListTileThemeData(
        textColor: AppColors.text,
        iconColor: AppColors.textSecondary,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: AppColors.surfaceRaised,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        textStyle: const TextStyle(color: AppColors.text, fontSize: 12),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(builders: {
        TargetPlatform.android: FadeSlidePageTransitionsBuilder(),
        TargetPlatform.iOS: FadeSlidePageTransitionsBuilder(),
        TargetPlatform.macOS: FadeSlidePageTransitionsBuilder(),
        TargetPlatform.windows: FadeSlidePageTransitionsBuilder(),
        TargetPlatform.linux: FadeSlidePageTransitionsBuilder(),
        TargetPlatform.fuchsia: FadeSlidePageTransitionsBuilder(),
      }),
    );
  }
}

/// Every screen change: the new page fades in while rising a few pixels,
/// and the page underneath dims slightly.
class FadeSlidePageTransitionsBuilder extends PageTransitionsBuilder {
  const FadeSlidePageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (MediaQuery.maybeOf(context)?.disableAnimations ?? false) return child;

    final incoming = CurvedAnimation(
      parent: animation,
      curve: AppMotion.enter,
      reverseCurve: AppMotion.exit,
    );
    final outgoing = CurvedAnimation(
      parent: secondaryAnimation,
      curve: AppMotion.enter,
      reverseCurve: AppMotion.exit,
    );

    return FadeTransition(
      opacity: Tween<double>(begin: 1, end: 0.6).animate(outgoing),
      child: FadeTransition(
        opacity: incoming,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.035),
            end: Offset.zero,
          ).animate(incoming),
          child: child,
        ),
      ),
    );
  }
}
