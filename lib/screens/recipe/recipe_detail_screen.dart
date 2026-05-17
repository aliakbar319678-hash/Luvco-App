import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart' as image_picker;

import '../../core/theme/app_colors.dart';
import '../../models/recipe_detail_model.dart';
import '../../providers/recipe_detail_provider.dart';
import '../../providers/recipe_provider.dart';
import '../../widgets/bottom_nav_bar.dart';

// ═══════════════════════════════════════════════════════════════════
//  RECIPE DETAIL SCREEN — entry point
// ═══════════════════════════════════════════════════════════════════
class RecipeDetailScreen extends ConsumerWidget {
  final RecipeDetailModel recipe;
  const RecipeDetailScreen({super.key, required this.recipe});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final size = MediaQuery.sizeOf(context);
    final scale = size.width / 390;
    final padding = MediaQuery.paddingOf(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: AppColors.pureWhite,
        bottomNavigationBar: const LuvcoBottomNavBar(),
        body: Stack(
          children: [
            // ── Background color ──────────────────────────────────────
            Container(color: AppColors.pageBackground),

            // ── Main scrollable content ───────────────────────────────
            Consumer(
              builder: (context, ref, _) {
                final detail = ref.watch(recipeDetailProvider(recipe));
                final activeTab = ref.watch(recipeDetailTabProvider);
                final showMoreActions = ref.watch(
                  recipeDetailMoreActionsProvider,
                );
                final showDupSuccess = ref.watch(
                  recipeDuplicatedSuccessProvider,
                );

                return Stack(
                  children: [
                    // ── Scrollable Body ─────────────────────────────
                    Positioned.fill(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          children: [
                            // Space for the header so content starts below its visual center
                            SizedBox(height: 75 * scale),

                            // ── Hero Image ──────────────────────────
                            _HeroImage(recipe: detail, scale: scale),

                            // ── Overlap content card ────────────────
                            Transform.translate(
                              offset: Offset(0, -30 * scale),
                              child: Container(
                                decoration: const BoxDecoration(
                                  color: AppColors.pureWhite,
                                  borderRadius: BorderRadius.vertical(
                                    bottom: Radius.circular(40),
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    const SizedBox(height: 12),
                                    // ── Recipe meta info ──────────────
                                    _RecipeMetaSection(
                                      recipe: detail,
                                      scale: scale,
                                    ),

                                    const SizedBox(height: 8),

                                    // ── Diet chips ────────────────────
                                    _DietChipsSection(
                                      recipe: detail,
                                      scale: scale,
                                    ),

                                    const SizedBox(height: 16),

                                    // ── Tab bar ───────────────────────
                                    _RecipeTabBar(
                                      activeTab: activeTab,
                                      scale: scale,
                                      onChanged: (i) =>
                                          ref
                                                  .read(
                                                    recipeDetailTabProvider
                                                        .notifier,
                                                  )
                                                  .state =
                                              i,
                                    ),

                                    // ── Tab content ───────────────────
                                    _TabContent(
                                      recipe: detail,
                                      activeTab: activeTab,
                                      scale: scale,
                                      size: size,
                                    ),

                                    const SizedBox(height: 40),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // ── Fixed Floating Header ────────────────────────
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: _CustomHeader(
                        scale: scale,
                        padding: padding,
                        onBack: () => context.pop(),
                        onMore: detail.isOwner
                            ? () =>
                                  ref
                                          .read(
                                            recipeDetailMoreActionsProvider
                                                .notifier,
                                          )
                                          .state =
                                      true
                            : null,
                      ),
                    ),

                    // ── More actions popup ───────────────────────────
                    if (showMoreActions)
                      _MoreActionsOverlay(
                        recipe: detail,
                        scale: scale,
                        onDismiss: () =>
                            ref
                                    .read(
                                      recipeDetailMoreActionsProvider.notifier,
                                    )
                                    .state =
                                false,
                        onEdit: () {
                          ref
                                  .read(
                                    recipeDetailMoreActionsProvider.notifier,
                                  )
                                  .state =
                              false;
                          _openEditSheet(context, ref, detail, scale);
                        },
                        onDuplicate: () {
                          ref
                                  .read(
                                    recipeDetailMoreActionsProvider.notifier,
                                  )
                                  .state =
                              false;
                          ref
                              .read(myRecipesProvider.notifier)
                              .duplicateRecipe(detail.id);
                          ref
                                  .read(
                                    recipeDuplicatedSuccessProvider.notifier,
                                  )
                                  .state =
                              true;
                          Future.delayed(const Duration(seconds: 2), () {
                            if (context.mounted) {
                              ref
                                      .read(
                                        recipeDuplicatedSuccessProvider
                                            .notifier,
                                      )
                                      .state =
                                  false;
                            }
                          });
                        },
                        onDelete: () {
                          ref
                                  .read(
                                    recipeDetailMoreActionsProvider.notifier,
                                  )
                                  .state =
                              false;
                          ref
                              .read(myRecipesProvider.notifier)
                              .deleteRecipe(detail.id);
                          context.pop();
                        },
                      ),

                    // ── Duplicate success toast ──────────────────────
                    if (showDupSuccess) const _DuplicateSuccessOverlay(),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _openEditSheet(
    BuildContext context,
    WidgetRef ref,
    RecipeDetailModel recipe,
    double scale,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _EditRecipeSheet(recipe: recipe),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  CUSTOM HEADER — flat, transparent bg, matches Figma 1.4.0
// ═══════════════════════════════════════════════════════════════════
class _CustomHeader extends StatelessWidget {
  final double scale;
  final EdgeInsets padding;
  final VoidCallback onBack;
  final VoidCallback? onMore;

  const _CustomHeader({
    required this.scale,
    required this.padding,
    required this.onBack,
    this.onMore,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(40)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: EdgeInsets.only(
        top: padding.top + 6,
        bottom: 28 * scale,
        left: 4,
        right: 4,
      ),
      child: Row(
        children: [
          // Back button
          IconButton(
            onPressed: onBack,
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: AppColors.vibrantPink,
              size: 20,
            ),
          ),

          // Title
          Expanded(
            child: Text(
              'Recipe Detail',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 18 * scale.clamp(0.85, 1.2),
                fontWeight: FontWeight.w700,
                color: AppColors.vibrantPink,
              ),
            ),
          ),

          // More (three dots) — always show slot for alignment
          if (onMore != null)
            IconButton(
              onPressed: onMore,
              icon: const Icon(
                Icons.more_horiz_rounded,
                color: AppColors.vibrantPink,
                size: 26,
              ),
            )
          else
            const SizedBox(width: 48),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  HERO IMAGE — reduced height to match Figma proportions
// ═══════════════════════════════════════════════════════════════════
class _HeroImage extends StatelessWidget {
  final RecipeDetailModel recipe;
  final double scale;

  const _HeroImage({required this.recipe, required this.scale});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 317 * scale,
      width: double.infinity,
      child: recipe.imageUrl != null
          ? Image.asset(
              recipe.imageUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  Container(color: AppColors.clearGrey),
            )
          : Container(color: AppColors.clearGrey),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  RECIPE META CARD — card with dashed border, matches Figma
// ═══════════════════════════════════════════════════════════════════
class _RecipeMetaSection extends StatelessWidget {
  final RecipeDetailModel recipe;
  final double scale;
  const _RecipeMetaSection({required this.recipe, required this.scale});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 375 * scale,
      height: 157 * scale,
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(32 * scale),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: EdgeInsets.all(24 * scale),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Title + Bookmark Row ────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recipe.title,
                      style: GoogleFonts.inter(
                        fontSize: 22 * scale,
                        fontWeight: FontWeight.w700,
                        color: AppColors.vibrantPink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Short description of the recipe.',
                      style: GoogleFonts.inter(
                        fontSize: 14 * scale,
                        fontWeight: FontWeight.w400,
                        color: AppColors.black,
                      ),
                    ),
                  ],
                ),
              ),
              // Bookmark Button
              Container(
                width: 44 * scale,
                height: 44 * scale,
                decoration: BoxDecoration(
                  color: AppColors.royalPurple,
                  borderRadius: BorderRadius.circular(16 * scale),
                ),
                child: Center(
                  child: Icon(
                    Icons.bookmark_border_rounded,
                    color: AppColors.pureWhite,
                    size: 20 * scale,
                  ),
                ),
              ),
            ],
          ),

          const Spacer(), // Gap of 24px or flexible space

          // ── Servings + Time row (Centered) ───────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _MetaItem(
                label: 'Servings',
                value: '${recipe.servings}',
                icon: Icons.restaurant_menu_rounded,
                scale: scale,
              ),
              SizedBox(width: 50 * scale),
              _MetaItem(
                label: 'Time',
                value: '${recipe.timeMinutes} min',
                icon: Icons.access_time_rounded,
                scale: scale,
              ),
            ],
          ),
        ],
      ),
    );
  }
}


/// Paints a rounded-rect dashed border

class _MetaItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final double scale;

  const _MetaItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.scale,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13 * scale.clamp(0.85, 1.2),
            fontWeight: FontWeight.w500,
            color: AppColors.vibrantPink,
          ),
        ),
        const SizedBox(height: 5),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20 * scale.clamp(0.85, 1.2),
              color: AppColors.vibrantPink,
            ),
            const SizedBox(width: 6),
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 18 * scale.clamp(0.85, 1.2),
                fontWeight: FontWeight.w700,
                color: AppColors.vibrantPink,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  DIET CHIPS SECTION
// ═══════════════════════════════════════════════════════════════════
class _DietChipsSection extends StatelessWidget {
  final RecipeDetailModel recipe;
  final double scale;
  const _DietChipsSection({required this.recipe, required this.scale});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: 16 * scale,
        vertical: 6 * scale,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ChipRow(label: 'Diet Type', tags: recipe.dietTypes, scale: scale),
          const SizedBox(height: 12),
          _ChipRow(
            label: 'Free of Ingredients',
            tags: recipe.freeOfIngredients,
            scale: scale,
          ),
        ],
      ),
    );
  }
}

class _ChipRow extends StatelessWidget {
  final String label;
  final List<String> tags;
  final double scale;
  const _ChipRow({
    required this.label,
    required this.tags,
    required this.scale,
  });

  @override
  Widget build(BuildContext context) {
    // ALWAYS show 4 'Label' items to match the Figma design screenshot exactly
    const displayTags = ['Label', 'Label', 'Label', 'Label'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 15 * scale.clamp(0.85, 1.2),
            fontWeight: FontWeight.w700,
            color: AppColors.black,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12 * scale,
          runSpacing: 12 * scale,
          children: displayTags
              .map(
                (tag) => _OutlineChip(label: tag, scale: scale),
              )
              .toList(),
        ),
      ],
    );
  }
}

class _OutlineChip extends StatelessWidget {
  final String label;
  final double scale;
  const _OutlineChip({required this.label, required this.scale});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72 * scale.clamp(0.85, 1.2),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.clearGrey, width: 1.2),
        color: AppColors.pureWhite,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.hexagon_outlined,
            size: 18 * scale.clamp(0.85, 1.2),
            color: Colors.black, // Black icon — matches Figma
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 11 * scale.clamp(0.85, 1.2),
              fontWeight: FontWeight.w500,
              color: Colors.black, // Black label — matches Figma
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  TAB BAR — matches Figma purple pill tabs
// ═══════════════════════════════════════════════════════════════════
class _RecipeTabBar extends StatelessWidget {
  final int activeTab;
  final double scale;
  final ValueChanged<int> onChanged;

  const _RecipeTabBar({
    required this.activeTab,
    required this.scale,
    required this.onChanged,
  });

  static const _tabs = ['Ingredients', 'Instructions', 'Products'];

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16 * scale),
      height: 42,
      decoration: BoxDecoration(
        color: const Color(0xFFF0EBF9),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: List.generate(_tabs.length, (i) {
          final isActive = i == activeTab;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: isActive ? AppColors.royalPurple : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Text(
                    _tabs[i],
                    style: GoogleFonts.inter(
                      fontSize: 12 * scale.clamp(0.85, 1.2),
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                      color: isActive
                          ? AppColors.pureWhite
                          : AppColors.neutralGrey,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  TAB CONTENT
// ═══════════════════════════════════════════════════════════════════
class _TabContent extends StatelessWidget {
  final RecipeDetailModel recipe;
  final int activeTab;
  final double scale;
  final Size size;

  const _TabContent({
    required this.recipe,
    required this.activeTab,
    required this.scale,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    switch (activeTab) {
      case 0:
        return _IngredientsTab(recipe: recipe, scale: scale);
      case 1:
        return _InstructionsTab(recipe: recipe, scale: scale);
      case 2:
        return _ProductsTab(recipe: recipe, scale: scale);
      default:
        return const SizedBox.shrink();
    }
  }
}

// ── Ingredients Tab ────────────────────────────────────────────────
class _IngredientsTab extends StatelessWidget {
  final RecipeDetailModel recipe;
  final double scale;
  const _IngredientsTab({required this.recipe, required this.scale});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16 * scale, vertical: 8),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(22 * scale),
        decoration: BoxDecoration(
          color: AppColors.pureWhite,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: AppColors.clearGrey.withValues(alpha: 0.5),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.soup_kitchen_outlined,
                  size: 24 * scale.clamp(0.85, 1.2),
                  color: AppColors.black,
                ),
                const SizedBox(width: 12),
                Text(
                  'Ingredients',
                  style: GoogleFonts.inter(
                    fontSize: 18 * scale.clamp(0.85, 1.2),
                    fontWeight: FontWeight.w700,
                    color: AppColors.black,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              recipe.ingredients,
              style: GoogleFonts.inter(
                fontSize: 14 * scale.clamp(0.85, 1.2),
                color: AppColors.black,
                height: 2.0,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Instructions Tab ───────────────────────────────────────────────
class _InstructionsTab extends StatelessWidget {
  final RecipeDetailModel recipe;
  final double scale;
  const _InstructionsTab({required this.recipe, required this.scale});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(16 * scale),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(16 * scale),
        decoration: BoxDecoration(
          color: AppColors.softGrey,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.menu_book_outlined,
                  size: 18 * scale.clamp(0.85, 1.2),
                  color: AppColors.vibrantPink,
                ),
                const SizedBox(width: 6),
                Text(
                  'Instructions',
                  style: GoogleFonts.inter(
                    fontSize: 16 * scale.clamp(0.85, 1.2),
                    fontWeight: FontWeight.w700,
                    color: AppColors.black,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              recipe.instructions,
              style: GoogleFonts.inter(
                fontSize: 13 * scale.clamp(0.85, 1.2),
                color: AppColors.darkGrey,
                height: 1.7,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Products Tab ───────────────────────────────────────────────────
class _ProductsTab extends ConsumerWidget {
  final RecipeDetailModel recipe;
  final double scale;
  const _ProductsTab({required this.recipe, required this.scale});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: EdgeInsets.all(16 * scale),
      child: Column(
        children: [
          if (recipe.isOwner) _AddProductsButton(scale: scale),

          if (recipe.products.isEmpty) ...[
            SizedBox(height: 40 * scale),
            _ProductsEmptyState(scale: scale),
          ] else ...[
            SizedBox(height: 12 * scale),
            ...recipe.products.map(
              (p) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _ProductCard(
                  product: p,
                  scale: scale,
                  isOwner: recipe.isOwner,
                  onDelete: recipe.isOwner
                      ? () => ref
                            .read(recipeDetailProvider(recipe).notifier)
                            .removeProduct(p.id)
                      : null,
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _AddProductsButton extends StatelessWidget {
  final double scale;
  const _AddProductsButton({required this.scale});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton.icon(
        onPressed: () {},
        icon: Icon(
          Icons.add,
          size: 18 * scale.clamp(0.85, 1.2),
          color: AppColors.royalPurple,
        ),
        label: Text(
          'Add Products',
          style: GoogleFonts.inter(
            fontSize: 14 * scale.clamp(0.85, 1.2),
            fontWeight: FontWeight.w600,
            color: AppColors.royalPurple,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.royalPurple, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          backgroundColor: Colors.transparent,
        ),
      ),
    );
  }
}

class _ProductsEmptyState extends StatelessWidget {
  final double scale;
  const _ProductsEmptyState({required this.scale});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(
          Icons.shopping_bag_outlined,
          size: 64 * scale.clamp(0.85, 1.2),
          color: AppColors.clearGrey,
        ),
        SizedBox(height: 12 * scale),
        Text(
          'No products are attached\nto this recipe',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 14 * scale.clamp(0.85, 1.2),
            fontWeight: FontWeight.w500,
            color: AppColors.neutralGrey,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

class _ProductCard extends StatelessWidget {
  final RecipeProduct product;
  final double scale;
  final bool isOwner;
  final VoidCallback? onDelete;

  const _ProductCard({
    required this.product,
    required this.scale,
    required this.isOwner,
    this.onDelete,
  });

  Color get _sustainabilityColor {
    switch (product.sustainabilityLevel) {
      case 'Unsustainable':
        return const Color(0xFFEF4444);
      case 'Moderate Impact':
        return const Color(0xFFF59E0B);
      case 'Eco-Friendly':
        return const Color(0xFF22C55E);
      default:
        return AppColors.neutralGrey;
    }
  }

  Color get _safetyColor {
    switch (product.safetyLevel) {
      case 'Avoid':
        return const Color(0xFFF59E0B);
      case 'Safe':
        return const Color(0xFF22C55E);
      default:
        return AppColors.neutralGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    // ── ONE unified card — matches Figma exactly ─────────────────────
    // Structure: rounded white card → top row has [Unsustainable tab | Safe tab]
    //            → below: product image centered with heart icon overlay
    return Container(
      margin: EdgeInsets.only(bottom: 20 * scale),
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // ── Top Status Bar — two coloured tabs side by side ────────
          IntrinsicHeight(
            child: Row(
              children: [
                // Sustainability tab (left)
                Expanded(
                  child: Container(
                    color: _sustainabilityColor,
                    padding: EdgeInsets.symmetric(
                      vertical: 10 * scale,
                      horizontal: 8 * scale,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.eco_outlined,
                          size: 16,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          product.sustainabilityLevel,
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
                // Safety tab (right)
                Expanded(
                  child: Container(
                    color: _safetyColor,
                    padding: EdgeInsets.symmetric(
                      vertical: 10 * scale,
                      horizontal: 8 * scale,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.flag_outlined,
                          size: 16,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          product.safetyLevel,
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
          ),

          // ── Product Info Area ──────────────────────────────────────
          Container(
            color: AppColors.pureWhite,
            padding: EdgeInsets.symmetric(
              vertical: 20 * scale,
              horizontal: 16 * scale,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Product Image
                SizedBox(
                  width: 64 * scale,
                  height: 64 * scale,
                  child: product.imageAsset != null
                      ? Image.asset(
                          product.imageAsset!,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => Icon(
                            Icons.image_outlined,
                            size: 32 * scale,
                            color: AppColors.clearGrey,
                          ),
                        )
                      : Icon(
                          Icons.image_outlined,
                          size: 32 * scale,
                          color: AppColors.clearGrey,
                        ),
                ),
                SizedBox(width: 16 * scale),
                // Text Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: GoogleFonts.inter(
                          fontSize: 14 * scale.clamp(0.85, 1.2),
                          fontWeight: FontWeight.w700,
                          color: AppColors.black,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        product.otherData,
                        style: GoogleFonts.inter(
                          fontSize: 13 * scale.clamp(0.85, 1.2),
                          color: AppColors.darkGrey,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // Delete Button
                if (isOwner && onDelete != null) ...[
                  SizedBox(width: 12 * scale),
                  GestureDetector(
                    onTap: onDelete,
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Icon(
                        Icons.delete_outline_rounded,
                        size: 24 * scale.clamp(0.85, 1.2),
                        color: AppColors.black,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  MORE ACTIONS POPUP OVERLAY
// ═══════════════════════════════════════════════════════════════════
class _MoreActionsOverlay extends StatelessWidget {
  final RecipeDetailModel recipe;
  final double scale;
  final VoidCallback onDismiss;
  final VoidCallback onEdit;
  final VoidCallback onDuplicate;
  final VoidCallback onDelete;

  const _MoreActionsOverlay({
    required this.recipe,
    required this.scale,
    required this.onDismiss,
    required this.onEdit,
    required this.onDuplicate,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            onTap: onDismiss,
            child: Container(color: Colors.transparent),
          ),
        ),
        Positioned(
          top: MediaQuery.paddingOf(context).top + 48,
          right: 16,
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: 180 * scale.clamp(0.85, 1.2),
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
                  _PopupItem(
                    label: 'Edit Recipe',
                    icon: Icons.edit_outlined,
                    color: AppColors.black,
                    scale: scale,
                    onTap: onEdit,
                  ),
                  const Divider(height: 1, color: AppColors.clearGrey),
                  _PopupItem(
                    label: 'Duplicate Recipe',
                    icon: Icons.copy_outlined,
                    color: AppColors.black,
                    scale: scale,
                    onTap: onDuplicate,
                  ),
                  const Divider(height: 1, color: AppColors.clearGrey),
                  _PopupItem(
                    label: 'Delete Recipe',
                    icon: Icons.delete_outline_rounded,
                    color: AppColors.errorRed,
                    scale: scale,
                    onTap: onDelete,
                    isDestructive: true,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PopupItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final double scale;
  final VoidCallback onTap;
  final bool isDestructive;

  const _PopupItem({
    required this.label,
    required this.icon,
    required this.color,
    required this.scale,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: 16 * scale,
          vertical: 13 * scale,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 14 * scale.clamp(0.85, 1.2),
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
            ),
            Icon(icon, size: 18 * scale.clamp(0.85, 1.2), color: color),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  DUPLICATE SUCCESS OVERLAY
// ═══════════════════════════════════════════════════════════════════
class _DuplicateSuccessOverlay extends StatelessWidget {
  const _DuplicateSuccessOverlay();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.3),
        child: Center(
          child: Container(
            width: 220,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 30,
                  offset: const Offset(0, 8),
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
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Image.asset(
                    'assets/icons/done_icon.png',
                    width: 64,
                    height: 64,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'The recipe was\nduplicated!',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.black,
                    height: 1.4,
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

// ═══════════════════════════════════════════════════════════════════
//  EDIT RECIPE BOTTOM SHEET
// ═══════════════════════════════════════════════════════════════════
class _EditRecipeSheet extends ConsumerStatefulWidget {
  final RecipeDetailModel recipe;
  const _EditRecipeSheet({required this.recipe});

  @override
  ConsumerState<_EditRecipeSheet> createState() => _EditRecipeSheetState();
}

class _EditRecipeSheetState extends ConsumerState<_EditRecipeSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _ingredientsCtrl;
  late final TextEditingController _instructionsCtrl;

  late int _servings;
  late int _timeMinutes;
  late List<String> _dietTypes;
  late List<String> _freeOfIngredients;
  File? _pickedImage;

  static const _dietOptions = [
    'Nullam Scelerisque',
    'Nullam',
    'Duis',
    'Ullamcorper',
    'Ligula Imperdiet',
    'Lectus',
  ];
  static const _freeOfOptions = [
    'Duis',
    'Nullam Scelerisque',
    'Nullam',
    'Ullamcorper',
    'Ligula Imperdiet',
    'Lectus',
  ];
  static const _prepTimes = [15, 30, 45, 60, 90, 120];
  static const _servingOptions = [1, 2, 3, 4, 5, 6, 8, 10];

  @override
  void initState() {
    super.initState();
    final r = widget.recipe;
    _nameCtrl = TextEditingController(text: r.title);
    _descCtrl = TextEditingController(text: r.description);
    _ingredientsCtrl = TextEditingController(text: r.ingredients);
    _instructionsCtrl = TextEditingController(text: r.instructions);
    _servings = r.servings;
    _timeMinutes = r.timeMinutes;
    _dietTypes = List.from(r.dietTypes);
    _freeOfIngredients = List.from(r.freeOfIngredients);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _ingredientsCtrl.dispose();
    _instructionsCtrl.dispose();
    super.dispose();
  }

  void _saveChanges() {
    final notifier = ref.read(recipeDetailProvider(widget.recipe).notifier);
    final activeTab = ref.read(editRecipeTabProvider);

    if (activeTab == 0) {
      notifier.updateDetails(
        title: _nameCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        servings: _servings,
        timeMinutes: _timeMinutes,
        dietTypes: _dietTypes,
        freeOfIngredients: _freeOfIngredients,
      );
    } else if (activeTab == 1) {
      notifier.updatePreparation(
        ingredients: _ingredientsCtrl.text,
        instructions: _instructionsCtrl.text,
      );
    }
    Navigator.of(context).pop();
  }

  Future<void> _pickCoverImage() async {
    final picker = image_picker.ImagePicker();
    final image = await picker.pickImage(source: image_picker.ImageSource.gallery);
    if (image != null) {
      setState(() => _pickedImage = File(image.path));
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final scale = size.width / 390;
    final padding = MediaQuery.paddingOf(context);
    final activeTab = ref.watch(editRecipeTabProvider);

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: Column(
        children: [
          _EditSheetHeader(
            scale: scale,
            onBack: () => Navigator.of(context).pop(),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: size.width * 0.058),
            child: _EditTabBar(
              scale: scale,
              activeTab: activeTab,
              onTabChanged: (i) =>
                  ref.read(editRecipeTabProvider.notifier).state = i,
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                size.width * 0.058,
                24,
                size.width * 0.058,
                padding.bottom + 24,
              ),
              child: _buildTabContent(context, activeTab, scale, size),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent(
    BuildContext context,
    int activeTab,
    double scale,
    Size size,
  ) {
    switch (activeTab) {
      case 0:
        return _EditDetailsTab(
          scale: scale,
          nameCtrl: _nameCtrl,
          descCtrl: _descCtrl,
          servings: _servings,
          timeMinutes: _timeMinutes,
          dietTypes: _dietTypes,
          freeOfIngredients: _freeOfIngredients,
          prepTimes: _prepTimes,
          servingOptions: _servingOptions,
          dietOptions: _dietOptions,
          freeOfOptions: _freeOfOptions,
          onServingsChanged: (v) => setState(() => _servings = v ?? _servings),
          onTimeChanged: (v) =>
              setState(() => _timeMinutes = v ?? _timeMinutes),
          onDietToggle: (tag) => setState(() {
            _dietTypes.contains(tag)
                ? _dietTypes.remove(tag)
                : _dietTypes.add(tag);
          }),
          onFreeOfToggle: (tag) => setState(() {
            _freeOfIngredients.contains(tag)
                ? _freeOfIngredients.remove(tag)
                : _freeOfIngredients.add(tag);
          }),
          onPickImage: _pickCoverImage,
          pickedImage: _pickedImage,
          onSave: _saveChanges,
        );
      case 1:
        return _EditPreparationTab(
          scale: scale,
          ingredientsCtrl: _ingredientsCtrl,
          instructionsCtrl: _instructionsCtrl,
          onSave: _saveChanges,
        );
      case 2:
        return _EditProductsTab(
          recipe: widget.recipe,
          scale: scale,
          onSave: _saveChanges,
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

// ── Edit Sheet Header ─────────────────────────────────────────────
class _EditSheetHeader extends StatelessWidget {
  final double scale;
  final VoidCallback onBack;

  const _EditSheetHeader({
    required this.scale,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.paddingOf(context);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(40)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(
        MediaQuery.sizeOf(context).width * 0.058,
        padding.top + 16,
        MediaQuery.sizeOf(context).width * 0.058,
        28,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: GestureDetector(
              onTap: onBack,
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: AppColors.vibrantPink,
                size: 20,
              ),
            ),
          ),
          Text(
            'Edit Recipe',
            style: GoogleFonts.inter(
              fontSize: 20 * scale.clamp(0.85, 1.2),
              fontWeight: FontWeight.w700,
              color: AppColors.vibrantPink,
            ),
          ),
        ],
      ),
    );
  }
}

class _EditTabBar extends StatelessWidget {
  final double scale;
  final int activeTab;
  final ValueChanged<int> onTabChanged;

  const _EditTabBar({
    required this.scale,
    required this.activeTab,
    required this.onTabChanged,
  });

  static const _tabs = ['Details', 'Preparation', 'Products'];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: const Color(0xFFF3E8FF),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: List.generate(_tabs.length, (i) {
          final isActive = i == activeTab;
          final isLast = i == _tabs.length - 1;

          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => onTabChanged(i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isActive ? AppColors.royalPurple : Colors.transparent,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: isActive
                            ? [
                                BoxShadow(
                                  color: AppColors.royalPurple.withValues(alpha: 0.25),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                )
                              ]
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          _tabs[i],
                          style: GoogleFonts.inter(
                            fontSize: 13 * scale.clamp(0.85, 1.2),
                            fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                            color: isActive ? Colors.white : AppColors.black.withValues(alpha: 0.7),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                if (!isLast && !isActive && (i + 1 != activeTab))
                  Container(
                    width: 1,
                    height: 14,
                    color: AppColors.royalPurple.withValues(alpha: 0.2),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

// ── Edit Details Tab ──────────────────────────────────────────────
class _EditDetailsTab extends StatelessWidget {
  final double scale;
  final TextEditingController nameCtrl;
  final TextEditingController descCtrl;
  final int servings;
  final int timeMinutes;
  final List<String> dietTypes;
  final List<String> freeOfIngredients;
  final List<int> prepTimes;
  final List<int> servingOptions;
  final List<String> dietOptions;
  final List<String> freeOfOptions;
  final ValueChanged<int?> onServingsChanged;
  final ValueChanged<int?> onTimeChanged;
  final ValueChanged<String> onDietToggle;
  final ValueChanged<String> onFreeOfToggle;
  final VoidCallback onPickImage;
  final File? pickedImage;
  final VoidCallback onSave;

  const _EditDetailsTab({
    required this.scale,
    required this.nameCtrl,
    required this.descCtrl,
    required this.servings,
    required this.timeMinutes,
    required this.dietTypes,
    required this.freeOfIngredients,
    required this.prepTimes,
    required this.servingOptions,
    required this.dietOptions,
    required this.freeOfOptions,
    required this.onServingsChanged,
    required this.onTimeChanged,
    required this.onDietToggle,
    required this.onFreeOfToggle,
    required this.onPickImage,
    required this.pickedImage,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Edit the details of the recipe:',
          style: GoogleFonts.inter(
            fontSize: 18 * scale.clamp(0.85, 1.2),
            fontWeight: FontWeight.w700,
            color: AppColors.black,
          ),
        ),
        Text(
          '*Mandatory fields',
          style: GoogleFonts.inter(
            fontSize: 11 * scale.clamp(0.85, 1.2),
            color: AppColors.neutralGrey,
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: 20),
        _EditSectionLabel(label: 'Cover Picture*', scale: scale),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: onPickImage,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: AspectRatio(
              aspectRatio: 2.1,
              child: Container(
                color: AppColors.clearGrey,
                child: pickedImage != null
                    ? Image.file(pickedImage!, fit: BoxFit.cover)
                    : Image.asset(
                        'assets/images/bread_pic.png',
                        fit: BoxFit.cover,
                      ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        _EditSectionLabel(label: "Recipe's Name:*", scale: scale),
        const SizedBox(height: 8),
        _EditInputField(
          controller: nameCtrl,
          hint: 'Cool Recipe',
          scale: scale,
        ),
        const SizedBox(height: 16),
        _EditSectionLabel(label: 'Description*', scale: scale),
        const SizedBox(height: 8),
        _EditInputField(
          controller: descCtrl,
          hint: 'Gluten-Free Cool Recipe',
          scale: scale,
        ),
        const SizedBox(height: 16),
        _EditSectionLabel(label: 'Time of preparation*', scale: scale),
        const SizedBox(height: 8),
        _EditDropdown<int>(
          value: timeMinutes,
          items: prepTimes,
          displayText: (v) => '$v min',
          scale: scale,
          onChanged: onTimeChanged,
        ),
        const SizedBox(height: 16),
        _EditSectionLabel(label: 'Servings*', scale: scale),
        const SizedBox(height: 8),
        _EditDropdown<int>(
          value: servings,
          items: servingOptions,
          displayText: (v) => '$v',
          scale: scale,
          onChanged: onServingsChanged,
        ),
        const SizedBox(height: 16),
        _EditSectionLabel(label: 'Type of Diet*', scale: scale),
        const SizedBox(height: 10),
        _EditChipGroup(
          options: dietOptions,
          selected: dietTypes,
          onToggle: onDietToggle,
          scale: scale,
        ),
        const SizedBox(height: 16),
        _EditSectionLabel(label: 'Free of Ingredients', scale: scale),
        const SizedBox(height: 10),
        _EditChipGroup(
          options: freeOfOptions,
          selected: freeOfIngredients,
          onToggle: onFreeOfToggle,
          scale: scale,
        ),
        const SizedBox(height: 32),
        _SaveChangesButton(scale: scale, onSave: onSave),
        const SizedBox(height: 16),
      ],
    );
  }
}

// ── Edit Preparation Tab ──────────────────────────────────────────
class _EditPreparationTab extends StatelessWidget {
  final double scale;
  final TextEditingController ingredientsCtrl;
  final TextEditingController instructionsCtrl;
  final VoidCallback onSave;

  const _EditPreparationTab({
    required this.scale,
    required this.ingredientsCtrl,
    required this.instructionsCtrl,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Edit the details of the\npreparation:',
          style: GoogleFonts.inter(
            fontSize: 18 * scale.clamp(0.85, 1.2),
            fontWeight: FontWeight.w700,
            color: AppColors.black,
            height: 1.3,
          ),
        ),
        Text(
          '*Mandatory fields',
          style: GoogleFonts.inter(
            fontSize: 11 * scale.clamp(0.85, 1.2),
            color: AppColors.neutralGrey,
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: 20),
        _EditSectionLabel(label: "Recipe's Ingredients*", scale: scale),
        const SizedBox(height: 8),
        _EditTextArea(
          controller: ingredientsCtrl,
          hint: 'List your ingredients here...',
          scale: scale,
          minLines: 6,
        ),
        const SizedBox(height: 16),
        _EditSectionLabel(label: "Recipe's Instructions*", scale: scale),
        const SizedBox(height: 8),
        _EditTextArea(
          controller: instructionsCtrl,
          hint: 'Write your step-by-step instructions here...',
          scale: scale,
          minLines: 8,
        ),
        const SizedBox(height: 32),
        _SaveChangesButton(scale: scale, onSave: onSave),
        const SizedBox(height: 16),
      ],
    );
  }
}

// ── Edit Products Tab ─────────────────────────────────────────────
class _EditProductsTab extends ConsumerWidget {
  final RecipeDetailModel recipe;
  final double scale;
  final VoidCallback onSave;

  const _EditProductsTab({
    required this.recipe,
    required this.scale,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(recipeDetailProvider(recipe));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Edit the products attached to\nthe recipe:',
          style: GoogleFonts.inter(
            fontSize: 18 * scale.clamp(0.85, 1.2),
            fontWeight: FontWeight.w700,
            color: AppColors.black,
            height: 1.3,
          ),
        ),
        Text(
          '*Mandatory fields',
          style: GoogleFonts.inter(
            fontSize: 11 * scale.clamp(0.85, 1.2),
            color: AppColors.neutralGrey,
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: 16),
        _AddProductsButton(scale: scale),
        const SizedBox(height: 12),
        if (detail.products.isEmpty)
          _ProductsEmptyState(scale: scale)
        else
          ...detail.products.map(
            (p) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _ProductCard(
                product: p,
                scale: scale,
                isOwner: true,
                onDelete: () => ref
                    .read(recipeDetailProvider(recipe).notifier)
                    .removeProduct(p.id),
              ),
            ),
          ),
        const SizedBox(height: 32),
        _SaveChangesButton(scale: scale, onSave: onSave),
        const SizedBox(height: 16),
      ],
    );
  }
}

// ── Shared edit sub-widgets ───────────────────────────────────────
class _EditSectionLabel extends StatelessWidget {
  final String label;
  final double scale;
  const _EditSectionLabel({required this.label, required this.scale});

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

class _EditInputField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final double scale;
  const _EditInputField({
    required this.controller,
    required this.hint,
    required this.scale,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
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
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        filled: true,
        fillColor: AppColors.softGrey,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.inputBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.inputBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppColors.royalPurple,
            width: 1.5,
          ),
        ),
      ),
    );
  }
}

class _EditTextArea extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final double scale;
  final int minLines;

  const _EditTextArea({
    required this.controller,
    required this.hint,
    required this.scale,
    this.minLines = 5,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: null,
      minLines: minLines,
      style: GoogleFonts.inter(
        fontSize: 13 * scale.clamp(0.85, 1.2),
        color: AppColors.black,
        height: 1.6,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(
          fontSize: 13 * scale.clamp(0.85, 1.2),
          color: AppColors.neutralGrey,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        filled: true,
        fillColor: AppColors.softGrey,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.inputBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.inputBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppColors.royalPurple,
            width: 1.5,
          ),
        ),
      ),
    );
  }
}

class _EditDropdown<T> extends StatelessWidget {
  final T value;
  final List<T> items;
  final String Function(T) displayText;
  final double scale;
  final ValueChanged<T?> onChanged;

  const _EditDropdown({
    required this.value,
    required this.items,
    required this.displayText,
    required this.scale,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.softGrey,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: AppColors.darkGrey,
          ),
          style: GoogleFonts.inter(
            fontSize: 14 * scale.clamp(0.85, 1.2),
            color: AppColors.black,
          ),
          dropdownColor: Colors.white,
          items: items
              .map(
                (item) => DropdownMenuItem<T>(
                  value: item,
                  child: Text(displayText(item)),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _EditChipGroup extends StatelessWidget {
  final List<String> options;
  final List<String> selected;
  final ValueChanged<String> onToggle;
  final double scale;

  const _EditChipGroup({
    required this.options,
    required this.selected,
    required this.onToggle,
    required this.scale,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((opt) {
        final isSelected = selected.contains(opt);
        return GestureDetector(
          onTap: () => onToggle(opt),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.royalPurple : AppColors.softGrey,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected
                    ? AppColors.royalPurple
                    : AppColors.inputBorder,
              ),
            ),
            child: Text(
              opt,
              style: GoogleFonts.inter(
                fontSize: 12 * scale.clamp(0.85, 1.2),
                fontWeight: FontWeight.w500,
                color: isSelected ? AppColors.pureWhite : AppColors.darkGrey,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _SaveChangesButton extends StatelessWidget {
  final double scale;
  final VoidCallback onSave;

  const _SaveChangesButton({required this.scale, required this.onSave});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: onSave,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.faintPink,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Text(
          'Save Changes',
          style: GoogleFonts.inter(
            fontSize: 15 * scale.clamp(0.85, 1.2),
            fontWeight: FontWeight.w600,
            color: AppColors.royalPurple,
          ),
        ),
      ),
    );
  }
}
