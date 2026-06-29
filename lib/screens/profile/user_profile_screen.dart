import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../models/shopping_list_model.dart';
import '../../providers/shopping_list_provider.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../../widgets/luvco_dialog.dart';
import '../../widgets/shopping_list_grid_card.dart';
import '../../widgets/shopping_list_list_card.dart';
import '../recipe/my_recipes_tab.dart';
import 'food_settings_tab.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/fab_menu_dialog.dart';
import '../../providers/account_settings_provider.dart';
import '../../providers/new_recipe_provider.dart';
import '../../providers/user_profile_provider.dart';
import '../../providers/recipe_provider.dart';

class UserProfileScreen extends ConsumerWidget {
  const UserProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final size = MediaQuery.sizeOf(context);
    final padding = MediaQuery.paddingOf(context);
    final lists = ref.watch(shoppingListProvider);
    final viewMode = ref.watch(viewModeProvider);
    final activeTab = ref.watch(profileTabProvider);
    final scale = size.width / 390;

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
                // ── Top Header ──
                _ProfileHeader(
                  size: size,
                  padding: padding,
                  scale: scale,
                  onSettingsTap: () => context.push('/account-settings'),
                  onFavoritesTap: () => context.push('/favorites'),
                ),

                // ── Scrollable body ──
                Expanded(
                  child: RefreshIndicator(
                    color: AppColors.vibrantPink,
                    onRefresh: () async {
                      ref.invalidate(shoppingListProvider);
                      ref.invalidate(myRecipesProvider);
                      ref.invalidate(savedRecipesProvider);
                      await Future.delayed(const Duration(milliseconds: 500));
                    },
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      child: Column(
                      children: [
                        const SizedBox(height: 16),

                        // ── Profile avatar + name ──
                        _ProfileInfo(size: size, scale: scale),

                        const SizedBox(height: 10),

                        // ── Tab bar ──
                        _ProfileTabBar(
                          activeTab: activeTab,
                          scale: scale,
                          size: size,
                          onTabChanged: (tab) =>
                              ref.read(profileTabProvider.notifier).state = tab,
                        ),

                        const SizedBox(height: 20),

                        // ── Tab content ──
                        if (activeTab == ProfileTab.shoppingLists)
                          _ShoppingListsTab(
                            lists: lists,
                            viewMode: viewMode,
                            size: size,
                            scale: scale,
                          )
                        else if (activeTab == ProfileTab.myRecipes)
                          const MyRecipesTab()
                        else if (activeTab == ProfileTab.foodSettings)
                          const FoodSettingsTab()
                        else
                          _PlaceholderTab(
                            label: 'Coming Soon',
                            scale: scale,
                          ),


                        // Bottom padding for FAB + nav
                        const SizedBox(height: 120),
                      ],
                    ),
                  ),
                ),
              ),

                // ── Bottom nav ──
                const LuvcoBottomNavBar(),
              ],
            ),

            // ── Floating Action Button ──
            Positioned(
              bottom: 126 + padding.bottom,
              right: size.width * 0.058,
              child: _FabButton(
                onTap: () {
                    showLuvcoFabActionMenu(
                      context,
                      onCreateList: () => context.push('/new-shopping-list'),
                      onSearchProducts: () => context.push('/dashboard-search'),
                      onCreateRecipe: () {
                        ref.read(newRecipeProvider.notifier).reset();
                        ref.read(newRecipeStepProvider.notifier).state = 1;
                        context.push('/new-recipe');
                      },
                      onSearchRecipe: () => context.push('/search-recipe'),
                    );
                },
              ),

            ),
          ],
        ),
      ),
    );
  }


}

// ─────────────────────────────────────────────────────────────────
// Profile Header — "My Profile" + heart + settings icons
// ─────────────────────────────────────────────────────────────────
class _ProfileHeader extends StatelessWidget {
  final Size size;
  final EdgeInsets padding;
  final double scale;
  final VoidCallback onSettingsTap;
  final VoidCallback onFavoritesTap;

  const _ProfileHeader({
    required this.size,
    required this.padding,
    required this.scale,
    required this.onSettingsTap,
    required this.onFavoritesTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 145 * scale,
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: EdgeInsets.only(
        top: padding.top,
        left: size.width * 0.058,
        right: size.width * 0.058,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── "My Profile" title ──
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'My Profile',
                style: GoogleFonts.inter(
                  fontSize: 22 * scale.clamp(0.85, 1.2),
                  fontWeight: FontWeight.w700,
                  color: AppColors.vibrantPink,
                ),
              ),
            ),
          ),

          // ── Heart icon ──
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: GestureDetector(
              onTap: onFavoritesTap,
              behavior: HitTestBehavior.opaque,
              child: Icon(
                Icons.favorite_border_rounded,
                color: AppColors.vibrantPink,
                size: 26 * scale.clamp(0.85, 1.2),
              ),
            ),
          ),

          const SizedBox(width: 16),

          // ── Settings icon ──
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: GestureDetector(
              onTap: onSettingsTap,
              child: Icon(
                Icons.settings_outlined,
                color: AppColors.vibrantPink,
                size: 26 * scale.clamp(0.85, 1.2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Profile avatar + name
// ─────────────────────────────────────────────────────────────────
class _ProfileInfo extends ConsumerWidget {
  final Size size;
  final double scale;

  const _ProfileInfo({required this.size, required this.scale});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountState = ref.watch(accountSettingsProvider);
    final userProfileAsync = ref.watch(userProfileProvider);

    final displayName = userProfileAsync.maybeWhen(
      data: (user) => '${user.firstName ?? ""} ${user.lastName ?? ""}'.trim().isEmpty
          ? 'User Name'
          : '${user.firstName} ${user.lastName}'.trim(),
      orElse: () => 'User Name',
    );

    final profilePicUrl = userProfileAsync.maybeWhen(
      data: (user) => user.profilePictureUrl,
      orElse: () => null,
    );

    return Column(
      children: [
        // Avatar circle
        Container(
          width: 102 * scale,
          height: 102 * scale,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.clearGrey,
            border: Border.all(color: AppColors.pureWhite, width: 3),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipOval(
            child: accountState.profileImage != null
                ? Image.file(
                    accountState.profileImage!,
                    fit: BoxFit.cover,
                  )
                : (profilePicUrl != null && profilePicUrl.isNotEmpty)
                    ? Image.network(
                        profilePicUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Image.asset(
                          'assets/images/profile_pic.png',
                          fit: BoxFit.cover,
                        ),
                      )
                    : Image.asset(
                        'assets/images/profile_pic.png',
                        fit: BoxFit.cover,
                      ),
          ),
        ),

        const SizedBox(height: 8),

        Text(
          displayName,
          style: GoogleFonts.nunito(
            fontSize: 20 * scale.clamp(0.85, 1.2),
            fontWeight: FontWeight.w700,
            color: AppColors.black,
            height: 1.0,
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Profile Tab Bar — Shopping Lists | My Recipes | Food Settings
// ─────────────────────────────────────────────────────────────────
class _ProfileTabBar extends StatelessWidget {
  final ProfileTab activeTab;
  final double scale;
  final Size size;
  final ValueChanged<ProfileTab> onTabChanged;

  const _ProfileTabBar({
    required this.activeTab,
    required this.scale,
    required this.size,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 347 * scale,
        height: 40 * scale,
        padding: EdgeInsets.all(3 * scale),
        decoration: BoxDecoration(
          color: const Color(0xFFF1EEF9), // Light lilac background
          borderRadius: BorderRadius.circular(20 * scale),
        ),
        child: Row(
          children: [
            _TabItem(
              label: 'Shopping Lists',
              isActive: activeTab == ProfileTab.shoppingLists,
              scale: scale,
              onTap: () => onTabChanged(ProfileTab.shoppingLists),
            ),
            _TabDivider(
              isVisible:
                  activeTab != ProfileTab.shoppingLists &&
                  activeTab != ProfileTab.myRecipes,
            ),
            _TabItem(
              label: 'My Recipes',
              isActive: activeTab == ProfileTab.myRecipes,
              scale: scale,
              onTap: () => onTabChanged(ProfileTab.myRecipes),
            ),
            _TabDivider(
              isVisible:
                  activeTab != ProfileTab.myRecipes &&
                  activeTab != ProfileTab.foodSettings,
            ),
            _TabItem(
              label: 'Food Settings',
              isActive: activeTab == ProfileTab.foodSettings,
              scale: scale,
              onTap: () => onTabChanged(ProfileTab.foodSettings),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  final String label;
  final bool isActive;
  final double scale;
  final VoidCallback onTap;

  const _TabItem({
    required this.label,
    required this.isActive,
    required this.scale,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: double.infinity,
          decoration: BoxDecoration(
            color: isActive ? AppColors.royalPurple : Colors.transparent,
            borderRadius: BorderRadius.circular(21 * scale),
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11 * scale.clamp(0.85, 1.1),
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                color: isActive ? AppColors.pureWhite : AppColors.black,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}

class _TabDivider extends StatelessWidget {
  final bool isVisible;
  const _TabDivider({required this.isVisible});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 14,
      color: isVisible ? AppColors.clearGrey : Colors.transparent,
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Shopping Lists Tab content
// ─────────────────────────────────────────────────────────────────
class _ShoppingListsTab extends ConsumerWidget {
  final List<ShoppingListModel> lists;
  final ShoppingListViewMode viewMode;
  final Size size;
  final double scale;
  // Uses ref directly for view mode toggles — no prop-drilling needed

  const _ShoppingListsTab({
    required this.lists,
    required this.viewMode,
    required this.size,
    required this.scale,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: size.width * 0.058),
      child: Column(
        children: [
          // ── Section header: "My Shopping Lists" + view toggles ──
          Row(
            children: [
              SvgPicture.asset(
                'assets/icons/shopping-bag.svg',
                colorFilter: const ColorFilter.mode(AppColors.black, BlendMode.srcIn),
                width: 22,
                height: 22,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'My Shopping Lists',
                  style: GoogleFonts.inter(
                    fontSize: 17 * scale.clamp(0.85, 1.2),
                    fontWeight: FontWeight.w700,
                    color: AppColors.black,
                  ),
                ),
              ),
              // Grid view icon
              GestureDetector(
                onTap: () => ref.read(viewModeProvider.notifier).state =
                    ShoppingListViewMode.grid,
                child: SvgPicture.asset(
                  'assets/icons/layout-grid.svg',
                  colorFilter: ColorFilter.mode(
                    viewMode == ShoppingListViewMode.grid
                        ? AppColors.black
                        : AppColors.neutralGrey.withValues(alpha: 0.5),
                    BlendMode.srcIn,
                  ),
                  width: 22,
                  height: 22,
                ),
              ),
              const SizedBox(width: 6),
              Container(width: 1, height: 14, color: AppColors.clearGrey),
              const SizedBox(width: 6),
              // List view icon
              GestureDetector(
                onTap: () => ref.read(viewModeProvider.notifier).state =
                    ShoppingListViewMode.list,
                child: SvgPicture.asset(
                  'assets/icons/list-details.svg',
                  colorFilter: ColorFilter.mode(
                    viewMode == ShoppingListViewMode.list
                        ? AppColors.black
                        : AppColors.neutralGrey.withValues(alpha: 0.5),
                    BlendMode.srcIn,
                  ),
                  width: 22,
                  height: 22,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // ── Empty state ──
          if (lists.isEmpty)
            _EmptyState(scale: scale, size: size)
          else if (viewMode == ShoppingListViewMode.grid)
            _GridView(lists: lists, size: size)
          else
            _ListView(lists: lists),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Empty state
// ─────────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final double scale;
  final Size size;

  const _EmptyState({required this.scale, required this.size});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: size.height * 0.06),
      child: Column(
        children: [
          // Illustration
          SizedBox(
            width: 120 * scale,
            height: 120 * scale,
            child: Image.asset(
              'assets/images/home_cart_pic.png',
              fit: BoxFit.contain,
            ),
          ),

          const SizedBox(height: 16),

          Text(
            'No shopping list has been\ncreated yet',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 16 * scale.clamp(0.85, 1.2),
              fontWeight: FontWeight.w700,
              color: AppColors.black,
              height: 1.3,
            ),
          ),

          const SizedBox(height: 12),

          TextButton(
            onPressed: () => context.push('/new-shopping-list'),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              'Create New Shopping List',
              style: GoogleFonts.inter(
                fontSize: 14 * scale.clamp(0.85, 1.2),
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
/// Grid view is now a [ConsumerWidget] so it reads the shopping-list
/// provider directly rather than receiving a [WidgetRef] as a prop.
/// This eliminates ref prop-drilling and enables correct selective rebuilds.
class _GridView extends ConsumerWidget {
  final List<ShoppingListModel> lists;
  final Size size;

  const _GridView({required this.lists, required this.size});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 14,
        childAspectRatio: 0.84,
      ),
      itemCount: lists.length,
      itemBuilder: (context, index) {
        final list = lists[index];
        return ShoppingListGridCard(
          list: list,
          onAction: (action) => _handleAction(context, ref, action, list),
          onTap: () => context.push('/shopping-list/${list.id}'),
        );
      },
    );
  }

  void _handleAction(
    BuildContext context,
    WidgetRef ref,
    String action,
    ShoppingListModel list,
  ) {
    if (action == 'edit') {
      _showEditDialog(context, ref, list);
    } else if (action == 'duplicate') {
      _showDuplicateSuccess(context, ref, list.id);
    } else if (action == 'delete') {
      _showDeleteDialog(context, ref, list);
    }
  }

  void _showEditDialog(
    BuildContext context,
    WidgetRef ref,
    ShoppingListModel list,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => LuvcoEditListBottomSheet(
        initialTitle: list.title,
        initialDescription: list.description,
        onSave: (title, desc) =>
            ref.read(shoppingListProvider.notifier).editList(list.id, title, desc),
      ),
    );
  }

  void _showDuplicateSuccess(
    BuildContext context,
    WidgetRef ref,
    String id,
  ) {
    ref.read(shoppingListProvider.notifier).duplicateList(id);
    showDialog(
      context: context,
      builder: (dialogContext) {
        Future.delayed(const Duration(seconds: 2), () {
          if (dialogContext.mounted) {
            Navigator.of(dialogContext).pop();
          }
        });
        return const LuvcoDuplicateSuccessOverlay();
      },
    );
  }

  void _showDeleteDialog(
    BuildContext context,
    WidgetRef ref,
    ShoppingListModel list,
  ) {
    showDialog(
      context: context,
      builder: (_) => LuvcoDeleteConfirmDialog(
        listName: list.title,
        onDelete: () =>
            ref.read(shoppingListProvider.notifier).deleteList(list.id),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// List view
// ─────────────────────────────────────────────────────────────────
/// List view is a [ConsumerWidget] — reads shopping-list provider itself
/// rather than accepting [WidgetRef] as a prop (eliminates ref prop-drilling).
/// Also deduplicates action handling with _GridView by using the same helper.
class _ListView extends ConsumerWidget {
  final List<ShoppingListModel> lists;

  const _ListView({required this.lists});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: lists
          .map(
            (list) => ShoppingListListCard(
              list: list,
              onAction: (action) => _handleAction(context, ref, action, list),
              onTap: () => context.push('/shopping-list/${list.id}'),
            ),
          )
          .toList(),
    );
  }

  void _handleAction(
    BuildContext context,
    WidgetRef ref,
    String action,
    ShoppingListModel list,
  ) {
    if (action == 'edit') {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => LuvcoEditListBottomSheet(
          initialTitle: list.title,
          initialDescription: list.description,
          onSave: (title, desc) =>
              ref.read(shoppingListProvider.notifier).editList(list.id, title, desc),
        ),
      );
    } else if (action == 'duplicate') {
      ref.read(shoppingListProvider.notifier).duplicateList(list.id);
      showDialog(
        context: context,
        builder: (dialogContext) {
          Future.delayed(const Duration(seconds: 2), () {
            if (dialogContext.mounted) {
              Navigator.of(dialogContext).pop();
            }
          });
          return const LuvcoDuplicateSuccessOverlay();
        },
      );
    } else if (action == 'delete') {
      showDialog(
        context: context,
        builder: (_) => LuvcoDeleteConfirmDialog(
          listName: list.title,
          onDelete: () =>
              ref.read(shoppingListProvider.notifier).deleteList(list.id),
        ),
      );
    }
  }
}

// ─────────────────────────────────────────────────────────────────
// Placeholder for other tabs
// ─────────────────────────────────────────────────────────────────
class _PlaceholderTab extends StatelessWidget {
  final String label;
  final double scale;

  const _PlaceholderTab({required this.label, required this.scale});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Center(
        child: Text(
          '$label coming soon',
          style: GoogleFonts.inter(
            fontSize: 14 * scale.clamp(0.85, 1.2),
            color: AppColors.neutralGrey,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// FAB Button
// ─────────────────────────────────────────────────────────────────
class _FabButton extends StatelessWidget {
  final VoidCallback onTap;
  const _FabButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 54,
        height: 54,
        padding: const EdgeInsets.all(12), // Resulting in a clean look
        decoration: BoxDecoration(
          color: AppColors.royalPurple,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.royalPurple.withValues(alpha: 0.35),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
      ),
    );
  }
}
