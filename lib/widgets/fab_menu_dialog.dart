import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/app_colors.dart';

class LuvcoFabActionMenu extends StatelessWidget {
  final VoidCallback onCreateList;
  final VoidCallback onSearchProducts;
  final VoidCallback onCreateRecipe;
  final VoidCallback onSearchRecipe;

  const LuvcoFabActionMenu({
    super.key,
    required this.onCreateList,
    required this.onSearchProducts,
    required this.onCreateRecipe,
    required this.onSearchRecipe,
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

            // ── Options ──
            _FabOptionItem(
              icon: SvgPicture.asset(
                'assets/icons/shopping-bag.svg',
                width: 22,
                height: 22,
                colorFilter: const ColorFilter.mode(AppColors.black, BlendMode.srcIn),
              ),
              label: 'Create New Shopping List',
              onTap: () {
                Navigator.of(context).pop();
                onCreateList();
              },
              scale: scale,
            ),

            const SizedBox(height: 24),

            _FabOptionItem(
              icon: const Icon(Icons.search_rounded, color: AppColors.black, size: 22),
              label: 'Search For Products',
              onTap: () {
                Navigator.of(context).pop();
                onSearchProducts();
              },
              scale: scale,
            ),

            const SizedBox(height: 24),

            _FabOptionItem(
              icon: const Icon(Icons.restaurant_rounded, color: AppColors.black, size: 22), // Chef hat approx
              label: 'Create New Recipe Manually',
              onTap: () {
                Navigator.of(context).pop();
                onCreateRecipe();
              },
              scale: scale,
            ),

            const SizedBox(height: 24),

            _FabOptionItem(
              icon: const Icon(Icons.search_rounded, color: AppColors.black, size: 22),
              label: 'Search For New Recipe',
              onTap: () {
                Navigator.of(context).pop();
                onSearchRecipe();
              },
              scale: scale,
            ),
          ],
        ),
      ),
    );
  }
}

class _FabOptionItem extends StatelessWidget {
  final Widget icon;
  final String label;
  final VoidCallback onTap;
  final double scale;

  const _FabOptionItem({
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
          SizedBox(width: 24, height: 24, child: Center(child: icon)),
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
