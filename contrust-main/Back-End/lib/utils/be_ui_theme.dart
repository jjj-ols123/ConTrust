import 'package:flutter/material.dart';

/// Centralized UI theme constants for consistent styling across the app
class AppTheme {
  // Button Colors
  static const Color buttonPrimary = Color(0xFFFFB300); 
  static const Color buttonPrimaryDark = Color(0xFFFFA000); 
  static const Color buttonSecondary = Color(0xFF757575); 
  static const Color buttonDanger = Color(0xFFE53935);
  static const Color buttonSuccess = Color(0xFF43A047); 
  
  static const Color headerBackground = Color(0xFFFFF9E6); 
  static const Color headerText = Color(0xFF212121); 
  
  static const Color iconPrimary = Color(0xFFFFB300);
  static const Color iconSecondary = Color(0xFF757575);
  
  static ButtonStyle get standardButtonStyle => ElevatedButton.styleFrom(
    backgroundColor: buttonPrimary,
    foregroundColor: Colors.black,
    minimumSize: const Size.fromHeight(50),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
  );
  
  static ButtonStyle get dangerButtonStyle => ElevatedButton.styleFrom(
    backgroundColor: buttonDanger,
    foregroundColor: Colors.white,
    minimumSize: const Size.fromHeight(50),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
  );
  
  static ButtonStyle get secondaryButtonStyle => ElevatedButton.styleFrom(
    backgroundColor: buttonSecondary,
    foregroundColor: Colors.white,
    minimumSize: const Size.fromHeight(50),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
  );
}

