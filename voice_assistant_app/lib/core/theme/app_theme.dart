import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Colors.teal;
  static const Color accent = Colors.orange;
  static const Color background = Color(0xFFF8F9FA);
  static const Color tileBlue = Color(0xFF4A90E2);
  static const Color tileGreen = Color(0xFF50E3C2);
  static const Color tilePink = Color(0xFFFF6F91);
  static const Color tileYellow = Color(0xFFFFC75F);
  static const Color tilePurple = Color(0xFFA993FF);
  static const Color tileRed = Color(0xFFFF8A65);
}

class AppTextStyles {
  static const TextStyle tileTitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );

  static const TextStyle header = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: Colors.black87,
  );

  static const TextStyle buttonText = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: Colors.white,
  );

  // 🔹 Added for new Splash/Menu screens
  static const TextStyle titleText = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: Colors.black87,
  );

  static const TextStyle menuTileText = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: ColorScheme.fromSwatch().copyWith(
        primary: AppColors.primary,
        secondary: AppColors.accent,
      ),
      textTheme: const TextTheme(
        titleLarge: AppTextStyles.titleText,
        bodyMedium: AppTextStyles.header,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primary,
        elevation: 0,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),
    );
  }
}
