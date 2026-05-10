import 'package:flutter/material.dart';

import 'package:google_fonts/google_fonts.dart';
import '../core/theme/app_colors.dart';
import '../models/product_model.dart';

// ─────────────────────────────────────────────────────────────────
// Product Detail Bottom Sheet
// Shown when user taps a product in search results.
// Matches screenshots 1.1.3 and 1.1.4 exactly.
// ─────────────────────────────────────────────────────────────────
void showProductDetailSheet(
  BuildContext context, {
  required ProductModel product,
  required VoidCallback onAddProduct,
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    barrierColor: Colors.black.withValues(alpha: 0.45),
    builder: (_) =>
        _ProductDetailSheet(product: product, onAddProduct: onAddProduct),
  );
}

class _ProductDetailSheet extends StatefulWidget {
  final ProductModel product;
  final VoidCallback onAddProduct;

  const _ProductDetailSheet({
    required this.product,
    required this.onAddProduct,
  });

  @override
  State<_ProductDetailSheet> createState() => _ProductDetailSheetState();
}

class _ProductDetailSheetState extends State<_ProductDetailSheet> {
  bool _isSaved = false;
  bool _productAdded = false; // drives the success toast overlay

  void _handleAddProduct() {
    widget.onAddProduct();
    setState(() => _productAdded = true);
    // Auto-hide success toast after 1.8s, then pop sheet
    Future.delayed(const Duration(milliseconds: 1800), () {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final scale = size.width / 390;
    final product = widget.product;

    return Stack(
      children: [
        // ── Main sheet ──────────────────────────────────────────
        DraggableScrollableSheet(
          initialChildSize: 0.78,
          minChildSize: 0.5,
          maxChildSize: 0.92,
          builder: (_, scrollController) => Container(
            decoration: const BoxDecoration(
              color: AppColors.softGrey,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Column(
              children: [
                // ── Drag handle ──
                const SizedBox(height: 10),
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
                const SizedBox(height: 6),

                // ── Scrollable content ──
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Close + title row ──
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: size.width * 0.058,
                          ),
                          child: SizedBox(
                            width: double.infinity,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Column(
                                  children: [
                                    Text(
                                      product.name,
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.inter(
                                        fontSize: 17 * scale.clamp(0.85, 1.2),
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.vibrantPink,
                                      ),
                                    ),
                                    Text(
                                      product.description,
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.inter(
                                        fontSize: 12 * scale.clamp(0.85, 1.2),
                                        color: AppColors.darkGrey,
                                      ),
                                    ),
                                  ],
                                ),
                                Positioned(
                                  right: 0,
                                  top: 0,
                                  child: GestureDetector(
                                    onTap: () => Navigator.of(context).pop(),
                                    child: const Icon(
                                      Icons.close,
                                      color: AppColors.black, // Darker close icon
                                      size: 24,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 10),

                        // ── Image Card with Sustainability Header ──
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: size.width * 0.058,
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            clipBehavior: Clip.antiAlias, // Clips the red/green tabs to match the 24px border radius
                            child: Column(
                              children: [
                                // Top tabs (Unsustainable / Safe)
                                Row(
                                  children: [
                                    Expanded(
                                      child: Container(
                                        height: 50 * scale.clamp(0.85, 1.2),
                                        decoration: const BoxDecoration(
                                          color: AppColors.errorRed,
                                          borderRadius: BorderRadius.only(
                                            topRight: Radius.circular(16), // Curving the inner border
                                          ),
                                        ),
                                        alignment: Alignment.center,
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Image.asset(
                                              'assets/icons/tabler-icon-leaf.png',
                                              width: 18 * scale.clamp(0.85, 1.2),
                                              height: 18 * scale.clamp(0.85, 1.2),
                                              color: Colors.white,
                                              errorBuilder: (_, __, ___) => const Icon(
                                                Icons.recycling_outlined,
                                                color: Colors.white,
                                                size: 18,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              'Unsustainable',
                                              style: GoogleFonts.inter(
                                                fontSize: 13 * scale.clamp(0.85, 1.2),
                                                fontWeight: FontWeight.w600,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Container(
                                        height: 50 * scale.clamp(0.85, 1.2),
                                        decoration: const BoxDecoration(
                                          color: Color(0xFF43A047),
                                          borderRadius: BorderRadius.only(
                                            topLeft: Radius.circular(16), // Curving the inner border
                                          ),
                                        ),
                                        alignment: Alignment.center,
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.flag_outlined,
                                              color: Colors.white,
                                              size: 18 * scale.clamp(0.85, 1.2),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              'Safe',
                                              style: GoogleFonts.inter(
                                                fontSize: 13 * scale.clamp(0.85, 1.2),
                                                fontWeight: FontWeight.w600,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                // Bottom Image Section
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.only(top: 20, bottom: 20),
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      // Product image
                                      if (product.imageAsset != null)
                                        Image.asset(
                                          product.imageAsset!,
                                          height: 180 * scale.clamp(0.85, 1.2),
                                          fit: BoxFit.contain,
                                          errorBuilder: (_, __, ___) =>
                                              const Icon(
                                                Icons.image_outlined,
                                                size: 80,
                                                color: AppColors.clearGrey,
                                              ),
                                        )
                                      else
                                        const Icon(
                                          Icons.image_outlined,
                                          size: 80,
                                          color: AppColors.clearGrey,
                                        ),
                                      
                                      // Heart save button
                                      Positioned(
                                        right: 16,
                                        top: 0, // Neatly at the top right of the white image section
                                        child: GestureDetector(
                                          onTap: () =>
                                              setState(() => _isSaved = !_isSaved),
                                          child: Icon(
                                            _isSaved
                                                ? Icons.favorite_rounded
                                                : Icons.favorite_border_rounded,
                                            color: _isSaved
                                                ? AppColors.vibrantPink
                                                : AppColors.black, // Dark outline matching Figma
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
                        ),

                        const SizedBox(height: 20),

                        // ── Labels and Certifications ──
                        _InfoSection(
                          title: 'Labels and Certifications',
                          items: product.labels,
                          scale: scale,
                          padding: size.width * 0.058,
                        ),

                        const SizedBox(height: 20),

                        // ── Possible allergens ──
                        _InfoSection(
                          title: 'Possible allergens',
                          items: product.allergens,
                          scale: scale,
                          padding: size.width * 0.058,
                        ),

                        const SizedBox(height: 20),

                        // ── Ingredients list ──
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: size.width * 0.058,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Ingredients list',
                                style: GoogleFonts.inter(
                                  fontSize: 14 * scale.clamp(0.85, 1.2),
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.black,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ...product.ingredients.map(
                                (ing) => Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Text(
                                    ing,
                                    style: GoogleFonts.inter(
                                      fontSize: 13 * scale.clamp(0.85, 1.2),
                                      color: AppColors.darkGrey,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 90), // space for Add button
                      ],
                    ),
                  ),
                ),

                // ── Add Product button — always visible at bottom ──
                _AddProductButton(
                  scale: scale,
                  size: size,
                  onTap: _handleAddProduct,
                ),
              ],
            ),
          ),
        ),

        // ── "Product added to the list!" success overlay ─────────
        if (_productAdded)
          Positioned.fill(
            child: Container(
              color: Colors.black.withValues(alpha: 0.4), // Dimmed background overlay
              child: Center(
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: size.width * 0.12),
                  padding: const EdgeInsets.symmetric(
                    vertical: 28,
                    horizontal: 24,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 24,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFF43A047),
                            width: 2.5,
                          ),
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          color: Color(0xFF43A047),
                          size: 36,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Product added to the list!',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 15 * scale.clamp(0.85, 1.2),
                          fontWeight: FontWeight.w700,
                          color: AppColors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}


// ─────────────────────────────────────────────────────────────────
// Info section with label circles (Labels / Allergens)
// ─────────────────────────────────────────────────────────────────
class _InfoSection extends StatelessWidget {
  final String title;
  final List<String> items;
  final double scale;
  final double padding;

  const _InfoSection({
    required this.title,
    required this.items,
    required this.scale,
    required this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 14 * scale.clamp(0.85, 1.2),
              fontWeight: FontWeight.w700,
              color: AppColors.black,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: items
                .take(4)
                .map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Column(
                      children: [
                        Container(
                          width: 44 * scale.clamp(0.85, 1.2),
                          height: 44 * scale.clamp(0.85, 1.2),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.softGrey,
                            border: Border.all(color: AppColors.clearGrey),
                          ),
                          alignment: Alignment.center,
                          child: Image.asset(
                            'assets/icons/create_icon.png',
                            width: 22 * scale.clamp(0.85, 1.2),
                            height: 22 * scale.clamp(0.85, 1.2),
                            color: AppColors.black,
                            errorBuilder: (_, __, ___) => const SizedBox(),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item,
                          style: GoogleFonts.inter(
                            fontSize: 10 * scale.clamp(0.85, 1.2),
                            color: AppColors.darkGrey,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Add Product button (sticky bottom)
// ─────────────────────────────────────────────────────────────────
class _AddProductButton extends StatelessWidget {
  final double scale;
  final Size size;
  final VoidCallback onTap;

  const _AddProductButton({
    required this.scale,
    required this.size,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.paddingOf(context).bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(
        size.width * 0.058,
        12,
        size.width * 0.058,
        12 + bottomPadding,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: (size.height * 0.062).clamp(48.0, 58.0),
        child: ElevatedButton.icon(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.royalPurple,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(50),
            ),
          ),
          icon: const Icon(Icons.add_rounded, color: Colors.white, size: 20),
          label: Text(
            'Add Product',
            style: GoogleFonts.inter(
              fontSize: 16 * scale.clamp(0.85, 1.3),
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
