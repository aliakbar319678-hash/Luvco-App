import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import '../../core/network/product_api_service.dart';
import '../../models/product_model.dart';
import '../../providers/shopping_list_detail_provider.dart';
import '../../providers/favorites_provider.dart';

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
                  // (Product detail via barcode scanner uses the
                  // full ProductDetailScreen which shows full data)
                  _IngredientItem(
                    name: item.description.isNotEmpty ? item.description : 'See product details',
                    info: item.barcode != null ? 'Barcode: ${item.barcode}' : null,
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
                            icon: const Icon(Icons.shopping_bag_outlined, color: AppColors.royalPurple, size: 18),
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
                            icon: const Icon(Icons.restaurant_menu_outlined, color: AppColors.royalPurple, size: 18),
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

class _ProductImageSection extends ConsumerStatefulWidget {
  final ShoppingListItem item;
  final double scale;

  const _ProductImageSection({required this.item, required this.scale});

  @override
  ConsumerState<_ProductImageSection> createState() => _ProductImageSectionState();
}

class _ProductImageSectionState extends ConsumerState<_ProductImageSection> {
  ProductModel? _fullProduct;

  @override
  void initState() {
    super.initState();
    _loadProduct();
  }

  Future<void> _loadProduct() async {
    final barcode = widget.item.barcode;
    if (barcode == null || barcode.isEmpty) return;
    try {
      final product = await ProductApiService.instance.lookupProduct(barcode);
      if (mounted) {
        setState(() {
          _fullProduct = product;
        });
      }
    } catch (e) {
      // Ignore lookup errors
    }
  }

  @override
  Widget build(BuildContext context) {
    final isFavorite = ref.watch(favoritesProvider).items.any((i) => i.barcode == (widget.item.barcode ?? widget.item.id));
    final isSustainable = _fullProduct?.isSustainable ?? false;
    final sustainColor = isSustainable ? const Color(0xFF43A047) : const Color(0xFFE53935);
    final sustainLabel = isSustainable ? 'Sustainable' : 'Unsustainable';

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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // 1. Red/Green background tabs - Background Layer
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 90 * widget.scale.clamp(0.85, 1.2),
                    decoration: BoxDecoration(
                      color: sustainColor,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(16),
                      ),
                    ),
                    alignment: Alignment.topCenter,
                    padding: EdgeInsets.only(top: 14 * widget.scale.clamp(0.85, 1.2)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.eco_outlined, color: Colors.white, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          sustainLabel,
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
                    height: 90 * widget.scale.clamp(0.85, 1.2),
                    decoration: const BoxDecoration(
                      color: Color(0xFF43A047), // Green
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    alignment: Alignment.topCenter,
                    padding: EdgeInsets.only(top: 14 * widget.scale.clamp(0.85, 1.2)),
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

            // 2. White image card overlapping the background tabs - Foreground Layer (Overlapping)
            Container(
              margin: EdgeInsets.only(top: 46 * widget.scale.clamp(0.85, 1.2)),
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              padding: const EdgeInsets.only(top: 20, bottom: 20),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Product image
                  Padding(
                    padding: const EdgeInsets.only(top: 20, bottom: 0, left: 20, right: 20),
                    child: Center(
                      child: widget.item.thumbnailAsset != null
                          ? (widget.item.thumbnailAsset!.startsWith('http')
                              ? Image.network(
                                  widget.item.thumbnailAsset!,
                                  height: 180 * widget.scale.clamp(0.85, 1.2),
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) => const Icon(
                                    Icons.image_outlined,
                                    size: 80,
                                    color: AppColors.neutralGrey,
                                  ),
                                )
                              : Image.asset(
                                  widget.item.thumbnailAsset!,
                                  height: 180 * widget.scale.clamp(0.85, 1.2),
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) => const Icon(
                                    Icons.image_outlined,
                                    size: 80,
                                    color: AppColors.neutralGrey,
                                  ),
                                ))
                          : const Icon(
                              Icons.image_outlined,
                              size: 80,
                              color: AppColors.neutralGrey,
                            ),
                    ),
                  ),
                  
                  // Heart save button
                  Positioned(
                    right: 16,
                    top: 0,
                    child: GestureDetector(
                      onTap: () async {
                        final barcode = widget.item.barcode ?? widget.item.id;
                        final notifier = ref.read(favoritesProvider.notifier);
                        if (isFavorite) {
                          await notifier.removeItem(barcode);
                        } else {
                          await notifier.addFavorite(
                            barcode: barcode,
                            productName: widget.item.name,
                            productImageUrl: widget.item.thumbnailAsset,
                          );
                        }
                      },
                      child: Icon(
                        isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                        color: isFavorite ? AppColors.vibrantPink : AppColors.black,
                        size: 26,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
