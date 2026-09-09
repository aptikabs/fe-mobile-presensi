import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors (Brand Red)
  static const Color primary50 = Color(0xFFF0FFF7);
  static const Color primary100 = Color(0xFFD9F7E8);
  static const Color primary200 = Color(0xFFB3EFD1);
  static const Color primary300 = Color(0xFF66D9A3);
  static const Color primary400 = Color(0xFF33BA79);
  static const Color primary500 = Color(0xFF009B4F);
  static const Color primary600 = Color(0xFF008A46);
  static const Color primary700 = Color(0xFF00753C);
  static const Color primary800 = Color(0xFF005F31);
  static const Color primary900 = Color(0xFF004A26);

  // Secondary Colors (Blue)
  static const Color secondary100 = Color(0xFFDBEAFE);
  static const Color secondary200 = Color(0xFFBFDBFE);
  static const Color secondary300 = Color(0xFF93C5FD);
  static const Color secondary400 = Color(0xFF60A5FA);
  static const Color secondary500 = Color(0xFF3B82F6);
  static const Color secondary600 = Color(0xFF2563EB);
  static const Color secondary700 = Color(0xFF1D4ED8);
  static const Color secondary800 = Color(0xFF1E40AF);
  static const Color secondary900 = Color(0xFF1E3A8A);

  // Neutral Colors (Greys)
  static const Color neutral50 = Color(0xFFF9FAFB);
  static const Color neutral100 = Color(0xFFF3F4F6);
  static const Color neutral200 = Color(0xFFE5E7EB);
  static const Color neutral300 = Color(0xFFD1D5DB);
  static const Color neutral400 = Color(0xFF9CA3AF);
  static const Color neutral500 = Color(0xFF6B7280);
  static const Color neutral600 = Color(0xFF4B5563);
  static const Color neutral700 = Color(0xFF374151);
  static const Color neutral800 = Color(0xFF1F2937);
  static const Color neutral900 = Color(0xFF111827);

  // Success Colors (Green)
  static const Color success50 = Color(0xFFF0FDF4);
  static const Color success100 = Color(0xFFDCFCE7);
  static const Color success200 = Color(0xFFBBF7D0);
  static const Color success300 = Color(0xFF86EFAC);
  static const Color success400 = Color(0xFF4ADE80);
  static const Color success500 = Color(0xFF22C55E);
  static const Color success600 = Color(0xFF16A34A);
  static const Color success700 = Color(0xFF15803D);
  static const Color success800 = Color(0xFF166534);
  static const Color success900 = Color(0xFF14532D);

  // Info Colors (Sky Blue)
  static const Color info100 = Color(0xFFE0F2FE);
  static const Color info200 = Color(0xFFBAE6FD);
  static const Color info300 = Color(0xFF7DD3FC);
  static const Color info400 = Color(0xFF38BDF8);
  static const Color info500 = Color(0xFF0EA5E9);
  static const Color info600 = Color(0xFF0284C7);
  static const Color info700 = Color(0xFF0369A1);
  static const Color info800 = Color(0xFF075985);
  static const Color info900 = Color(0xFF0C4A6E);

  // Warning Colors (Amber)
  static const Color warning100 = Color(0xFFFEF3C7);
  static const Color warning200 = Color(0xFFFDE68A);
  static const Color warning300 = Color(0xFFFCD34D);
  static const Color warning400 = Color(0xFFFBBF24);
  static const Color warning500 = Color(0xFFF59E0B);
  static const Color warning600 = Color(0xFFD97706);
  static const Color warning700 = Color(0xFFB45309);
  static const Color warning800 = Color(0xFF92400E);
  static const Color warning900 = Color(0xFF78350F);

  // Danger Colors (Red - distinct from Primary)
  static const Color danger50 = Color(0xFFFEF2F2);
  static const Color danger100 = Color(0xFFFEE2E2);
  static const Color danger200 = Color(0xFFFECACA);
  static const Color danger300 = Color(0xFFFCA5A5);
  static const Color danger400 = Color(0xFFF87171);
  static const Color danger500 = Color(0xFFEF4444);
  static const Color danger600 = Color(0xFFDC2626);
  static const Color danger700 = Color(0xFFB91C1C);
  static const Color danger800 = Color(0xFF991B1B);
  static const Color danger900 = Color(0xFF7F1D1D);

  // Aliases for easier use
  static const Color success = success500;
  static const Color info = info500;
  static const Color warning = warning500;
  static const Color danger = danger500;
  static const Color error = danger500;

  // Background Colors
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color background = Color(0xFFF9FAFB);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color scaffoldBackground = Color(0xFFF3F4F6);

  // Text Colors
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textDisabled = Color(0xFF9CA3AF);
  static const Color textInverse = Color(0xFFFFFFFF);

  // Button Colors
  static const Color buttonPrimary = secondary500;
  static const Color buttonSecondary = primary500;
  static const Color buttonDisabled = neutral300;

  // Border Colors
  static const Color border = neutral200;
  static const Color borderFocus = secondary500;
  static const Color borderError = danger500;

  // Other
  static const Color divider = neutral200;
  static const Color shadow = Color(0x1A000000);
  static const Color overlay = Color(0x80000000);
}
