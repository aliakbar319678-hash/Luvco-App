import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../models/recipe_model.dart';
import '../../models/recipe_detail_model.dart';
import '../../providers/search_recipe_provider.dart';

import '../../widgets/bottom_nav_bar.dart';

// ═══════════════════════════════════════════════════════════════
// Search Recipe Screen  (frames 2.0.8 → 2.0.12)
// ═══════════════════════════════════════════════════════════════
class SearchRecipeScreen extends ConsumerStatefulWidget {
  const SearchRecipeScreen({super.key});

  @override
  ConsumerState<SearchRecipeScreen> createState() => _SearchRecipeScreenState();
}

class _SearchRecipeScreenState extends ConsumerState<SearchRecipeScreen> {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(bottomNavIndexProvider.notifier).state = 1;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(searchRecipeProvider);
    final notifier = ref.read(searchRecipeProvider.notifier);
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
            Column(
              children: [
                // ── Header ──
                _SearchHeader(
                  padding: padding,
                  scale: scale,
                  size: size,
                  controller: _searchController,
                  focusNode: _focusNode,
                  query: state.query,
                  onChanged: notifier.onSearchChanged,
                  onClear: () {
                    _searchController.clear();
                    notifier.clearSearch();
                  },
                  onFilterTap: () =>
                      _showFilterSheet(context, ref, scale, size),
                ),

                // ── Body ──
                Expanded(
                  child: state.isSearching
                      ? _ResultsList(
                          results: state.results,
                          scale: scale,
                          size: size,
                          onItemTap: notifier.openQuickView,
                          onMoreTap: notifier.showMoreActionsFor,
                        )
                      : _EmptyState(scale: scale),
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

            // ── Quick View Modal ──
            if (state.selectedRecipe != null)
              _QuickViewModal(
                recipe: state.selectedRecipe!,
                scale: scale,
                size: size,
                onClose: notifier.closeQuickView,
                onSave: () => notifier.toggleSave(state.selectedRecipe!.id),
                onSeeMore: () {
                  notifier.closeQuickView();
                  final detail = _recipeToDetail(state.selectedRecipe!);
                  context.push('/recipe-detail', extra: detail);
                },
              ),

            // ── More Actions Popup ──
            if (state.showMoreActions && state.moreActionsRecipeId != null)
              _MoreActionsPopup(
                recipeId: state.moreActionsRecipeId!,
                scale: scale,
                size: size,
                onDismiss: notifier.hideMoreActions,
                onSeeMore: () {
                  notifier.hideMoreActions();
                  final recipe = state.results.firstWhere(
                    (r) => r.id == state.moreActionsRecipeId,
                    orElse: () => state.results.first,
                  );
                  final detail = _recipeToDetail(recipe);
                  context.push('/recipe-detail', extra: detail);
                },
                onSave: () {
                  notifier.toggleSave(state.moreActionsRecipeId!);
                  notifier.hideMoreActions();
                },
              ),
          ],
        ),
      ),
    );
  }

  RecipeDetailModel _recipeToDetail(RecipeModel r) => RecipeDetailModel(
    id: r.id,
    title: r.title,
    description: r.description,
    imageUrl: r.imageUrl,
    servings: r.servings,
    timeMinutes: r.timeOfPreparation,
    dietTypes: r.dietTags,
    freeOfIngredients: r.freeOfIngredients,
    ingredients:
        '• 4 cups (500g) all-purpose flour\n• 1 ½ teaspoons salt\n• 1 tablespoon sugar',
    instructions:
        '1. Make the Dough:\nIn a large bowl, mix the flour, salt, sugar, and yeast.',
    products: const [
      RecipeProduct(
        id: 'p1',
        name: 'Name of the Product',
        otherData: 'Other data from the product.',
        sustainabilityLevel: 'Unsustainable',
        safetyLevel: 'Avoid',
        imageAsset: 'assets/images/product_image.png',
      ),
      RecipeProduct(
        id: 'p2',
        name: 'Name of the Product',
        otherData: 'Other data from the product.',
        sustainabilityLevel: 'Moderate Impact',
        safetyLevel: 'Safe',
        imageAsset: 'assets/images/product_image.png',
      ),
    ],
    isOwner: false,
  );

  void _showFilterSheet(
    BuildContext context,
    WidgetRef ref,
    double scale,
    Size size,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FilterSheet(scale: scale, size: size, ref: ref),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Header with search bar
// ═══════════════════════════════════════════════════════════════
class _SearchHeader extends StatelessWidget {
  final EdgeInsets padding;
  final double scale;
  final Size size;
  final TextEditingController controller;
  final FocusNode focusNode;
  final String query;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final VoidCallback onFilterTap;

  const _SearchHeader({
    required this.padding,
    required this.scale,
    required this.size,
    required this.controller,
    required this.focusNode,
    required this.query,
    required this.onChanged,
    required this.onClear,
    required this.onFilterTap,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back + Title row
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.of(context).maybePop(),
                child: Icon(
                  Icons.chevron_left,
                  size: 28 * scale,
                  color: AppColors.vibrantPink,
                ),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    'Search Recipe',
                    style: GoogleFonts.inter(
                      fontSize: 18 * scale,
                      fontWeight: FontWeight.w700,
                      color: AppColors.vibrantPink,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 28 * scale),
            ],
          ),
          SizedBox(height: 12 * scale),

          // Search bar row
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 48 * scale,
                  decoration: BoxDecoration(
                    color: AppColors.pureWhite,
                    borderRadius: BorderRadius.circular(12 * scale),
                    border: Border.all(
                      color: query.isNotEmpty
                          ? AppColors.vibrantPink
                          : AppColors.inputBorder,
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    children: [
                      SizedBox(width: 12 * scale),
                      Icon(
                        Icons.search,
                        size: 20 * scale,
                        color: AppColors.vibrantPink,
                      ),
                      SizedBox(width: 8 * scale),
                      Expanded(
                        child: TextField(
                          controller: controller,
                          focusNode: focusNode,
                          style: GoogleFonts.inter(
                            fontSize: 14 * scale,
                            color: AppColors.black,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Search for a Recipe',
                            hintStyle: GoogleFonts.inter(
                              fontSize: 14 * scale,
                              color: AppColors.neutralGrey,
                            ),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                          onChanged: onChanged,
                        ),
                      ),
                      if (query.isNotEmpty) ...[
                        GestureDetector(
                          onTap: onClear,
                          child: Icon(
                            Icons.close,
                            size: 18 * scale,
                            color: AppColors.neutralGrey,
                          ),
                        ),
                        SizedBox(width: 10 * scale),
                      ],
                    ],
                  ),
                ),
              ),

              // Filter button — only visible when searching
              if (query.isNotEmpty) ...[
                SizedBox(width: 10 * scale),
                GestureDetector(
                  onTap: onFilterTap,
                  child: Row(
                    children: [
                      Icon(
                        Icons.tune,
                        size: 18 * scale,
                        color: AppColors.black,
                      ),
                      SizedBox(width: 4 * scale),
                      Text(
                        'Filter',
                        style: GoogleFonts.inter(
                          fontSize: 13 * scale,
                          fontWeight: FontWeight.w500,
                          color: AppColors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Empty State  (frame 2.0.8)
// ═══════════════════════════════════════════════════════════════
class _EmptyState extends StatelessWidget {
  final double scale;
  const _EmptyState({required this.scale});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Illustration
          SizedBox(
            width: 180 * scale,
            height: 180 * scale,
            child: Image.asset(
              'assets/images/search_recipe_empty.png',
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Icon(
                Icons.restaurant_menu_outlined,
                size: 100 * scale,
                color: AppColors.clearGrey,
              ),
            ),
          ),
          SizedBox(height: 16 * scale),
          Text(
            'Search for a recipe by\ningredient or diet type',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 15 * scale,
              fontWeight: FontWeight.w500,
              color: AppColors.darkGrey,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Results List  (frame 2.0.9)
// ═══════════════════════════════════════════════════════════════
class _ResultsList extends StatelessWidget {
  final List<RecipeModel> results;
  final double scale;
  final Size size;
  final ValueChanged<RecipeModel> onItemTap;
  final ValueChanged<String> onMoreTap;

  const _ResultsList({
    required this.results,
    required this.scale,
    required this.size,
    required this.onItemTap,
    required this.onMoreTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Results label
        Padding(
          padding: EdgeInsets.fromLTRB(
            16 * scale,
            16 * scale,
            16 * scale,
            8 * scale,
          ),
          child: Text(
            'Results',
            style: GoogleFonts.inter(
              fontSize: 16 * scale,
              fontWeight: FontWeight.w700,
              color: AppColors.black,
            ),
          ),
        ),

        Expanded(
          child: ListView.separated(
            padding: EdgeInsets.fromLTRB(
              16 * scale,
              0,
              16 * scale,
              100 * scale,
            ),
            itemCount: results.length,
            separatorBuilder: (_, __) => SizedBox(height: 10 * scale),
            itemBuilder: (_, i) => _RecipeCard(
              recipe: results[i],
              scale: scale,
              onTap: () => onItemTap(results[i]),
              onMoreTap: () => onMoreTap(results[i].id),
            ),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Recipe Card  (reused in results list)
// ═══════════════════════════════════════════════════════════════
class _RecipeCard extends StatelessWidget {
  final RecipeModel recipe;
  final double scale;
  final VoidCallback onTap;
  final VoidCallback onMoreTap;

  const _RecipeCard({
    required this.recipe,
    required this.scale,
    required this.onTap,
    required this.onMoreTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.pureWhite,
          borderRadius: BorderRadius.circular(12 * scale),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: EdgeInsets.all(8 * scale),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(8 * scale),
              child: SizedBox(
                width: 80 * scale,
                height: 80 * scale,
                child: recipe.imageUrl != null
                    ? Image.asset(
                        recipe.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: AppColors.softGrey,
                          child: Icon(
                            Icons.image,
                            color: AppColors.clearGrey,
                            size: 32 * scale,
                          ),
                        ),
                      )
                    : Container(
                        color: AppColors.softGrey,
                        child: Icon(
                          Icons.image,
                          color: AppColors.clearGrey,
                          size: 32 * scale,
                        ),
                      ),
              ),
            ),
            SizedBox(width: 10 * scale),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          recipe.title,
                          style: GoogleFonts.inter(
                            fontSize: 14 * scale,
                            fontWeight: FontWeight.w700,
                            color: AppColors.vibrantPink,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: onMoreTap,
                        behavior: HitTestBehavior.opaque,
                        child: Padding(
                          padding: EdgeInsets.only(left: 8 * scale),
                          child: Icon(
                            Icons.more_horiz,
                            size: 20 * scale,
                            color: AppColors.darkGrey,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 2 * scale),
                  Text(
                    recipe.description,
                    style: GoogleFonts.inter(
                      fontSize: 12 * scale,
                      color: AppColors.darkGrey,
                    ),
                  ),
                  SizedBox(height: 6 * scale),
                  Wrap(
                    spacing: 6 * scale,
                    runSpacing: 4 * scale,
                    children: recipe.dietTags.take(3).map((tag) {
                      return Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8 * scale,
                          vertical: 3 * scale,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.inputBorder),
                          borderRadius: BorderRadius.circular(20 * scale),
                        ),
                        child: Text(
                          tag,
                          style: GoogleFonts.inter(
                            fontSize: 11 * scale,
                            color: AppColors.darkGrey,
                          ),
                        ),
                      );
                    }).toList(),
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
// Quick View Modal  (frame 2.0.10)
// ═══════════════════════════════════════════════════════════════
class _QuickViewModal extends StatelessWidget {
  final RecipeModel recipe;
  final double scale;
  final Size size;
  final VoidCallback onClose;
  final VoidCallback onSave;
  final VoidCallback onSeeMore;

  const _QuickViewModal({
    required this.recipe,
    required this.scale,
    required this.size,
    required this.onClose,
    required this.onSave,
    required this.onSeeMore,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onClose,
      child: Container(
        color: Colors.black.withValues(alpha: 0.45),
        child: Center(
          child: GestureDetector(
            onTap: () {}, // prevent dismiss when tapping inside
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 16 * scale),
              constraints: BoxConstraints(maxWidth: 380 * scale),
              decoration: BoxDecoration(
                color: AppColors.pureWhite,
                borderRadius: BorderRadius.circular(16 * scale),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Top bar with close ──
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      16 * scale,
                      12 * scale,
                      8 * scale,
                      0,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                recipe.title,
                                style: GoogleFonts.inter(
                                  fontSize: 18 * scale,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.vibrantPink,
                                ),
                              ),
                              SizedBox(height: 2 * scale),
                              Text(
                                recipe.description,
                                style: GoogleFonts.inter(
                                  fontSize: 13 * scale,
                                  color: AppColors.darkGrey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.close,
                            size: 22 * scale,
                            color: AppColors.darkGrey,
                          ),
                          onPressed: onClose,
                        ),
                      ],
                    ),
                  ),

                  // ── Recipe image ──
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16 * scale,
                      vertical: 8 * scale,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12 * scale),
                      child: SizedBox(
                        width: double.infinity,
                        height: 160 * scale,
                        child: recipe.imageUrl != null
                            ? Image.asset(
                                recipe.imageUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  color: AppColors.softGrey,
                                  child: Icon(
                                    Icons.image,
                                    color: AppColors.clearGrey,
                                    size: 48 * scale,
                                  ),
                                ),
                              )
                            : Container(color: AppColors.softGrey),
                      ),
                    ),
                  ),

                  // ── Servings & Time ──
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16 * scale),
                    child: Row(
                      children: [
                        _InfoChip(
                          icon: Icons.fork_right,
                          label: 'Servings',
                          value: '${recipe.servings}',
                          scale: scale,
                          color: AppColors.vibrantPink,
                        ),
                        SizedBox(width: 24 * scale),
                        _InfoChip(
                          icon: Icons.access_time,
                          label: 'Time',
                          value: '${recipe.timeOfPreparation} min',
                          scale: scale,
                          color: AppColors.vibrantPink,
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 10 * scale),

                  // ── Diet Types ──
                  _LabelSection(
                    title: 'Diet Types',
                    labels: recipe.dietTags,
                    scale: scale,
                  ),

                  // ── Free of Ingredients ──
                  _LabelSection(
                    title: 'Free of Ingredients',
                    labels: recipe.freeOfIngredients,
                    scale: scale,
                  ),

                  SizedBox(height: 12 * scale),

                  // ── Save Recipe Button ──
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16 * scale),
                    child: SizedBox(
                      width: double.infinity,
                      height: 48 * scale,
                      child: ElevatedButton.icon(
                        onPressed: onSave,
                        icon: Icon(
                          Icons.bookmark_border,
                          size: 18 * scale,
                          color: AppColors.pureWhite,
                        ),
                        label: Text(
                          'Save Recipe',
                          style: GoogleFonts.inter(
                            fontSize: 15 * scale,
                            fontWeight: FontWeight.w600,
                            color: AppColors.pureWhite,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.royalPurple,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12 * scale),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 8 * scale),

                  // ── See More Details Button ──
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16 * scale),
                    child: SizedBox(
                      width: double.infinity,
                      height: 48 * scale,
                      child: OutlinedButton(
                        onPressed: onSeeMore,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.royalPurple),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12 * scale),
                          ),
                        ),
                        child: Text(
                          'See More Details',
                          style: GoogleFonts.inter(
                            fontSize: 15 * scale,
                            fontWeight: FontWeight.w600,
                            color: AppColors.royalPurple,
                          ),
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 12 * scale),

                  // ── Swipe hint ──
                  Text(
                    'Swipe up to see similar',
                    style: GoogleFonts.inter(
                      fontSize: 12 * scale,
                      color: AppColors.neutralGrey,
                    ),
                  ),
                  SizedBox(height: 12 * scale),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// More Actions Popup  (frame 2.0.11)
// ═══════════════════════════════════════════════════════════════
class _MoreActionsPopup extends StatelessWidget {
  final String recipeId;
  final double scale;
  final Size size;
  final VoidCallback onDismiss;
  final VoidCallback onSeeMore;
  final VoidCallback onSave;

  const _MoreActionsPopup({
    required this.recipeId,
    required this.scale,
    required this.size,
    required this.onDismiss,
    required this.onSeeMore,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onDismiss,
      child: Container(
        color: Colors.transparent,
        child: Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: EdgeInsets.only(right: 16 * scale, top: 100 * scale),
            child: GestureDetector(
              onTap: () {},
              child: Container(
                width: 190 * scale,
                decoration: BoxDecoration(
                  color: AppColors.pureWhite,
                  borderRadius: BorderRadius.circular(12 * scale),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _PopupItem(
                      icon: Icons.remove_red_eye_outlined,
                      label: 'See More Details',
                      scale: scale,
                      onTap: onSeeMore,
                    ),
                    const Divider(height: 1, color: AppColors.clearGrey),
                    _PopupItem(
                      icon: Icons.bookmark_border,
                      label: 'Save Recipe',
                      scale: scale,
                      onTap: onSave,
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

class _PopupItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final double scale;
  final VoidCallback onTap;

  const _PopupItem({
    required this.icon,
    required this.label,
    required this.scale,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12 * scale),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 14 * scale,
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
            Icon(icon, size: 18 * scale, color: AppColors.darkGrey),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Filter Bottom Sheet  (frame 2.0.12)
// ═══════════════════════════════════════════════════════════════
class _FilterSheet extends ConsumerStatefulWidget {
  final double scale;
  final Size size;
  final WidgetRef ref;

  const _FilterSheet({
    required this.scale,
    required this.size,
    required this.ref,
  });

  @override
  ConsumerState<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends ConsumerState<_FilterSheet> {
  late SearchRecipeFilter _localFilter;

  static const _sortOptions = ['Most Recent', 'Oldest', 'A-Z', 'Z-A'];
  static const _filter2Options = [
    'Nullam Scelerisque',
    'Nullam',
    'Duis',
    'Ullamcorper',
    'Ligula Imperdiet',
  ];
  static const _filter3Options = [
    'Nullam Scelerisque',
    'Nullam',
    'Duis',
    'Ullamcorper',
    'Ligula Imperdiet',
  ];

  @override
  void initState() {
    super.initState();
    _localFilter = widget.ref.read(searchRecipeProvider).filter;
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.scale;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20 * s)),
      ),
      padding: EdgeInsets.fromLTRB(
        16 * s,
        16 * s,
        16 * s,
        MediaQuery.paddingOf(context).bottom + 16 * s,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle + Close
          Row(
            children: [
              Expanded(
                child: Text(
                  'Filter Preferences',
                  style: GoogleFonts.inter(
                    fontSize: 17 * s,
                    fontWeight: FontWeight.w700,
                    color: AppColors.black,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Icon(Icons.close, size: 22 * s, color: AppColors.black),
              ),
            ],
          ),

          SizedBox(height: 18 * s),

          // Filter 01 — Sort dropdown
          Text(
            'Filter 01',
            style: GoogleFonts.inter(
              fontSize: 13 * s,
              fontWeight: FontWeight.w600,
              color: AppColors.black,
            ),
          ),
          SizedBox(height: 6 * s),
          _SortDropdown(
            value: _localFilter.sortBy,
            options: _sortOptions,
            scale: s,
            onChanged: (v) =>
                setState(() => _localFilter = _localFilter.copyWith(sortBy: v)),
          ),

          SizedBox(height: 16 * s),

          // Filter 02 — Tag chips
          Text(
            'Filter 02',
            style: GoogleFonts.inter(
              fontSize: 13 * s,
              fontWeight: FontWeight.w600,
              color: AppColors.black,
            ),
          ),
          SizedBox(height: 8 * s),
          _TagChips(
            options: _filter2Options,
            selected: _localFilter.filter2Tags,
            scale: s,
            onToggle: (tag) {
              final list = List<String>.from(_localFilter.filter2Tags);
              list.contains(tag) ? list.remove(tag) : list.add(tag);
              setState(
                () => _localFilter = _localFilter.copyWith(filter2Tags: list),
              );
            },
          ),

          SizedBox(height: 16 * s),

          // Filter 03 — Tag chips
          Text(
            'Filter 03',
            style: GoogleFonts.inter(
              fontSize: 13 * s,
              fontWeight: FontWeight.w600,
              color: AppColors.black,
            ),
          ),
          SizedBox(height: 8 * s),
          _TagChips(
            options: _filter3Options,
            selected: _localFilter.filter3Tags,
            scale: s,
            onToggle: (tag) {
              final list = List<String>.from(_localFilter.filter3Tags);
              list.contains(tag) ? list.remove(tag) : list.add(tag);
              setState(
                () => _localFilter = _localFilter.copyWith(filter3Tags: list),
              );
            },
          ),

          SizedBox(height: 24 * s),

          // Show Results button
          SizedBox(
            width: double.infinity,
            height: 50 * s,
            child: ElevatedButton(
              onPressed: () {
                widget.ref
                    .read(searchRecipeProvider.notifier)
                    .updateFilter(_localFilter);
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.vibrantPink,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12 * s),
                ),
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
        ],
      ),
    );
  }
}

class _SortDropdown extends StatelessWidget {
  final String value;
  final List<String> options;
  final double scale;
  final ValueChanged<String> onChanged;

  const _SortDropdown({
    required this.value,
    required this.options,
    required this.scale,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48 * scale,
      padding: EdgeInsets.symmetric(horizontal: 14 * scale),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.inputBorder),
        borderRadius: BorderRadius.circular(10 * scale),
        color: AppColors.pureWhite,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: Icon(
            Icons.keyboard_arrow_down,
            size: 20 * scale,
            color: AppColors.darkGrey,
          ),
          style: GoogleFonts.inter(
            fontSize: 14 * scale,
            color: AppColors.black,
          ),
          items: options
              .map((o) => DropdownMenuItem(value: o, child: Text(o)))
              .toList(),
          onChanged: (v) => v != null ? onChanged(v) : null,
        ),
      ),
    );
  }
}

class _TagChips extends StatelessWidget {
  final List<String> options;
  final List<String> selected;
  final double scale;
  final ValueChanged<String> onToggle;

  const _TagChips({
    required this.options,
    required this.selected,
    required this.scale,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8 * scale,
      runSpacing: 8 * scale,
      children: options.map((tag) {
        final isSelected = selected.contains(tag);
        return GestureDetector(
          onTap: () => onToggle(tag),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: 14 * scale,
              vertical: 7 * scale,
            ),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.softLavender : AppColors.pureWhite,
              border: Border.all(
                color: isSelected
                    ? AppColors.royalPurple
                    : AppColors.inputBorder,
              ),
              borderRadius: BorderRadius.circular(20 * scale),
            ),
            child: Text(
              tag,
              style: GoogleFonts.inter(
                fontSize: 13 * scale,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? AppColors.royalPurple : AppColors.darkGrey,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Reusable sub-widgets
// ═══════════════════════════════════════════════════════════════
class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final double scale;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.scale,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18 * scale, color: color),
        SizedBox(width: 4 * scale),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11 * scale,
                color: AppColors.darkGrey,
              ),
            ),
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 14 * scale,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _LabelSection extends StatelessWidget {
  final String title;
  final List<String> labels;
  final double scale;

  const _LabelSection({
    required this.title,
    required this.labels,
    required this.scale,
  });

  @override
  Widget build(BuildContext context) {
    if (labels.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: EdgeInsets.fromLTRB(16 * scale, 8 * scale, 16 * scale, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 13 * scale,
              fontWeight: FontWeight.w600,
              color: AppColors.black,
            ),
          ),
          SizedBox(height: 6 * scale),
          Wrap(
            spacing: 8 * scale,
            runSpacing: 6 * scale,
            children: labels.map((l) {
              return Container(
                width: 52 * scale,
                height: 52 * scale,
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.clearGrey),
                  borderRadius: BorderRadius.circular(8 * scale),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.circle_outlined,
                      size: 20 * scale,
                      color: AppColors.neutralGrey,
                    ),
                    SizedBox(height: 2 * scale),
                    Text(
                      l,
                      style: GoogleFonts.inter(
                        fontSize: 10 * scale,
                        color: AppColors.darkGrey,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
