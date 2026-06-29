
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:luvco_logo/widgets/label_circle.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../models/recipe_model.dart';
import '../../models/shopping_list_model.dart';
import '../../core/network/recipe_api_service.dart';
import '../../core/network/list_api_service.dart';
import '../../providers/dashboard_search_provider.dart';
import '../../providers/favorites_provider.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../../core/network/api_client.dart';

// ─────────────────────────────────────────────────────────────────
// Main Screen
// ─────────────────────────────────────────────────────────────────
class DashboardSearchProductScreen extends ConsumerStatefulWidget {
  const DashboardSearchProductScreen({super.key});

  @override
  ConsumerState<DashboardSearchProductScreen> createState() =>
      _DashboardSearchProductScreenState();
}

class _DashboardSearchProductScreenState
    extends ConsumerState<DashboardSearchProductScreen> {
  final TextEditingController _controller = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(bottomNavIndexProvider.notifier).state = 1;
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String v) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      ref.read(dashboardSearchProvider.notifier).onSearchChanged(v);
    });
  }

  void _clear() {
    _controller.clear();
    ref.read(dashboardSearchProvider.notifier).clearSearch();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final scale = size.width / 390;
    final state = ref.watch(dashboardSearchProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: AppColors.pageBackground,
        body: Column(
          children: [
            _TopBar(scale: scale),
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 20 * scale.clamp(0.85, 1.2),
                vertical: 16 * scale.clamp(0.85, 1.2),
              ),
              child: _SearchBar(
                controller: _controller,
                onChanged: _onChanged,
                onClear: _clear,
                scale: scale,
              ),
            ),
            _ResultsHeader(scale: scale),
            Expanded(
              child: state.isSearching
                  ? const Center(child: CircularProgressIndicator(color: AppColors.royalPurple))
                  : state.query.isNotEmpty
                      ? _ResultsBody(scale: scale, state: state)
                      : _EmptyBody(scale: scale),
            ),
            const LuvcoBottomNavBar(),
          ],
        ),
      ),
    );
  }
}

class _ResultsHeader extends ConsumerWidget {
  final double scale;
  const _ResultsHeader({required this.scale});

  void _showFilterSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FilterSheet(scale: scale, ref: ref),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = scale.clamp(0.85, 1.2);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20 * s, vertical: 8 * s),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Results',
            style: GoogleFonts.inter(
              fontSize: 16 * s,
              fontWeight: FontWeight.w700,
              color: AppColors.black,
            ),
          ),
          GestureDetector(
            onTap: () => _showFilterSheet(context, ref),
            behavior: HitTestBehavior.opaque,
            child: Row(
              children: [
                Icon(
                  Icons.tune_rounded,
                  size: 16 * s,
                  color: AppColors.black,
                ),
                const SizedBox(width: 4),
                Text(
                  'Filter',
                  style: GoogleFonts.inter(
                    fontSize: 13 * s,
                    fontWeight: FontWeight.w500,
                    color: AppColors.black,
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
// Top Bar
// ─────────────────────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  final double scale;
  const _TopBar({required this.scale});

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.paddingOf(context);
    return Container(
      padding: EdgeInsets.only(
        top: padding.top + 16,
        bottom: 22,
        left: 16,
        right: 16,
      ),
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            behavior: HitTestBehavior.opaque,
            child: SizedBox(
              width: 36,
              height: 36,
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: AppColors.vibrantPink,
                size: 20 * scale.clamp(0.85, 1.2),
              ),
            ),
          ),
          Expanded(
            child: Text(
              'Search New Products',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 20 * scale.clamp(0.85, 1.2),
                fontWeight: FontWeight.w700,
                color: AppColors.vibrantPink,
              ),
            ),
          ),
          const SizedBox(width: 36),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Search Bar
// ─────────────────────────────────────────────────────────────────
class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final double scale;

  const _SearchBar({
    required this.controller,
    required this.onChanged,
    required this.onClear,
    required this.scale,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: BorderRadius.circular(50),
        border: Border.all(
          color: AppColors.royalPurple.withValues(alpha: 0.5),
          width: 1.5,
        ),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: GoogleFonts.inter(
          fontSize: 14 * scale.clamp(0.85, 1.2),
          color: AppColors.black,
        ),
        decoration: InputDecoration(
          hintText: 'Search for a Product',
          hintStyle: GoogleFonts.inter(
            fontSize: 14 * scale.clamp(0.85, 1.2),
            color: AppColors.royalPurple.withValues(alpha: 0.5),
          ),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 16, right: 8),
            child: Icon(
              Icons.search_rounded,
              color: AppColors.royalPurple,
              size: 22 * scale.clamp(0.85, 1.2),
            ),
          ),
          prefixIconConstraints: const BoxConstraints(),
          suffixIcon: controller.text.isNotEmpty
              ? GestureDetector(
                  onTap: onClear,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Icon(
                      Icons.close_rounded,
                      color: AppColors.neutralGrey,
                      size: 20 * scale.clamp(0.85, 1.2),
                    ),
                  ),
                )
              : null,
          suffixIconConstraints: const BoxConstraints(),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Empty State Body (2.0.1)
// ─────────────────────────────────────────────────────────────────
class _EmptyBody extends StatelessWidget {
  final double scale;
  const _EmptyBody({required this.scale});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 160 * scale.clamp(0.8, 1.2),
            height: 160 * scale.clamp(0.8, 1.2),
            child: Image.asset(
              'assets/icons/search_icon.png',
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Icon(
                Icons.search_rounded,
                size: 100 * scale.clamp(0.8, 1.2),
                color: AppColors.clearGrey,
              ),
            ),
          ),
          SizedBox(height: 20 * scale.clamp(0.85, 1.2)),
          Text(
            'Search by name or brand',
            style: GoogleFonts.inter(
              fontSize: 16 * scale.clamp(0.85, 1.2),
              fontWeight: FontWeight.w700,
              color: AppColors.black,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Results Body (2.0.2)
// ─────────────────────────────────────────────────────────────────
class _ResultsBody extends ConsumerWidget {
  final double scale;
  final DashboardSearchState state;

  const _ResultsBody({required this.scale, required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = scale.clamp(0.85, 1.2);
    return Column(
      children: [
        // List
        Expanded(
          child: state.results.isEmpty
              ? Center(child: Text('No results found.', style: GoogleFonts.inter(fontSize: 14 * scale, color: AppColors.neutralGrey)))
              : ListView.separated(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16 * s, // ↓ was 20
                    vertical: 6 * s,
                  ),
                  physics: const BouncingScrollPhysics(),
                  itemCount: state.results.length,
                  separatorBuilder: (_, __) => SizedBox(height: 10 * s), // ↓ was 16
                  itemBuilder: (ctx, i) => _ProductCard(
                    result: state.results[i],
                    scale: scale,
                    shoppingLists: state.shoppingLists,
                    recipes: state.recipes,
                  ),
                ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Product Card  ← ALL THE KEY SIZE CHANGES ARE HERE
// ─────────────────────────────────────────────────────────────────
class _ProductCard extends ConsumerStatefulWidget {
  final DashboardSearchResult result;
  final double scale;
  final List<ShoppingListModel> shoppingLists;
  final List<RecipeModel> recipes;

  const _ProductCard({
    required this.result,
    required this.scale,
    required this.shoppingLists,
    required this.recipes,
  });

  @override
  ConsumerState<_ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends ConsumerState<_ProductCard> {
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();

  void _toggleMenu() {
    if (_overlayEntry != null) {
      _closeMenu();
      return;
    }
    _overlayEntry = OverlayEntry(
      builder: (_) => _CardMenu(
        layerLink: _layerLink,
        scale: widget.scale,
        isFavorite: widget.result.isFavorite,
        onDismiss: _closeMenu,
        onSeeDetails: () {
          _closeMenu();
          _openDetailSheet();
        },
        onAddToList: () {
          _closeMenu();
          _showAddToListModal();
        },
        onAddToRecipe: () {
          _closeMenu();
          _showAddToRecipeModal();
        },
        onFavorite: () {
          _closeMenu();
          ref
              .read(dashboardSearchProvider.notifier)
              .toggleFavorite(widget.result.product.id);
        },
      ),
    );
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _closeMenu() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _openDetailSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ProductDetailSheet(
        result: widget.result,
        scale: widget.scale,
        shoppingLists: widget.shoppingLists,
        recipes: widget.recipes,
      ),
    );
  }

  void _showAddToListModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddToListModal(
        lists: widget.shoppingLists,
        scale: widget.scale,
        productBarcode: widget.result.product.id,
        productName: widget.result.product.name,
        productImageUrl: widget.result.product.thumbnailAsset ?? '',
      ),
    );
  }

  void _showAddToRecipeModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddToRecipeModal(
        recipes: widget.recipes,
        scale: widget.scale,
        productBarcode: widget.result.product.id,
        productName: widget.result.product.name,
        productImageUrl: widget.result.product.thumbnailAsset ?? '',
      ),
    );
  }

  @override
  void dispose() {
    _closeMenu();
    super.dispose();
  }

  Color _badgeColor(String label) => Color(ecoColorFor(label));

  @override
  Widget build(BuildContext context) {
    final eco = widget.result.badges.ecoLabel;
    final safe = widget.result.badges.safetyLabel;
    final s = widget.scale.clamp(0.85, 1.2);

    return GestureDetector(
      onTap: _openDetailSheet,
      child: Center(
        child: SizedBox(
          width: 343 * s,
          height: 158 * s,
          child: Stack(
            children: [
              // ── BADGE LAYER ────────────────────────────────────────
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 2 * s),
                child: Row(
                  children: [
                    // Left badge (eco)
                    Expanded(
                      child: Container(
                        height: 38 * s,
                        decoration: BoxDecoration(
                          color: _badgeColor(eco),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(16 * s),
                            topRight: Radius.circular(16 * s),
                          ),
                        ),
                        padding: EdgeInsets.only(top: 8 * s, bottom: 12 * s),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.eco_outlined,
                              color: Colors.white,
                              size: 14 * s,
                            ),
                            SizedBox(width: 6 * s),
                            Flexible(
                              child: Text(
                                eco,
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 11 * s,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Right badge (safety)
                    Expanded(
                      child: Container(
                        height: 38 * s,
                        decoration: BoxDecoration(
                          color: _badgeColor(safe),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(16 * s),
                            topRight: Radius.circular(16 * s),
                          ),
                        ),
                        padding: EdgeInsets.only(top: 8 * s, bottom: 12 * s),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.flag_outlined,
                              color: Colors.white,
                              size: 14 * s,
                            ),
                            SizedBox(width: 6 * s),
                            Flexible(
                              child: Text(
                                safe,
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 11 * s,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── WHITE CARD LAYER ───────────────────────────────────
              Container(
                margin: EdgeInsets.only(top: 26 * s),
                decoration: BoxDecoration(
                  color: AppColors.pureWhite,
                  borderRadius: BorderRadius.circular(20 * s),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.07),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 14 * s, vertical: 10 * s),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Product thumbnail
                  Container(
                    width: 64 * s,
                    height: 64 * s,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF9C4).withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: _buildProductImage(widget.result.product.thumbnailAsset, widget.scale),
                      ),
                    ),
                  ),

                  SizedBox(width: 12 * s),
                  // Name + description — centered
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          widget.result.product.name,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 15 * s,
                            fontWeight: FontWeight.w700,
                            color: AppColors.black,
                          ),
                        ),
                        SizedBox(height: 3 * s),
                        Text(
                          widget.result.product.description,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 12 * s,
                            color: AppColors.darkGrey,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),

                  // Three-dot menu
                  CompositedTransformTarget(
                    link: _layerLink,
                    child: GestureDetector(
                      onTap: _toggleMenu,
                      behavior: HitTestBehavior.opaque,
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: Icon(
                          Icons.more_horiz,
                          color: AppColors.black,
                          size: 20 * s,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  ),
);
}
}

// ─────────────────────────────────────────────────────────────────
// Context Menu Overlay (2.0.4)
// ─────────────────────────────────────────────────────────────────
class _CardMenu extends StatelessWidget {
  final LayerLink layerLink;
  final double scale;
  final bool isFavorite;
  final VoidCallback onDismiss;
  final VoidCallback onSeeDetails;
  final VoidCallback onAddToList;
  final VoidCallback onAddToRecipe;
  final VoidCallback onFavorite;

  const _CardMenu({
    required this.layerLink,
    required this.scale,
    required this.isFavorite,
    required this.onDismiss,
    required this.onSeeDetails,
    required this.onAddToList,
    required this.onAddToRecipe,
    required this.onFavorite,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: onDismiss,
      child: Stack(
        children: [
          CompositedTransformFollower(
            link: layerLink,
            showWhenUnlinked: false,
            offset: const Offset(-170, 30),
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: 210,
                decoration: BoxDecoration(
                  color: AppColors.pureWhite,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _MenuRow(
                      label: 'See More Details',
                      icon: Icons.remove_red_eye_outlined,
                      scale: scale,
                      onTap: onSeeDetails,
                    ),
                    _divider(),
                    _MenuRow(
                      label: 'Add to a Shopping List',
                      icon: Icons.shopping_bag_outlined,
                      scale: scale,
                      onTap: onAddToList,
                    ),
                    _divider(),
                    _MenuRow(
                      label: 'Add to a Recipe',
                      icon: Icons.menu_book_outlined,
                      scale: scale,
                      onTap: onAddToRecipe,
                    ),
                    _divider(),
                    _MenuRow(
                      label: isFavorite ? 'Mark as un favorite' : 'Mark as favorite',
                      icon: isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                      scale: scale,
                      onTap: onFavorite,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() =>
      const Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE));
}

class _MenuRow extends StatelessWidget {
  final String label;
  final IconData icon;
  final double scale;
  final VoidCallback onTap;

  const _MenuRow({
    required this.label,
    required this.icon,
    required this.scale,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 13 * scale.clamp(0.85, 1.2),
                  fontWeight: FontWeight.w500,
                  color: AppColors.black,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Icon(
              icon,
              size: 19 * scale.clamp(0.85, 1.2),
              color: AppColors.black,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Product Detail Bottom Sheet (2.0.4)
// ─────────────────────────────────────────────────────────────────
class _ProductDetailSheet extends ConsumerStatefulWidget {
  final DashboardSearchResult result;
  final double scale;
  final List<ShoppingListModel> shoppingLists;
  final List<RecipeModel> recipes;

  const _ProductDetailSheet({
    required this.result,
    required this.scale,
    required this.shoppingLists,
    required this.recipes,
  });

  @override
  ConsumerState<_ProductDetailSheet> createState() => _ProductDetailSheetState();
}

class _ProductDetailSheetState extends ConsumerState<_ProductDetailSheet> {
  Color _ecoColor(String label) => Color(ecoColorFor(label));

  void _showAddToList() {
    Navigator.pop(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddToListModal(
        lists: widget.shoppingLists,
        scale: widget.scale,
        productBarcode: widget.result.product.id,
        productName: widget.result.product.name,
        productImageUrl: widget.result.product.thumbnailAsset ?? '',
      ),
    );
  }

  void _showAddToRecipe() {
    Navigator.pop(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddToRecipeModal(
        recipes: widget.recipes,
        scale: widget.scale,
        productBarcode: widget.result.product.id,
        productName: widget.result.product.name,
        productImageUrl: widget.result.product.thumbnailAsset ?? '',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.scale.clamp(0.85, 1.2);
    final eco = widget.result.badges.ecoLabel;
    final safe = widget.result.badges.safetyLabel;
    final product = widget.result.product;
    final isFav = ref.watch(favoritesProvider).items.any((i) => i.barcode == product.id);
    final size = MediaQuery.sizeOf(context);

    return Container(
      height: size.height * 0.85,
      margin: EdgeInsets.fromLTRB(16 * s, 16 * s, 16 * s, 24 * s),
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: BorderRadius.circular(24 * s),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 4),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.clearGrey,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: AppColors.softGrey,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.close_rounded,
                        size: 18 * s,
                        color: AppColors.darkGrey,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  product.name,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 18 * s,
                    fontWeight: FontWeight.w700,
                    color: AppColors.vibrantPink,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  product.description,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 13 * s,
                    color: AppColors.darkGrey,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24 * s),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24 * s),
                    child: Stack(
                      children: [
                        // ── BADGE LAYER (behind) ──
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 90 * s,
                                decoration: BoxDecoration(
                                  color: _ecoColor(eco),
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(24 * s),
                                    topRight: Radius.circular(16 * s),
                                  ),
                                ),
                                alignment: Alignment.topCenter,
                                padding: EdgeInsets.only(top: 14 * s),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.eco_outlined, color: Colors.white, size: 15 * s),
                                    SizedBox(width: 6 * s),
                                    Text(
                                      eco,
                                      style: GoogleFonts.inter(
                                        fontSize: 12 * s,
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
                                height: 90 * s,
                                decoration: BoxDecoration(
                                  color: _ecoColor(safe),
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(16 * s),
                                    topRight: Radius.circular(24 * s),
                                  ),
                                ),
                                alignment: Alignment.topCenter,
                                padding: EdgeInsets.only(top: 14 * s),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.flag_outlined, color: Colors.white, size: 15 * s),
                                    SizedBox(width: 6 * s),
                                    Text(
                                      safe,
                                      style: GoogleFonts.inter(
                                        fontSize: 12 * s,
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

                        // ── WHITE CARD LAYER (in front) ──
                        Container(
                          margin: EdgeInsets.only(top: 46 * s),
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: AppColors.pureWhite,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(24 * s),
                              topRight: Radius.circular(24 * s),
                            ),
                          ),
                          padding: EdgeInsets.symmetric(vertical: 20 * s, horizontal: 20 * s),
                          child: Stack(
                            alignment: Alignment.topRight,
                            children: [
                              Center(
                                child: product.imageAsset != null && product.imageAsset!.isNotEmpty
                                    ? (() {
                                        final resolved = _resolveImageUrl(product.imageAsset);
                                        if (resolved != null && (resolved.startsWith('http') || resolved.startsWith('https'))) {
                                          return Image.network(
                                            resolved,
                                            height: 180 * s,
                                            fit: BoxFit.contain,
                                            errorBuilder: (_, __, ___) => Icon(
                                              Icons.image_outlined,
                                              size: 80 * s,
                                              color: AppColors.neutralGrey,
                                            ),
                                          );
                                        } else {
                                          return Image.asset(
                                            resolved ?? product.imageAsset!,
                                            height: 180 * s,
                                            fit: BoxFit.contain,
                                            errorBuilder: (_, __, ___) => Icon(
                                              Icons.image_outlined,
                                              size: 80 * s,
                                              color: AppColors.neutralGrey,
                                            ),
                                          );
                                        }
                                      })()
                                    : Icon(
                                        Icons.image_outlined,
                                        size: 80 * s,
                                        color: AppColors.neutralGrey,
                                      ),
                              ),
                              // Favorite Heart Icon overlay in the top right of the card
                              GestureDetector(
                                onTap: () async {
                                  final notifier = ref.read(favoritesProvider.notifier);
                                  if (isFav) {
                                    await notifier.removeItem(product.id);
                                  } else {
                                    await notifier.addFavorite(
                                      barcode: product.id,
                                      productName: product.name,
                                      productImageUrl: product.thumbnailAsset,
                                    );
                                  }
                                },
                                child: Icon(
                                  isFav
                                      ? Icons.favorite_rounded
                                      : Icons.favorite_border_rounded,
                                  color: isFav
                                      ? AppColors.vibrantPink
                                      : AppColors.neutralGrey,
                                  size: 26 * s,
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
                _ChipSection(
                  title: 'Labels and Certifications',
                  items: product.labels.isNotEmpty ? product.labels : const ['None Listed'],
                  scale: s,
                ),
                const SizedBox(height: 16),
                _ChipSection(
                  title: 'Possible allergens',
                  items: product.allergens.isNotEmpty ? product.allergens : const ['No Allergens Listed'],
                  scale: s,
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _OutlineActionButton(
                        label: 'Add To List',
                        icon: Icons.add_shopping_cart_outlined,
                        scale: s,
                        onTap: _showAddToList,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _OutlineActionButton(
                        label: 'Add To Recipe',
                        icon: Icons.menu_book_outlined,
                        scale: s,
                        onTap: _showAddToRecipe,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 52 * s,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      context.push('/product-detail', extra: product);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.royalPurple,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'See More Details',
                      style: GoogleFonts.inter(
                        fontSize: 15 * s,
                        fontWeight: FontWeight.w600,
                        color: AppColors.pureWhite,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    'Swipe up to see similar',
                    style: GoogleFonts.inter(
                      fontSize: 12 * s,
                      color: AppColors.neutralGrey,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }
}




// ─────────────────────────────────────────────────────────────────
// Chip Section
// ─────────────────────────────────────────────────────────────────
class _ChipSection extends StatelessWidget {
  final String title;
  final List<String> items;
  final double scale;

  const _ChipSection({
    required this.title,
    required this.items,
    required this.scale,
  });

  @override
  Widget build(BuildContext context) {
    final s = scale.clamp(0.85, 1.2);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 15 * s,
            fontWeight: FontWeight.w700,
            color: AppColors.black,
          ),
        ),
        SizedBox(height: 12 * s),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (int i = 0; i < items.length; i++) ...[
                LabelCircle(label: items[i], scale: s),
                if (i < items.length - 1) SizedBox(width: 8 * s),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Outline Action Button
// ─────────────────────────────────────────────────────────────────
class _OutlineActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final double scale;
  final VoidCallback onTap;

  const _OutlineActionButton({
    required this.label,
    required this.icon,
    required this.scale,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 46 * scale,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.royalPurple, width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.royalPurple, size: 18 * scale),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13 * scale,
                fontWeight: FontWeight.w600,
                color: AppColors.royalPurple,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Add to Shopping List Modal (2.0.5)
// ─────────────────────────────────────────────────────────────────
class _AddToListModal extends ConsumerStatefulWidget {
  final List<ShoppingListModel> lists;
  final double scale;
  final String productBarcode;
  final String productName;
  final String productImageUrl;

  const _AddToListModal({
    required this.lists,
    required this.scale,
    required this.productBarcode,
    required this.productName,
    required this.productImageUrl,
  });

  @override
  ConsumerState<_AddToListModal> createState() => _AddToListModalState();
}

class _AddToListModalState extends ConsumerState<_AddToListModal> {
  late final List<bool> _checked;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _checked = List.generate(widget.lists.length, (_) => false);
  }

  Future<void> _onSave() async {
    // Collect selected list IDs
    final selectedLists = <String>[];
    for (int i = 0; i < widget.lists.length; i++) {
      if (_checked[i]) selectedLists.add(widget.lists[i].id);
    }
    if (selectedLists.isEmpty) return;

    setState(() => _isSaving = true);
    int successCount = 0;
    for (final listId in selectedLists) {
      try {
        await ListApiService.instance.addItem(
          listId,
          barcode: widget.productBarcode,
          productName: widget.productName,
          productImageUrl: widget.productImageUrl,
          quantity: 1,
        );
        successCount++;
      } catch (_) {}
    }
    if (!mounted) return;
    setState(() => _isSaving = false);
    Navigator.pop(context);
    if (successCount > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(successCount == 1
              ? 'Product added to shopping list!'
              : 'Product added to $successCount lists!'),
          backgroundColor: AppColors.royalPurple,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.scale.clamp(0.85, 1.2);
    return _BaseModal(
      scale: s,
      title: 'Which shopping list do you want\nto add this product?',
      saveLabel: _isSaving ? 'Saving...' : 'Save On List',
      onSave: _isSaving ? null : _onSave,
      child: widget.lists.isEmpty
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'No shopping lists found. Create a list first.',
                style: GoogleFonts.inter(
                  fontSize: 13 * s,
                  color: AppColors.darkGrey,
                ),
              ),
            )
          : Column(
              children: List.generate(widget.lists.length, (i) {
                return _CheckRow(
                  label: widget.lists[i].title,
                  checked: _checked[i],
                  scale: s,
                  onChanged: (v) => setState(() => _checked[i] = v),
                );
              }),
            ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Add to Recipe Modal (2.0.6)
// ─────────────────────────────────────────────────────────────────
class _AddToRecipeModal extends ConsumerStatefulWidget {
  final List<RecipeModel> recipes;
  final double scale;
  final String productBarcode;
  final String productName;
  final String productImageUrl;

  const _AddToRecipeModal({
    required this.recipes,
    required this.scale,
    required this.productBarcode,
    required this.productName,
    required this.productImageUrl,
  });

  @override
  ConsumerState<_AddToRecipeModal> createState() => _AddToRecipeModalState();
}

class _AddToRecipeModalState extends ConsumerState<_AddToRecipeModal> {
  late final List<bool> _checked;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _checked = List.generate(widget.recipes.length, (_) => false);
  }

  Future<void> _onSave() async {
    final selectedRecipes = <RecipeModel>[];
    for (int i = 0; i < widget.recipes.length; i++) {
      if (_checked[i]) selectedRecipes.add(widget.recipes[i]);
    }
    if (selectedRecipes.isEmpty) return;

    setState(() => _isSaving = true);
    int successCount = 0;
    for (final recipe in selectedRecipes) {
      try {
        await RecipeApiService.instance.addLinkedProduct(recipe.id, {
          'barcode': widget.productBarcode,
          'productName': widget.productName,
          'productImageUrl': widget.productImageUrl,
          'quantity': 1,
          'position': 1,
        });
        successCount++;
      } catch (_) {}
    }
    if (!mounted) return;
    setState(() => _isSaving = false);
    Navigator.pop(context);
    if (successCount > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            successCount == 1
                ? 'Product added to recipe successfully!'
                : 'Product added to $successCount recipes!',
          ),
          backgroundColor: AppColors.royalPurple,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.scale.clamp(0.85, 1.2);
    return _BaseModal(
      scale: s,
      title: 'Which recipe do you want to add\nthis product?',
      saveLabel: _isSaving ? 'Saving...' : 'Save On Recipe',
      onSave: _isSaving ? null : _onSave,
      child: widget.recipes.isEmpty
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'No recipes found. Create a recipe first.',
                style: GoogleFonts.inter(
                  fontSize: 13 * s,
                  color: AppColors.darkGrey,
                ),
              ),
            )
          : Column(
              children: List.generate(widget.recipes.length, (i) {
                return _CheckRow(
                  label: widget.recipes[i].title,
                  checked: _checked[i],
                  scale: s,
                  onChanged: (v) => setState(() => _checked[i] = v),
                );
              }),
            ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Base Modal
// ─────────────────────────────────────────────────────────────────
class _BaseModal extends StatelessWidget {
  final double scale;
  final String title;
  final String saveLabel;
  final VoidCallback? onSave;
  final Widget child;

  const _BaseModal({
    required this.scale,
    required this.title,
    required this.saveLabel,
    required this.onSave,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: MediaQuery.viewInsetsOf(context),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        decoration: BoxDecoration(
          color: AppColors.pureWhite,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.softGrey,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.close_rounded,
                      size: 18 * scale,
                      color: AppColors.darkGrey,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 15 * scale,
                  fontWeight: FontWeight.w700,
                  color: AppColors.black,
                ),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: child,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 52 * scale,
                child: ElevatedButton(
                  onPressed: onSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.royalPurple,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    saveLabel,
                    style: GoogleFonts.inter(
                      fontSize: 15 * scale,
                      fontWeight: FontWeight.w600,
                      color: AppColors.pureWhite,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Checkbox Row
// ─────────────────────────────────────────────────────────────────
class _CheckRow extends StatelessWidget {
  final String label;
  final bool checked;
  final double scale;
  final ValueChanged<bool> onChanged;

  const _CheckRow({
    required this.label,
    required this.checked,
    required this.scale,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onChanged(!checked),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 22 * scale,
              height: 22 * scale,
              decoration: BoxDecoration(
                color: checked ? AppColors.royalPurple : Colors.transparent,
                borderRadius: BorderRadius.circular(5),
                border: Border.all(
                  color: checked ? AppColors.royalPurple : AppColors.clearGrey,
                  width: 2,
                ),
              ),
              child: checked
                  ? Icon(
                      Icons.check_rounded,
                      color: AppColors.pureWhite,
                      size: 14 * scale,
                    )
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 14 * scale,
                  fontWeight: FontWeight.w500,
                  color: AppColors.black,
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
// Filter Sheet (2.0.7)
// ─────────────────────────────────────────────────────────────────
class _FilterSheet extends StatefulWidget {
  final double scale;
  final WidgetRef ref;
  const _FilterSheet({required this.scale, required this.ref});

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  String _sortBy = 'Most Recent';
  final List<String> _sortOptions = ['Most Recent', 'A-Z', 'Z-A', 'Eco Score'];

  final List<String> _filter2Options = [
    'Eco-Friendly',
    'Moderate Impact',
    'Unsustainable',
  ];
  final List<String> _filter3Options = [
    'Safe',
    'Avoid',
  ];

  final Set<String> _selected2 = {};
  final Set<String> _selected3 = {};

  @override
  void initState() {
    super.initState();
    final currentFilter = widget.ref.read(dashboardSearchProvider).filter;
    _sortBy = currentFilter.sortBy;
    _selected2.addAll(currentFilter.filter2Tags);
    _selected3.addAll(currentFilter.filter3Tags);
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.scale.clamp(0.85, 1.2);

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Filter Preferences',
                  style: GoogleFonts.inter(
                    fontSize: 17 * s,
                    fontWeight: FontWeight.w700,
                    color: AppColors.black,
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: const BoxDecoration(
                      color: AppColors.softGrey,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.close_rounded,
                      size: 18 * s,
                      color: AppColors.darkGrey,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              'Sort By',
              style: GoogleFonts.inter(
                fontSize: 13 * s,
                fontWeight: FontWeight.w600,
                color: AppColors.darkGrey,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.clearGrey, width: 1.5),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _sortBy,
                  isExpanded: true,
                  icon: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: AppColors.darkGrey,
                    size: 22 * s,
                  ),
                  style: GoogleFonts.inter(
                    fontSize: 14 * s,
                    color: AppColors.black,
                  ),
                  items: _sortOptions
                      .map((o) => DropdownMenuItem(value: o, child: Text(o)))
                      .toList(),
                  onChanged: (v) => setState(() => _sortBy = v ?? _sortBy),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Sustainability Level',
              style: GoogleFonts.inter(
                fontSize: 13 * s,
                fontWeight: FontWeight.w600,
                color: AppColors.darkGrey,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _filter2Options
                  .map(
                    (tag) => _FilterChip(
                      label: tag,
                      selected: _selected2.contains(tag),
                      scale: s,
                      onTap: () => setState(
                        () => _selected2.contains(tag)
                            ? _selected2.remove(tag)
                            : _selected2.add(tag),
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 20),
            Text(
              'Safety Level',
              style: GoogleFonts.inter(
                fontSize: 13 * s,
                fontWeight: FontWeight.w600,
                color: AppColors.darkGrey,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _filter3Options
                  .map(
                    (tag) => _FilterChip(
                      label: tag,
                      selected: _selected3.contains(tag),
                      scale: s,
                      onTap: () => setState(
                        () => _selected3.contains(tag)
                            ? _selected3.remove(tag)
                            : _selected3.add(tag),
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52 * s,
              child: ElevatedButton(
                onPressed: () {
                  widget.ref
                      .read(dashboardSearchProvider.notifier)
                      .updateFilter(
                        DashboardSearchFilter(
                          sortBy: _sortBy,
                          filter2Tags: _selected2.toList(),
                          filter3Tags: _selected3.toList(),
                        ),
                      );
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.royalPurple,
                  disabledBackgroundColor: AppColors.royalPurple.withValues(
                    alpha: 0.3,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Show Results',
                  style: GoogleFonts.inter(
                    fontSize: 15 * s,
                    fontWeight: FontWeight.w600,
                    color: AppColors.pureWhite,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final double scale;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.scale,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.royalPurple.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.royalPurple : AppColors.clearGrey,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12 * scale,
            fontWeight: FontWeight.w500,
            color: selected ? AppColors.royalPurple : AppColors.darkGrey,
          ),
        ),
      ),
    );
  }
}

// Helper functions for image resolution
String? _resolveImageUrl(String? url) {
  if (url == null || url.isEmpty) return null;
  if (url.startsWith('http://') || url.startsWith('https://')) {
    return url;
  }
  if (url.startsWith('assets/')) {
    return url;
  }
  final baseUrl = ApiClient.instance.dio.options.baseUrl;
  final rootUrl = baseUrl.endsWith('/api/v1')
      ? baseUrl.substring(0, baseUrl.length - 7)
      : baseUrl;
  final path = url.startsWith('/') ? url : '/$url';
  return '$rootUrl$path';
}

Widget _buildProductImage(String? path, double scale) {
  if (path == null || path.isEmpty) {
    return const Icon(
      Icons.image_outlined,
      color: AppColors.neutralGrey,
    );
  }

  final resolvedPath = _resolveImageUrl(path);

  if (resolvedPath != null && (resolvedPath.startsWith('http') || resolvedPath.startsWith('https'))) {
    return Image.network(
      resolvedPath,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => const Icon(
        Icons.image_outlined,
        color: AppColors.neutralGrey,
      ),
    );
  } else {
    return Image.asset(
      resolvedPath ?? path,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => const Icon(
        Icons.image_outlined,
        color: AppColors.neutralGrey,
      ),
    );
  }
}
