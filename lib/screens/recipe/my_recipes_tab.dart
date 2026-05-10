import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../models/recipe_model.dart';
import '../../providers/recipe_provider.dart';
import '../../widgets/recipe_card.dart';
import '../../widgets/recipe_dialogs.dart';
import 'edit_recipe_screen.dart';

class MyRecipesTab extends ConsumerWidget {
  const MyRecipesTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final size = MediaQuery.sizeOf(context);
    final scale = size.width / 390;
    final myRecipes = ref.watch(myRecipesProvider);
    final savedRecipes = ref.watch(savedRecipesProvider);
    final viewMode = ref.watch(recipeViewModeProvider);
    final filterState = ref.watch(recipeFilterProvider);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: size.width * 0.058),
      child: Column(
        children: [
          // ── My Recipes section ──────────────────────────────────
          _RecipeSectionHeader(
            title: 'My Recipe',
            viewMode: viewMode,
            scale: scale,
            onGridTap: () => ref.read(recipeViewModeProvider.notifier).state =
                RecipeViewMode.grid,
            onListTap: () => ref.read(recipeViewModeProvider.notifier).state =
                RecipeViewMode.list,
            onFilterTap: () => _showFilterSheet(context, ref, filterState),
          ),

          const SizedBox(height: 16),

          if (myRecipes.isEmpty)
            _EmptyRecipeState(
              message: 'You have not yet created\na recipe.',
              actionLabel: 'Create New Recipe',
              scale: scale,
              size: size,
              onAction: () => _openEditRecipe(context, null),
            )
          else if (viewMode == RecipeViewMode.grid)
            _RecipeGridView(recipes: myRecipes, ref: ref, isMyRecipes: true)
          else
            _RecipeListViewSection(
              recipes: myRecipes,
              ref: ref,
              isMyRecipes: true,
            ),

          const SizedBox(height: 28),

          // ── Saved Recipes section ───────────────────────────────
          _RecipeSectionHeader(
            title: 'Saved Recipes',
            viewMode: viewMode,
            scale: scale,
            onGridTap: () => ref.read(recipeViewModeProvider.notifier).state =
                RecipeViewMode.grid,
            onListTap: () => ref.read(recipeViewModeProvider.notifier).state =
                RecipeViewMode.list,
            onFilterTap: () => _showFilterSheet(context, ref, filterState),
          ),

          const SizedBox(height: 16),

          if (savedRecipes.isEmpty)
            _EmptyRecipeState(
              message: 'A recipe has not been\nsaved yet.',
              actionLabel: 'Look For Recipes',
              scale: scale,
              size: size,
              onAction: () {},
            )
          else if (viewMode == RecipeViewMode.grid)
            _RecipeGridView(recipes: savedRecipes, ref: ref, isMyRecipes: false)
          else
            _RecipeListViewSection(
              recipes: savedRecipes,
              ref: ref,
              isMyRecipes: false,
            ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _showFilterSheet(
    BuildContext context,
    WidgetRef ref,
    RecipeFilterState filterState,
  ) {
    showDialog(
      context: context,
      builder: (_) => RecipeFilterSheet(
        initialSortBy: filterState.sortBy,
        initialDietFilters: filterState.dietFilters,
        onApply: (result) {
          ref.read(recipeFilterProvider.notifier).setSortBy(result.sortBy);
          for (final tag in result.dietFilters) {
            ref.read(recipeFilterProvider.notifier).toggleDietFilter(tag);
          }
        },
      ),
    );
  }

  void _openEditRecipe(BuildContext context, RecipeModel? recipe) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => EditRecipeScreen(recipe: recipe)));
  }
}

// ─────────────────────────────────────────────────────────────────
// Section Header Row
// ─────────────────────────────────────────────────────────────────
class _RecipeSectionHeader extends StatelessWidget {
  final String title;
  final RecipeViewMode viewMode;
  final double scale;
  final VoidCallback onGridTap;
  final VoidCallback onListTap;
  final VoidCallback onFilterTap;

  const _RecipeSectionHeader({
    required this.title,
    required this.viewMode,
    required this.scale,
    required this.onGridTap,
    required this.onListTap,
    required this.onFilterTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.menu_book_outlined, color: AppColors.black, size: 22),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 17 * scale.clamp(0.85, 1.2),
              fontWeight: FontWeight.w700,
              color: AppColors.black,
            ),
          ),
        ),
        // Grid toggle
        GestureDetector(
          onTap: onGridTap,
          child: Icon(
            Icons.grid_view_rounded,
            color: viewMode == RecipeViewMode.grid
                ? AppColors.black
                : AppColors.neutralGrey.withValues(alpha: 0.5),
            size: 22,
          ),
        ),
        const SizedBox(width: 8),
        Container(width: 1, height: 16, color: AppColors.clearGrey),
        const SizedBox(width: 8),
        // List toggle
        GestureDetector(
          onTap: onListTap,
          child: Icon(
            Icons.format_list_bulleted_rounded,
            color: viewMode == RecipeViewMode.list
                ? AppColors.black
                : AppColors.neutralGrey.withValues(alpha: 0.5),
            size: 22,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Empty state
// ─────────────────────────────────────────────────────────────────
class _EmptyRecipeState extends StatelessWidget {
  final String message;
  final String actionLabel;
  final double scale;
  final Size size;
  final VoidCallback onAction;

  const _EmptyRecipeState({
    required this.message,
    required this.actionLabel,
    required this.scale,
    required this.size,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: size.height * 0.04),
      child: Column(
        children: [
          SizedBox(
            width: 110 * scale.clamp(0.85, 1.2),
            height: 110 * scale.clamp(0.85, 1.2),
            child: Image.asset(
              'assets/images/home_cart_pic.png',
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Icon(
                Icons.restaurant_menu_outlined,
                size: 80 * scale.clamp(0.85, 1.2),
                color: AppColors.clearGrey,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 15 * scale.clamp(0.85, 1.2),
              fontWeight: FontWeight.w700,
              color: AppColors.black,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: onAction,
            child: Text(
              actionLabel,
              style: GoogleFonts.inter(
                fontSize: 13 * scale.clamp(0.85, 1.2),
                fontWeight: FontWeight.w500,
                color: AppColors.neutralGrey,
                decoration: TextDecoration.underline,
                decorationColor: AppColors.neutralGrey,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Grid view
// ─────────────────────────────────────────────────────────────────
class _RecipeGridView extends StatelessWidget {
  final List<RecipeModel> recipes;
  final WidgetRef ref;
  final bool isMyRecipes;

  const _RecipeGridView({
    required this.recipes,
    required this.ref,
    required this.isMyRecipes,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 16,
        childAspectRatio: 0.64,
      ),
      itemCount: recipes.length,
      itemBuilder: (context, index) {
        final recipe = recipes[index];
        return RecipeGridCard(
          recipe: recipe,
          onMoreTap: () => _showMoreActions(context, recipe),
        );
      },
    );
  }

  void _showMoreActions(BuildContext context, RecipeModel recipe) {
    showDialog(
      context: context,
      builder: (_) => RecipeMoreActionsMenu(
        onEdit: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => EditRecipeScreen(recipe: recipe)),
        ),
        onDuplicate: () {
          if (isMyRecipes) {
            ref.read(myRecipesProvider.notifier).duplicateRecipe(recipe.id);
          }
          _showDuplicateSuccess(context);
        },
        onDelete: () => _showDeleteDialog(context, recipe),
      ),
    );
  }

  void _showDuplicateSuccess(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => const RecipeDuplicateSuccessOverlay(),
    );
    Future.delayed(
      const Duration(seconds: 2),
      () {
        if (context.mounted) {
          Navigator.of(context, rootNavigator: true).pop();
        }
      },
    );
  }

  void _showDeleteDialog(BuildContext context, RecipeModel recipe) {
    showDialog(
      context: context,
      builder: (_) => RecipeDeleteConfirmDialog(
        recipeName: recipe.title,
        onDelete: () {
          if (isMyRecipes) {
            ref.read(myRecipesProvider.notifier).deleteRecipe(recipe.id);
          } else {
            ref.read(savedRecipesProvider.notifier).deleteRecipe(recipe.id);
          }
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// List view
// ─────────────────────────────────────────────────────────────────
class _RecipeListViewSection extends StatelessWidget {
  final List<RecipeModel> recipes;
  final WidgetRef ref;
  final bool isMyRecipes;

  const _RecipeListViewSection({
    required this.recipes,
    required this.ref,
    required this.isMyRecipes,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: recipes
          .map(
            (recipe) => RecipeListCard(
              recipe: recipe,
              onMoreTap: () => _showMoreActions(context, recipe),
            ),
          )
          .toList(),
    );
  }

  void _showMoreActions(BuildContext context, RecipeModel recipe) {
    showDialog(
      context: context,
      builder: (_) => RecipeMoreActionsMenu(
        onEdit: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => EditRecipeScreen(recipe: recipe)),
        ),
        onDuplicate: () {
          if (isMyRecipes) {
            ref.read(myRecipesProvider.notifier).duplicateRecipe(recipe.id);
          }
          showDialog(
            context: context,
            builder: (_) => const RecipeDuplicateSuccessOverlay(),
          );
          Future.delayed(
            const Duration(seconds: 2),
            () {
              if (context.mounted) {
                Navigator.of(context, rootNavigator: true).pop();
              }
            },
          );
        },
        onDelete: () => showDialog(
          context: context,
          builder: (_) => RecipeDeleteConfirmDialog(
            recipeName: recipe.title,
            onDelete: () {
              if (isMyRecipes) {
                ref.read(myRecipesProvider.notifier).deleteRecipe(recipe.id);
              } else {
                ref.read(savedRecipesProvider.notifier).deleteRecipe(recipe.id);
              }
            },
          ),
        ),
      ),
    );
  }
}
