import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../models/food_preferences_model.dart';
import '../../providers/food_preferences_provider.dart';
import '../../widgets/bottom_nav_bar.dart';

// ═══════════════════════════════════════════════════════════════════
//  FOOD PREFERENCES SCREEN
//  isDiet=false → Food Challenges & Allergies
//  isDiet=true  → Diet Preferences
// ═══════════════════════════════════════════════════════════════════
class FoodPreferencesScreen extends ConsumerWidget {
  final bool isDiet;
  const FoodPreferencesScreen({super.key, this.isDiet = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final size = MediaQuery.sizeOf(context);
    final scale = size.width / 390;
    final padding = MediaQuery.paddingOf(context);

    final activeTab = ref.watch(foodPrefsTabProvider);
    final deleteItem = ref.watch(foodPrefsDeleteItemProvider);
    final showSuccess = ref.watch(foodPrefsSuccessProvider);

    final provider = isDiet ? foodDietProvider : foodAllergiesProvider;
    final state = ref.watch(provider);

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
                // ── Top bar ──────────────────────────────────────
                _TopBar(
                  isDiet: isDiet,
                  scale: scale,
                  padding: padding,
                  onBack: () => GoRouter.of(context).pop(),
                ),

                // ── Tab switcher ─────────────────────────────────
                _TabSwitcher(
                  activeTab: activeTab,
                  scale: scale,
                  onChanged: (i) =>
                      ref.read(foodPrefsTabProvider.notifier).state = i,
                ),

                // ── Scrollable content ───────────────────────────
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(
                      24 * scale,
                      20,
                      24 * scale,
                      padding.bottom + 100,
                    ),
                    child: activeTab == 0
                        ? _SelectedTabContent(
                            state: state,
                            scale: scale,
                            isDiet: isDiet,
                            provider: provider,
                            onAddChoice: () => _openSearch(context, ref, isDiet, provider, scale),
                            onDeleteItem: (item) =>
                                ref
                                        .read(
                                          foodPrefsDeleteItemProvider.notifier,
                                        )
                                        .state =
                                    item,
                          )
                        : _CustomTabContent(
                            state: state,
                            scale: scale,
                            isDiet: isDiet,
                            provider: provider,
                            onAddManually: () => _openAddManually(context, ref, provider, scale),
                            onEditItem: (item) => _openEditItem(context, ref, provider, scale, item),
                            onDeleteItem: (item) =>
                                ref
                                        .read(
                                          foodPrefsDeleteItemProvider.notifier,
                                        )
                                        .state =
                                    item,
                          ),
                  ),
                ),

                // ── Bottom nav ───────────────────────────────────
                const LuvcoBottomNavBar(),
              ],
            ),

            // ── Delete confirm dialog ────────────────────────────
            if (deleteItem != null)
              _DeleteConfirmDialog(
                item: deleteItem,
                scale: scale,
                onCancel: () =>
                    ref.read(foodPrefsDeleteItemProvider.notifier).state = null,
                onDelete: () {
                  final isCustom = deleteItem.isCustom;
                  if (isCustom) {
                    ref.read(provider.notifier).deleteCustomItem(deleteItem.id);
                  } else {
                    ref
                        .read(provider.notifier)
                        .deleteSelectedItem(deleteItem.id);
                  }
                  ref.read(foodPrefsDeleteItemProvider.notifier).state = null;
                },
              ),

            // ── Success toast ─────────────────────────────────────
            if (showSuccess) const _SuccessToast(),
          ],
        ),
      ),
    );
  }

  void _showSuccess(WidgetRef ref) {
    ref.read(foodPrefsSuccessProvider.notifier).state = true;
    Future.delayed(const Duration(seconds: 2), () {
      ref.read(foodPrefsSuccessProvider.notifier).state = false;
    });
  }

  // ── Helper to open Search Bottom Sheet ──
  void _openSearch(BuildContext context, WidgetRef ref, bool isDiet, provider, double scale) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SearchModal(
        isDiet: isDiet,
        scale: scale,
        provider: provider,
        onClose: () => Navigator.pop(context),
        onSave: (selected) {
          ref.read(provider.notifier).addSelectedItems(selected);
          Navigator.pop(context);
          _showSuccess(ref);
        },
      ),
    );
  }

  // ── Helper to open Add Manually Bottom Sheet ──
  void _openAddManually(BuildContext context, WidgetRef ref, provider, double scale) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddManuallyModal(
        scale: scale,
        onClose: () => Navigator.pop(context),
        onSave: (labels) {
          ref.read(provider.notifier).addCustomItems(labels);
          Navigator.pop(context);
          _showSuccess(ref);
        },
      ),
    );
  }

  // ── Helper to open Edit Item Bottom Sheet ──
  void _openEditItem(BuildContext context, WidgetRef ref, provider, double scale, item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditCustomItemModal(
        item: item,
        scale: scale,
        onClose: () => Navigator.pop(context),
        onSave: (newLabel) {
          ref.read(provider.notifier).editCustomItem(item.id, newLabel);
          Navigator.pop(context);
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  TOP BAR
// ═══════════════════════════════════════════════════════════════════
class _TopBar extends StatelessWidget {
  final bool isDiet;
  final double scale;
  final EdgeInsets padding;
  final VoidCallback onBack;

  const _TopBar({
    required this.isDiet,
    required this.scale,
    required this.padding,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.pageBackground,
      padding: EdgeInsets.only(
        top: padding.top + 10,
        bottom: 14,
        left: 16 * scale,
        right: 16 * scale,
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: onBack,
            behavior: HitTestBehavior.opaque,
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: AppColors.vibrantPink,
              size: 20,
            ),
          ),
          Expanded(
            child: Text(
              isDiet
                  ? 'Settings: Diet Preferences'
                  : 'Settings: Food Challenges\n& Allergies',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 20 * scale.clamp(0.85, 1.2),
                fontWeight: FontWeight.w700,
                color: AppColors.vibrantPink,
                height: 1.25,
              ),
            ),
          ),
          SizedBox(width: 20 * scale),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  TAB SWITCHER  (Selected | Custom)
// ═══════════════════════════════════════════════════════════════════
class _TabSwitcher extends StatelessWidget {
  final int activeTab;
  final double scale;
  final ValueChanged<int> onChanged;

  const _TabSwitcher({
    required this.activeTab,
    required this.scale,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24 * scale, vertical: 12),
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: const Color(0xFFF3E8FF),
          borderRadius: BorderRadius.circular(26),
        ),
        child: Row(
          children: [
            _Tab(
              label: 'Selected',
              isActive: activeTab == 0,
              scale: scale,
              onTap: () => onChanged(0),
            ),
            _Tab(
              label: 'Custom',
              isActive: activeTab == 1,
              scale: scale,
              onTap: () => onChanged(1),
            ),
          ],
        ),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  final String label;
  final bool isActive;
  final double scale;
  final VoidCallback onTap;

  const _Tab({
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
          margin: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: isActive ? AppColors.royalPurple : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14 * scale.clamp(0.85, 1.2),
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: isActive ? AppColors.pureWhite : AppColors.darkGrey,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  SELECTED TAB CONTENT (1.5.0)
// ═══════════════════════════════════════════════════════════════════
class _SelectedTabContent extends StatefulWidget {
  final FoodPreferencesModel state;
  final double scale;
  final bool isDiet;
  final dynamic provider;
  final VoidCallback onAddChoice;
  final ValueChanged<FoodPreferenceItem> onDeleteItem;

  const _SelectedTabContent({
    required this.state,
    required this.scale,
    required this.isDiet,
    required this.provider,
    required this.onAddChoice,
    required this.onDeleteItem,
  });

  @override
  State<_SelectedTabContent> createState() => _SelectedTabContentState();
}

class _SelectedTabContentState extends State<_SelectedTabContent> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.scale;
    final label = widget.isDiet
        ? 'Diet Preferences'
        : 'Food Challenges or Allergies';
    final filtered = widget.state.selectedItems
        .where(
          (e) =>
              _query.isEmpty ||
              e.label.toLowerCase().contains(_query.toLowerCase()),
        )
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Section title ──
        Text(
          'Add ${widget.isDiet ? "Diet Preferences" : "Food Challenges or\nAllergies"}:',
          style: GoogleFonts.inter(
            fontSize: 22 * s.clamp(0.85, 1.2),
            fontWeight: FontWeight.w700,
            color: AppColors.black,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Search  and add for new $label.',
          style: GoogleFonts.inter(
            fontSize: 15 * s.clamp(0.85, 1.2),
            color: AppColors.darkGrey,
          ),
        ),
        const SizedBox(height: 16),

        // ── Add Another Choice button ──
        _AddChoiceButton(
          label: '+ Add Another Choice',
          scale: s,
          onTap: widget.onAddChoice,
        ),

        const SizedBox(height: 24),

        // ── Divider ──
        const Divider(color: AppColors.clearGrey, height: 1),

        const SizedBox(height: 16),

        // ── "Edit your..." subtitle ──
        Text(
          'Edit your ${widget.isDiet ? "Diet Preferences" : "food challenges &\nallergies"} items:',
          style: GoogleFonts.inter(
            fontSize: 18 * s.clamp(0.85, 1.2),
            fontWeight: FontWeight.w700,
            color: AppColors.black,
            height: 1.3,
          ),
        ),

        const SizedBox(height: 12),

        // ── Search bar ──
        _InlineSearchBar(
          controller: _searchCtrl,
          scale: s,
          onChanged: (v) => setState(() => _query = v),
        ),

        const SizedBox(height: 8),

        // ── List items ──
        ...filtered.map(
          (item) => _SelectedListItem(
            item: item,
            scale: s,
            onDelete: () => widget.onDeleteItem(item),
          ),
        ),

        const SizedBox(height: 40),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  CUSTOM TAB CONTENT (1.5.1)
// ═══════════════════════════════════════════════════════════════════
class _CustomTabContent extends StatefulWidget {
  final FoodPreferencesModel state;
  final double scale;
  final bool isDiet;
  final dynamic provider;
  final VoidCallback onAddManually;
  final ValueChanged<FoodPreferenceItem> onEditItem;
  final ValueChanged<FoodPreferenceItem> onDeleteItem;

  const _CustomTabContent({
    required this.state,
    required this.scale,
    required this.isDiet,
    required this.provider,
    required this.onAddManually,
    required this.onEditItem,
    required this.onDeleteItem,
  });

  @override
  State<_CustomTabContent> createState() => _CustomTabContentState();
}

class _CustomTabContentState extends State<_CustomTabContent> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.scale;
    final filtered = widget.state.customItems
        .where(
          (e) =>
              _query.isEmpty ||
              e.label.toLowerCase().contains(_query.toLowerCase()),
        )
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Section title ──
        Text(
          'Add Custom ${widget.isDiet ? "Food Challenges\nor Allergies" : "Food Challenges\nor Allergies"}:',
          style: GoogleFonts.inter(
            fontSize: 22 * s.clamp(0.85, 1.2),
            fontWeight: FontWeight.w700,
            color: AppColors.black,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Search  and add for new Food Challenges or Allergies.',
          style: GoogleFonts.inter(
            fontSize: 15 * s.clamp(0.85, 1.2),
            color: AppColors.darkGrey,
          ),
        ),
        const SizedBox(height: 16),

        // ── Add Manually button ──
        _AddChoiceButton(
          label: '+ Add Manually',
          scale: s,
          onTap: widget.onAddManually,
        ),

        const SizedBox(height: 24),

        const Divider(color: AppColors.clearGrey, height: 1),

        const SizedBox(height: 16),

        Text(
          'Edit your custom food\nchallenges & allergies items:',
          style: GoogleFonts.inter(
            fontSize: 15 * s.clamp(0.85, 1.2),
            fontWeight: FontWeight.w600,
            color: AppColors.black,
            height: 1.3,
          ),
        ),

        const SizedBox(height: 12),

        // ── Search bar ──
        _InlineSearchBar(
          controller: _searchCtrl,
          scale: s,
          onChanged: (v) => setState(() => _query = v),
        ),

        const SizedBox(height: 8),

        // ── List items with edit + delete ──
        ...filtered.map(
          (item) => _CustomListItem(
            item: item,
            scale: s,
            onEdit: () => widget.onEditItem(item),
            onDelete: () => widget.onDeleteItem(item),
          ),
        ),

        const SizedBox(height: 40),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  SEARCH MODAL (1.5.2 / 1.5.3 / 1.5.4)
// ═══════════════════════════════════════════════════════════════════
class _SearchModal extends ConsumerStatefulWidget {
  final bool isDiet;
  final double scale;
  final dynamic provider;
  final VoidCallback onClose;
  final ValueChanged<List<String>> onSave;

  const _SearchModal({
    required this.isDiet,
    required this.scale,
    required this.provider,
    required this.onClose,
    required this.onSave,
  });

  @override
  ConsumerState<_SearchModal> createState() => _SearchModalState();
}

class _SearchModalState extends ConsumerState<_SearchModal> {
  final TextEditingController _ctrl = TextEditingController();
  String _query = '';
  final List<String> _selected = [];

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _toggleChip(String label) {
    setState(() {
      if (_selected.contains(label)) {
        _selected.remove(label);
      } else {
        _selected.add(label);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.scale;
    final onboardingTagsAsync = ref.watch(onboardingTagsProvider);

    return onboardingTagsAsync.when(
      loading: () => Container(
        height: 300,
        decoration: const BoxDecoration(
          color: AppColors.pureWhite,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: AppColors.royalPurple),
        ),
      ),
      error: (err, stack) => Container(
        height: 300,
        decoration: const BoxDecoration(
          color: AppColors.pureWhite,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Center(
          child: Text(
            'Failed to load options: $err',
            style: GoogleFonts.inter(color: AppColors.errorRed),
          ),
        ),
      ),
      data: (tags) {
        final allResults = widget.isDiet
            ? (tags['diets'] ?? [])
            : (tags['allergies'] ?? []);

        final filteredResults = _query.isEmpty
            ? <String>[]
            : allResults
                .where((e) =>
                    e.toLowerCase().contains(_query.toLowerCase()) &&
                    !_selected.contains(e))
                .toList();

        final canSave = _selected.isNotEmpty;

        return GestureDetector(
          onTap: () {}, // prevent tap-through
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            decoration: const BoxDecoration(
              color: AppColors.pureWhite,
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Handle for bottom sheet ──
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.clearGrey,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                // ── Header ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Search for additional choices:',
                          style: GoogleFonts.inter(
                            fontSize: 16 * s.clamp(0.85, 1.2),
                            fontWeight: FontWeight.w700,
                            color: AppColors.black,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: widget.onClose,
                        child: const Icon(
                          Icons.close,
                          color: AppColors.darkGrey,
                          size: 22,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // ── Search field ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _ModalSearchField(
                    controller: _ctrl,
                    scale: s,
                    onChanged: (v) => setState(() => _query = v),
                    onClear: () {
                      _ctrl.clear();
                      setState(() => _query = '');
                    },
                  ),
                ),

                const SizedBox(height: 8),

                // ── Search results ──
                if (filteredResults.isNotEmpty)
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 160),
                    child: ListView.builder(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      itemCount: filteredResults.length,
                      itemBuilder: (_, i) => _SearchResultItem(
                        label: filteredResults[i],
                        isDiet: widget.isDiet,
                        scale: s,
                        onTap: () => _toggleChip(filteredResults[i]),
                      ),
                    ),
                  ),

                // ── Selected chips ──
                if (_selected.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _selected
                          .map(
                            (label) => _SelectedChip(
                              label: label,
                              scale: s,
                              onRemove: () => _toggleChip(label),
                            ),
                          )
                          .toList(),
                    ),
                  ),

                const SizedBox(height: 16),

                // ── Save Changes button ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: canSave
                          ? () => widget.onSave(_selected)
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: canSave
                            ? AppColors.royalPurple
                            : AppColors.faintPink,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        'Save Changes',
                        style: GoogleFonts.inter(
                          fontSize: 16 * s.clamp(0.85, 1.2),
                          fontWeight: FontWeight.w600,
                          color: canSave
                              ? AppColors.pureWhite
                              : AppColors.lightRoyalPurple,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  ADD MANUALLY MODAL (1.5.6 / 1.5.7)
// ═══════════════════════════════════════════════════════════════════
class _AddManuallyModal extends StatefulWidget {
  final double scale;
  final VoidCallback onClose;
  final ValueChanged<List<String>> onSave;

  const _AddManuallyModal({
    required this.scale,
    required this.onClose,
    required this.onSave,
  });

  @override
  State<_AddManuallyModal> createState() => _AddManuallyModalState();
}

class _AddManuallyModalState extends State<_AddManuallyModal> {
  final List<TextEditingController> _controllers = [TextEditingController()];

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _addMore() {
    setState(() => _controllers.add(TextEditingController()));
  }

  bool get _canSave => _controllers.any((c) => c.text.trim().isNotEmpty);

  @override
  Widget build(BuildContext context) {
    final s = widget.scale;

    return GestureDetector(
      onTap: () {},
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.fromLTRB(
          20,
          12,
          20,
          MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        decoration: const BoxDecoration(
          color: AppColors.pureWhite,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Handle ──
            Center(
              child: Container(
                margin: const EdgeInsets.only(bottom: 20),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.clearGrey,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // ── Header ──
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Do you want to add a custom food\nchallenges or allergies?',
                    style: GoogleFonts.inter(
                      fontSize: 16 * s.clamp(0.85, 1.2),
                      fontWeight: FontWeight.w700,
                      color: AppColors.black,
                      height: 1.3,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: widget.onClose,
                  child: const Icon(
                    Icons.close,
                    color: AppColors.darkGrey,
                    size: 22,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ── Input fields ──
            ..._controllers.asMap().entries.map((entry) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Other',
                    style: GoogleFonts.inter(
                      fontSize: 13 * s.clamp(0.85, 1.2),
                      fontWeight: FontWeight.w500,
                      color: AppColors.darkGrey,
                    ),
                  ),
                  const SizedBox(height: 6),
                  _ManualInputField(
                    controller: entry.value,
                    hint: 'Enter your food challenge or allergy',
                    scale: s,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 12),
                ],
              );
            }),

            // ── Add More ──
            Center(
              child: GestureDetector(
                onTap: _addMore,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(
                        color: AppColors.black,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.add,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Add More',
                      style: GoogleFonts.inter(
                        fontSize: 13 * s.clamp(0.85, 1.2),
                        fontWeight: FontWeight.w500,
                        color: AppColors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ── Save button ──
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _canSave
                    ? () => widget.onSave(
                        _controllers
                            .map((c) => c.text.trim())
                            .where((t) => t.isNotEmpty)
                            .toList(),
                      )
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _canSave
                      ? AppColors.royalPurple
                      : AppColors.faintPink,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  'Save Changes',
                  style: GoogleFonts.inter(
                    fontSize: 15 * s.clamp(0.85, 1.2),
                    fontWeight: FontWeight.w600,
                    color: _canSave
                        ? AppColors.pureWhite
                        : AppColors.lightRoyalPurple,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  EDIT CUSTOM ITEM MODAL (1.5.9)
// ═══════════════════════════════════════════════════════════════════
class _EditCustomItemModal extends StatefulWidget {
  final FoodPreferenceItem item;
  final double scale;
  final VoidCallback onClose;
  final ValueChanged<String> onSave;

  const _EditCustomItemModal({
    required this.item,
    required this.scale,
    required this.onClose,
    required this.onSave,
  });

  @override
  State<_EditCustomItemModal> createState() => _EditCustomItemModalState();
}

class _EditCustomItemModalState extends State<_EditCustomItemModal> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.item.label);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.scale;

    return GestureDetector(
      onTap: () {},
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.fromLTRB(
          20,
          12,
          20,
          MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        decoration: const BoxDecoration(
          color: AppColors.pureWhite,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Handle ──
            Center(
              child: Container(
                margin: const EdgeInsets.only(bottom: 20),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.clearGrey,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // ── Header ──
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Do you want to edit this custom\nitem?',
                    style: GoogleFonts.inter(
                      fontSize: 16 * s.clamp(0.85, 1.2),
                      fontWeight: FontWeight.w700,
                      color: AppColors.black,
                      height: 1.3,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: widget.onClose,
                  child: const Icon(
                    Icons.close,
                    color: AppColors.darkGrey,
                    size: 22,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            Text(
              'Other',
              style: GoogleFonts.inter(
                fontSize: 13 * s.clamp(0.85, 1.2),
                fontWeight: FontWeight.w500,
                color: AppColors.darkGrey,
              ),
            ),
            const SizedBox(height: 6),

            _ManualInputField(
              controller: _ctrl,
              hint: 'Enter item name',
              scale: s,
              onChanged: (_) => setState(() {}),
              autofocus: true,
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _ctrl.text.trim().isNotEmpty
                    ? () => widget.onSave(_ctrl.text.trim())
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.royalPurple,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  'Save Changes',
                  style: GoogleFonts.inter(
                    fontSize: 15 * s.clamp(0.85, 1.2),
                    fontWeight: FontWeight.w600,
                    color: AppColors.pureWhite,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  DELETE CONFIRM DIALOG (1.5.10 / 1.5.12)
// ═══════════════════════════════════════════════════════════════════
class _DeleteConfirmDialog extends StatelessWidget {
  final FoodPreferenceItem item;
  final double scale;
  final VoidCallback onCancel;
  final VoidCallback onDelete;

  const _DeleteConfirmDialog({
    required this.item,
    required this.scale,
    required this.onCancel,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final s = scale;

    return Positioned.fill(
      child: GestureDetector(
        onTap: onCancel,
        child: Container(
          color: Colors.black.withValues(alpha: 0.45),
          child: Center(
            child: GestureDetector(
              onTap: () {},
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 30 * s),
                decoration: BoxDecoration(
                  color: AppColors.pureWhite,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                      child: Text(
                        'Do you want to delete\n"Custom Item"?',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 16 * s.clamp(0.85, 1.2),
                          fontWeight: FontWeight.w700,
                          color: AppColors.black,
                          height: 1.3,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        'Lorem ipsum dolor sit amet,\nconsectetur adipiscing elit.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 12 * s.clamp(0.85, 1.2),
                          color: AppColors.neutralGrey,
                          height: 1.4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Divider(height: 1, color: AppColors.clearGrey),
                    IntrinsicHeight(
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: onCancel,
                              behavior: HitTestBehavior.opaque,
                              child: Container(
                                alignment: Alignment.center,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                child: Text(
                                  'Cancel',
                                  style: GoogleFonts.inter(
                                    fontSize: 14 * s.clamp(0.85, 1.2),
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFF007AFF),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const VerticalDivider(width: 1, color: AppColors.clearGrey),
                          Expanded(
                            child: GestureDetector(
                              onTap: onDelete,
                              behavior: HitTestBehavior.opaque,
                              child: Container(
                                alignment: Alignment.center,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                child: Text(
                                  'Delete',
                                  style: GoogleFonts.inter(
                                    fontSize: 14 * s.clamp(0.85, 1.2),
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.errorRed,
                                  ),
                                ),
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
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  SUCCESS TOAST (1.5.5 / 1.5.8 / 1.5.16)
// ═══════════════════════════════════════════════════════════════════
class _SuccessToast extends StatelessWidget {
  const _SuccessToast();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.45),
        child: Center(
          child: Container(
            width: 200,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 24,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/icons/circle_check.png',
                  width: 56,
                  height: 56,
                ),
                const SizedBox(height: 14),
                Text(
                  'New Food Preferences\nadded successfully!',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 14,
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
//  SHARED SMALL WIDGETS
// ═══════════════════════════════════════════════════════════════════

// ── "Add Another Choice" / "Add Manually" outline button ──────────
class _AddChoiceButton extends StatelessWidget {
  final String label;
  final double scale;
  final VoidCallback onTap;

  const _AddChoiceButton({
    required this.label,
    required this.scale,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.royalPurple, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 16 * scale.clamp(0.85, 1.2),
            fontWeight: FontWeight.w600,
            color: AppColors.royalPurple,
          ),
        ),
      ),
    );
  }
}

// ── Inline search bar (inside tab content) ────────────────────────
class _InlineSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final double scale;
  final ValueChanged<String> onChanged;

  const _InlineSearchBar({
    required this.controller,
    required this.scale,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.royalPurple, width: 1.5),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: GoogleFonts.inter(
          fontSize: 16 * scale.clamp(0.85, 1.2),
          color: AppColors.black,
        ),
        decoration: InputDecoration(
          hintText: 'Search in your list',
          hintStyle: GoogleFonts.inter(
            fontSize: 16 * scale.clamp(0.85, 1.2),
            color: AppColors.neutralGrey,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: AppColors.royalPurple,
            size: 20,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 13),
        ),
      ),
    );
  }
}

// ── Modal search field ────────────────────────────────────────────
class _ModalSearchField extends StatelessWidget {
  final TextEditingController controller;
  final double scale;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _ModalSearchField({
    required this.controller,
    required this.scale,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.royalPurple, width: 1.5),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: GoogleFonts.inter(
          fontSize: 16 * scale.clamp(0.85, 1.2),
          color: AppColors.black,
        ),
        decoration: InputDecoration(
          hintText: 'Dairy-Free',
          hintStyle: GoogleFonts.inter(
            fontSize: 16 * scale.clamp(0.85, 1.2),
            color: AppColors.neutralGrey,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: AppColors.royalPurple,
            size: 20,
          ),
          suffixIcon: controller.text.isNotEmpty
              ? GestureDetector(
                  onTap: onClear,
                  child: const Icon(
                    Icons.close,
                    color: AppColors.neutralGrey,
                    size: 18,
                  ),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 13),
        ),
      ),
    );
  }
}

// ── Selected list item (star icon + delete trash) ─────────────────
class _SelectedListItem extends StatelessWidget {
  final FoodPreferenceItem item;
  final double scale;
  final VoidCallback onDelete;

  const _SelectedListItem({
    required this.item,
    required this.scale,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.inputBorder, width: 0.5),
      ),
      child: Row(
        children: [
          Icon(
            Icons.star_rounded,
            color: AppColors.black,
            size: 26 * scale.clamp(0.85, 1.2),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              item.label,
              style: GoogleFonts.inter(
                fontSize: 16 * scale.clamp(0.85, 1.2),
                fontWeight: FontWeight.w500,
                color: AppColors.black,
              ),
            ),
          ),
          GestureDetector(
            onTap: onDelete,
            child: Icon(
              Icons.delete_outline_rounded,
              color: AppColors.black,
              size: 24 * scale.clamp(0.85, 1.2),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Custom list item (star + edit pencil + delete trash) ──────────
class _CustomListItem extends StatelessWidget {
  final FoodPreferenceItem item;
  final double scale;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CustomListItem({
    required this.item,
    required this.scale,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.inputBorder, width: 0.5),
      ),
      child: Row(
        children: [
          Icon(
            Icons.star_rounded,
            color: AppColors.black,
            size: 26 * scale.clamp(0.85, 1.2),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              item.label,
              style: GoogleFonts.inter(
                fontSize: 16 * scale.clamp(0.85, 1.2),
                fontWeight: FontWeight.w500,
                color: AppColors.black,
              ),
            ),
          ),
          GestureDetector(
            onTap: onEdit,
            child: Icon(
              Icons.edit_outlined,
              color: AppColors.black,
              size: 24 * scale.clamp(0.85, 1.2),
            ),
          ),
          const SizedBox(width: 14),
          GestureDetector(
            onTap: onDelete,
            child: Icon(
              Icons.delete_outline_rounded,
              color: AppColors.black,
              size: 24 * scale.clamp(0.85, 1.2),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Search result list item ───────────────────────────────────────
class _SearchResultItem extends StatelessWidget {
  final String label;
  final bool isDiet;
  final double scale;
  final VoidCallback onTap;

  const _SearchResultItem({
    required this.label,
    required this.isDiet,
    required this.scale,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            isDiet
                ? Icon(
                    Icons.lunch_dining_outlined,
                    size: 20 * scale.clamp(0.85, 1.2),
                    color: AppColors.darkGrey,
                  )
                : Image.asset(
                    'assets/icons/milk_icon.png',
                    width: 20 * scale.clamp(0.85, 1.2),
                    height: 20 * scale.clamp(0.85, 1.2),
                    color: AppColors.darkGrey,
                  ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 14 * scale.clamp(0.85, 1.2),
                  color: AppColors.darkGrey,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Selected chip with × remove ──────────────────────────────────
class _SelectedChip extends StatelessWidget {
  final String label;
  final double scale;
  final VoidCallback onRemove;

  const _SelectedChip({
    required this.label,
    required this.scale,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.royalPurple, width: 1.5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12 * scale.clamp(0.85, 1.2),
              fontWeight: FontWeight.w500,
              color: AppColors.royalPurple,
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(Icons.close, size: 14, color: AppColors.royalPurple),
          ),
        ],
      ),
    );
  }
}

// ── Manual input field ────────────────────────────────────────────
class _ManualInputField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final double scale;
  final ValueChanged<String> onChanged;
  final bool autofocus;

  const _ManualInputField({
    required this.controller,
    required this.hint,
    required this.scale,
    required this.onChanged,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      autofocus: autofocus,
      onChanged: onChanged,
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
