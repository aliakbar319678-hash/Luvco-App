import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/app_colors.dart';

// ─────────────────────────────────────────────────────────────────
// Recipe More Actions Menu (Edit / Duplicate / Delete)
// ─────────────────────────────────────────────────────────────────
class RecipeMoreActionsMenu extends StatelessWidget {
  final VoidCallback onEdit;
  final VoidCallback onDuplicate;
  final VoidCallback onDelete;

  const RecipeMoreActionsMenu({
    super.key,
    required this.onEdit,
    required this.onDuplicate,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      elevation: 0,
      child: Center(
        child: Container(
          width: 250,
          decoration: BoxDecoration(
            color: AppColors.pureWhite,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 16,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _MenuAction(
                label: 'Edit Recipe',
                icon: Icons.edit_outlined,
                onTap: () {
                  Navigator.of(context).pop();
                  onEdit();
                },
              ),
              const Divider(height: 1, thickness: 1, color: Color(0xFFF0F0F0)),
              _MenuAction(
                label: 'Duplicate Recipe',
                icon: Icons.copy_outlined,
                onTap: () {
                  Navigator.of(context).pop();
                  onDuplicate();
                },
              ),
              const Divider(height: 1, thickness: 1, color: Color(0xFFF0F0F0)),
              _MenuAction(
                label: 'Delete Recipe',
                icon: Icons.delete_outline_rounded,
                isDestructive: true,
                onTap: () {
                  Navigator.of(context).pop();
                  onDelete();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuAction extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isDestructive;
  final VoidCallback onTap;

  const _MenuAction({
    required this.label,
    required this.icon,
    this.isDestructive = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? AppColors.errorRed : AppColors.black;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: 46,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: color,
                  ),
                ),
              ),
              Icon(icon, size: 18, color: color),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Delete Confirmation Dialog
// ─────────────────────────────────────────────────────────────────
class RecipeDeleteConfirmDialog extends StatelessWidget {
  final String recipeName;
  final VoidCallback onDelete;

  const RecipeDeleteConfirmDialog({
    super.key,
    required this.recipeName,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.sizeOf(context).width / 390;

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: EdgeInsets.symmetric(horizontal: 32 * scale),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Do you want to delete\n"$recipeName"?',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 16 * scale.clamp(0.85, 1.2),
                    fontWeight: FontWeight.w700,
                    color: AppColors.black,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Lorem ipsum dolor sit amet, consectetur adipiscing elit.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 12 * scale.clamp(0.85, 1.2),
                    color: AppColors.neutralGrey,
                  ),
                ),
              ],
            ),
          ),

          // Horizontal Divider
          const Divider(height: 1, thickness: 1, color: AppColors.clearGrey),

          // Cancel / Delete row
          IntrinsicHeight(
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.inter(
                          fontSize: 14 * scale.clamp(0.85, 1.2),
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF007AFF), // Figma blue text
                        ),
                      ),
                    ),
                  ),
                ),
                const VerticalDivider(width: 1, thickness: 1, color: AppColors.clearGrey),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.of(context).pop();
                      onDelete();
                    },
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        'Delete',
                        style: GoogleFonts.inter(
                          fontSize: 14 * scale.clamp(0.85, 1.2),
                          fontWeight: FontWeight.w600,
                          color: AppColors.vibrantPink, // Figma red/pink text
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
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Duplicate Success Overlay
// ─────────────────────────────────────────────────────────────────
class RecipeDuplicateSuccessOverlay extends StatelessWidget {
  const RecipeDuplicateSuccessOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 60),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Green checkmark icon with rounded square bg
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.check_circle_outline_rounded,
                color: Color(0xFF4CAF50),
                size: 42,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'The recipe was\nduplicated!',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Filter Preferences Bottom Modal Sheet
// ─────────────────────────────────────────────────────────────────
class RecipeFilterSheet extends StatefulWidget {
  final String initialSortBy;
  final List<String> initialDietFilters;
  final ValueChanged<RecipeFilterResult> onApply;

  const RecipeFilterSheet({
    super.key,
    required this.initialSortBy,
    required this.initialDietFilters,
    required this.onApply,
  });

  @override
  State<RecipeFilterSheet> createState() => _RecipeFilterSheetState();
}

class RecipeFilterResult {
  final String sortBy;
  final List<String> dietFilters;
  const RecipeFilterResult({required this.sortBy, required this.dietFilters});
}

class _RecipeFilterSheetState extends State<RecipeFilterSheet> {
  late String _sortBy;
  late List<String> _dietFilters;

  static const _sortOptions = ['Most Recent', 'Oldest', 'A-Z', 'Z-A'];
  static const _dietOptions = [
    'See All',
    'Gluten Free',
    'Duis',
    'Ullamcorper',
    'Ligula Imperdiet',
  ];

  @override
  void initState() {
    super.initState();
    _sortBy = widget.initialSortBy;
    _dietFilters = List.from(widget.initialDietFilters);
  }

  void _toggleDiet(String filter) {
    setState(() {
      if (filter == 'See All') {
        _dietFilters.clear();
        return;
      }
      if (_dietFilters.contains(filter)) {
        _dietFilters.remove(filter);
      } else {
        _dietFilters.add(filter);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.sizeOf(context).width / 390;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 24,
        bottom: 24 + MediaQuery.of(context).viewInsets.bottom,
      ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Filter Preferences',
                    style: GoogleFonts.inter(
                      fontSize: 16 * scale.clamp(0.85, 1.2),
                      fontWeight: FontWeight.w700,
                      color: AppColors.black,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: const Icon(
                    Icons.close,
                    size: 20,
                    color: AppColors.darkGrey,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // ── Filter 01: Sort dropdown ──
            Text(
              'Filter 01',
              style: GoogleFonts.inter(
                fontSize: 12 * scale.clamp(0.85, 1.2),
                fontWeight: FontWeight.w600,
                color: AppColors.neutralGrey,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: AppColors.softGrey,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.inputBorder),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _sortBy,
                  isExpanded: true,
                  icon: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: AppColors.darkGrey,
                  ),
                  style: GoogleFonts.inter(
                    fontSize: 14 * scale.clamp(0.85, 1.2),
                    color: AppColors.black,
                    fontWeight: FontWeight.w500,
                  ),
                  dropdownColor: Colors.white,
                  items: _sortOptions
                      .map((o) => DropdownMenuItem(value: o, child: Text(o)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _sortBy = val);
                  },
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ── Filter 02: Diet chips ──
            Text(
              'Filter 02',
              style: GoogleFonts.inter(
                fontSize: 12 * scale.clamp(0.85, 1.2),
                fontWeight: FontWeight.w600,
                color: AppColors.neutralGrey,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _dietOptions.map((opt) {
                final isSelected = opt == 'See All'
                    ? _dietFilters.isEmpty
                    : _dietFilters.contains(opt);
                return GestureDetector(
                  onTap: () => _toggleDiet(opt),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.softLavender
                          : AppColors.softGrey,
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
                        fontSize: 13 * scale.clamp(0.85, 1.2),
                        fontWeight: FontWeight.w500,
                        color: isSelected
                            ? AppColors.royalPurple
                            : AppColors.darkGrey,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 24),

            // ── Show Results button ──
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  widget.onApply(
                    RecipeFilterResult(
                      sortBy: _sortBy,
                      dietFilters: _dietFilters,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.faintPink,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  'Show Results',
                  style: GoogleFonts.inter(
                    fontSize: 15 * scale.clamp(0.85, 1.2),
                    fontWeight: FontWeight.w600,
                    color: AppColors.royalPurple,
                  ),
                ),
              ),
            ),
          ],
        ),
    );
  }
}
