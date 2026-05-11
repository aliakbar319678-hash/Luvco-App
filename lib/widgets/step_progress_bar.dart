import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/app_colors.dart';

// ─────────────────────────────────────────────────────────────────
// StepProgressBar — the 3-step progress indicator at top of each step
// Figma: Step 01 (pink circle #1) → line → Step 02 (grey #2) → line → Step 03 (#3)
// ─────────────────────────────────────────────────────────────────
class StepProgressBar extends StatelessWidget {
  final int currentStep; // 1, 2, or 3

  const StepProgressBar({super.key, required this.currentStep});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final scale = size.width / 390;

    return Row(
      children: [
        _buildStep(context, 1, scale),
        _buildLine(1, scale),
        _buildStep(context, 2, scale),
        _buildLine(2, scale),
        _buildStep(context, 3, scale),
      ],
    );
  }

  Widget _buildStep(BuildContext context, int step, double scale) {
    final isCompleted = step < currentStep;
    final isActive = step == currentStep;

    Color circleColor;
    Color borderColor;
    Color textColor;

    if (isActive) {
      circleColor = AppColors.vibrantPink;
      borderColor = AppColors.vibrantPink;
      textColor = AppColors.pureWhite;
    } else if (isCompleted) {
      circleColor = AppColors.vibrantPink;
      borderColor = AppColors.vibrantPink;
      textColor = AppColors.pureWhite;
    } else {
      circleColor = Colors.transparent;
      borderColor = AppColors.clearGrey;
      textColor = AppColors.neutralGrey;
    }

    final circleDiameter = 28.0 * scale.clamp(0.85, 1.2);
    final labelFontSize = 10.0 * scale.clamp(0.85, 1.2);
    final stepFontSize = 12.0 * scale.clamp(0.85, 1.2);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: circleDiameter,
          height: circleDiameter,
          decoration: BoxDecoration(
            color: circleColor,
            shape: BoxShape.circle,
            border: Border.all(color: borderColor, width: 1.5),
          ),
          child: Center(
            child: Text(
              '$step',
              style: GoogleFonts.inter(
                fontSize: stepFontSize,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Step 0$step',
          style: GoogleFonts.inter(
            fontSize: labelFontSize,
            fontWeight: FontWeight.w400,
            color: isActive || isCompleted
                ? AppColors.vibrantPink
                : AppColors.neutralGrey,
          ),
        ),
      ],
    );
  }

  Widget _buildLine(int afterStep, double scale) {
    final isActive = afterStep < currentStep;
    return Expanded(
      child: Container(
        height: 1.5,
        margin: const EdgeInsets.only(bottom: 16),
        color: isActive ? AppColors.vibrantPink : AppColors.clearGrey,
      ),
    );
  }
}
