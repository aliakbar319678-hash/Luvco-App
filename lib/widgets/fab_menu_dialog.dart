import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/app_colors.dart';

/// Shows the FAB action menu as a bottom sheet that slides up from the bottom.
void showLuvcoFabActionMenu(
  BuildContext context, {
  required VoidCallback onCreateList,
  required VoidCallback onSearchProducts,
  required VoidCallback onCreateRecipe,
  required VoidCallback onSearchRecipe,
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.35),
    isScrollControlled: true,
    builder: (_) => _LuvcoFabBottomSheet(
      onCreateList: () {
        Navigator.of(context).pop();
        onCreateList();
      },
      onSearchProducts: () {
        Navigator.of(context).pop();
        onSearchProducts();
      },
      onCreateRecipe: () {
        Navigator.of(context).pop();
        onCreateRecipe();
      },
      onSearchRecipe: () {
        Navigator.of(context).pop();
        onSearchRecipe();
      },
    ),
  );
}

class _LuvcoFabBottomSheet extends StatelessWidget {
  final VoidCallback onCreateList;
  final VoidCallback onSearchProducts;
  final VoidCallback onCreateRecipe;
  final VoidCallback onSearchRecipe;

  const _LuvcoFabBottomSheet({
    required this.onCreateList,
    required this.onSearchProducts,
    required this.onCreateRecipe,
    required this.onSearchRecipe,
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

          const SizedBox(height: 8),

          // ── Option 1: Create New Shopping List ──
          _FabOptionItem(
            icon: SvgPicture.asset(
              'assets/icons/shopping-bag.svg',
              width: 22,
              height: 22,
              colorFilter: const ColorFilter.mode(AppColors.black, BlendMode.srcIn),
            ),
            label: 'Create New Shopping List',
            onTap: onCreateList,
            scale: scale,
          ),

          const SizedBox(height: 28),

          // ── Option 2: Search For Products ──
          _FabOptionItem(
            icon: const Icon(Icons.search_rounded, color: AppColors.black, size: 22),
            label: 'Search For Products',
            onTap: onSearchProducts,
            scale: scale,
          ),

          const SizedBox(height: 28),

          // ── Option 3: Create New Recipe Manually ──
          _FabOptionItem(
            icon: const Icon(Icons.restaurant_outlined, color: AppColors.black, size: 22),
            label: 'Create New Recipe Manually',
            onTap: onCreateRecipe,
            scale: scale,
          ),

          const SizedBox(height: 28),

          // ── Option 4: Search For New Recipe ──
          _FabOptionItem(
            icon: const Icon(Icons.search_rounded, color: AppColors.black, size: 22),
            label: 'Search For New Recipe',
            onTap: onSearchRecipe,
            scale: scale,
          ),

          const SizedBox(height: 8),
        ],
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
