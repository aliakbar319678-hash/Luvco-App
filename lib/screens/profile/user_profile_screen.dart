import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../models/shopping_list_model.dart';
import '../../providers/shopping_list_provider.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../../widgets/luvco_dialog.dart';
import '../../widgets/shopping_list_grid_card.dart';
import '../../widgets/shopping_list_list_card.dart';

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
                _ProfileHeader(size: size, padding: padding, scale: scale),

                // ── Scrollable body ──
                Expanded(
                  child: SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    child: Column(
                      children: [
                        SizedBox(height: size.height * 0.022),

                        // ── Profile avatar + name ──
                        _ProfileInfo(size: size, scale: scale),

                        SizedBox(height: size.height * 0.022),

                        // ── Tab bar ──
                        _ProfileTabBar(
                          activeTab: activeTab,
                          scale: scale,
                          size: size,
                          onTabChanged: (tab) =>
                              ref.read(profileTabProvider.notifier).state = tab,
                        ),

                        SizedBox(height: size.height * 0.022),

                        // ── Tab content ──
                        if (activeTab == ProfileTab.shoppingLists)
                          _ShoppingListsTab(
                            lists: lists,
                            viewMode: viewMode,
                            size: size,
                            scale: scale,
                            ref: ref,
                          )
                        else
                          _PlaceholderTab(
                            label: activeTab == ProfileTab.myRecipes
                                ? 'My Recipes'
                                : 'Food Settings',
                            scale: scale,
                          ),

                        // Bottom padding for FAB + nav
                        SizedBox(height: size.height * 0.14),
                      ],
                    ),
                  ),
                ),

                // ── Bottom nav ──
                const LuvcoBottomNavBar(),
              ],
            ),

            // ── Floating Action Button ──
            Positioned(
              bottom: 72 + padding.bottom,
              right: size.width * 0.058,
              child: _FabButton(
                onTap: () => _showCreateListDialog(context, ref),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Show create list dialog ──────────────────────────────────
  void _showCreateListDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => LuvcoEditListDialog(
        initialTitle: '',
        initialDescription: '',
        onSave: (title, description) {
          ref
              .read(shoppingListProvider.notifier)
              .addList(
                ShoppingListModel(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  title: title.isEmpty ? 'New List' : title,
                  description: description,
                  itemCount: 0,
                ),
              );
        },
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

  const _ProfileHeader({
    required this.size,
    required this.padding,
    required this.scale,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.pureWhite,
      padding: EdgeInsets.only(
        top: padding.top + 12,
        bottom: 12,
        left: size.width * 0.058,
        right: size.width * 0.058,
      ),
      child: Row(
        children: [
          // ── "My Profile" title ──
          Expanded(
            child: Text(
              'My Profile',
              style: GoogleFonts.inter(
                fontSize: 20 * scale.clamp(0.85, 1.2),
                fontWeight: FontWeight.w700,
                color: AppColors.vibrantPink,
              ),
            ),
          ),

          // ── Heart icon ──
          GestureDetector(
            onTap: () {},
            child: Icon(
              Icons.favorite_border_rounded,
              color: AppColors.vibrantPink,
              size: 24,
            ),
          ),

          const SizedBox(width: 16),

          // ── Settings icon ──
          GestureDetector(
            onTap: () {},
            child: Icon(
              Icons.settings_outlined,
              color: AppColors.vibrantPink,
              size: 24,
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
class _ProfileInfo extends StatelessWidget {
  final Size size;
  final double scale;

  const _ProfileInfo({required this.size, required this.scale});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Avatar circle
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.clearGrey,
            border: Border.all(color: AppColors.pureWhite, width: 3),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.10),
                blurRadius: 8,
              ),
            ],
          ),
          child: ClipOval(
            child: Image.asset(
              'assets/images/profile_pic.png',
              fit: BoxFit.cover,
            ),
          ),
        ),

        const SizedBox(height: 10),

        Text(
          'User Name',
          style: GoogleFonts.inter(
            fontSize: 17 * scale.clamp(0.85, 1.2),
            fontWeight: FontWeight.w700,
            color: AppColors.black,
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
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: size.width * 0.058),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.pureWhite,
          borderRadius: BorderRadius.circular(50),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
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
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? AppColors.royalPurple : Colors.transparent,
            borderRadius: BorderRadius.circular(50),
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11 * scale.clamp(0.85, 1.1),
                fontWeight: FontWeight.w600,
                color: isActive ? AppColors.pureWhite : AppColors.darkGrey,
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
      height: 16,
      color: isVisible ? AppColors.clearGrey : Colors.transparent,
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Shopping Lists Tab content
// ─────────────────────────────────────────────────────────────────
class _ShoppingListsTab extends StatelessWidget {
  final List<ShoppingListModel> lists;
  final ShoppingListViewMode viewMode;
  final Size size;
  final double scale;
  final WidgetRef ref;

  const _ShoppingListsTab({
    required this.lists,
    required this.viewMode,
    required this.size,
    required this.scale,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: size.width * 0.058),
      child: Column(
        children: [
          // ── Section header: "My Shopping Lists" + view toggles ──
          Row(
            children: [
              Icon(
                Icons.shopping_basket_outlined,
                color: AppColors.black,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'My Shopping Lists',
                  style: GoogleFonts.inter(
                    fontSize: 15 * scale.clamp(0.85, 1.2),
                    fontWeight: FontWeight.w700,
                    color: AppColors.black,
                  ),
                ),
              ),
              // Grid view icon
              GestureDetector(
                onTap: () => ref.read(viewModeProvider.notifier).state =
                    ShoppingListViewMode.grid,
                child: Icon(
                  Icons.grid_view_rounded,
                  color: viewMode == ShoppingListViewMode.grid
                      ? AppColors.royalPurple
                      : AppColors.neutralGrey,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              // List view icon
              GestureDetector(
                onTap: () => ref.read(viewModeProvider.notifier).state =
                    ShoppingListViewMode.list,
                child: Icon(
                  Icons.view_list_rounded,
                  color: viewMode == ShoppingListViewMode.list
                      ? AppColors.royalPurple
                      : AppColors.neutralGrey,
                  size: 22,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ── Empty state ──
          if (lists.isEmpty)
            _EmptyState(scale: scale, size: size)
          else if (viewMode == ShoppingListViewMode.grid)
            _GridView(lists: lists, size: size, ref: ref)
          else
            _ListView(lists: lists, ref: ref),
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
              fontSize: 14 * scale.clamp(0.85, 1.2),
              fontWeight: FontWeight.w600,
              color: AppColors.black,
              height: 1.4,
            ),
          ),

          const SizedBox(height: 8),

          GestureDetector(
            onTap: () {},
            child: Text(
              'Create New Shopping List',
              style: GoogleFonts.inter(
                fontSize: 13 * scale.clamp(0.85, 1.2),
                fontWeight: FontWeight.w500,
                color: AppColors.royalPurple,
                decoration: TextDecoration.underline,
                decorationColor: AppColors.royalPurple,
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
class _GridView extends StatelessWidget {
  final List<ShoppingListModel> lists;
  final Size size;
  final WidgetRef ref;

  const _GridView({required this.lists, required this.size, required this.ref});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.82,
      ),
      itemCount: lists.length,
      itemBuilder: (context, index) {
        final list = lists[index];
        return ShoppingListGridCard(
          list: list,
          onMoreTap: () => _showMoreActions(context, list),
        );
      },
    );
  }

  void _showMoreActions(BuildContext context, ShoppingListModel list) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => LuvcoMoreActionsSheet(
        onEdit: () => _showEditDialog(context, list),
        onDuplicate: () => _showDuplicateSuccess(context, list.id),
        onDelete: () => _showDeleteDialog(context, list),
      ),
    );
  }

  void _showEditDialog(BuildContext context, ShoppingListModel list) {
    showDialog(
      context: context,
      builder: (_) => LuvcoEditListDialog(
        initialTitle: list.title,
        initialDescription: list.description,
        onSave: (title, desc) => ref
            .read(shoppingListProvider.notifier)
            .editList(list.id, title, desc),
      ),
    );
  }

  void _showDuplicateSuccess(BuildContext context, String id) {
    ref.read(shoppingListProvider.notifier).duplicateList(id);
    showDialog(
      context: context,
      builder: (_) => const LuvcoDuplicateSuccessOverlay(),
    );
    Future.delayed(
      const Duration(seconds: 2),
      () => Navigator.of(context, rootNavigator: true).pop(),
    );
  }

  void _showDeleteDialog(BuildContext context, ShoppingListModel list) {
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
class _ListView extends StatelessWidget {
  final List<ShoppingListModel> lists;
  final WidgetRef ref;

  const _ListView({required this.lists, required this.ref});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: lists
          .map(
            (list) => ShoppingListListCard(
              list: list,
              onMoreTap: () => _showMoreActions(context, list),
            ),
          )
          .toList(),
    );
  }

  void _showMoreActions(BuildContext context, ShoppingListModel list) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => LuvcoMoreActionsSheet(
        onEdit: () => showDialog(
          context: context,
          builder: (_) => LuvcoEditListDialog(
            initialTitle: list.title,
            initialDescription: list.description,
            onSave: (title, desc) => ref
                .read(shoppingListProvider.notifier)
                .editList(list.id, title, desc),
          ),
        ),
        onDuplicate: () {
          ref.read(shoppingListProvider.notifier).duplicateList(list.id);
          showDialog(
            context: context,
            builder: (_) => const LuvcoDuplicateSuccessOverlay(),
          );
          Future.delayed(
            const Duration(seconds: 2),
            () => Navigator.of(context, rootNavigator: true).pop(),
          );
        },
        onDelete: () => showDialog(
          context: context,
          builder: (_) => LuvcoDeleteConfirmDialog(
            listName: list.title,
            onDelete: () =>
                ref.read(shoppingListProvider.notifier).deleteList(list.id),
          ),
        ),
      ),
    );
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
        width: 52,
        height: 52,
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
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }
}
