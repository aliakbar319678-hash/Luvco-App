import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../models/product_model.dart';
import '../../providers/new_shopping_list_provider.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../../widgets/product_detail_sheet.dart';

// ─────────────────────────────────────────────────────────────────
// New Shopping List Screen
// Covers all 7 Figma frames: 1.1.0 → 1.1.6
// ─────────────────────────────────────────────────────────────────
class NewShoppingListScreen extends ConsumerWidget {
  const NewShoppingListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(newShoppingListProvider);
    final notifier = ref.read(newShoppingListProvider.notifier);
    final size = MediaQuery.sizeOf(context);
    final padding = MediaQuery.paddingOf(context);
    final scale = size.width / 390;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: AppColors.pureWhite,
        body: Stack(
          children: [
            Column(
              children: [
                // ── Header ──────────────────────────────────────
                _NewListHeader(padding: padding, scale: scale, size: size),

                // ── Scrollable body ──────────────────────────────
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.symmetric(
                      horizontal: size.width * 0.058,
                      vertical: 20,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Title + mandatory note ──
                        Text(
                          'Create a new shopping list:',
                          style: GoogleFonts.inter(
                            fontSize: 20 * scale.clamp(0.85, 1.2),
                            fontWeight: FontWeight.w700,
                            color: AppColors.black,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod.',
                          style: GoogleFonts.inter(
                            fontSize: 13 * scale.clamp(0.85, 1.2),
                            color: AppColors.darkGrey,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '*Mandatory fields',
                          style: GoogleFonts.inter(
                            fontSize: 11 * scale.clamp(0.85, 1.2),
                            color: AppColors.neutralGrey,
                            fontStyle: FontStyle.italic,
                          ),
                        ),

                        const SizedBox(height: 20),

                        // ── List Name field ──
                        _FieldLabel(label: 'List Name:*', scale: scale),
                        const SizedBox(height: 8),
                        _InputField(
                          hint: "Enter the list's name",
                          onChanged: notifier.setListName,
                          scale: scale,
                          maxLines: 1,
                        ),

                        const SizedBox(height: 16),

                        // ── Description field ──
                        _FieldLabel(label: 'Description', scale: scale),
                        const SizedBox(height: 8),
                        _InputField(
                          hint: 'Enter a brief description of this list',
                          onChanged: notifier.setDescription,
                          scale: scale,
                          maxLines: 3,
                        ),

                        const SizedBox(height: 20),

                        // ── Divider ──
                        const Divider(color: AppColors.clearGrey, thickness: 1),

                        const SizedBox(height: 16),

                        // ── Search bar ──
                        _ProductSearchBar(
                          query: state.searchQuery,
                          onChanged: notifier.onSearchChanged,
                          onClear: notifier.clearSearch,
                          scale: scale,
                          size: size,
                        ),

                        const SizedBox(height: 20),

                        // ── Search results list ──
                        if (state.isSearching && state.searchResults.isNotEmpty)
                          _SearchResultsList(
                            results: state.searchResults,
                            scale: scale,
                            size: size,
                            onProductTap: (product) =>
                                _openProductDetail(context, product, notifier),
                          )
                        // ── Added products section ──
                        else if (state.addedProducts.isNotEmpty)
                          _AddedProductsList(
                            products: state.addedProducts,
                            scale: scale,
                            size: size,
                            onRemove: notifier.removeProduct,
                          )
                        // ── Empty state ──
                        else
                          _EmptyProductState(scale: scale, size: size),

                        const SizedBox(height: 120),
                      ],
                    ),
                  ),
                ),

                // ── Bottom nav ──
                const LuvcoBottomNavBar(),
              ],
            ),

            // ── "Create Shopping List" sticky button ────────────
            Positioned(
              left: 0,
              right: 0,
              bottom: 106 * scale, // sits just above bottom nav
              child: _CreateListButton(
                state: state,
                scale: scale,
                size: size,
                onTap: () => _handleCreateList(context, ref, notifier),
              ),
            ),

            // ── List created success overlay ──────────────────
            if (state.listCreated)
              Positioned.fill(
                child: _ListCreatedOverlay(
                  scale: scale,
                  size: size,
                  onDone: () {
                    notifier.dismissSuccess();
                    Navigator.of(context).pop();
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _openProductDetail(
    BuildContext context,
    ProductModel product,
    NewShoppingListNotifier notifier,
  ) {
    showProductDetailSheet(
      context,
      product: product,
      onAddProduct: () => notifier.addProduct(product),
    );
  }

  Future<void> _handleCreateList(
    BuildContext context,
    WidgetRef ref,
    NewShoppingListNotifier notifier,
  ) async {
    await notifier.createList();
  }
}

// ─────────────────────────────────────────────────────────────────
// Header — back arrow + "New Shopping List" title
// ─────────────────────────────────────────────────────────────────
class _NewListHeader extends StatelessWidget {
  final EdgeInsets padding;
  final double scale;
  final Size size;

  const _NewListHeader({
    required this.padding,
    required this.scale,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: padding.top + 12,
        bottom: 16,
        left: size.width * 0.058,
        right: size.width * 0.058,
      ),
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Back arrow
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: AppColors.vibrantPink,
              size: 20,
            ),
          ),
          const SizedBox(width: 8),
          // Title
          Expanded(
            child: Text(
              'New Shopping List',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 20 * scale.clamp(0.85, 1.2),
                fontWeight: FontWeight.w700,
                color: AppColors.vibrantPink,
              ),
            ),
          ),
          // Spacer to balance the back icon
          const SizedBox(width: 28),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Reusable field label
// ─────────────────────────────────────────────────────────────────
class _FieldLabel extends StatelessWidget {
  final String label;
  final double scale;

  const _FieldLabel({required this.label, required this.scale});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: GoogleFonts.inter(
        fontSize: 14 * scale.clamp(0.85, 1.2),
        fontWeight: FontWeight.w600,
        color: AppColors.black,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Reusable input field
// ─────────────────────────────────────────────────────────────────
class _InputField extends StatelessWidget {
  final String hint;
  final ValueChanged<String> onChanged;
  final double scale;
  final int maxLines;

  const _InputField({
    required this.hint,
    required this.onChanged,
    required this.scale,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      onChanged: onChanged,
      maxLines: maxLines,
      style: GoogleFonts.inter(
        fontSize: 14 * scale.clamp(0.85, 1.2),
        color: AppColors.black,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(
          fontSize: 14 * scale.clamp(0.85, 1.2),
          color: AppColors.neutralGrey,
        ),
        filled: true,
        fillColor: AppColors.pureWhite,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.inputBorder, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.inputBorder, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: AppColors.royalPurple,
            width: 1.5,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Product search bar
// Matches Figma exactly: purple border, search icon, clear X
// ─────────────────────────────────────────────────────────────────
class _ProductSearchBar extends StatefulWidget {
  final String query;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final double scale;
  final Size size;

  const _ProductSearchBar({
    required this.query,
    required this.onChanged,
    required this.onClear,
    required this.scale,
    required this.size,
  });

  @override
  State<_ProductSearchBar> createState() => _ProductSearchBarState();
}

class _ProductSearchBarState extends State<_ProductSearchBar> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.query);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isActive = widget.query.isNotEmpty;

    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: BorderRadius.circular(50),
        border: Border.all(
          color: isActive ? AppColors.royalPurple : AppColors.royalPurple,
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 14),
          Icon(
            Icons.search_rounded,
            color: AppColors.royalPurple,
            size: 22 * widget.scale.clamp(0.85, 1.2),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _ctrl,
              onChanged: widget.onChanged,
              style: GoogleFonts.inter(
                fontSize: 14 * widget.scale.clamp(0.85, 1.2),
                color: AppColors.black,
              ),
              decoration: InputDecoration(
                hintText: isActive ? null : 'Search for a Product',
                hintStyle: GoogleFonts.inter(
                  fontSize: 14 * widget.scale.clamp(0.85, 1.2),
                  color: AppColors.neutralGrey,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              cursorColor: AppColors.royalPurple,
            ),
          ),
          if (isActive)
            GestureDetector(
              onTap: () {
                _ctrl.clear();
                widget.onClear();
              },
              child: const Padding(
                padding: EdgeInsets.only(right: 14),
                child: Icon(
                  Icons.close_rounded,
                  color: AppColors.neutralGrey,
                  size: 20,
                ),
              ),
            )
          else
            const SizedBox(width: 14),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Search results list — shown when search has text
// Matches screenshot 1.1.2 — nutila.svg icon per row
// ─────────────────────────────────────────────────────────────────
class _SearchResultsList extends StatelessWidget {
  final List<ProductModel> results;
  final double scale;
  final Size size;
  final ValueChanged<ProductModel> onProductTap;

  const _SearchResultsList({
    required this.results,
    required this.scale,
    required this.size,
    required this.onProductTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: results
          .map(
            (product) => GestureDetector(
              onTap: () => onProductTap(product),
              behavior: HitTestBehavior.opaque,
              child: Container(
                margin: const EdgeInsets.only(bottom: 2),
                padding: EdgeInsets.symmetric(
                  horizontal: size.width * 0.02,
                  vertical: 12,
                ),
                decoration: const BoxDecoration(
                  color: AppColors.pureWhite,
                  border: Border(
                    bottom: BorderSide(color: AppColors.clearGrey, width: 0.8),
                  ),
                ),
                child: Row(
                  children: [
                    // Product icon — nutila thumbnail (separate from large detail image)
                    SizedBox(
                      width: 36 * scale.clamp(0.85, 1.2),
                      height: 36 * scale.clamp(0.85, 1.2),
                      child: product.thumbnailAsset != null
                          ? Image.asset(
                              product.thumbnailAsset!,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.fastfood_outlined,
                                color: AppColors.neutralGrey,
                              ),
                            )
                          : product.imageAsset != null
                          ? Image.asset(
                              product.imageAsset!,
                              fit: BoxFit.contain,
                            )
                          : const Icon(
                              Icons.fastfood_outlined,
                              color: AppColors.neutralGrey,
                            ),
                    ),
                    const SizedBox(width: 14),
                    // Name
                    Text(
                      product.name,
                      style: GoogleFonts.inter(
                        fontSize: 14 * scale.clamp(0.85, 1.2),
                        fontWeight: FontWeight.w500,
                        color: AppColors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Added products list — shown in 1.1.5
// Each card shows sustainability badge + product image + name + delete
// ─────────────────────────────────────────────────────────────────
class _AddedProductsList extends StatelessWidget {
  final List<ProductModel> products;
  final double scale;
  final Size size;
  final ValueChanged<String> onRemove;

  const _AddedProductsList({
    required this.products,
    required this.scale,
    required this.size,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Text(
          'Products added to this list (${products.length})',
          style: GoogleFonts.inter(
            fontSize: 15 * scale.clamp(0.85, 1.2),
            fontWeight: FontWeight.w700,
            color: AppColors.black,
          ),
        ),
        const SizedBox(height: 12),
        // Product cards
        ...products.map(
          (p) => _AddedProductCard(
            product: p,
            scale: scale,
            size: size,
            onRemove: () => onRemove(p.id),
          ),
        ),
      ],
    );
  }
}

class _AddedProductCard extends StatelessWidget {
  final ProductModel product;
  final double scale;
  final Size size;
  final VoidCallback onRemove;

  const _AddedProductCard({
    required this.product,
    required this.scale,
    required this.size,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias, // Clips the tabs and card nicely
      child: Column(
        children: [
          // ── Sustainability Header Tabs ──
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 36 * scale.clamp(0.85, 1.2),
                  decoration: const BoxDecoration(
                    color: AppColors.errorRed,
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(12), // Inner notch
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/icons/tabler-icon-leaf.png',
                        width: 14 * scale.clamp(0.85, 1.2),
                        height: 14 * scale.clamp(0.85, 1.2),
                        color: Colors.white,
                        errorBuilder: (_, __, ___) => Icon(
                          Icons.recycling_outlined,
                          color: Colors.white,
                          size: 14 * scale.clamp(0.85, 1.2),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Unsustainable',
                        style: GoogleFonts.inter(
                          fontSize: 11 * scale.clamp(0.85, 1.2),
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
                  height: 36 * scale.clamp(0.85, 1.2),
                  decoration: const BoxDecoration(
                    color: Color(0xFF43A047),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(12), // Inner notch
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.flag_outlined,
                        color: Colors.white,
                        size: 14 * scale.clamp(0.85, 1.2),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Safe',
                        style: GoogleFonts.inter(
                          fontSize: 11 * scale.clamp(0.85, 1.2),
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

          // ── Product Image and Details ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                // Product image
                SizedBox(
                  width: 52 * scale.clamp(0.85, 1.2),
                  height: 52 * scale.clamp(0.85, 1.2),
                  child: Image.asset(
                    product.imageAsset ??
                        product.thumbnailAsset ??
                        '', // Favor large image like in Figma
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.image_outlined,
                      size: 30,
                      color: AppColors.clearGrey,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                // Name + description
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: GoogleFonts.inter(
                          fontSize: 13 * scale.clamp(0.85, 1.2),
                          fontWeight: FontWeight.w700,
                          color: AppColors.black,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        product.description,
                        style: GoogleFonts.inter(
                          fontSize: 11 * scale.clamp(0.85, 1.2),
                          color: AppColors.darkGrey,
                        ),
                      ),
                    ],
                  ),
                ),
                // Delete button
                GestureDetector(
                  onTap: onRemove,
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(
                      Icons.delete_outline_rounded,
                      color: AppColors.black, // Dark color to match Figma
                      size: 22,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Empty product state — matches 1.1.0 (cart illustration + text)
// ─────────────────────────────────────────────────────────────────
class _EmptyProductState extends StatelessWidget {
  final double scale;
  final Size size;

  const _EmptyProductState({required this.scale, required this.size});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: size.height * 0.04),
      child: Center(
        child: Column(
          children: [
            // Illustration — already in project
            SizedBox(
              width: 110 * scale.clamp(0.85, 1.2),
              height: 110 * scale.clamp(0.85, 1.2),
              child: Image.asset(
                'assets/images/home_cart_pic.png',
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.shopping_bag_outlined,
                  size: 80,
                  color: AppColors.clearGrey,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Yo can add items later',
              style: GoogleFonts.inter(
                fontSize: 15 * scale.clamp(0.85, 1.2),
                fontWeight: FontWeight.w700,
                color: AppColors.black,
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () {}, // user can tap search bar above instead
              child: Text(
                'Create And Add Items Later',
                style: GoogleFonts.inter(
                  fontSize: 13 * scale.clamp(0.85, 1.2),
                  color: AppColors.neutralGrey,
                  decoration: TextDecoration.underline,
                  decorationColor: AppColors.neutralGrey,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Sticky "Create Shopping List" button
// Disabled (faint pink) when list name is empty — matches 1.1.0
// Enabled (purple) when list name has text — matches 1.1.1
// ─────────────────────────────────────────────────────────────────
class _CreateListButton extends StatelessWidget {
  final NewShoppingListState state;
  final double scale;
  final Size size;
  final VoidCallback onTap;

  const _CreateListButton({
    required this.state,
    required this.scale,
    required this.size,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = state.canCreate && !state.isCreating;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: size.width * 0.058),
      child: SizedBox(
        width: double.infinity,
        height: (size.height * 0.062).clamp(48.0, 58.0),
        child: ElevatedButton(
          onPressed: enabled ? onTap : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: enabled
                ? AppColors.royalPurple
                : AppColors.faintPink,
            disabledBackgroundColor: AppColors.faintPink,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(50),
            ),
          ),
          child: state.isCreating
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                )
              : Text(
                  'Create Shopping List',
                  style: GoogleFonts.inter(
                    fontSize: 16 * scale.clamp(0.85, 1.3),
                    fontWeight: FontWeight.w600,
                    color: enabled
                        ? AppColors.pureWhite
                        : AppColors.lightRoyalPurple,
                  ),
                ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// "Shopping list created successfully!" overlay — matches 1.1.6
// ─────────────────────────────────────────────────────────────────
class _ListCreatedOverlay extends StatelessWidget {
  final double scale;
  final Size size;
  final VoidCallback onDone;

  const _ListCreatedOverlay({
    required this.scale,
    required this.size,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    // Auto-navigate after 2 seconds
    Future.delayed(const Duration(seconds: 2), onDone);

    return GestureDetector(
      onTap: onDone,
      child: Container(
        color: Colors.black.withValues(alpha: 0.15),
        child: Center(
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: size.width * 0.12),
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
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
                  width: 68,
                  height: 68,
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
                    size: 38,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Shopping list created\nsuccessfully!',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 16 * scale.clamp(0.85, 1.2),
                    fontWeight: FontWeight.w700,
                    color: AppColors.black,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
