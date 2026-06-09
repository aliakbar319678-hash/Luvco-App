import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/app_colors.dart';
import '../../models/recipe_model.dart';
import '../../models/recipe_detail_model.dart';
import '../../providers/recipe_provider.dart';
import '../../providers/recipe_detail_provider.dart';
import '../../core/network/recipe_api_service.dart';

class EditRecipeScreen extends ConsumerStatefulWidget {
  final RecipeModel? recipe; // null = create new

  const EditRecipeScreen({super.key, this.recipe});

  @override
  ConsumerState<EditRecipeScreen> createState() => _EditRecipeScreenState();
}

class _EditRecipeScreenState extends ConsumerState<EditRecipeScreen> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _ingredientCtrl;
  late final TextEditingController _stepCtrl;
  late final TextEditingController _productNameCtrl;
  late final TextEditingController _productBarcodeCtrl;

  late int _timeOfPrep;
  late int _servings;
  late List<String> _selectedDietTags;
  late List<String> _selectedFreeOf;
  String? _coverImagePath;

  int _activeTab = 0; // 0=Details 1=Preparation 2=Products

  static const _dietOptions = [
    'Vegetarian',
    'Vegan',
    'Gluten Free',
    'Dairy-Free',
    'Keto',
    'Paleo',
  ];

  static const _freeOfOptions = [
    'Gluten',
    'Dairy',
    'Soy',
    'Nuts',
    'Eggs',
    'Shellfish',
  ];

  static const _prepTimes = [15, 30, 45, 60, 90, 120];
  static const _servingOptions = [1, 2, 3, 4, 5, 6, 8, 10];

  @override
  void initState() {
    super.initState();
    final r = widget.recipe;
    _nameCtrl = TextEditingController(text: r?.title ?? '');
    _descCtrl = TextEditingController(text: r?.description ?? '');
    _ingredientCtrl = TextEditingController();
    _stepCtrl = TextEditingController();
    _productNameCtrl = TextEditingController();
    _productBarcodeCtrl = TextEditingController();

    _timeOfPrep = r?.timeOfPreparation ?? 60;
    _servings = r?.servings ?? 2;
    _selectedDietTags = List.from(r?.dietTags ?? []);
    _selectedFreeOf = List.from(r?.freeOfIngredients ?? []);
    _coverImagePath = r?.imageUrl;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _ingredientCtrl.dispose();
    _stepCtrl.dispose();
    _productNameCtrl.dispose();
    _productBarcodeCtrl.dispose();
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

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _coverImagePath = image.path;
      });
    }
  }

  void _saveChanges() async {
    final r = widget.recipe;
    if (r == null) {
      // Create new is handled via the 3-step wizard NewRecipeScreen.
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: AppColors.royalPurple),
      ),
    );

    try {
      String? coverUrl = _coverImagePath;
      if (_coverImagePath != null &&
          !_coverImagePath!.startsWith('http') &&
          !_coverImagePath!.startsWith('assets/')) {
        final file = File(_coverImagePath!);
        if (file.existsSync()) {
          final name = _coverImagePath!.split('/').last;
          coverUrl = await RecipeApiService.instance.uploadRecipeCover(file, name);
        }
      }

      final payload = {
        'title': _nameCtrl.text.trim().isEmpty ? 'Cool Recipe' : _nameCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'prepTimeMinutes': _timeOfPrep,
        'servings': _servings,
        'dietTags': _selectedDietTags,
        'freeOfTags': _selectedFreeOf,
        'coverImageUrl': coverUrl,
      };

      await RecipeApiService.instance.editRecipe(r.id, payload);

      // Refresh My Recipes catalog
      ref.read(myRecipesProvider.notifier).loadRecipes();
      
      // Refresh details screen providers
      final detailModel = RecipeDetailModel(core: r);
      ref.read(recipeDetailProvider(detailModel).notifier).fetchDetails();

      if (mounted) {
        Navigator.of(context).pop(); // Pop loading dialog
        Navigator.of(context).pop(); // Pop edit screen
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Pop loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final padding = MediaQuery.paddingOf(context);
    final scale = size.width / 390;

    Widget bodyContent;
    if (_activeTab == 0) {
      bodyContent = _buildDetailsTab(scale, size);
    } else if (_activeTab == 1) {
      bodyContent = _buildPreparationTab(scale, size);
    } else {
      bodyContent = _buildProductsTab(scale, size);
    }

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

            // ── Tab Body Content ──
            Expanded(
              child: bodyContent,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsTab(double scale, Size size) {
    return SingleChildScrollView(
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
          _CoverPicturePicker(
            imagePath: _coverImagePath,
            onTap: _pickImage,
            scale: scale,
          ),
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
            onChanged: (v) => setState(() => _timeOfPrep = v ?? _timeOfPrep),
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
            onChanged: (v) => setState(() => _servings = v ?? _servings),
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
    );
  }

  Widget _buildPreparationTab(double scale, Size size) {
    if (widget.recipe == null) {
      return const Center(child: Text('Please save core details first.'));
    }

    final detail = ref.watch(recipeDetailProvider(RecipeDetailModel(core: widget.recipe!)));

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.symmetric(
        horizontal: size.width * 0.058,
        vertical: 20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Edit Preparation Steps & Ingredients:',
            style: GoogleFonts.inter(
              fontSize: 18 * scale.clamp(0.85, 1.2),
              fontWeight: FontWeight.w700,
              color: AppColors.black,
            ),
          ),
          const SizedBox(height: 20),

          // Ingredients section
          Text(
            'Ingredients',
            style: GoogleFonts.inter(
              fontSize: 15 * scale.clamp(0.85, 1.2),
              fontWeight: FontWeight.w700,
              color: AppColors.black,
            ),
          ),
          const SizedBox(height: 10),

          if (detail.ingredientsList.isEmpty)
            Text(
              'No ingredients added yet.',
              style: GoogleFonts.inter(color: AppColors.neutralGrey, fontSize: 13),
            )
          else
            ...detail.ingredientsList.map((ing) => Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '• ${ing.description}',
                          style: GoogleFonts.inter(fontSize: 14, color: AppColors.black),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () {
                          ref.read(recipeDetailProvider(detail).notifier).removeIngredient(ing.id);
                        },
                      )
                    ],
                  ),
                )),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _LuvcoInputField(
                  controller: _ingredientCtrl,
                  hint: 'Add an ingredient',
                  scale: scale,
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  final text = _ingredientCtrl.text.trim();
                  if (text.isNotEmpty) {
                    ref.read(recipeDetailProvider(detail).notifier).addIngredient(text);
                    _ingredientCtrl.clear();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.royalPurple,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Add', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),

          const SizedBox(height: 32),

          // Instructions Section
          Text(
            'Instructions Steps',
            style: GoogleFonts.inter(
              fontSize: 15 * scale.clamp(0.85, 1.2),
              fontWeight: FontWeight.w700,
              color: AppColors.black,
            ),
          ),
          const SizedBox(height: 10),

          if (detail.instructionsList.isEmpty)
            Text(
              'No steps added yet.',
              style: GoogleFonts.inter(color: AppColors.neutralGrey, fontSize: 13),
            )
          else
            ...detail.instructionsList.map((step) => Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${step.stepNumber}. ${step.text}',
                          style: GoogleFonts.inter(fontSize: 14, color: AppColors.black),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () {
                          ref.read(recipeDetailProvider(detail).notifier).removeInstructionStep(step.id);
                        },
                      )
                    ],
                  ),
                )),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _LuvcoInputField(
                  controller: _stepCtrl,
                  hint: 'Add a preparation step',
                  scale: scale,
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  final text = _stepCtrl.text.trim();
                  if (text.isNotEmpty) {
                    ref.read(recipeDetailProvider(detail).notifier).addInstructionStep(text);
                    _stepCtrl.clear();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.royalPurple,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Add', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildProductsTab(double scale, Size size) {
    if (widget.recipe == null) {
      return const Center(child: Text('Please save core details first.'));
    }

    final detail = ref.watch(recipeDetailProvider(RecipeDetailModel(core: widget.recipe!)));

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.symmetric(
        horizontal: size.width * 0.058,
        vertical: 20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Link Products to Recipe:',
            style: GoogleFonts.inter(
              fontSize: 18 * scale.clamp(0.85, 1.2),
              fontWeight: FontWeight.w700,
              color: AppColors.black,
            ),
          ),
          const SizedBox(height: 20),

          if (detail.products.isEmpty)
            Text(
              'No products linked yet.',
              style: GoogleFonts.inter(color: AppColors.neutralGrey, fontSize: 13),
            )
          else
            ...detail.products.map((p) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: SizedBox(
                          width: 50,
                          height: 50,
                          child: p.productImageUrl.isNotEmpty
                              ? (p.productImageUrl.startsWith('http')
                                  ? Image.network(p.productImageUrl, fit: BoxFit.cover)
                                  : Image.asset(p.productImageUrl, fit: BoxFit.cover))
                              : Container(color: AppColors.clearGrey),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p.productName,
                              style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.black),
                            ),
                            if (p.barcode != null)
                              Text(
                                'Barcode: ${p.barcode}',
                                style: GoogleFonts.inter(color: AppColors.neutralGrey, fontSize: 11),
                              ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () {
                          ref.read(recipeDetailProvider(detail).notifier).removeProduct(p.id);
                        },
                      )
                    ],
                  ),
                )),

          const SizedBox(height: 24),
          Text(
            'Quick-Link a custom product:',
            style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.black),
          ),
          const SizedBox(height: 10),
          _LuvcoInputField(
            controller: _productNameCtrl,
            hint: 'Product Name',
            scale: scale,
          ),
          const SizedBox(height: 10),
          _LuvcoInputField(
            controller: _productBarcodeCtrl,
            hint: 'Product Barcode (Optional)',
            scale: scale,
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                final name = _productNameCtrl.text.trim();
                final barcode = _productBarcodeCtrl.text.trim();
                if (name.isNotEmpty) {
                  ref.read(recipeDetailProvider(detail).notifier).addProduct({
                    'productName': name,
                    'barcode': barcode.isNotEmpty ? barcode : null,
                  });
                  _productNameCtrl.clear();
                  _productBarcodeCtrl.clear();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.royalPurple,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Link Product', style: TextStyle(color: Colors.white)),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

// ── Header with back arrow + "Edit Recipe" title + tab bar ──
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
                          color: isActive ? AppColors.royalPurple : Colors.transparent,
                          width: 2.5,
                        ),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        _tabs[i],
                        style: GoogleFonts.inter(
                          fontSize: 13 * scale.clamp(0.85, 1.2),
                          fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                          color: isActive ? AppColors.royalPurple : AppColors.neutralGrey,
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

// ── Cover picture picker placeholder ──
class _CoverPicturePicker extends StatelessWidget {
  final String? imagePath;
  final VoidCallback onTap;
  final double scale;

  const _CoverPicturePicker({
    this.imagePath,
    required this.onTap,
    required this.scale,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: AspectRatio(
          aspectRatio: 2.2,
          child: imagePath != null && imagePath!.isNotEmpty
              ? (imagePath!.startsWith('http')
                  ? Image.network(imagePath!, fit: BoxFit.cover)
                  : (imagePath!.startsWith('assets/')
                      ? Image.asset(imagePath!, fit: BoxFit.cover)
                      : Image.file(File(imagePath!), fit: BoxFit.cover)))
              : Image.asset(
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

// ── Small helpers ──
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
                color: isSelected ? AppColors.royalPurple : AppColors.inputBorder,
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
