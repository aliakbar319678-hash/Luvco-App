import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  static TextStyle heading1(BuildContext context) {
    final scale = MediaQuery.sizeOf(context).width / 390;
    return GoogleFonts.inter(
      fontSize: 28 * scale.clamp(0.85, 1.3),
      fontWeight: FontWeight.w700,
      color: AppColors.black,
      height: 1.2,
    );
  }

  static TextStyle subtitle(BuildContext context) {
    final scale = MediaQuery.sizeOf(context).width / 390;
    return GoogleFonts.inter(
      fontSize: 14 * scale.clamp(0.85, 1.3),
      fontWeight: FontWeight.w400,
      color: AppColors.darkGrey,
      height: 1.4,
    );
  }

  static TextStyle label(BuildContext context) {
    final scale = MediaQuery.sizeOf(context).width / 390;
    return GoogleFonts.inter(
      fontSize: 14 * scale.clamp(0.85, 1.3),
      fontWeight: FontWeight.w500,
      color: AppColors.black,
    );
  }

  static TextStyle hint(BuildContext context) {
    final scale = MediaQuery.sizeOf(context).width / 390;
    return GoogleFonts.inter(
      fontSize: 14 * scale.clamp(0.85, 1.3),
      fontWeight: FontWeight.w400,
      color: AppColors.neutralGrey,
    );
  }

  static TextStyle button(BuildContext context) {
    final scale = MediaQuery.sizeOf(context).width / 390;
    return GoogleFonts.inter(
      fontSize: 16 * scale.clamp(0.85, 1.3),
      fontWeight: FontWeight.w600,
      color: AppColors.pureWhite,
    );
  }

  static TextStyle link(BuildContext context) {
    final scale = MediaQuery.sizeOf(context).width / 390;
    return GoogleFonts.inter(
      fontSize: 13 * scale.clamp(0.85, 1.3),
      fontWeight: FontWeight.w400,
      color: AppColors.darkGrey,
    );
  }
}
