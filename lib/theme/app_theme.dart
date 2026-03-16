import 'package:flutter/material.dart';

class AppColors {
  // Ana Renkler
  static const Color primary = Color(0xFF1A3A5C);      // Koyu lacivert
  static const Color secondary = Color(0xFF2196F3);     // Mavi
  static const Color accent = Color(0xFF00BCD4);        // Cyan

  // Memnuniyet Renkleri
  static const Color satisfied = Color(0xFF2ECC71);     // Yeşil - Memnun
  static const Color neutral = Color(0xFFF39C12);       // Sarı - Orta
  static const Color unsatisfied = Color(0xFFE74C3C);   // Kırmızı - Memnun değil
  static const Color noData = Color(0xFF95A5A6);        // Gri - Veri yok

  // Kategori Renkleri
  static const Color cleaning = Color(0xFF27AE60);
  static const Color road = Color(0xFFE67E22);
  static const Color security = Color(0xFFE74C3C);
  static const Color park = Color(0xFF2ECC71);
  static const Color transport = Color(0xFF3498DB);
  static const Color social = Color(0xFF9B59B6);

  // Background
  static const Color background = Color(0xFFF5F7FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color cardBg = Color(0xFFFFFFFF);

  // Text
  static const Color textPrimary = Color(0xFF1A2332);
  static const Color textSecondary = Color(0xFF6B7A8D);
  static const Color textLight = Color(0xFFB0BEC5);
}

class AppTheme {
  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: 'SF Pro Display',
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      cardTheme: const CardThemeData(
        color: AppColors.cardBg,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.all(Radius.circular(16)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
    );
  }
}

// Memnuniyet seviyesi enum
enum SatisfactionLevel {
  high,    // %70+  → Yeşil
  medium,  // %40-70 → Sarı
  low,     // <%40  → Kırmızı
  noData,  // Veri yok → Gri
}

extension SatisfactionExtension on SatisfactionLevel {
  Color get color {
    switch (this) {
      case SatisfactionLevel.high:
        return AppColors.satisfied;
      case SatisfactionLevel.medium:
        return AppColors.neutral;
      case SatisfactionLevel.low:
        return AppColors.unsatisfied;
      case SatisfactionLevel.noData:
        return AppColors.noData;
    }
  }

  String get label {
    switch (this) {
      case SatisfactionLevel.high:
        return 'Memnun';
      case SatisfactionLevel.medium:
        return 'Orta';
      case SatisfactionLevel.low:
        return 'Memnun Değil';
      case SatisfactionLevel.noData:
        return 'Veri Yok';
    }
  }

  String get emoji {
    switch (this) {
      case SatisfactionLevel.high:
        return '😊';
      case SatisfactionLevel.medium:
        return '😐';
      case SatisfactionLevel.low:
        return '😞';
      case SatisfactionLevel.noData:
        return '❓';
    }
  }
}

SatisfactionLevel getSatisfactionLevel(double score) {
  if (score >= 70) return SatisfactionLevel.high;
  if (score >= 40) return SatisfactionLevel.medium;
  if (score > 0) return SatisfactionLevel.low;
  return SatisfactionLevel.noData;
}
