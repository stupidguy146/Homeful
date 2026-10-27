import 'package:flutter/material.dart';

/// ============================================================
/// DESIGN TOKENS — single source of truth สำหรับทั้งแอป
/// ค่าทุกอย่างในนี้ถูก export ออกไปเป็น design/figma-tokens.json ด้วย
/// (Tokens Studio for Figma format) จึงใช้ตรงกันทั้งโค้ดและ Figma
/// ============================================================

/// ---------- COLOR ----------
class AppColors {
  AppColors._();

  // Brand (homeful blue-grey family) — primary = brand500 #477FA8
  static const Color brand50 = Color(0xFFFAF9F6); // warm white
  static const Color brand100 = Color(0xFFEAF3F8); // soft blue
  static const Color brand200 = Color(0xFFCADEEB);
  static const Color brand300 = Color(0xFF9FC2D6);
  static const Color brand400 = Color(0xFF6FA0BF);
  static const Color brand500 = Color(0xFF477FA8); // primary blue
  static const Color brand600 = Color(0xFF3A6B90);
  static const Color brand700 = Color(0xFF2F5675);
  static const Color brand800 = Color(0xFF26455C);
  static const Color brand900 = Color(0xFF1C3545);

  // Accent (warm amber for highlights / money)
  static const Color accent400 = Color(0xFFF7E7C6); // amber (soft)
  static const Color accent500 = Color(0xFFE8B65C);
  static const Color accent600 = Color(0xFFC98A2B);

  // Semantic — status palette (homeful): ปกติ / ใกล้หมด / ควรซื้อ / หมดแล้ว
  static const Color success = Color(0xFF6FA86F); // ปกติ (sage green)
  static const Color sage = Color(0xFFDCE9D0); // sage tint (chip bg)
  static const Color warning = Color(0xFFD9A441); // ใกล้หมด (amber)
  static const Color amberTint = Color(0xFFF7E7C6);
  static const Color shouldBuy = Color(0xFFE08A4C); // ควรซื้อ (orange)
  static const Color danger = Color(0xFFD98278); // หมดแล้ว (coral)
  static const Color coralTint = Color(0xFFF6DAD5);
  static const Color info = Color(0xFF477FA8); // info = brand blue

  // Neutral / slate (warm-tinted to match homeful)
  static const Color neutral0 = Color(0xFFFFFFFF);
  static const Color neutral50 = Color(0xFFFAF9F6); // warm white (scaffold bg)
  static const Color neutral100 = Color(0xFFF0F3F6); // soft blue-grey
  static const Color neutral200 = Color(0xFFE2E8EE);
  static const Color neutral300 = Color(0xFFCBD5DE);
  static const Color neutral400 = Color(0xFF94A3B3);
  static const Color neutral500 = Color(0xFF64748B);
  static const Color neutral600 = Color(0xFF475569);
  static const Color neutral700 = Color(0xFF334155);
  static const Color neutral800 = Color(0xFF1E293B);
  static const Color neutral900 = Color(0xFF0F172A);

  // Dark surfaces
  static const Color darkBg = Color(0xFF0B1120);
  static const Color darkSurface = Color(0xFF151C2C);
  static const Color darkSurfaceAlt = Color(0xFF1E283B);
}

/// ---------- GRADIENT ----------
class AppGradients {
  AppGradients._();

  static const LinearGradient brand = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.brand500, AppColors.brand700],
  );

  static const LinearGradient brandSoft = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.brand400, AppColors.brand600],
  );

  static const LinearGradient accent = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.accent400, AppColors.accent600],
  );
}

/// ---------- SPACING (4pt scale) ----------
class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;
}

/// ---------- RADIUS ----------
class AppRadius {
  AppRadius._();

  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 28;
  static const double pill = 999;

  static BorderRadius get rSm => BorderRadius.circular(sm);
  static BorderRadius get rMd => BorderRadius.circular(md);
  static BorderRadius get rLg => BorderRadius.circular(lg);
  static BorderRadius get rXl => BorderRadius.circular(xl);
  static BorderRadius get rXxl => BorderRadius.circular(xxl);
}

/// ---------- SHADOW / ELEVATION ----------
class AppShadows {
  AppShadows._();

  static List<BoxShadow> get sm => [
        BoxShadow(
          color: AppColors.neutral900.withValues(alpha: 0.06),
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> get md => [
        BoxShadow(
          color: AppColors.neutral900.withValues(alpha: 0.06),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ];

  static List<BoxShadow> get lg => [
        BoxShadow(
          color: AppColors.neutral900.withValues(alpha: 0.10),
          blurRadius: 28,
          offset: const Offset(0, 12),
        ),
      ];

  static List<BoxShadow> brandGlow(Color c) => [
        BoxShadow(
          color: c.withValues(alpha: 0.30),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ];
}

/// ---------- TYPOGRAPHY ----------
/// ขนาด/น้ำหนัก/line-height กลาง (ใช้ชื่อตาม Material type scale)
class AppType {
  AppType._();

  static const String fontFamily = 'Roboto';

  static const TextStyle displayLarge = TextStyle(
      fontSize: 34, fontWeight: FontWeight.w800, height: 1.15, letterSpacing: -0.5);
  static const TextStyle headlineMedium = TextStyle(
      fontSize: 26, fontWeight: FontWeight.w700, height: 1.2, letterSpacing: -0.3);
  static const TextStyle titleLarge =
      TextStyle(fontSize: 20, fontWeight: FontWeight.w700, height: 1.25);
  static const TextStyle titleMedium =
      TextStyle(fontSize: 16, fontWeight: FontWeight.w600, height: 1.3);
  static const TextStyle bodyLarge =
      TextStyle(fontSize: 15, fontWeight: FontWeight.w400, height: 1.4);
  static const TextStyle bodyMedium =
      TextStyle(fontSize: 13.5, fontWeight: FontWeight.w400, height: 1.4);
  static const TextStyle label =
      TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, letterSpacing: 0.2);
    static const TextStyle caption = TextStyle(
      fontSize: 11.5, fontWeight: FontWeight.w500, letterSpacing: 0.3, height: 1.3);
}

/// ---------- DURATION ----------
class AppDurations {
  AppDurations._();
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 400);
}

/// ---------- STATUS (4 แบบตาม homeful) ----------
/// ปกติ / ใกล้หมด / ควรซื้อ / หมดแล้ว — ใช้กับ status chip
enum StockStatus { normal, low, shouldBuy, out }

class AppStatus {
  AppStatus._();

  /// สีตัวอักษร/ไอคอนของแต่ละสถานะ
  static Color fg(StockStatus s) {
    switch (s) {
      case StockStatus.normal:
        return AppColors.success;
      case StockStatus.low:
        return AppColors.warning;
      case StockStatus.shouldBuy:
        return AppColors.shouldBuy;
      case StockStatus.out:
        return AppColors.danger;
    }
  }

  /// สีพื้นชิป (tint อ่อน) ของแต่ละสถานะ
  static Color bg(StockStatus s) {
    switch (s) {
      case StockStatus.normal:
        return AppColors.sage;
      case StockStatus.low:
        return AppColors.amberTint;
      case StockStatus.shouldBuy:
        return AppColors.amberTint;
      case StockStatus.out:
        return AppColors.coralTint;
    }
  }

  /// map จาก daysUntilExpiry → สถานะ (null = ไม่ระบุวันหมด → ปกติ)
  /// out: เลยกำหนด, shouldBuy: <=3, low: <=7, normal: อื่น ๆ
  static StockStatus fromDays(int? days) {
    if (days == null) return StockStatus.normal;
    if (days < 0) return StockStatus.out;
    if (days <= 3) return StockStatus.shouldBuy;
    if (days <= 7) return StockStatus.low;
    return StockStatus.normal;
  }
}
