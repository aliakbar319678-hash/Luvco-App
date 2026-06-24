import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import '../../core/network/product_api_service.dart';
import '../../models/product_model.dart';
import '../../providers/shopping_list_detail_provider.dart';
import '../../providers/favorites_provider.dart';

// Helper: filter to English labels only
List<String> _filterEnglish(List<String> all) {
  final englishOnly = all
      .where((l) => !RegExp(r'^[a-z]{2,3}:').hasMatch(l) || l.startsWith('en:'))
      .toList();
  return englishOnly.isNotEmpty ? englishOnly : all;
}

String _cleanLabel(String raw) {
  String cleaned = raw.replaceAll(RegExp(r'^[a-z]{2,3}(-[a-z]{2,3})?:'), '');
  cleaned = cleaned.replaceAll(RegExp(r'[-_]'), ' ').trim();
  if (cleaned.isEmpty) return raw;
  return cleaned
      .split(' ')
      .map((w) {
        if (w.isEmpty) return '';
        if (w.toLowerCase() == 'eu') return 'EU';
        return '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}';
      })
      .join(' ');
}

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
            child: _ProductDetailBody(
              item: item,
              scale: scale,
              showAddButton: showAddButton,
              onAddTap: onAddTap,
              showFavoritesButtons: showFavoritesButtons,
              onAddToListTap: onAddToListTap,
              onAddToRecipeTap: onAddToRecipeTap,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Body widget that fetches and displays full product details ──
class _ProductDetailBody extends ConsumerStatefulWidget {
  final ShoppingListItem item;
  final double scale;
  final bool showAddButton;
  final VoidCallback? onAddTap;
  final bool showFavoritesButtons;
  final VoidCallback? onAddToListTap;
  final VoidCallback? onAddToRecipeTap;

  const _ProductDetailBody({
    required this.item,
    required this.scale,
    required this.showAddButton,
    this.onAddTap,
    required this.showFavoritesButtons,
    this.onAddToListTap,
    this.onAddToRecipeTap,
  });

  @override
  ConsumerState<_ProductDetailBody> createState() => _ProductDetailBodyState();
}

class _ProductDetailBodyState extends ConsumerState<_ProductDetailBody> {
  ProductModel? _fullProduct;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProduct();
  }

  Future<void> _loadProduct() async {
    final barcode = widget.item.barcode;
    if (barcode == null || barcode.isEmpty) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    try {
      final product = await ProductApiService.instance.lookupProduct(barcode);
      if (mounted) {
        setState(() {
          _fullProduct = product;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scale = widget.scale;
    final isFavorite = ref.watch(favoritesProvider).items.any(
      (i) => i.barcode == (widget.item.barcode ?? widget.item.id),
    );

    final filteredLabels = _fullProduct != null
        ? _filterEnglish(_fullProduct!.labels).map(_cleanLabel).toList()
        : <String>[];
    final filteredAllergens = _fullProduct != null
        ? _filterEnglish(_fullProduct!.allergens).map(_cleanLabel).toList()
        : <String>[];
    final ingredients = _fullProduct?.ingredients ?? <String>[];

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Image Container with Badges ──
          _ProductImageSection(
            item: widget.item,
            scale: scale,
            fullProduct: _fullProduct,
            isFavorite: isFavorite,
          ),

          const SizedBox(height: 28),

          if (_loading)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: CircularProgressIndicator(
                  color: AppColors.royalPurple,
                  strokeWidth: 2,
                ),
              ),
            )
          else ...[
            // ── Labels and Certifications ──
            if (filteredLabels.isNotEmpty) ...[
              Text(
                'Labels and Certifications',
                style: GoogleFonts.inter(
                  fontSize: 15 * scale.clamp(0.85, 1.2),
                  fontWeight: FontWeight.w700,
                  color: AppColors.black,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: filteredLabels
                    .map((l) => _LabelChip(label: l, scale: scale, isAllergen: false))
                    .toList(),
              ),
              const SizedBox(height: 24),
            ],

            // ── Possible Allergens ──
            if (filteredAllergens.isNotEmpty) ...[
              Text(
                'Possible Allergens',
                style: GoogleFonts.inter(
                  fontSize: 15 * scale.clamp(0.85, 1.2),
                  fontWeight: FontWeight.w700,
                  color: AppColors.black,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: filteredAllergens
                    .map((l) => _LabelChip(label: l, scale: scale, isAllergen: true))
                    .toList(),
              ),
              const SizedBox(height: 24),
            ],

            // ── Ingredients List ──
            Text(
              'Ingredients list',
              style: GoogleFonts.inter(
                fontSize: 15 * scale.clamp(0.85, 1.2),
                fontWeight: FontWeight.w700,
                color: AppColors.black,
              ),
            ),
            const SizedBox(height: 12),
            if (ingredients.isNotEmpty)
              ...ingredients.map(
                (ing) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        margin: const EdgeInsets.only(top: 6, right: 8),
                        decoration: const BoxDecoration(
                          color: AppColors.royalPurple,
                          shape: BoxShape.circle,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          ing,
                          style: GoogleFonts.inter(
                            fontSize: 14 * scale.clamp(0.85, 1.2),
                            color: AppColors.darkGrey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Text(
                widget.item.description.isNotEmpty
                    ? widget.item.description
                    : 'No ingredient information available.',
                style: GoogleFonts.inter(
                  fontSize: 14 * scale.clamp(0.85, 1.2),
                  color: AppColors.darkGrey,
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],

          if (widget.showAddButton) ...[
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 54 * scale.clamp(0.85, 1.2),
              child: ElevatedButton.icon(
                onPressed: widget.onAddTap,
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
          if (widget.showFavoritesButtons) ...[
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: widget.onAddToListTap,
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
                    onPressed: widget.onAddToRecipeTap,
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
    );
  }
}


// Simplified image section widget that uses pre-fetched data passed from parent
class _ProductImageSection extends ConsumerWidget {
  final ShoppingListItem item;
  final double scale;
  final ProductModel? fullProduct;
  final bool isFavorite;

  const _ProductImageSection({
    required this.item,
    required this.scale,
    this.fullProduct,
    required this.isFavorite,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = scale.clamp(0.85, 1.2);

    // Use dynamic labels from backend data
    final sustainLabel = fullProduct?.sustainabilityLabel ?? 'Loading...';
    final Color sustainColor;
    if (sustainLabel.toLowerCase().contains('eco-friendly') ||
        sustainLabel.toLowerCase().contains('sustainable')) {
      sustainColor = const Color(0xFF4CAF50);
    } else if (sustainLabel.toLowerCase().contains('moderate')) {
      sustainColor = const Color(0xFFFFB800);
    } else if (sustainLabel == 'Loading...') {
      sustainColor = AppColors.neutralGrey;
    } else {
      sustainColor = const Color(0xFFE12C2C);
    }

    final safeLabel = fullProduct?.safetyLabel ?? 'Loading...';
    final Color safeColor;
    if (safeLabel.toLowerCase().contains('safe')) {
      safeColor = const Color(0xFF4CAF50);
    } else if (safeLabel == 'Loading...') {
      safeColor = AppColors.neutralGrey;
    } else {
      safeColor = const Color(0xFFFFB800);
    }

    // Use the full product image if available
    final imageUrl = fullProduct?.imageAsset ?? item.thumbnailAsset;

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
            // 1. Dynamic sustainability/safety background tabs
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 90 * s,
                    decoration: BoxDecoration(
                      color: sustainColor,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(16),
                      ),
                    ),
                    alignment: Alignment.topCenter,
                    padding: EdgeInsets.only(top: 14 * s),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.eco_outlined, color: Colors.white, size: 16 * s),
                        SizedBox(width: 6 * s),
                        Flexible(
                          child: Text(
                            sustainLabel,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 12 * s,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    height: 90 * s,
                    decoration: BoxDecoration(
                      color: safeColor,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    alignment: Alignment.topCenter,
                    padding: EdgeInsets.only(top: 14 * s),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.flag_outlined, color: Colors.white, size: 16 * s),
                        SizedBox(width: 6 * s),
                        Flexible(
                          child: Text(
                            safeLabel,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 12 * s,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // 2. White image card overlapping the background tabs
            Container(
              margin: EdgeInsets.only(top: 46 * s),
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              padding: EdgeInsets.only(top: 20 * s, bottom: 20 * s),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Product image
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20 * s, vertical: 10 * s),
                    child: Center(
                      child: imageUrl != null
                          ? (imageUrl.startsWith('http')
                              ? Image.network(
                                  imageUrl,
                                  height: 180 * s,
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) => Icon(
                                    Icons.image_outlined,
                                    size: 80 * s,
                                    color: AppColors.neutralGrey,
                                  ),
                                )
                              : Image.asset(
                                  imageUrl,
                                  height: 180 * s,
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) => Icon(
                                    Icons.image_outlined,
                                    size: 80 * s,
                                    color: AppColors.neutralGrey,
                                  ),
                                ))
                          : Icon(
                              Icons.image_outlined,
                              size: 80 * s,
                              color: AppColors.neutralGrey,
                            ),
                    ),
                  ),

                  // Heart save button
                  Positioned(
                    right: 16 * s,
                    top: 0,
                    child: GestureDetector(
                      onTap: () async {
                        final barcode = item.barcode ?? item.id;
                        final notifier = ref.read(favoritesProvider.notifier);
                        if (isFavorite) {
                          await notifier.removeItem(barcode);
                        } else {
                          await notifier.addFavorite(
                            barcode: barcode,
                            productName: item.name,
                            productImageUrl: item.thumbnailAsset,
                          );
                        }
                      },
                      child: Icon(
                        isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                        color: isFavorite ? AppColors.vibrantPink : AppColors.black,
                        size: 26 * s,
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


// Chip widget for labels/certifications and allergens
class _LabelChip extends StatelessWidget {
  final String label;
  final double scale;
  final bool isAllergen;

  const _LabelChip({
    required this.label,
    required this.scale,
    required this.isAllergen,
  });

  @override
  Widget build(BuildContext context) {
    final s = scale.clamp(0.85, 1.2);
    final bgColor = isAllergen
        ? const Color(0xFFFFF3E0)
        : const Color(0xFFE8F5E9);
    final textColor = isAllergen
        ? const Color(0xFFE65100)
        : const Color(0xFF2E7D32);
    final icon = isAllergen ? Icons.warning_amber_rounded : Icons.verified_outlined;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10 * s, vertical: 6 * s),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20 * s),
        border: Border.all(
          color: textColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13 * s, color: textColor),
          SizedBox(width: 5 * s),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12 * s,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
