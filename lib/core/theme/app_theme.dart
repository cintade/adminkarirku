import 'package:flutter/material.dart';

class AppColors {
  // Sidebar
  static const sidebarBg = Color(0xFF1A2332);
  static const sidebarActive = Color(0xFF2D3F55);
  static const sidebarText = Color(0xFFB0BEC5);
  static const sidebarTextActive = Colors.white;
  static const sidebarAccent = Color(0xFF4FC3F7);

  // Content
  static const pageBg = Color(0xFFF5F7FA);
  static const cardBg = Colors.white;
  static const border = Color(0xFFE8ECF0);

  // Text
  static const textPrimary = Color(0xFF1A2332);
  static const textSecondary = Color(0xFF6B7A8D);
  static const textMuted = Color(0xFF9AA5B4);

  // Accents
  static const primary = Color(0xFF1565C0);
  static const primaryLight = Color(0xFFE3F2FD);
  static const success = Color(0xFF2E7D32);
  static const successLight = Color(0xFFE8F5E9);
  static const danger = Color(0xFFC62828);
  static const dangerLight = Color(0xFFFFEBEE);
  static const warning = Color(0xFFE65100);

  // RIASEC badge colors
  static const badgeR = Color(0xFF1565C0);
  static const badgeI = Color(0xFF6A1B9A);
  static const badgeA = Color(0xFFAD1457);
  static const badgeS = Color(0xFF2E7D32);
  static const badgeE = Color(0xFFE65100);
  static const badgeC = Color(0xFF00695C);
}

class AppTheme {
  static ThemeData get light => ThemeData(
    useMaterial3: true,
    fontFamily: 'Poppins',
    scaffoldBackgroundColor: AppColors.pageBg,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      background: AppColors.pageBg,
    ),
    cardTheme: CardThemeData(
      color: AppColors.cardBg,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
    ),
  );
}
