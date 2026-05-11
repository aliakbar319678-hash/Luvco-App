import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import '../../providers/shopping_list_detail_provider.dart';

class ProductDetailSheet extends ConsumerWidget {
  final ShoppingListItem item;
  final bool showAddButton;
  final VoidCallback? onAddTap;
  final bool showFavoritesButtons;
  final VoidCallback? onAddToListTap;
  final VoidCallback? onAddToRecipeTap;

  const ProductDetailSheet({
    super.key,
    required this.item,
    this.showAddButton = false,
    this.onAddTap,
    this.showFavoritesButtons = false,
    this.onAddToListTap,
    this.onAddToRecipeTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final size = MediaQuery.sizeOf(context);
    final scale = size.width / 390;

    return Container(
      height: size.height * 0.9,
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header (Close button + Title) ──
          Padding(
            padding: const EdgeInsets.only(top: 24, right: 24, left: 24),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  behavior: HitTestBehavior.opaque,
                  child: const Icon(
                    Icons.close_rounded,
                    color: AppColors.black,
                    size: 24,
                  ),
                ),
              ],
            ),
          ),

          // ── Title & Subtitle ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                Text(
                  item.name,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 20 * scale.clamp(0.85, 1.2),
                    fontWeight: FontWeight.w800,
                    color: AppColors.vibrantPink,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.description,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 13 * scale.clamp(0.85, 1.2),
                    fontWeight: FontWeight.w500,
                    color: AppColors.darkGrey,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── Scrollable Body ──
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Image Container with Badges ──
                  _ProductImageSection(item: item, scale: scale),

                  const SizedBox(height: 28),

                  // ── Labels and Certifications ──
                  Text(
                    'Labels and Certifications',
                    style: GoogleFonts.inter(
                      fontSize: 15 * scale.clamp(0.85, 1.2),
                      fontWeight: FontWeight.w700,
                      color: AppColors.black,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _HexagonLabelsList(scale: scale),

                  const SizedBox(height: 24),

                  // ── Possible allergens ──
                  Text(
                    'Possible allergens',
                    style: GoogleFonts.inter(
                      fontSize: 15 * scale.clamp(0.85, 1.2),
                      fontWeight: FontWeight.w700,
                      color: AppColors.black,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _HexagonLabelsList(scale: scale),

                  const SizedBox(height: 24),

                  // ── Ingredients list ──
                  Text(
                    'Ingredients list',
                    style: GoogleFonts.inter(
                      fontSize: 15 * scale.clamp(0.85, 1.2),
                      fontWeight: FontWeight.w700,
                      color: AppColors.black,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _IngredientItem(
                    name: 'Ingredient Name',
                    info: 'Nutritional Info',
                    scale: scale,
                  ),
                  const Divider(color: AppColors.clearGrey, height: 24),
                  _IngredientItem(
                    name: 'Ingredient Name',
                    info: null,
                    scale: scale,
                  ),
                  if (showAddButton) ...[
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 54 * scale.clamp(0.85, 1.2),
                      child: ElevatedButton.icon(
                        onPressed: onAddTap,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.royalPurple,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                        ),
                        icon: Icon(Icons.add, color: AppColors.pureWhite, size: 20 * scale.clamp(0.85, 1.2)),
                        label: Text('Add Product To This List',
                            style: GoogleFonts.inter(fontSize: 15 * scale.clamp(0.85, 1.2), fontWeight: FontWeight.w600, color: AppColors.pureWhite)),
                      ),
                    ),
                  ],
                  if (showFavoritesButtons) ...[
                    const SizedBox(height: 28),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: onAddToListTap,
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppColors.royalPurple),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            icon: Icon(Icons.shopping_bag_outlined, color: AppColors.royalPurple, size: 18),
                            label: Text('Add To List',
                                style: GoogleFonts.inter(fontSize: 14 * scale.clamp(0.85, 1.2), fontWeight: FontWeight.w600, color: AppColors.royalPurple)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: onAddToRecipeTap,
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppColors.royalPurple),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            icon: Icon(Icons.restaurant_menu_outlined, color: AppColors.royalPurple, size: 18),
                            label: Text('Add To Recipe',
                                style: GoogleFonts.inter(fontSize: 14 * scale.clamp(0.85, 1.2), fontWeight: FontWeight.w600, color: AppColors.royalPurple)),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductImageSection extends StatefulWidget {
  final ShoppingListItem item;
  final double scale;

  const _ProductImageSection({required this.item, required this.scale});

  @override
  State<_ProductImageSection> createState() => _ProductImageSectionState();
}

class _ProductImageSectionState extends State<_ProductImageSection> {
  bool _isFavorite = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // ── Main Image ──
          Padding(
            padding: const EdgeInsets.only(top: 40, bottom: 20, left: 20, right: 20),
            child: Center(
              child: widget.item.thumbnailAsset != null
                  ? Image.asset(
                      widget.item.thumbnailAsset!,
                      height: 180 * widget.scale.clamp(0.85, 1.2),
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.image_outlined,
                        size: 80,
                        color: AppColors.neutralGrey,
                      ),
                    )
                  : const Icon(
                      Icons.image_outlined,
                      size: 80,
                      color: AppColors.neutralGrey,
                    ),
            ),
          ),

          // ── Top Badges (Unsustainable / Safe) ──
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 36,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE53935), // Red
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20),
                        bottomRight: Radius.circular(12),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.eco_outlined, color: Colors.white, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          'Unsustainable',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 12 * widget.scale.clamp(0.85, 1.2),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    height: 36,
                    decoration: const BoxDecoration(
                      color: Color(0xFF43A047), // Green
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(20),
                        bottomLeft: Radius.circular(12),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.flag_outlined, color: Colors.white, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          'Safe',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 12 * widget.scale.clamp(0.85, 1.2),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Heart Icon ──
          Positioned(
            top: 48,
            right: 16,
            child: GestureDetector(
              onTap: () => setState(() => _isFavorite = !_isFavorite),
              child: Icon(
                _isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                color: _isFavorite ? AppColors.vibrantPink : AppColors.black,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HexagonLabelsList extends StatelessWidget {
  final double scale;

  const _HexagonLabelsList({required this.scale});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: List.generate(4, (index) {
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Column(
              children: [
                Container(
                  width: 50 * scale.clamp(0.85, 1.2),
                  height: 50 * scale.clamp(0.85, 1.2),
                  decoration: BoxDecoration(
                    color: AppColors.pureWhite,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.hexagon_outlined,
                    color: AppColors.black,
                    size: 24 * scale.clamp(0.85, 1.2),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Label',
                  style: GoogleFonts.inter(
                    fontSize: 11 * scale.clamp(0.85, 1.2),
                    color: AppColors.black,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _IngredientItem extends StatelessWidget {
  final String name;
  final String? info;
  final double scale;

  const _IngredientItem({
    required this.name,
    this.info,
    required this.scale,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          name,
          style: GoogleFonts.inter(
            fontSize: 14 * scale.clamp(0.85, 1.2),
            color: AppColors.darkGrey,
            fontWeight: FontWeight.w500,
          ),
        ),
        if (info != null) ...[
          const SizedBox(height: 4),
          Text(
            info!,
            style: GoogleFonts.inter(
              fontSize: 12 * scale.clamp(0.85, 1.2),
              color: AppColors.darkGrey.withValues(alpha: 0.7),
            ),
          ),
        ],
      ],
    );
  }
}
