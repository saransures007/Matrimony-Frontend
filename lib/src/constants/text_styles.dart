import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'color_constants.dart';

class AppTextStyles {
  // Headings - Light Theme
  static TextStyle h1Light = GoogleFonts.poppins(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimaryLight,
  );
  
  static TextStyle h2Light = GoogleFonts.poppins(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimaryLight,
  );
  
  static TextStyle h3Light = GoogleFonts.poppins(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimaryLight,
  );
  
  static TextStyle h4Light = GoogleFonts.poppins(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimaryLight,
  );
  
  static TextStyle h5Light = GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimaryLight,
  );
  
  // Headings - Dark Theme
  static TextStyle h1Dark = GoogleFonts.poppins(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimaryDark,
  );
  
  static TextStyle h2Dark = GoogleFonts.poppins(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimaryDark,
  );
  
  static TextStyle h3Dark = GoogleFonts.poppins(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimaryDark,
  );
  
  static TextStyle h4Dark = GoogleFonts.poppins(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimaryDark,
  );
  
  static TextStyle h5Dark = GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimaryDark,
  );
  
  // Body Text - Light Theme
  static TextStyle bodyLargeLight = GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimaryLight,
  );
  
  static TextStyle bodyMediumLight = GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimaryLight,
  );
  
  static TextStyle bodySmallLight = GoogleFonts.poppins(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondaryLight,
  );
  
  // Body Text - Dark Theme
  static TextStyle bodyLargeDark = GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimaryDark,
  );
  
  static TextStyle bodyMediumDark = GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimaryDark,
  );
  
  static TextStyle bodySmallDark = GoogleFonts.poppins(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondaryDark,
  );
  
  // Button Text
  static TextStyle buttonLarge = GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );
  
  static TextStyle buttonMedium = GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );
  
  static TextStyle buttonSmall = GoogleFonts.poppins(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );
  
  // Special Text Styles
  static TextStyle appBarTitle = GoogleFonts.poppins(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );
  
  static TextStyle tabLabel = GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.w500,
  );
  
  static TextStyle caption = GoogleFonts.poppins(
    fontSize: 11,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondaryLight,
  );
  
  static TextStyle captionDark = GoogleFonts.poppins(
    fontSize: 11,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondaryDark,
  );
}
