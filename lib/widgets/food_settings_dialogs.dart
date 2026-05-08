import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/app_colors.dart';

/// Shows the "Which setting would you like to modify?" bottom sheet
/// that slides up from the bottom — matching the Figma design exactly.
void showFoodSettingsModifySheet(
  BuildContext context, {
  required VoidCallback onModifyDiet,
  required VoidCallback onModifyChallenges,
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.35),
    isScrollControlled: true,
    builder: (_) => _FoodSettingsModifySheet(
      onModifyDiet: () {
        Navigator.of(context).pop();
        onModifyDiet();
      },
      onModifyChallenges: () {
        Navigator.of(context).pop();
        onModifyChallenges();
      },
    ),
  );
}

class _FoodSettingsModifySheet extends StatelessWidget {
  final VoidCallback onModifyDiet;
  final VoidCallback onModifyChallenges;

  const _FoodSettingsModifySheet({
    required this.onModifyDiet,
    required this.onModifyChallenges,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final scale = size.width / 390;
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 16,
        bottom: 32 + bottomPadding,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Drag Handle ──
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.clearGrey,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // ── Close Button ──
          Align(
            alignment: Alignment.topRight,
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: const Icon(Icons.close, color: AppColors.darkGrey, size: 24),
            ),
          ),

          const SizedBox(height: 4),

          // ── Title ──
          Text(
            'Which setting would you like to\nmodify?',
            style: GoogleFonts.inter(
              fontSize: 20 * scale.clamp(0.85, 1.2),
              fontWeight: FontWeight.w700,
              color: AppColors.black,
              height: 1.35,
            ),
          ),

          const SizedBox(height: 32),

          // ── Option 1: Diet Choices ──
          _SheetOptionItem(
            icon: Icons.restaurant,
            label: 'Add or Edit Diet Choices',
            onTap: onModifyDiet,
            scale: scale,
          ),

          const SizedBox(height: 28),

          // ── Option 2: Food Challenges ──
          _SheetOptionItem(
            icon: Icons.no_food_outlined,
            label: 'Add or Edit Food Challenges',
            onTap: onModifyChallenges,
            scale: scale,
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _SheetOptionItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final double scale;

  const _SheetOptionItem({
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
          Icon(icon, color: AppColors.black, size: 24),
          const SizedBox(width: 18),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 15 * scale.clamp(0.85, 1.2),
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
