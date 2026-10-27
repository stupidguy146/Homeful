import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_tokens.dart';

/// ============================================================
/// APP THEME — สร้าง ThemeData จาก design tokens
/// ทุกหน้าใช้ค่าเดียวกันผ่าน Theme.of(context)
/// ============================================================
class AppTheme {
  AppTheme._();

  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.brand500,
      primary: AppColors.brand500,
      secondary: AppColors.accent500,
      error: AppColors.danger,
      surface: AppColors.neutral0,
      brightness: Brightness.light,
    );
    return _base(scheme, AppColors.neutral50, AppColors.neutral0);
  }

  static ThemeData get dark {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.brand500,
      primary: AppColors.brand400,
      secondary: AppColors.accent500,
      error: AppColors.danger,
      surface: AppColors.darkSurface,
      brightness: Brightness.dark,
    );
    return _base(scheme, AppColors.darkBg, AppColors.darkSurface);
  }

  static ThemeData _base(
    ColorScheme scheme,
    Color scaffoldBg,
    Color cardBg,
  ) {
    final isDark = scheme.brightness == Brightness.dark;
    final onSurface = isDark ? AppColors.neutral100 : AppColors.neutral900;
    final onSurfaceMuted =
        isDark ? AppColors.neutral400 : AppColors.neutral500;

    final textTheme = GoogleFonts.notoSansThaiTextTheme(
      TextTheme(
        displayLarge: AppType.displayLarge.copyWith(color: onSurface),
        headlineMedium: AppType.headlineMedium.copyWith(color: onSurface),
        titleLarge: AppType.titleLarge.copyWith(color: onSurface),
        titleMedium: AppType.titleMedium.copyWith(color: onSurface),
        bodyLarge: AppType.bodyLarge.copyWith(color: onSurface),
        bodyMedium: AppType.bodyMedium.copyWith(color: onSurfaceMuted),
        labelLarge: AppType.label.copyWith(color: onSurface),
        bodySmall: AppType.caption.copyWith(color: onSurfaceMuted),
      ),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scaffoldBg,
      canvasColor: cardBg,
      dividerColor: isDark ? AppColors.neutral800 : AppColors.neutral200,
      fontFamily: GoogleFonts.notoSansThai().fontFamily,
      textTheme: textTheme,
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: scaffoldBg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: AppType.titleLarge.copyWith(color: onSurface),
        iconTheme: IconThemeData(color: onSurface),
      ),
      cardTheme: CardThemeData(
        color: cardBg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.rLg),
      ),
      dividerTheme: DividerThemeData(
        color: isDark ? AppColors.neutral800 : AppColors.neutral200,
        thickness: 1,
        space: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? AppColors.darkSurfaceAlt : AppColors.neutral100,
        contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        border: OutlineInputBorder(
          borderRadius: AppRadius.rMd,
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.rMd,
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.rMd,
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
        labelStyle: TextStyle(color: onSurfaceMuted),
        floatingLabelStyle: TextStyle(color: scheme.primary),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl, vertical: AppSpacing.md),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.rMd),
          textStyle: AppType.titleMedium,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          textStyle: AppType.titleMedium,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        highlightElevation: 0,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.rLg),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.neutral800,
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.rMd),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: cardBg,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.rXl),
        titleTextStyle: AppType.titleLarge.copyWith(color: onSurface),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: cardBg,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xxl)),
        ),
      ),
    );
  }
}
