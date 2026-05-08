import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/app_colors.dart';

class LuvcoFoodSettingsModifyDialog extends StatelessWidget {
  final VoidCallback onModifyDiet;
  final VoidCallback onModifyChallenges;

  const LuvcoFoodSettingsModifyDialog({
    super.key,
    required this.onModifyDiet,
    required this.onModifyChallenges,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final scale = size.width / 390;

    return Dialog(
      backgroundColor: AppColors.pureWhite,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: EdgeInsets.symmetric(horizontal: size.width * 0.06),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Close Button ──
            Align(
              alignment: Alignment.topRight,
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: const Icon(Icons.close, color: AppColors.darkGrey, size: 24),
              ),
            ),

            const SizedBox(height: 8),

            // ── Title ──
            Text(
              'Which setting would you like to\nmodify?',
              style: GoogleFonts.inter(
                fontSize: 18 * scale.clamp(0.85, 1.2),
                fontWeight: FontWeight.w700,
                color: AppColors.black,
                height: 1.3,
              ),
            ),

            const SizedBox(height: 32),

            // ── Option 1: Diet Choices ──
            _ModifyOptionItem(
              icon: Icons.restaurant_menu_rounded,
              label: 'Add or Edit Diet Choices',
              onTap: () {
                Navigator.of(context).pop();
                onModifyDiet();
              },
              scale: scale,
            ),

            const SizedBox(height: 24),

            // ── Option 2: Food Challenges ──
            _ModifyOptionItem(
              icon: Icons.no_food_outlined,
              label: 'Add or Edit Food Challenges',
              onTap: () {
                Navigator.of(context).pop();
                onModifyChallenges();
              },
              scale: scale,
            ),
          ],
        ),
      ),
    );
  }
}

class _ModifyOptionItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final double scale;

  const _ModifyOptionItem({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.scale,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        children: [
          Icon(icon, color: AppColors.black, size: 22),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14 * scale.clamp(0.85, 1.2),
                fontWeight: FontWeight.w500,
                color: AppColors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
