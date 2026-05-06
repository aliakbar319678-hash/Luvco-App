import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/app_colors.dart';

class LuvcoTextField extends StatelessWidget {
  final String label;
  final String hintText;
  final bool obscureText;
  final TextInputType keyboardType;
  final ValueChanged<String> onChanged;
  final Widget? suffixIcon;
  final bool hasError;

  const LuvcoTextField({
    super.key,
    required this.label,
    required this.hintText,
    required this.onChanged,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.suffixIcon,
    this.hasError = false,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final scale = size.width / 390;
    final fontSize = 14 * scale.clamp(0.85, 1.3);
    final fieldHeight = (size.height * 0.062).clamp(48.0, 60.0);

    // ── Border colors depend on error state ──
    final borderColor = hasError ? AppColors.errorRed : AppColors.inputBorder;
    final focusColor = hasError ? AppColors.errorRed : AppColors.royalPurple;
    final labelColor = hasError ? AppColors.errorRed : AppColors.black;

    final defaultBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: borderColor, width: 1.0),
    );
    final focusedBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: focusColor, width: 1.5),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Label ──
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: fontSize,
            fontWeight: FontWeight.w500,
            color: labelColor,
          ),
        ),
        const SizedBox(height: 8),

        // ── Input field ──
        SizedBox(
          height: fieldHeight,
          child: TextField(
            onChanged: onChanged,
            obscureText: obscureText,
            keyboardType: keyboardType,
            cursorColor: hasError ? AppColors.errorRed : AppColors.royalPurple,
            style: GoogleFonts.inter(
              fontSize: fontSize,
              color: hasError ? AppColors.errorRed : AppColors.black,
              fontWeight: FontWeight.w400,
            ),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: GoogleFonts.inter(
                fontSize: fontSize,
                color: hasError ? AppColors.errorRed.withValues(alpha: 0.6) : AppColors.neutralGrey,
                fontWeight: FontWeight.w400,
              ),
              filled: true,
              fillColor: AppColors.pureWhite,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              border: defaultBorder,
              enabledBorder: defaultBorder,
              focusedBorder: focusedBorder,
              suffixIcon: suffixIcon,
            ),
          ),
        ),
      ],
    );
  }
}
