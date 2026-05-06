import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/app_colors.dart';

enum LuvcoButtonStyle { filled, outlined }

class LuvcoButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final LuvcoButtonStyle style;
  final bool isLoading;

  const LuvcoButton({
    super.key,
    required this.label,
    this.onTap,
    this.style = LuvcoButtonStyle.filled,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final scale = size.width / 390;
    final height = (size.height * 0.062).clamp(48.0, 58.0);

    if (style == LuvcoButtonStyle.filled) {
      return SizedBox(
        width: double.infinity,
        height: height,
        child: ElevatedButton(
          onPressed: isLoading ? null : onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.royalPurple,
            disabledBackgroundColor: AppColors.royalPurple.withOpacity(0.55),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(50),
            ),
          ),
          child: isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                )
              : Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 16 * scale.clamp(0.85, 1.3),
                    fontWeight: FontWeight.w600,
                    color: AppColors.pureWhite,
                  ),
                ),
        ),
      );
    }

    // outlined
    return SizedBox(
      width: double.infinity,
      height: height,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.royalPurple,
          side: const BorderSide(color: AppColors.royalPurple, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(50),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 16 * scale.clamp(0.85, 1.3),
            fontWeight: FontWeight.w600,
            color: AppColors.royalPurple,
          ),
        ),
      ),
    );
  }
}
