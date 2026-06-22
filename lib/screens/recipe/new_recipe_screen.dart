import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/theme/app_colors.dart';
import '../../models/new_recipe_model.dart';
import '../../providers/new_recipe_provider.dart';
import '../../widgets/auth_header.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../../widgets/luvco_button.dart';
import '../../widgets/preference_chip.dart';
import '../../widgets/step_progress_bar.dart';

// ═══════════════════════════════════════════════════════════════════
// NewRecipeScreen — 3-step recipe creation flow
// Step 1: Basic info + cover + diet chips
// Step 2: Ingredients & Instructions (text areas)
// Step 3: Look for Products (search + add ingredients)
// ═══════════════════════════════════════════════════════════════════
class NewRecipeScreen extends ConsumerWidget {
  const NewRecipeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final step = ref.watch(newRecipeStepProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: AppColors.pageBackground,
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, anim) => FadeTransition(
            opacity: anim,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.05, 0),
                end: Offset.zero,
              ).animate(anim),
              child: child,
            ),
          ),
          child: switch (step) {
            1 => const _Step1Widget(key: ValueKey('step1')),
            2 => const _Step2Widget(key: ValueKey('step2')),
            3 => const _Step3Widget(key: ValueKey('step3')),
            _ => const _Step1Widget(key: ValueKey('step1')),
          },
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// STEP 1 — Create a new recipe (basic info)
// ═══════════════════════════════════════════════════════════════════
class _Step1Widget extends ConsumerStatefulWidget {
  const _Step1Widget({super.key});

  @override
  ConsumerState<_Step1Widget> createState() => _Step1WidgetState();
}

class _Step1WidgetState extends ConsumerState<_Step1Widget> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  static const _dietOptions = [
    'Nullam Scelerisque',
    'Nullam',
    'Duis',
    'Ullamcorper',
    'Ligula Imperdiet',
    'Lectus',
  ];
  static const _freeOptions = [
    'None',
    'Nullam Scelerisque',
    'Nullam',
    'Ullamcorper',
    'Lectus',
    'Ligula Imperdiet',
  ];
  static const _timeOptions = ['30 mins', '45 mins', '60 mins', '90 mins', '120 mins'];
  static const _servingOptions = ['1 person', '2 people', '3 people', '4 people', '5 people', '6 people'];

  @override
  void initState() {
    super.initState();
    final recipe = ref.read(newRecipeProvider);
    _nameCtrl.text = recipe.recipeName;
    _descCtrl.text = recipe.description;
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      ref.read(newRecipeProvider.notifier).setCoverImage(image.path);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final scale = size.width / 390;
    final recipe = ref.watch(newRecipeProvider);
    final notifier = ref.read(newRecipeProvider.notifier);

    return Column(
      children: [
        // ── Header ──────────────────────────────────────────────
        AuthHeader(
          title: 'New Recipe',
          showBackButton: true,
          onBackTap: () {
            ref.read(newRecipeProvider.notifier).reset();
            context.pop();
          },
        ),

        // ── Body ─────────────────────────────────────────────────
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
                // ── Step Progress ──
                const StepProgressBar(currentStep: 1),
                SizedBox(height: size.height * 0.028),

                // ── Title ──
                Text(
                  'Create a new recipe:',
                  style: GoogleFonts.inter(
                    fontSize: 20 * scale.clamp(0.85, 1.2),
                    fontWeight: FontWeight.w700,
                    color: AppColors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod.',
                  style: GoogleFonts.inter(
                    fontSize: 13 * scale.clamp(0.85, 1.2),
                    color: AppColors.darkGrey,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '*Mandatory fields',
                  style: GoogleFonts.inter(
                    fontSize: 11 * scale.clamp(0.85, 1.2),
                    color: AppColors.neutralGrey,
                    fontStyle: FontStyle.italic,
                  ),
                ),

                SizedBox(height: size.height * 0.026),

                // ── Cover Picture ──
                _SectionLabel(label: 'Cover Picture*', scale: scale),
                const SizedBox(height: 8),
                _CoverPicturePicker(
                  imagePath: recipe.coverImagePath,
                  onTap: _pickImage,
                ),

                SizedBox(height: size.height * 0.022),

                // ── Recipe Name ──
                _SectionLabel(label: "Recipe's Name:*", scale: scale),
                const SizedBox(height: 8),
                _RecipeTextField(
                  controller: _nameCtrl,
                  hint: "Enter the recipe's name",
                  onChanged: notifier.setRecipeName,
                ),

                SizedBox(height: size.height * 0.018),

                // ── Description ──
                _SectionLabel(label: 'Description*', scale: scale),
                const SizedBox(height: 8),
                _RecipeTextField(
                  controller: _descCtrl,
                  hint: 'Brief description of the Recipe',
                  onChanged: notifier.setDescription,
                ),

                SizedBox(height: size.height * 0.018),

                // ── Time of Preparation ──
                _SectionLabel(label: 'Time of preparation*', scale: scale),
                const SizedBox(height: 8),
                _DropdownField(
                  value: recipe.timeOfPreparation,
                  hint: 'Choose an option',
                  options: _timeOptions,
                  onChanged: notifier.setTimeOfPreparation,
                  scale: scale,
                ),

                SizedBox(height: size.height * 0.018),

                // ── Servings ──
                _SectionLabel(label: 'Servings*', scale: scale),
                const SizedBox(height: 8),
                _DropdownField(
                  value: recipe.servings,
                  hint: 'Choose an option',
                  options: _servingOptions,
                  onChanged: notifier.setServings,
                  scale: scale,
                ),

                SizedBox(height: size.height * 0.018),

                // ── Type of Diet ──
                _SectionLabel(label: 'Type of Diet*', scale: scale),
                const SizedBox(height: 10),
                PreferenceChipWrap(
                  options: _dietOptions,
                  selected: recipe.selectedDietTypes,
                  onTap: notifier.toggleDietType,
                ),

                SizedBox(height: size.height * 0.018),

                // ── Free of Ingredients ──
                _SectionLabel(label: 'Free of Ingredients', scale: scale),
                const SizedBox(height: 10),
                PreferenceChipWrap(
                  options: _freeOptions,
                  selected: recipe.selectedFreeIngredients,
                  onTap: notifier.toggleFreeIngredient,
                ),

                SizedBox(height: size.height * 0.032),

                // ── Continue Button ──
                LuvcoButton(
                  label: 'Continue',
                  isDisabled: !recipe.isStep1Valid,
                  onTap: recipe.isStep1Valid
                      ? () => ref.read(newRecipeStepProvider.notifier).state = 2
                      : null,
                ),

                SizedBox(height: size.height * 0.04),
              ],
            ),
          ),
        ),

        // ── Bottom Nav ──
        const LuvcoBottomNavBar(),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// STEP 2 — Recipe's Preparation (Ingredients & Instructions)
// ═══════════════════════════════════════════════════════════════════
class _Step2Widget extends ConsumerStatefulWidget {
  const _Step2Widget({super.key});

  @override
  ConsumerState<_Step2Widget> createState() => _Step2WidgetState();
}

class _Step2WidgetState extends ConsumerState<_Step2Widget> {
  final _ingredientsCtrl = TextEditingController();
  final _instructionsCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final recipe = ref.read(newRecipeProvider);
    _ingredientsCtrl.text = recipe.ingredients;
    _instructionsCtrl.text = recipe.instructions;
  }

  @override
  void dispose() {
    _ingredientsCtrl.dispose();
    _instructionsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final scale = size.width / 390;
    final recipe = ref.watch(newRecipeProvider);
    final notifier = ref.read(newRecipeProvider.notifier);

    return Column(
      children: [
        // ── Header ──
        AuthHeader(
          title: 'New Recipe',
          showBackButton: true,
          onBackTap: () => ref.read(newRecipeStepProvider.notifier).state = 1,
        ),

        // ── Body ──
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
                // ── Step Progress ──
                const StepProgressBar(currentStep: 2),
                SizedBox(height: size.height * 0.028),

                // ── Title ──
                Text(
                  "Recipe's Preparation",
                  style: GoogleFonts.inter(
                    fontSize: 20 * scale.clamp(0.85, 1.2),
                    fontWeight: FontWeight.w700,
                    color: AppColors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod.',
                  style: GoogleFonts.inter(
                    fontSize: 13 * scale.clamp(0.85, 1.2),
                    color: AppColors.darkGrey,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '*Mandatory fields',
                  style: GoogleFonts.inter(
                    fontSize: 11 * scale.clamp(0.85, 1.2),
                    color: AppColors.neutralGrey,
                    fontStyle: FontStyle.italic,
                  ),
                ),

                SizedBox(height: size.height * 0.026),

                // ── Recipe's Ingredients ──
                _SectionLabel(label: "Recipe's Ingredients*", scale: scale),
                const SizedBox(height: 8),
                _MultilineTextField(
                  controller: _ingredientsCtrl,
                  hint: "Enter the Recipe's Ingredients",
                  minLines: 5,
                  onChanged: notifier.setIngredients,
                ),

                SizedBox(height: size.height * 0.018),

                // ── Recipe's Instructions ──
                _SectionLabel(label: "Recipe's Instructions*", scale: scale),
                const SizedBox(height: 8),
                _MultilineTextField(
                  controller: _instructionsCtrl,
                  hint: "Enter the Recipe's Ingredients",
                  minLines: 5,
                  onChanged: notifier.setInstructions,
                ),

                SizedBox(height: size.height * 0.032),

                // ── Continue Button ──
                LuvcoButton(
                  label: 'Continue',
                  isDisabled: !recipe.isStep2Valid,
                  onTap: recipe.isStep2Valid
                      ? () => ref.read(newRecipeStepProvider.notifier).state = 3
                      : null,
                ),

                SizedBox(height: size.height * 0.04),
              ],
            ),
          ),
        ),

        // ── Bottom Nav ──
        const LuvcoBottomNavBar(),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// STEP 3 — Look for Products
// ═══════════════════════════════════════════════════════════════════
class _Step3Widget extends ConsumerStatefulWidget {
  const _Step3Widget({super.key});

  @override
  ConsumerState<_Step3Widget> createState() => _Step3WidgetState();
}

class _Step3WidgetState extends ConsumerState<_Step3Widget> {
  final _searchCtrl = TextEditingController();
  bool _showResults = false;
  MockProduct? _selectedProduct;
  bool _showProductDetail = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final scale = size.width / 390;
    final recipe = ref.watch(newRecipeProvider);
    final notifier = ref.read(newRecipeProvider.notifier);
    final showIngredientSuccess = ref.watch(ingredientAddedSuccessProvider);
    final showRecipeSuccess = ref.watch(recipeCreatedSuccessProvider);

    return Stack(
      children: [
        Column(
          children: [
            // ── Header ──
            AuthHeader(
              title: 'New Recipe',
              showBackButton: true,
              onBackTap: () =>
                  ref.read(newRecipeStepProvider.notifier).state = 2,
            ),

            // ── Body ──
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
                    // ── Step Progress ──
                    const StepProgressBar(currentStep: 3),
                    SizedBox(height: size.height * 0.028),

                    // ── Title ──
                    Text(
                      'Look for Products',
                      style: GoogleFonts.inter(
                        fontSize: 20 * scale.clamp(0.85, 1.2),
                        fontWeight: FontWeight.w700,
                        color: AppColors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod.',
                      style: GoogleFonts.inter(
                        fontSize: 13 * scale.clamp(0.85, 1.2),
                        color: AppColors.darkGrey,
                        height: 1.4,
                      ),
                    ),

                    SizedBox(height: size.height * 0.022),

                    // ── Search Bar ──
                    _SearchBar(
                      controller: _searchCtrl,
                      scale: scale,
                      onChanged: (v) {
                        setState(() => _showResults = v.isNotEmpty);
                      },
                    ),

                    SizedBox(height: size.height * 0.022),

                    // ── Search Results ──
                    if (_showResults && !_showProductDetail)
                      Column(
                        children: mockProductSearchResults.map((p) {
                          return _ProductSearchResultItem(
                            product: p,
                            scale: scale,
                            onTap: () {
                              setState(() {
                                _selectedProduct = p;
                                _showProductDetail = true;
                                _showResults = false;
                              });
                            },
                          );
                        }).toList(),
                      ),

                    // ── Empty State (no search) ──
                    if (!_showResults &&
                        recipe.addedIngredients.isEmpty &&
                        !_showProductDetail)
                      _EmptyProductState(scale: scale),

                    // ── Added Ingredients list ──
                    if (recipe.addedIngredients.isNotEmpty) ...[
                      Text(
                        'Ingredients Added (${recipe.addedIngredients.length})',
                        style: GoogleFonts.inter(
                          fontSize: 14 * scale.clamp(0.85, 1.2),
                          fontWeight: FontWeight.w600,
                          color: AppColors.black,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...recipe.addedIngredients.map((ing) {
                        return _AddedIngredientRow(
                          ingredient: ing,
                          scale: scale,
                          onDelete: () => notifier.removeIngredient(ing.id),
                        );
                      }),
                      SizedBox(height: size.height * 0.022),
                    ],

                    // ── Create Recipe Button ──
                    LuvcoButton(
                      label: 'Create Recipe',
                      onTap: () async {
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (context) => const Center(
                            child: CircularProgressIndicator(
                              color: AppColors.royalPurple,
                            ),
                          ),
                        );

                        try {
                          await ref.read(newRecipeProvider.notifier).submitRecipe();
                          if (context.mounted) {
                            Navigator.of(context).pop(); // Pop loading dialog
                          }

                          // Show success
                          ref.read(recipeCreatedSuccessProvider.notifier).state = true;
                          Future.delayed(const Duration(seconds: 2), () {
                            if (!mounted) return;
                            ref.read(recipeCreatedSuccessProvider.notifier).state = false;
                            ref.read(newRecipeStepProvider.notifier).state = 1;
                            ref.read(newRecipeProvider.notifier).reset();
                            if (context.mounted) context.pop();
                          });
                        } catch (e) {
                          if (context.mounted) {
                            Navigator.of(context).pop(); // Pop loading dialog
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: $e')),
                            );
                          }
                        }
                      },
                    ),

                    const SizedBox(height: 8),


                    SizedBox(height: size.height * 0.04),
                  ],
                ),
              ),
            ),

            // ── Bottom Nav ──
            const LuvcoBottomNavBar(),
          ],
        ),

        // ── Product Detail Bottom Sheet ──
        if (_showProductDetail && _selectedProduct != null)
          _ProductDetailOverlay(
            product: _selectedProduct!,
            scale: scale,
            size: size,
            onClose: () => setState(() {
              _showProductDetail = false;
              _selectedProduct = null;
            }),
            onAddIngredient: () {
              notifier.addIngredient(
                AddedIngredient(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  name: _selectedProduct!.name,
                  otherData: _selectedProduct!.otherData,
                  imageUrl: _selectedProduct!.imageUrl,
                  isUnsustainable: _selectedProduct!.isUnsustainable,
                ),
              );
              setState(() {
                _showProductDetail = false;
                _selectedProduct = null;
                _searchCtrl.clear();
              });
              ref.read(ingredientAddedSuccessProvider.notifier).state = true;
              Future.delayed(const Duration(milliseconds: 1800), () {
                if (mounted) {
                  ref.read(ingredientAddedSuccessProvider.notifier).state =
                      false;
                }
              });
            },
          ),

        // ── Ingredient Added Success Dialog ──
        if (showIngredientSuccess)
          const _SuccessOverlay(
            message: 'Ingredient added\nsuccessfully to the recipe',
          ),

        // ── Recipe Created Success Dialog ──
        if (showRecipeSuccess)
          const _SuccessOverlay(message: 'Recipe created\nsuccessfully!'),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// ── SHARED WIDGETS ─────────────────────────────────────────────────
// ═══════════════════════════════════════════════════════════════════

// ── Section Label ──────────────────────────────────────────────────
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
        fontWeight: FontWeight.w500,
        color: AppColors.black,
      ),
    );
  }
}

// ── Cover Picture Picker ────────────────────────────────────────────
class _CoverPicturePicker extends StatelessWidget {
  final String? imagePath;
  final VoidCallback onTap;

  const _CoverPicturePicker({this.imagePath, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: size.height * 0.18,
        decoration: BoxDecoration(
          color: AppColors.pureWhite,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.inputBorder,
            width: 1.0,
            style: BorderStyle.solid,
          ),
        ),
        child: imagePath != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: imagePath!.startsWith('assets/')
                    ? Image.asset(imagePath!, fit: BoxFit.cover)
                    : Image.file(File(imagePath!), fit: BoxFit.cover),
              )
            : const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.image_outlined,
                    size: 40,
                    color: AppColors.clearGrey,
                  ),
                ],
              ),
      ),
    );
  }
}

// ── Simple Recipe TextField ─────────────────────────────────────────
class _RecipeTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;

  const _RecipeTextField({
    required this.controller,
    required this.hint,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final scale = size.width / 390;
    final fontSize = 14.0 * scale.clamp(0.85, 1.2);
    final height = (size.height * 0.062).clamp(48.0, 58.0);

    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: AppColors.inputBorder, width: 1.0),
    );
    final focusedBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: AppColors.royalPurple, width: 1.5),
    );

    return SizedBox(
      height: height,
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: GoogleFonts.inter(fontSize: fontSize, color: AppColors.black),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.inter(
            fontSize: fontSize,
            color: AppColors.neutralGrey,
          ),
          filled: true,
          fillColor: AppColors.pureWhite,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          border: border,
          enabledBorder: border,
          focusedBorder: focusedBorder,
        ),
      ),
    );
  }
}

// ── Dropdown Field ──────────────────────────────────────────────────
class _DropdownField extends StatelessWidget {
  final String? value;
  final String hint;
  final List<String> options;
  final ValueChanged<String> onChanged;
  final double scale;

  const _DropdownField({
    required this.value,
    required this.hint,
    required this.options,
    required this.onChanged,
    required this.scale,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final height = (size.height * 0.062).clamp(48.0, 58.0);
    final fontSize = 14.0 * scale.clamp(0.85, 1.2);

    return SizedBox(
      height: height,
      child: DropdownButtonFormField<String>(
        initialValue: value,
        hint: Text(
          hint,
          style: GoogleFonts.inter(
            fontSize: fontSize,
            color: AppColors.neutralGrey,
          ),
        ),
        icon: const Icon(
          Icons.keyboard_arrow_down_rounded,
          color: AppColors.neutralGrey,
        ),
        isExpanded: true,
        dropdownColor: AppColors.pureWhite,
        style: GoogleFonts.inter(fontSize: fontSize, color: AppColors.black),
        decoration: InputDecoration(
          filled: true,
          fillColor: AppColors.pureWhite,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(
              color: AppColors.inputBorder,
              width: 1.0,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(
              color: AppColors.inputBorder,
              width: 1.0,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(
              color: AppColors.royalPurple,
              width: 1.5,
            ),
          ),
        ),
        items: options.map((o) {
          return DropdownMenuItem<String>(value: o, child: Text(o));
        }).toList(),
        onChanged: (v) {
          if (v != null) onChanged(v);
        },
      ),
    );
  }
}

// ── Multiline TextField ─────────────────────────────────────────────
class _MultilineTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final int minLines;
  final ValueChanged<String> onChanged;

  const _MultilineTextField({
    required this.controller,
    required this.hint,
    required this.minLines,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.sizeOf(context).width / 390;
    final fontSize = 14.0 * scale.clamp(0.85, 1.2);

    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: AppColors.inputBorder, width: 1.0),
    );
    final focusedBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: AppColors.royalPurple, width: 1.5),
    );

    return TextField(
      controller: controller,
      onChanged: onChanged,
      minLines: minLines,
      maxLines: null,
      style: GoogleFonts.inter(fontSize: fontSize, color: AppColors.black),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(
          fontSize: fontSize,
          color: AppColors.neutralGrey,
        ),
        filled: true,
        fillColor: AppColors.pureWhite,
        contentPadding: const EdgeInsets.all(16),
        border: border,
        enabledBorder: border,
        focusedBorder: focusedBorder,
        suffixIconConstraints: const BoxConstraints(
          minWidth: 40,
          minHeight: 40,
        ),
        suffixIcon: const Padding(
          padding: EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.open_in_full_rounded,
                size: 14,
                color: AppColors.clearGrey,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Search Bar ──────────────────────────────────────────────────────
class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final double scale;
  final ValueChanged<String> onChanged;

  const _SearchBar({
    required this.controller,
    required this.scale,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final height = (size.height * 0.062).clamp(48.0, 58.0);
    final fontSize = 14.0 * scale.clamp(0.85, 1.2);

    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(50),
      borderSide: const BorderSide(color: AppColors.royalPurple, width: 1.5),
    );

    return SizedBox(
      height: height,
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: GoogleFonts.inter(fontSize: fontSize, color: AppColors.black),
        decoration: InputDecoration(
          hintText: 'Search for a Product',
          hintStyle: GoogleFonts.inter(
            fontSize: fontSize,
            color: AppColors.neutralGrey,
          ),
          prefixIcon: const Padding(
            padding: EdgeInsets.all(14),
            child: Icon(
              Icons.search_rounded,
              size: 20,
              color: AppColors.royalPurple,
            ),
          ),
          filled: true,
          fillColor: AppColors.pureWhite,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 14,
          ),
          border: border,
          enabledBorder: border,
          focusedBorder: border,
        ),
      ),
    );
  }
}

// ── Product Search Result Item ──────────────────────────────────────
class _ProductSearchResultItem extends StatelessWidget {
  final MockProduct product;
  final double scale;
  final VoidCallback onTap;

  const _ProductSearchResultItem({
    required this.product,
    required this.scale,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.pureWhite,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.softGrey,
                borderRadius: BorderRadius.circular(8),
              ),
              child: product.imageUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset(
                        product.imageUrl!,
                        fit: BoxFit.contain,
                      ),
                    )
                  : const Icon(
                      Icons.fastfood_outlined,
                      size: 18,
                      color: AppColors.neutralGrey,
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                product.name,
                style: GoogleFonts.inter(
                  fontSize: 14 * scale.clamp(0.85, 1.2),
                  fontWeight: FontWeight.w500,
                  color: AppColors.black,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Empty Product State ─────────────────────────────────────────────
class _EmptyProductState extends StatelessWidget {
  final double scale;

  const _EmptyProductState({required this.scale});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: SizedBox(
        width: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
          SizedBox(
            width: 140 * scale,
            height: 140 * scale,
            child: Image.asset(
              'assets/images/new_recipe.png',
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.menu_book_outlined,
                size: 64,
                color: AppColors.clearGrey,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Create the recipe and add\nitems later',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 17 * scale.clamp(0.85, 1.2),
              fontWeight: FontWeight.w700,
              color: AppColors.black,
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () {
              Navigator.of(context).pop();
            },
            child: Text(
              'Create And Add Items Later',
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
      ),
    );
  }
}

// ── Added Ingredient Row ────────────────────────────────────────────
class _AddedIngredientRow extends StatelessWidget {
  final AddedIngredient ingredient;
  final double scale;
  final VoidCallback onDelete;

  const _AddedIngredientRow({
    required this.ingredient,
    required this.scale,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Stack(
        children: [
          // Background Tabs
          SizedBox(
            height: 44,
            child: Row(
              children: [
                // Red tab (Unsustainable)
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.only(top: 8),
                    alignment: Alignment.topCenter,
                    decoration: const BoxDecoration(
                      color: Color(0xFFED3232),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(14),
                        topRight: Radius.circular(14),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.eco_outlined, size: 14, color: Colors.white),
                        const SizedBox(width: 6),
                        Text(
                          'Unsustainable',
                          style: GoogleFonts.inter(
                            fontSize: 12 * scale.clamp(0.85, 1.2),
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Green tab (Safe)
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.only(top: 8),
                    alignment: Alignment.topCenter,
                    decoration: const BoxDecoration(
                      color: Color(0xFF4CAF50),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(14),
                        topRight: Radius.circular(14),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.flag_outlined, size: 14, color: Colors.white),
                        const SizedBox(width: 6),
                        Text(
                          'Safe',
                          style: GoogleFonts.inter(
                            fontSize: 12 * scale.clamp(0.85, 1.2),
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
          // White Foreground Card
          Container(
            margin: const EdgeInsets.only(top: 32),
            decoration: BoxDecoration(
              color: AppColors.pureWhite,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.softGrey,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ingredient.imageUrl != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.asset(
                              ingredient.imageUrl!,
                              fit: BoxFit.contain,
                            ),
                          )
                        : const Icon(
                            Icons.fastfood_outlined,
                            size: 20,
                            color: AppColors.neutralGrey,
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ingredient.name,
                          style: GoogleFonts.inter(
                            fontSize: 13 * scale.clamp(0.85, 1.2),
                            fontWeight: FontWeight.w600,
                            color: AppColors.black,
                          ),
                        ),
                        Text(
                          ingredient.otherData,
                          style: GoogleFonts.inter(
                            fontSize: 11 * scale.clamp(0.85, 1.2),
                            color: AppColors.neutralGrey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: onDelete,
                    child: const Icon(
                      Icons.delete_outline_rounded,
                      size: 20,
                      color: AppColors.black,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Product Detail Overlay (bottom sheet style) ─────────────────────
class _ProductDetailOverlay extends StatelessWidget {
  final MockProduct product;
  final double scale;
  final Size size;
  final VoidCallback onClose;
  final VoidCallback onAddIngredient;

  const _ProductDetailOverlay({
    required this.product,
    required this.scale,
    required this.size,
    required this.onClose,
    required this.onAddIngredient,
  });

  static const _certifications = ['Bio', 'Organic', 'Vegan', 'Ecocert'];
  static const _allergens = ['Gluten', 'Nut', 'Milk', 'Egg'];

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: GestureDetector(
        onTap: onClose,
        child: Container(
          color: Colors.black.withValues(alpha: 0.35),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: GestureDetector(
              onTap: () {}, // prevent close when tapping sheet
              child: Container(
                width: double.infinity,
                constraints: BoxConstraints(maxHeight: size.height * 0.80),
                decoration: const BoxDecoration(
                  color: AppColors.pureWhite,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    size.width * 0.058,
                    20,
                    size.width * 0.058,
                    32,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Header (Title, Subtitle, Close) ──
                      SizedBox(
                        width: double.infinity,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 40),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    product.name,
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.inter(
                                      fontSize: 18 * scale.clamp(0.85, 1.2),
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.vibrantPink,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    product.otherData,
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.inter(
                                      fontSize: 13 * scale.clamp(0.85, 1.2),
                                      color: AppColors.darkGrey,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Positioned(
                              right: 0,
                              top: 0,
                              child: GestureDetector(
                                onTap: onClose,
                                child: const Icon(
                                  Icons.close_rounded,
                                  color: AppColors.black,
                                  size: 26,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ── Image Card with Sustainability Header ──
                      Stack(
                        children: [
                          // Background Tabs
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  height: 80 * scale.clamp(0.85, 1.2), // extends behind the white card
                                  padding: EdgeInsets.only(top: 14 * scale.clamp(0.85, 1.2)),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFED3232),
                                    borderRadius: BorderRadius.only(
                                      topLeft: Radius.circular(28),
                                      topRight: Radius.circular(16),
                                    ),
                                  ),
                                  alignment: Alignment.topCenter,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.eco_outlined, color: Colors.white, size: 20),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Unsustainable',
                                        style: GoogleFonts.inter(
                                          fontSize: 14 * scale.clamp(0.85, 1.2),
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
                                  height: 80 * scale.clamp(0.85, 1.2),
                                  padding: EdgeInsets.only(top: 14 * scale.clamp(0.85, 1.2)),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF4CAF50),
                                    borderRadius: BorderRadius.only(
                                      topLeft: Radius.circular(16),
                                      topRight: Radius.circular(28),
                                    ),
                                  ),
                                  alignment: Alignment.topCenter,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.flag_outlined, color: Colors.white, size: 20),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Safe',
                                        style: GoogleFonts.inter(
                                          fontSize: 14 * scale.clamp(0.85, 1.2),
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
                          // White Foreground Card
                          Container(
                            margin: EdgeInsets.only(top: 48 * scale.clamp(0.85, 1.2)), // visible tab height
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: AppColors.pureWhite,
                              borderRadius: BorderRadius.circular(28),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, -2), // subtle shadow to show it's above tabs
                                ),
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 15,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 24),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  SizedBox(
                                    height: 190 * scale.clamp(0.85, 1.2),
                                    width: double.infinity,
                                    child: product.imageUrl != null
                                        ? Image.asset(
                                            product.imageUrl!,
                                            fit: BoxFit.contain,
                                          )
                                        : const Icon(
                                            Icons.fastfood_outlined,
                                            size: 70,
                                            color: AppColors.clearGrey,
                                          ),
                                  ),
                                  const Positioned(
                                    top: -4,
                                    right: 20,
                                    child: Icon(
                                      Icons.favorite_border_rounded,
                                      color: AppColors.black,
                                      size: 28,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // ── Labels & Certifications ──
                      Text(
                        'Labels and Certifications',
                        style: GoogleFonts.inter(
                          fontSize: 14 * scale.clamp(0.85, 1.2),
                          fontWeight: FontWeight.w700,
                          color: AppColors.black,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: _certifications
                            .map((l) => _LabelCircle(label: l, scale: scale))
                            .toList(),
                      ),
                      const SizedBox(height: 16),

                      // ── Possible Allergens ──
                      Text(
                        'Possible allergens',
                        style: GoogleFonts.inter(
                          fontSize: 14 * scale.clamp(0.85, 1.2),
                          fontWeight: FontWeight.w700,
                          color: AppColors.black,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: _allergens
                            .map((l) => _LabelCircle(label: l, scale: scale))
                            .toList(),
                      ),
                      const SizedBox(height: 16),

                      // ── Ingredients List ──
                      Text(
                        'Ingredients list',
                        style: GoogleFonts.inter(
                          fontSize: 14 * scale.clamp(0.85, 1.2),
                          fontWeight: FontWeight.w600,
                          color: AppColors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Ingredient Name',
                        style: GoogleFonts.inter(
                          fontSize: 13 * scale.clamp(0.85, 1.2),
                          color: AppColors.black,
                        ),
                      ),
                      const Divider(color: AppColors.clearGrey, height: 24),
                      Text(
                        'Ingredient Name',
                        style: GoogleFonts.inter(
                          fontSize: 13 * scale.clamp(0.85, 1.2),
                          color: AppColors.black,
                        ),
                      ),
                      
                      const SizedBox(height: 32),

                      LuvcoButton(
                        label: '+ Add Ingredient',
                        onTap: onAddIngredient,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LabelCircle extends StatelessWidget {
  final String label;
  final double scale;

  const _LabelCircle({required this.label, required this.scale});

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

  static String _cleanLabel(String raw) {
    String cleaned = raw.replaceAll(RegExp(r'^[a-z]{2}:'), '');
    cleaned = cleaned.replaceAll(RegExp(r'[-_]'), ' ').trim();
    if (cleaned.isEmpty) return raw;
    return cleaned
        .split(' ')
        .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : w)
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final clean = _cleanLabel(label);
    final iconInfo = _getIconAndColor(clean);
    final iconData = iconInfo.$1;
    final iconColor = iconInfo.$2;

    return Container(
      width: 64 * scale.clamp(0.85, 1.2),
      height: 64 * scale.clamp(0.85, 1.2),
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.clearGrey, width: 1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            iconData,
            size: 20 * scale.clamp(0.85, 1.2),
            color: iconColor,
          ),
          const SizedBox(height: 2),
          Text(
            clean,
            style: GoogleFonts.inter(
              fontSize: 10 * scale.clamp(0.85, 1.2),
              color: AppColors.darkGrey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Success Overlay (checkmark dialog) ─────────────────────────────
class _SuccessOverlay extends StatelessWidget {
  final String message;

  const _SuccessOverlay({required this.message});

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.sizeOf(context).width / 390;

    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.25),
        child: Center(
          child: Container(
            width: 200 * scale.clamp(0.85, 1.2),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            decoration: BoxDecoration(
              color: AppColors.pureWhite,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF4CAF50),
                      width: 2.5,
                    ),
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Color(0xFF4CAF50),
                    size: 30,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 14 * scale.clamp(0.85, 1.2),
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
