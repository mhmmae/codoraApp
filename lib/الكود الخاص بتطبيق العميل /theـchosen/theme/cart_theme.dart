import 'package:flutter/material.dart';

/// كلاس يحتوي على الألوان والثيمات الموحدة لصفحة السلة
class CartTheme {
  // الألوان الأساسية
  static const Color primaryColor = Color(0xFF667EEA);
  static const Color secondaryColor = Color(0xFF764BA2);
  static const Color accentColor = Color(0xFF00C851);
  static const Color errorColor = Color(0xFFFF4444);
  static const Color warningColor = Color(0xFFFF8800);
  static const Color successColor = Color(0xFF00C851);
  
  // الألوان الرمادية
  static const Color lightGrey = Color(0xFFF8F9FA);
  static const Color mediumGrey = Color(0xFFE9ECEF);
  static const Color darkGrey = Color(0xFF6C757D);
  static const Color textGrey = Color(0xFF495057);
  
  // التدرجات اللونية
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryColor, secondaryColor],
  );
  
  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [lightGrey, mediumGrey],
  );
  
  static const LinearGradient buttonGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [primaryColor, secondaryColor],
  );
  
  // الظلال
  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.05),
      blurRadius: 10,
      spreadRadius: 2,
      offset: const Offset(0, 2),
    ),
  ];
  
  static List<BoxShadow> get headerShadow => [
    const BoxShadow(
      color: Colors.black12,
      blurRadius: 10,
      offset: Offset(0, 2),
    ),
  ];
  
  static List<BoxShadow> get buttonShadow => [
    BoxShadow(
      color: primaryColor.withOpacity(0.3),
      blurRadius: 8,
      offset: const Offset(0, 4),
    ),
  ];
  
  // أنماط النصوص
  static TextStyle headerTextStyle(double fontSize) => TextStyle(
    fontSize: fontSize,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );
  
  static TextStyle subHeaderTextStyle(double fontSize) => TextStyle(
    fontSize: fontSize,
    fontWeight: FontWeight.w600,
    color: Colors.white70,
  );
  
  static TextStyle titleTextStyle(double fontSize) => TextStyle(
    fontSize: fontSize,
    fontWeight: FontWeight.w600,
    color: textGrey,
  );
  
  static TextStyle bodyTextStyle(double fontSize) => TextStyle(
    fontSize: fontSize,
    fontWeight: FontWeight.w500,
    color: darkGrey,
  );
  
  static TextStyle priceTextStyle(double fontSize) => TextStyle(
    fontSize: fontSize,
    fontWeight: FontWeight.w600,
    color: primaryColor,
  );
  
  static TextStyle currencyTextStyle(double fontSize) => TextStyle(
    fontSize: fontSize,
    fontWeight: FontWeight.w500,
    color: accentColor,
  );
  
  // أنماط الحاويات
  static BoxDecoration get cardDecoration => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    boxShadow: cardShadow,
  );
  
  static BoxDecoration get headerDecoration => BoxDecoration(
    gradient: primaryGradient,
    borderRadius: const BorderRadius.only(
      bottomLeft: Radius.circular(25),
      bottomRight: Radius.circular(25),
    ),
    boxShadow: headerShadow,
  );
  
  static BoxDecoration get buttonDecoration => BoxDecoration(
    gradient: buttonGradient,
    borderRadius: BorderRadius.circular(16),
    boxShadow: buttonShadow,
  );
  
  static BoxDecoration get inputDecoration => BoxDecoration(
    color: lightGrey,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: mediumGrey),
  );
  
  // أنماط الأزرار
  static ButtonStyle get primaryButtonStyle => ElevatedButton.styleFrom(
    backgroundColor: primaryColor,
    foregroundColor: Colors.white,
    elevation: 3,
    shadowColor: primaryColor.withOpacity(0.3),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
  );
  
  static ButtonStyle get secondaryButtonStyle => ElevatedButton.styleFrom(
    backgroundColor: Colors.white,
    foregroundColor: primaryColor,
    elevation: 2,
    shadowColor: Colors.black12,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: BorderSide(color: primaryColor.withOpacity(0.3)),
    ),
  );
  
  // الأيقونات
  static Widget primaryIcon(IconData icon, {double size = 24}) => Container(
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(
      color: primaryColor.withOpacity(0.1),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Icon(
      icon,
      color: primaryColor,
      size: size,
    ),
  );
  
  static Widget backgroundIcon(IconData icon, {double size = 24}) => Container(
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.2),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Icon(
      icon,
      color: Colors.white,
      size: size,
    ),
  );
  
  // الحالات الخاصة
  static BoxDecoration get errorCardDecoration => BoxDecoration(
    color: errorColor.withOpacity(0.1),
    borderRadius: BorderRadius.circular(8),
    border: Border.all(color: errorColor.withOpacity(0.3)),
  );
  
  static BoxDecoration get successCardDecoration => BoxDecoration(
    color: successColor.withOpacity(0.1),
    borderRadius: BorderRadius.circular(8),
    border: Border.all(color: successColor.withOpacity(0.3)),
  );
  
  static BoxDecoration get warningCardDecoration => BoxDecoration(
    color: warningColor.withOpacity(0.1),
    borderRadius: BorderRadius.circular(8),
    border: Border.all(color: warningColor.withOpacity(0.3)),
  );
  
  // الرسوم المتحركة
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration quickAnimationDuration = Duration(milliseconds: 150);
  
  // الأبعاد المعيارية
  static const double borderRadius = 16.0;
  static const double smallBorderRadius = 8.0;
  static const double largeBorderRadius = 25.0;
  
  static const double smallPadding = 8.0;
  static const double mediumPadding = 16.0;
  static const double largePadding = 24.0;
  
  static const double smallMargin = 4.0;
  static const double mediumMargin = 8.0;
  static const double largeMargin = 16.0;
} 