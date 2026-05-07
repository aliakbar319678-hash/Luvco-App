import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

class OnboardingProgressBar extends StatelessWidget {
  /// Total steps and which step is currently active (1-based)
  final int totalSteps;
  final int currentStep;

  const OnboardingProgressBar({
    super.key,
    required this.totalSteps,
    required this.currentStep,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    // Each bar width: fill available space with gaps between
    final barWidth = (size.width * 0.84 - (totalSteps - 1) * 6) / totalSteps;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(totalSteps, (index) {
        final isActive = index < currentStep;
        return Container(
          margin: EdgeInsets.only(right: index < totalSteps - 1 ? 6 : 0),
          width: barWidth,
          height: 4,
          decoration: BoxDecoration(
            color: isActive ? AppColors.vibrantPink : AppColors.clearGrey,
            borderRadius: BorderRadius.circular(100),
          ),
        );
      }),
    );
  }
}
