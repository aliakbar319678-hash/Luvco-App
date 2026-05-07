import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/app_colors.dart';

class PreferenceChipWrap extends StatelessWidget {
  final List<String> options;
  final List<String> selected;
  final ValueChanged<String> onTap;

  const PreferenceChipWrap({
    super.key,
    required this.options,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.sizeOf(context).width / 390;

    return Wrap(
      spacing: 8,
      runSpacing: 10,
      children: options.map((option) {
        final isSelected = selected.contains(option);
        return GestureDetector(
          onTap: () => onTap(option),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.royalPurple : AppColors.pureWhite,
              borderRadius: BorderRadius.circular(50),
              border: Border.all(
                color: isSelected
                    ? AppColors.royalPurple
                    : AppColors.inputBorder,
                width: 1.2,
              ),
            ),
            child: Text(
              option,
              style: GoogleFonts.inter(
                fontSize: 13 * scale.clamp(0.85, 1.3),
                fontWeight: FontWeight.w500,
                color: isSelected ? AppColors.pureWhite : AppColors.black,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
