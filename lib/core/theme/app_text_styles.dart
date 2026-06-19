import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';
import '../utils/responsive_utils.dart';

/// Centralised text style factory.
///
/// Performance notes:
///   • Each method calls [context.scale] ONCE (a single [MediaQuery.sizeOf]
///     via the extension) rather than re-calling MediaQuery per style.
///   • The returned [TextStyle] objects are lightweight value types; Flutter's
///     render pipeline caches paragraph layouts so allocating these on build is
///     not a bottleneck — but we still avoid unnecessary allocations by sharing
///     the computed [scale] variable.
class AppTextStyles {
  AppTextStyles._();

  static TextStyle heading1(BuildContext context) {
    final s = context.scale;
    return GoogleFonts.inter(
      fontSize: 28 * s,
      fontWeight: FontWeight.w700,
      color: AppColors.black,
      height: 1.2,
    );
  }

  static TextStyle subtitle(BuildContext context) {
    final s = context.scale;
    return GoogleFonts.inter(
      fontSize: 14 * s,
      fontWeight: FontWeight.w400,
      color: AppColors.darkGrey,
      height: 1.4,
    );
  }

  static TextStyle label(BuildContext context) {
    final s = context.scale;
    return GoogleFonts.inter(
      fontSize: 14 * s,
      fontWeight: FontWeight.w500,
      color: AppColors.black,
    );
  }

  static TextStyle hint(BuildContext context) {
    final s = context.scale;
    return GoogleFonts.inter(
      fontSize: 14 * s,
      fontWeight: FontWeight.w400,
      color: AppColors.neutralGrey,
    );
  }

  static TextStyle button(BuildContext context) {
    final s = context.scale;
    return GoogleFonts.inter(
      fontSize: 16 * s,
      fontWeight: FontWeight.w600,
      color: AppColors.pureWhite,
    );
  }

  static TextStyle link(BuildContext context) {
    final s = context.scale;
    return GoogleFonts.inter(
      fontSize: 13 * s,
      fontWeight: FontWeight.w400,
      color: AppColors.darkGrey,
      decoration: TextDecoration.underline,
    );
  }
}
