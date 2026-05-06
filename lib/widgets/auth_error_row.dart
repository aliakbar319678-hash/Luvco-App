import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/app_colors.dart';

class AuthErrorRow extends StatelessWidget {
  final String? message;
  final bool centered;

  const AuthErrorRow({super.key, this.message, this.centered = false});

  @override
  Widget build(BuildContext context) {
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.error_outline_rounded,
          color: AppColors.errorRed,
          size: 14,
        ),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            message ?? 'Please fill out this field',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.errorRed,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ],
    );

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: centered ? Center(child: content) : content,
    );
  }
}
