import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTypography {
  static TextStyle displayLarge = GoogleFonts.inter(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
    height: 1.2,
  );

  static TextStyle displayMedium = GoogleFonts.inter(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
    height: 1.25,
  );

  static TextStyle titleLarge = GoogleFonts.inter(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static TextStyle titleMedium = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static TextStyle bodyLarge = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
  );

  static TextStyle bodyMedium = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
  );

  static TextStyle labelLarge = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static TextStyle labelSmall = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.textMuted,
  );
}
