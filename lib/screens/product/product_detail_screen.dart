import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import '../../models/product_model.dart';
import '../../providers/product_detail_provider.dart';
import '../../widgets/bottom_nav_bar.dart';

// ═══════════════════════════════════════════════════════════════
// Product Detail Screen  (frames 2.1.0 → 2.1.3)
// ═══════════════════════════════════════════════════════════════
class ProductDetailScreen extends ConsumerWidget {
  final ProductModel product;
  const ProductDetailScreen({super.key, required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(productDetailProvider(product));
    final notifier = ref.read(productDetailProvider(product).notifier);
    final size = MediaQuery.sizeOf(context);
    final padding = MediaQuery.paddingOf(context);
    final scale = (size.width / 390).clamp(0.85, 1.3);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: AppColors.pageBackground,
        body: Stack(
          children: [
            // ── Main scrollable content ──
            Column(
              children: [
                _ProductDetailHeader(
                  padding: padding,
                  scale: scale,
                  onBack: () => Navigator.of(context).maybePop(),
                  onMoreTap: notifier.showMoreActions,
                ),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.only(bottom: 100 * scale),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // ── Title & subtitle ──
                        Padding(
                          padding: EdgeInsets.fromLTRB(
                            24 * scale,
                            20 * scale,
                            24 * scale,
                            0,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                state.product.name,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(
                                  fontSize: 20 * scale,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.vibrantPink,
                                ),
                              ),
                              SizedBox(height: 4 * scale),
                              Text(
                                state.product.description,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(
                                  fontSize: 13 * scale,
                                  color: AppColors.darkGrey,
                                ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: 16 * scale),

                        // ── Product image with badges ──
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16 * scale),
                          child: _ProductImageCard(
                            product: state.product,
                            isFavorite: state.isFavorite,
                            scale: scale,
                            onFavoriteTap: notifier.toggleFavorite,
                          ),
                        ),

                        SizedBox(height: 24 * scale),

                        // ── Labels and Certifications (hidden if empty) ──
                        if (state.product.labels.isNotEmpty) ...[
                          _SectionTitle(
                            title: 'Labels and Certifications',
                            scale: scale,
                          ),
                          SizedBox(height: 12 * scale),
                          _HexagonLabelRow(
                            labels: state.product.labels,
                            scale: scale,
                          ),
                          SizedBox(height: 24 * scale),
                        ],

                        // ── Possible allergens (hidden if empty) ──
                        if (state.product.allergens.isNotEmpty) ...[
                          _SectionTitle(
                            title: 'Possible allergens',
                            scale: scale,
                          ),
                          SizedBox(height: 12 * scale),
                          _HexagonLabelRow(
                            labels: state.product.allergens,
                            scale: scale,
                          ),
                          SizedBox(height: 24 * scale),
                        ],

                        // ── Ingredients list (hidden if empty) ──
                        if (state.product.ingredients.isNotEmpty) ...[
                          _SectionTitle(title: 'Ingredients list', scale: scale),
                          SizedBox(height: 8 * scale),
                          _IngredientsList(
                            ingredients: state.product.ingredients,
                            scale: scale,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // ── Bottom Nav ──
            const Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: LuvcoBottomNavBar(),
            ),

            // ── More Actions Popup ──
            if (state.popup == ProductDetailPopup.moreActions)
              _MoreActionsPopup(
                scale: scale,
                onDismiss: notifier.closePopup,
                onAddToList: notifier.showAddToList,
                onAddToRecipe: notifier.showAddToRecipe,
                onMarkFavorite: () {
                  notifier.toggleFavorite();
                  notifier.closePopup();
                },
              ),

            // ── Add to Shopping List Dialog ──
            if (state.popup == ProductDetailPopup.addToList)
              _CheckboxDialog(
                title: 'Which shopping list do you want\nto add this product?',
                items: state.shoppingLists,
                selected: state.selectedLists,
                buttonLabel: 'Save On List',
                scale: scale,
                size: size,
                onToggle: notifier.toggleList,
                onSave: notifier.saveOnList,
                onDismiss: notifier.closePopup,
              ),

            // ── Add to Recipe Dialog ──
            if (state.popup == ProductDetailPopup.addToRecipe)
              _CheckboxDialog(
                title: 'Which recipe do you want to add\nthis product?',
                items: state.recipes,
                selected: state.selectedRecipes,
                buttonLabel: 'Save On Recipe',
                scale: scale,
                size: size,
                onToggle: notifier.toggleRecipe,
                onSave: notifier.saveOnRecipe,
                onDismiss: notifier.closePopup,
              ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Header
// ═══════════════════════════════════════════════════════════════
class _ProductDetailHeader extends StatelessWidget {
  final EdgeInsets padding;
  final double scale;
  final VoidCallback onBack;
  final VoidCallback onMoreTap;

  const _ProductDetailHeader({
    required this.padding,
    required this.scale,
    required this.onBack,
    required this.onMoreTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.pureWhite,
      padding: EdgeInsets.only(
        top: padding.top + 8,
        left: 16 * scale,
        right: 16 * scale,
        bottom: 12 * scale,
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: onBack,
            behavior: HitTestBehavior.opaque,
            child: Icon(
              Icons.chevron_left,
              size: 28 * scale,
              color: AppColors.vibrantPink,
            ),
          ),
          Expanded(
            child: Center(
              child: Text(
                'Product Detail',
                style: GoogleFonts.inter(
                  fontSize: 18 * scale,
                  fontWeight: FontWeight.w700,
                  color: AppColors.vibrantPink,
                ),
              ),
            ),
          ),
          GestureDetector(
            onTap: onMoreTap,
            behavior: HitTestBehavior.opaque,
            child: Icon(
              Icons.more_horiz,
              size: 24 * scale,
              color: AppColors.darkGrey,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Product image card with badges + heart  — Figma exact match
// ═══════════════════════════════════════════════════════════════
class _ProductImageCard extends StatelessWidget {
  final ProductModel product;
  final bool isFavorite;
  final double scale;
  final VoidCallback onFavoriteTap;

  const _ProductImageCard({
    required this.product,
    required this.isFavorite,
    required this.scale,
    required this.onFavoriteTap,
  });

  @override
  Widget build(BuildContext context) {
    // Derive labels and colors dynamically
    final sustainLabel = product.isSustainable ? 'Sustainable' : 'Unsustainable';
    final sustainColor = product.isSustainable
        ? const Color(0xFF43A047)
        : const Color(0xFFE53935);
    const safeLabel = 'Safe';
    const safeColor = Color(0xFF43A047);

    final s = scale.clamp(0.85, 1.2);

    return Container(
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
            // Top tabs (Unsustainable/Sustainable & Safe) - Background Layer
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 90 * s,
                    decoration: BoxDecoration(
                      color: sustainColor,
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
                        Icon(
                          Icons.eco_outlined,
                          color: Colors.white,
                          size: 16 * s,
                        ),
                        SizedBox(width: 5 * s),
                        Text(
                          sustainLabel,
                          style: GoogleFonts.inter(
                            fontSize: 11 * s,
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
                      color: safeColor,
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
                        Icon(
                          Icons.flag_outlined,
                          color: Colors.white,
                          size: 16 * s,
                        ),
                        SizedBox(width: 5 * s),
                        Text(
                          safeLabel,
                          style: GoogleFonts.inter(
                            fontSize: 11 * s,
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
            // Bottom Image Section - Foreground Layer (Overlapping)
            Container(
              margin: EdgeInsets.only(top: 46 * s),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24 * s),
                  topRight: Radius.circular(24 * s),
                ),
              ),
              padding: EdgeInsets.only(top: 20 * s, bottom: 20 * s),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Product image
                  if (product.imageAsset != null && product.imageAsset!.isNotEmpty)
                    (product.imageAsset!.startsWith('http') || product.imageAsset!.startsWith('https'))
                        ? Image.network(
                            product.imageAsset!,
                            height: 180 * s,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => Icon(
                              Icons.image_outlined,
                              size: 80 * s,
                              color: AppColors.neutralGrey,
                            ),
                            loadingBuilder: (ctx, child, prog) {
                              if (prog == null) return child;
                              return SizedBox(
                                height: 180 * s,
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.royalPurple,
                                  ),
                                ),
                              );
                            },
                          )
                        : Image.asset(
                            product.imageAsset!,
                            height: 180 * s,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => Icon(
                              Icons.image_outlined,
                              size: 80 * s,
                              color: AppColors.neutralGrey,
                            ),
                          )
                  else
                    Icon(
                      Icons.image_outlined,
                      size: 80 * s,
                      color: AppColors.neutralGrey,
                    ),
                  
                  // Heart save button
                  Positioned(
                    right: 16 * s,
                    top: 0,
                    child: GestureDetector(
                      onTap: onFavoriteTap,
                      behavior: HitTestBehavior.opaque,
                      child: Icon(
                        isFavorite
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
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

// ═══════════════════════════════════════════════════════════════
// Section title
// ═══════════════════════════════════════════════════════════════
class _SectionTitle extends StatelessWidget {
  final String title;
  final double scale;
  const _SectionTitle({required this.title, required this.scale});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16 * scale),
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 15 * scale,
          fontWeight: FontWeight.w700,
          color: AppColors.black,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Hexagon label row  (Labels + Allergens)
// ═══════════════════════════════════════════════════════════════
class _HexagonLabelRow extends StatelessWidget {
  final List<String> labels;
  final double scale;
  const _HexagonLabelRow({required this.labels, required this.scale});

  /// Strip language prefix (e.g. "en:", "fr:") and clean up the text.
  static String _cleanLabel(String raw) {
    String cleaned = raw.replaceAll(RegExp(r'^[a-z]{2}:'), '');
    cleaned = cleaned.replaceAll(RegExp(r'[-_]'), ' ').trim();
    if (cleaned.isEmpty) return raw;
    return cleaned
        .split(' ')
        .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : w)
        .join(' ');
  }

  /// Keep only English (no prefix or "en:" prefix) labels.
  static List<String> _filterEnglish(List<String> all) {
    final englishOnly = all
        .where((l) => !RegExp(r'^[a-z]{2}:').hasMatch(l) || l.startsWith('en:'))
        .toList();
    return englishOnly.isNotEmpty ? englishOnly : all;
  }

  static (IconData, Color) _getIconAndColor(String name) {
    final lower = name.toLowerCase();
    
    // Allergens
    if (lower.contains('gluten') || lower.contains('wheat')) {
      return (Icons.grain_rounded, const Color(0xFFE5A93C)); // Amber/Orange
    }
    if (lower.contains('nut') || lower.contains('almond') || lower.contains('hazelnut') || lower.contains('pecan') || lower.contains('cashew')) {
      return (Icons.cookie_rounded, const Color(0xFF8D6E63)); // Brown
    }
    if (lower.contains('milk') || lower.contains('lactose') || lower.contains('dairy')) {
      return (Icons.water_drop_rounded, const Color(0xFF64B5F6)); // Light Blue
    }
    if (lower.contains('egg')) {
      return (Icons.egg_rounded, const Color(0xFFFFD54F)); // Yellow
    }
    if (lower.contains('soy')) {
      return (Icons.grass_rounded, const Color(0xFF81C784)); // Green
    }
    if (lower.contains('fish') || lower.contains('seafood') || lower.contains('shrimp')) {
      return (Icons.set_meal_rounded, const Color(0xFF4FC3F7)); // Blue
    }

    // Certifications & Labels
    if (lower.contains('organic') || lower.contains('bio')) {
      return (Icons.eco_rounded, const Color(0xFF4CAF50)); // Green
    }
    if (lower.contains('ecocert')) {
      return (Icons.verified_rounded, const Color(0xFF2E7D32)); // Dark Green
    }
    if (lower.contains('green dot') || lower.contains('recycl')) {
      return (Icons.recycling_rounded, const Color(0xFF388E3C)); // Green
    }
    if (lower.contains('agriculture') || lower.contains('grower')) {
      return (Icons.spa_rounded, const Color(0xFF81C784)); // Soft Green
    }
    if (lower.contains('vegan') || lower.contains('vegetarian')) {
      return (Icons.spa_rounded, const Color(0xFF4CAF50)); // Green
    }
    if (lower.contains('halal') || lower.contains('kosher')) {
      return (Icons.task_alt_rounded, const Color(0xFF009688)); // Teal
    }
    if (lower.contains('fair trade') || lower.contains('fairtrade')) {
      return (Icons.handshake_rounded, const Color(0xFF00897B)); // Teal
    }

    return (Icons.verified_rounded, const Color(0xFF7B52D3)); // Purple accent
  }

  Widget _buildLabelItem(String label) {
    final clean = _cleanLabel(label);
    final iconInfo = _getIconAndColor(clean);
    final iconData = iconInfo.$1;
    final iconColor = iconInfo.$2;

    return Padding(
      padding: EdgeInsets.only(right: 14 * scale),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 58 * scale,
            height: 58 * scale,
            decoration: BoxDecoration(
              color: AppColors.pureWhite,
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.clearGrey,
                width: 1.2,
              ),
            ),
            child: Center(
              child: Icon(
                iconData,
                color: iconColor,
                size: 26 * scale,
              ),
            ),
          ),
          SizedBox(height: 6 * scale),
          SizedBox(
            width: 68 * scale,
            child: Text(
              clean,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 10 * scale,
                color: AppColors.black,
                fontWeight: FontWeight.w500,
                height: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (labels.isEmpty) return const SizedBox.shrink();
    final items = _filterEnglish(labels);

    final List<String> row1;
    final List<String> row2;

    if (items.length <= 4) {
      row1 = items;
      row2 = [];
    } else {
      final half = (items.length / 2).ceil();
      row1 = items.sublist(0, half);
      row2 = items.sublist(half);
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16 * scale),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: row1.map((label) => _buildLabelItem(label)).toList(),
            ),
          ),
          if (row2.isNotEmpty) ...[
            SizedBox(height: 12 * scale),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: row2.map((label) => _buildLabelItem(label)).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Ingredients list with "See All Ingredients" link
// ═══════════════════════════════════════════════════════════════
class _IngredientsList extends StatefulWidget {
  final List<String> ingredients;
  final double scale;
  const _IngredientsList({required this.ingredients, required this.scale});

  @override
  State<_IngredientsList> createState() => _IngredientsListState();
}

class _IngredientsListState extends State<_IngredientsList> {
  bool _showAll = false;

  @override
  Widget build(BuildContext context) {
    final items = widget.ingredients.isEmpty
        ? const <String>[]
        : widget.ingredients;

    if (items.isEmpty) return const SizedBox.shrink();

    final visible = _showAll ? items : items.take(6).toList();

    return Column(
      children: [
        ...visible.asMap().entries.map((e) {
          final isLast = e.key == visible.length - 1;
          return Column(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 16 * widget.scale,
                  vertical: 10 * widget.scale,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            e.value,
                            style: GoogleFonts.inter(
                              fontSize: 14 * widget.scale,
                              fontWeight: FontWeight.w500,
                              color: AppColors.darkGrey,
                            ),
                          ),
                          SizedBox(height: 3 * widget.scale),
                          Text(
                            'Nutritional Info',
                            style: GoogleFonts.inter(
                              fontSize: 12 * widget.scale,
                              color: AppColors.neutralGrey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (!isLast)
                Divider(
                  height: 1,
                  color: AppColors.clearGrey,
                  indent: 16 * widget.scale,
                  endIndent: 16 * widget.scale,
                ),
            ],
          );
        }),

        // ── See All Ingredients ──
        if (!_showAll && items.length > 6)
          GestureDetector(
            onTap: () => setState(() => _showAll = true),
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 12 * widget.scale),
              child: Text(
                'See All Ingredients',
                style: GoogleFonts.inter(
                  fontSize: 13 * widget.scale,
                  color: AppColors.darkGrey,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),

        // Always show "See All Ingredients" link (matches Figma)
        if (_showAll || items.length <= 6)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 12 * widget.scale),
            child: Text(
              'See All Ingredients',
              style: GoogleFonts.inter(
                fontSize: 13 * widget.scale,
                color: AppColors.darkGrey,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// More Actions Popup  (frame 2.1.1)
// ═══════════════════════════════════════════════════════════════
class _MoreActionsPopup extends StatelessWidget {
  final double scale;
  final VoidCallback onDismiss;
  final VoidCallback onAddToList;
  final VoidCallback onAddToRecipe;
  final VoidCallback onMarkFavorite;

  const _MoreActionsPopup({
    required this.scale,
    required this.onDismiss,
    required this.onAddToList,
    required this.onAddToRecipe,
    required this.onMarkFavorite,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onDismiss,
      child: Container(
        color: Colors.transparent,
        child: Align(
          alignment: Alignment.topRight,
          child: Padding(
            padding: EdgeInsets.only(top: 70 * scale, right: 16 * scale),
            child: GestureDetector(
              onTap: () {},
              child: Container(
                width: 210 * scale,
                decoration: BoxDecoration(
                  color: AppColors.pureWhite,
                  borderRadius: BorderRadius.circular(12 * scale),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _PopupAction(
                      icon: Icons.check_box_outline_blank,
                      label: 'Add to a Shopping List',
                      scale: scale,
                      onTap: onAddToList,
                    ),
                    const Divider(height: 1, color: AppColors.clearGrey),
                    _PopupAction(
                      icon: Icons.folder_open_outlined,
                      label: 'Add to a Recipe',
                      scale: scale,
                      onTap: onAddToRecipe,
                    ),
                    const Divider(height: 1, color: AppColors.clearGrey),
                    _PopupAction(
                      icon: Icons.favorite_border_rounded,
                      label: 'Mark as favorite',
                      scale: scale,
                      onTap: onMarkFavorite,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PopupAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final double scale;
  final VoidCallback onTap;

  const _PopupAction({
    required this.icon,
    required this.label,
    required this.scale,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 16 * scale,
          vertical: 14 * scale,
        ),
        child: Row(
          children: [
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
            Icon(icon, size: 20 * scale, color: AppColors.darkGrey),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Checkbox Dialog  (frames 2.1.2 & 2.1.3)
// ═══════════════════════════════════════════════════════════════
class _CheckboxDialog extends StatelessWidget {
  final String title;
  final List<String> items;
  final List<String> selected;
  final String buttonLabel;
  final double scale;
  final Size size;
  final ValueChanged<String> onToggle;
  final VoidCallback onSave;
  final VoidCallback onDismiss;

  const _CheckboxDialog({
    required this.title,
    required this.items,
    required this.selected,
    required this.buttonLabel,
    required this.scale,
    required this.size,
    required this.onToggle,
    required this.onSave,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onDismiss,
      child: Container(
        color: Colors.black.withValues(alpha: 0.4),
        // ── Align to BOTTOM ── (matches Figma 2.1.2 & 2.1.3)
        child: Align(
          alignment: Alignment.bottomCenter,
          child: GestureDetector(
            onTap: () {},
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.pureWhite,
                // Only top corners rounded — bottom sheet style
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(24 * scale),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Drag handle
                  Center(
                    child: Container(
                      margin: EdgeInsets.only(top: 12 * scale, bottom: 4 * scale),
                      width: 40 * scale,
                      height: 4 * scale,
                      decoration: BoxDecoration(
                        color: AppColors.clearGrey,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  // ── Header ──
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      20 * scale,
                      12 * scale,
                      14 * scale,
                      0,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: GoogleFonts.inter(
                              fontSize: 15 * scale,
                              fontWeight: FontWeight.w700,
                              color: AppColors.black,
                              height: 1.4,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: onDismiss,
                          child: Icon(
                            Icons.close,
                            size: 22 * scale,
                            color: AppColors.black,
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 12 * scale),

                  // ── Checkbox items ──
                  ...items.map((item) {
                    final isChecked = selected.contains(item);
                    return InkWell(
                      onTap: () => onToggle(item),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 20 * scale,
                          vertical: 12 * scale,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 22 * scale,
                              height: 22 * scale,
                              decoration: BoxDecoration(
                                color: isChecked
                                    ? AppColors.royalPurple
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(4 * scale),
                                border: Border.all(
                                  color: isChecked
                                      ? AppColors.royalPurple
                                      : AppColors.inputBorder,
                                  width: 1.5,
                                ),
                              ),
                              child: isChecked
                                  ? Icon(
                                      Icons.check,
                                      size: 14 * scale,
                                      color: Colors.white,
                                    )
                                  : null,
                            ),
                            SizedBox(width: 12 * scale),
                            Text(
                              item,
                              style: GoogleFonts.inter(
                                fontSize: 14 * scale,
                                fontWeight: FontWeight.w500,
                                color: AppColors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),

                  SizedBox(height: 16 * scale),

                  // ── Save button ──
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      20 * scale,
                      0,
                      20 * scale,
                      MediaQuery.paddingOf(context).bottom + 20 * scale,
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      height: 50 * scale,
                      child: ElevatedButton(
                        onPressed: selected.isNotEmpty ? onSave : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.royalPurple,
                          disabledBackgroundColor: AppColors.lightRoyalPurple,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12 * scale),
                          ),
                        ),
                        child: Text(
                          buttonLabel,
                          style: GoogleFonts.inter(
                            fontSize: 15 * scale,
                            fontWeight: FontWeight.w600,
                            color: AppColors.pureWhite,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
