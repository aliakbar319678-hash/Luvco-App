import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../models/recipe_model.dart';
import '../../providers/recipe_provider.dart';

class EditRecipeScreen extends ConsumerStatefulWidget {
  final RecipeModel? recipe; // null = create new

  const EditRecipeScreen({super.key, this.recipe});

  @override
  ConsumerState<EditRecipeScreen> createState() => _EditRecipeScreenState();
}

class _EditRecipeScreenState extends ConsumerState<EditRecipeScreen> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  late int _timeOfPrep;
  late int _servings;
  late List<String> _selectedDietTags;
  late List<String> _selectedFreeOf;

  int _activeTab = 0; // 0=Details 1=Preparation 2=Products

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
    _nameCtrl = TextEditingController(text: r?.title ?? '');
    _descCtrl = TextEditingController(text: r?.description ?? '');
    _timeOfPrep = r?.timeOfPreparation ?? 60;
    _servings = r?.servings ?? 2;
    _selectedDietTags = List.from(r?.dietTags ?? []);
    _selectedFreeOf = List.from(r?.freeOfIngredients ?? []);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void _toggleDiet(String tag) {
    setState(() {
      _selectedDietTags.contains(tag)
          ? _selectedDietTags.remove(tag)
          : _selectedDietTags.add(tag);
    });
  }

  void _toggleFreeOf(String tag) {
    setState(() {
      _selectedFreeOf.contains(tag)
          ? _selectedFreeOf.remove(tag)
          : _selectedFreeOf.add(tag);
    });
  }

  void _saveChanges() {
    final r = widget.recipe;
    if (r == null) {
      // Create new
      ref
          .read(myRecipesProvider.notifier)
          .addRecipe(
            RecipeModel(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              title: _nameCtrl.text.trim().isEmpty
                  ? 'New Recipe'
                  : _nameCtrl.text.trim(),
              description: _descCtrl.text.trim(),
              timeOfPreparation: _timeOfPrep,
              servings: _servings,
              dietTags: _selectedDietTags,
              freeOfIngredients: _selectedFreeOf,
            ),
          );
    } else {
      ref
          .read(myRecipesProvider.notifier)
          .editRecipe(
            r.copyWith(
              title: _nameCtrl.text.trim(),
              description: _descCtrl.text.trim(),
              timeOfPreparation: _timeOfPrep,
              servings: _servings,
              dietTags: _selectedDietTags,
              freeOfIngredients: _selectedFreeOf,
            ),
          );
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final padding = MediaQuery.paddingOf(context);
    final scale = size.width / 390;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: AppColors.pureWhite,
        body: Column(
          children: [
            // ── Header ──
            _EditRecipeHeader(
              padding: padding,
              scale: scale,
              size: size,
              activeTab: _activeTab,
              onTabChanged: (t) => setState(() => _activeTab = t),
            ),

            // ── Scrollable body ──
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(
                  horizontal: size.width * 0.058,
                  vertical: 20,
                ),
                child: Column(
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
                    _RequiredNote(scale: scale),
                    const SizedBox(height: 20),

                    // Cover picture
                    _SectionLabel(label: 'Cover Picture*', scale: scale),
                    const SizedBox(height: 8),
                    _CoverPicturePicker(scale: scale),
                    const SizedBox(height: 20),

                    // Recipe name
                    _SectionLabel(label: "Recipe's Name:*", scale: scale),
                    const SizedBox(height: 8),
                    _LuvcoInputField(
                      controller: _nameCtrl,
                      hint: 'Cool Recipe',
                      scale: scale,
                    ),
                    const SizedBox(height: 16),

                    // Description
                    _SectionLabel(label: 'Description*', scale: scale),
                    const SizedBox(height: 8),
                    _LuvcoInputField(
                      controller: _descCtrl,
                      hint: 'Gluten-Free Cool Recipe',
                      scale: scale,
                    ),
                    const SizedBox(height: 16),

                    // Time of preparation
                    _SectionLabel(label: 'Time of preparation*', scale: scale),
                    const SizedBox(height: 8),
                    _DropdownField<int>(
                      value: _timeOfPrep,
                      items: _prepTimes,
                      displayText: (v) => '$v min',
                      scale: scale,
                      onChanged: (v) =>
                          setState(() => _timeOfPrep = v ?? _timeOfPrep),
                    ),
                    const SizedBox(height: 16),

                    // Servings
                    _SectionLabel(label: 'Servings*', scale: scale),
                    const SizedBox(height: 8),
                    _DropdownField<int>(
                      value: _servings,
                      items: _servingOptions,
                      displayText: (v) => '$v',
                      scale: scale,
                      onChanged: (v) =>
                          setState(() => _servings = v ?? _servings),
                    ),
                    const SizedBox(height: 16),

                    // Type of Diet
                    _SectionLabel(label: 'Type of Diet*', scale: scale),
                    const SizedBox(height: 10),
                    _ChipGroup(
                      options: _dietOptions,
                      selected: _selectedDietTags,
                      onToggle: _toggleDiet,
                      scale: scale,
                    ),
                    const SizedBox(height: 16),

                    // Free of Ingredients
                    _SectionLabel(label: 'Free of Ingredients', scale: scale),
                    const SizedBox(height: 10),
                    _ChipGroup(
                      options: _freeOfOptions,
                      selected: _selectedFreeOf,
                      onToggle: _toggleFreeOf,
                      scale: scale,
                    ),

                    const SizedBox(height: 32),

                    // Save Changes button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _saveChanges,
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
                    ),

                    const SizedBox(height: 40),
                  ],
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
// Header with back arrow + "Edit Recipe" title + tab bar
// ─────────────────────────────────────────────────────────────────
class _EditRecipeHeader extends StatelessWidget {
  final EdgeInsets padding;
  final double scale;
  final Size size;
  final int activeTab;
  final ValueChanged<int> onTabChanged;

  const _EditRecipeHeader({
    required this.padding,
    required this.scale,
    required this.size,
    required this.activeTab,
    required this.onTabChanged,
  });

  static const _tabs = ['Details', 'Preparation', 'Products'];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.pureWhite,
        boxShadow: [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 12,
            offset: Offset(0, 3),
          ),
        ],
      ),
      padding: EdgeInsets.only(
        top: padding.top + 10,
        bottom: 0,
        left: size.width * 0.058,
        right: size.width * 0.058,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Back + title
          Stack(
            alignment: Alignment.center,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: AppColors.royalPurple,
                    size: 20,
                  ),
                ),
              ),
              Text(
                'Edit Recipe',
                style: GoogleFonts.inter(
                  fontSize: 18 * scale.clamp(0.85, 1.2),
                  fontWeight: FontWeight.w700,
                  color: AppColors.royalPurple,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Tab bar
          Row(
            children: List.generate(_tabs.length, (i) {
              final isActive = i == activeTab;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onTabChanged(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: isActive
                              ? AppColors.royalPurple
                              : Colors.transparent,
                          width: 2.5,
                        ),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        _tabs[i],
                        style: GoogleFonts.inter(
                          fontSize: 13 * scale.clamp(0.85, 1.2),
                          fontWeight: isActive
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: isActive
                              ? AppColors.royalPurple
                              : AppColors.neutralGrey,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Cover picture picker placeholder
// ─────────────────────────────────────────────────────────────────
class _CoverPicturePicker extends StatelessWidget {
  final double scale;
  const _CoverPicturePicker({required this.scale});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {},
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: AspectRatio(
          aspectRatio: 2.2,
          child: Image.asset(
            'assets/images/bread_pic.png',
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: AppColors.clearGrey,
              child: Center(
                child: Icon(
                  Icons.add_photo_alternate_outlined,
                  size: 42 * scale.clamp(0.85, 1.2),
                  color: AppColors.neutralGrey,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Small helpers
// ─────────────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String label;
  final double scale;
  const _SectionLabel({required this.label, required this.scale});

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

class _RequiredNote extends StatelessWidget {
  final double scale;
  const _RequiredNote({required this.scale});

  @override
  Widget build(BuildContext context) {
    return Text(
      '*Mandatory fields',
      style: GoogleFonts.inter(
        fontSize: 11 * scale.clamp(0.85, 1.2),
        color: AppColors.neutralGrey,
        fontStyle: FontStyle.italic,
      ),
    );
  }
}

class _LuvcoInputField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final double scale;

  const _LuvcoInputField({
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

class _DropdownField<T> extends StatelessWidget {
  final T value;
  final List<T> items;
  final String Function(T) displayText;
  final double scale;
  final ValueChanged<T?> onChanged;

  const _DropdownField({
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

class _ChipGroup extends StatelessWidget {
  final List<String> options;
  final List<String> selected;
  final ValueChanged<String> onToggle;
  final double scale;

  const _ChipGroup({
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
