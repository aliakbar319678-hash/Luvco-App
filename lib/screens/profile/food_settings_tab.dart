import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/food_settings_provider.dart';
import '../../widgets/food_settings_dialogs.dart';
import '../../providers/onboarding_provider.dart';

class FoodSettingsTab extends ConsumerStatefulWidget {
  const FoodSettingsTab({super.key});

  @override
  ConsumerState<FoodSettingsTab> createState() => _FoodSettingsTabState();
}

class _FoodSettingsTabState extends ConsumerState<FoodSettingsTab> {
  final Map<String, bool> _expandedSections = {
    'diet': false,
    'challenges': false,
  };

  final List<String> _dietOptions = [
    'Vegan',
    'Vegetarian',
    'Pescatarian',
    'Keto',
    'Paleo',
    'Gluten-Free',
    'Dairy-Free',
  ];

  final List<String> _challengeOptions = [
    'Nut Allergy',
    'Shellfish Allergy',
    'Lactose Intolerance',
    'Diabetes Friendly',
    'Low Sodium',
    'No Sugar',
  ];

  void _openModifySheet() {
    showFoodSettingsModifySheet(
      context,
      onModifyDiet: () async {
        await GoRouter.of(context).push('/food-diet');
        ref.read(foodSettingsProvider.notifier).loadSettings();
      },
      onModifyChallenges: () async {
        await GoRouter.of(context).push('/food-challenges');
        ref.read(foodSettingsProvider.notifier).loadSettings();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final scale = size.width / 390;
    final settings = ref.watch(foodSettingsProvider);
    if (settings.isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.only(top: 40),
          child: CircularProgressIndicator(color: AppColors.royalPurple),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: size.width * 0.058),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Section header: "Food Settings" + "Add Or Edit" ──
          Row(
            children: [
              // Bowl/salad icon matching Figma — using a custom painted icon
              // that matches the outlined bowl with steam/fork design
              const Icon(Icons.set_meal, color: AppColors.black, size: 24),
              const SizedBox(width: 8),

              Expanded(
                child: Text(
                  'Food Settings',
                  style: GoogleFonts.inter(
                    fontSize: 17 * scale.clamp(0.85, 1.2),
                    fontWeight: FontWeight.w700,
                    color: AppColors.black,
                  ),
                ),
              ),
              GestureDetector(
                onTap: _openModifySheet,
                child: Text(
                  'Add Or Edit',
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

          const SizedBox(height: 20),

          Container(
            decoration: BoxDecoration(
              color: AppColors.pureWhite,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.clearGrey.withValues(alpha: 0.6),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                // ── Diet Choices accordion ──
                _SettingsAccordionSection(
                  title: 'Diet Choices',
                  // Figma: fork & knife / restaurant icon
                  icon: Icons.restaurant,
                  isExpanded: _expandedSections['diet'] ?? false,
                  onToggle: () => setState(
                    () => _expandedSections['diet'] =
                        !(_expandedSections['diet'] ?? false),
                  ),
                  scale: scale,
                  content: Column(
                    children: [
                      // Manually added custom diets (shown as selected)
                      ...settings.customDiets.map(
                        (customItem) => _SettingsListItem(
                          label: customItem,
                          isSelected: true,
                          onTap: () {}, // Editable via "Add Or Edit"
                          scale: scale,
                        ),
                      ),
                      // Preset diets
                      ...settings.dietChoices
                          .map(
                            (option) => _SettingsListItem(
                              label: option,
                              isSelected: true,
                              onTap: () => ref
                                  .read(foodSettingsProvider.notifier)
                                  .toggleDietChoice(option),
                              scale: scale,
                            ),
                          )
                          .toList(),
                    ],
                  ),
                ),

                const Divider(
                  height: 1,
                  thickness: 1,
                  color: Color(0xFFEEEEEE),
                ),

                // ── Food Challenges & Allergies accordion ──
                _SettingsAccordionSection(
                  title: 'Food Challenges & Allergies',
                  // Figma: crossed-out food container icon
                  icon: Icons.no_food_outlined,
                  isExpanded: _expandedSections['challenges'] ?? false,
                  onToggle: () => setState(
                    () => _expandedSections['challenges'] =
                        !(_expandedSections['challenges'] ?? false),
                  ),
                  scale: scale,
                  content: Column(
                    children: [
                      // Manually added challenges (shown as selected)
                      ...settings.customChallenges.map(
                        (customItem) => _SettingsListItem(
                          label: customItem,
                          isSelected: true,
                          onTap: () {}, // Editable via "Add Or Edit"
                          scale: scale,
                        ),
                      ),
                      // Preset challenges
                      ...settings.challenges.map(
                        (option) => _SettingsListItem(
                          label: option,
                          isSelected: true,
                          onTap: () => ref
                              .read(foodSettingsProvider.notifier)
                              .toggleChallenge(option),
                          scale: scale,
                        ),
                      ),
                    ],
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
// Single selectable list item inside accordion — star icon matches Figma
// ─────────────────────────────────────────────────────────────────
class _SettingsListItem extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final double scale;

  const _SettingsListItem({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.scale,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            // Star icon — filled when selected, outlined otherwise (matches Figma screenshot 2)
            Icon(
              isSelected ? Icons.star_rounded : Icons.star_outline_rounded,
              color: isSelected ? AppColors.black : AppColors.darkGrey,
              size: 22,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 14 * scale.clamp(0.85, 1.2),
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? AppColors.black : AppColors.darkGrey,
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
// Accordion section container — matches Figma card style exactly
// ─────────────────────────────────────────────────────────────────
class _SettingsAccordionSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isExpanded;
  final VoidCallback onToggle;
  final double scale;
  final Widget content;

  const _SettingsAccordionSection({
    required this.title,
    required this.icon,
    required this.isExpanded,
    required this.onToggle,
    required this.scale,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Header row: icon + title + +/× toggle ──
        GestureDetector(
          onTap: onToggle,
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            child: Row(
              children: [
                // Section icon (restaurant or no_food matching Figma)
                Icon(icon, color: AppColors.black, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 15 * scale.clamp(0.85, 1.2),
                      fontWeight: FontWeight.w600,
                      color: AppColors.black,
                    ),
                  ),
                ),
                // Toggle icon: + when collapsed, × when expanded (matches Figma)
                Icon(
                  isExpanded ? Icons.close : Icons.add,
                  color: AppColors.black,
                  size: 22,
                ),
              ],
            ),
          ),
        ),

        // ── Expanded content with divider ──
        if (isExpanded) ...[
          const Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE)),
          Padding(
            padding: const EdgeInsets.only(
              left: 16,
              right: 16,
              top: 4,
              bottom: 16,
            ),
            child: SizedBox(width: double.infinity, child: content),
          ),
        ],
      ],
    );
  }
}
