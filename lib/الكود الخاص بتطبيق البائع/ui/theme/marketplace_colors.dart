import 'package:flutter/material.dart';

/// ألوان السوق الإلكتروني الاحترافية
class MarketplaceColors {
  // الألوان الأساسية للتدرج
  static const Color primaryBlue = Color(0xFF6366F1);
  static const Color primaryPurple = Color(0xFF8B5CF6);
  static const Color primaryPink = Color(0xFFEC4899);
  
  // ألوان النجاح والتحذير
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);
  
  // ألوان النص
  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textLight = Color(0xFF9CA3AF);
  
  // ألوان الخلفية
  static const Color backgroundLight = Color(0xFFF8FAFC);
  static const Color backgroundWhite = Color(0xFFFFFFFF);
  static const Color backgroundGray = Color(0xFFF1F5F9);
  
  // ألوان الحدود والظلال
  static const Color borderLight = Color(0xFFE2E8F0);
  static const Color borderMedium = Color(0xFFCBD5E1);
  static const Color shadowLight = Color(0x1A000000);
  static const Color shadowMedium = Color(0x26000000);
  
  // تدرجات الألوان
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryBlue, primaryPurple, primaryPink],
  );
  
  static const LinearGradient successGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF10B981), Color(0xFF059669)],
  );
  
  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0x1A6366F1),
      Color(0x1A8B5CF6),
    ],
  );
  
  // ظلال مخصصة
  static List<BoxShadow> get softShadow => [
    BoxShadow(
      color: shadowLight,
      spreadRadius: 0,
      blurRadius: 10,
      offset: const Offset(0, 2),
    ),
  ];
  
  static List<BoxShadow> get mediumShadow => [
    BoxShadow(
      color: shadowMedium,
      spreadRadius: 0,
      blurRadius: 15,
      offset: const Offset(0, 4),
    ),
  ];
  
  static List<BoxShadow> get primaryShadow => [
    BoxShadow(
      color: primaryBlue.withOpacity(0.3),
      spreadRadius: 0,
      blurRadius: 20,
      offset: const Offset(0, 10),
    ),
  ];
  
  // ألوان الحالة
  static const Color activeStore = success;
  static const Color inactiveStore = Color(0xFF94A3B8);
  static const Color verifiedBadge = success;
  static const Color premiumBadge = Color(0xFFFF6B6B);
}

/// أنماط النصوص المخصصة
class MarketplaceTextStyles {
  static const TextStyle heading1 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: MarketplaceColors.textPrimary,
    height: 1.2,
  );
  
  static const TextStyle heading2 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: MarketplaceColors.textPrimary,
    height: 1.3,
  );
  
  static const TextStyle heading3 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: MarketplaceColors.textPrimary,
    height: 1.4,
  );
  
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: MarketplaceColors.textPrimary,
    height: 1.5,
  );
  
  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: MarketplaceColors.textSecondary,
    height: 1.5,
  );
  
  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: MarketplaceColors.textLight,
    height: 1.4,
  );
  
  static const TextStyle button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.0,
  );
  
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: MarketplaceColors.textLight,
  );
}

/// مفاتيح الانيميشن والمدة
class MarketplaceAnimations {
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration medium = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
  static const Duration staggered = Duration(milliseconds: 600);
  
  static const Curve easeInOut = Curves.easeInOut;
  static const Curve easeOutBack = Curves.easeOutBack;
  static const Curve elasticOut = Curves.elasticOut;
}

/// أبعاد وحشو مخصص
class MarketplaceDimensions {
  // الحشو
  static const double paddingTiny = 4.0;
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;
  static const double paddingXLarge = 32.0;
  
  // المسافات
  static const double spaceTiny = 4.0;
  static const double spaceSmall = 8.0;
  static const double spaceMedium = 16.0;
  static const double spaceLarge = 24.0;
  static const double spaceXLarge = 32.0;
  
  // نصف الأقطار
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusXLarge = 20.0;
  static const double radiusRound = 30.0;
  
  // أحجام الأيقونات
  static const double iconSmall = 16.0;
  static const double iconMedium = 20.0;
  static const double iconLarge = 24.0;
  static const double iconXLarge = 32.0;
  
  // أحجام الصور
  static const double imageSmall = 60.0;
  static const double imageMedium = 80.0;
  static const double imageLarge = 120.0;
  
  // ارتفاع العناصر
  static const double buttonHeight = 48.0;
  static const double inputHeight = 56.0;
  static const double cardMinHeight = 120.0;
} 