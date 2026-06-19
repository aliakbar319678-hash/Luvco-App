import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';

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
  late final TextEditingController _ingredientsTextCtrl;
  late final TextEditingController _instructionsTextCtrl;

  late int _timeOfPrep;
  late int _servings;
  late List<String> _selectedDietTags;
  late List<String> _selectedFreeOf;
  String? _coverImagePath;

  int _activeTab = 0; // 0=Details 1=Preparation 2=Products
  bool _prepInitialized = false;

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
    _ingredientsTextCtrl = TextEditingController();
    _instructionsTextCtrl = TextEditingController();

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
    _ingredientsTextCtrl.dispose();
    _instructionsTextCtrl.dispose();
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
    if (r == null) return;

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

      ref.read(myRecipesProvider.notifier).loadRecipes();
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

  Future<void> _savePreparation() async {
    final r = widget.recipe;
    if (r == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: AppColors.royalPurple),
      ),
    );

    try {
      final detailModel = RecipeDetailModel(core: r);
      final detail = ref.read(recipeDetailProvider(detailModel));

      // 1. Delete all existing ingredients
      for (final ing in detail.ingredientsList) {
        await RecipeApiService.instance.removeIngredient(r.id, ing.id);
      }

      // 2. Parse and add new ingredients
      final ingLines = _ingredientsTextCtrl.text.split('\n');
      int ingPos = 1;
      for (final line in ingLines) {
        final trimmed = line.replaceAll(RegExp(r'^[•\-\*\s]+'), '').trim();
        if (trimmed.isNotEmpty) {
          await RecipeApiService.instance.addIngredient(r.id, trimmed, ingPos++);
        }
      }

      // 3. Delete all existing instructions
      for (final inst in detail.instructionsList) {
        await RecipeApiService.instance.removeInstructionStep(r.id, inst.id);
      }

      // 4. Parse and add new instructions
      final instLines = _instructionsTextCtrl.text.split('\n');
      int instPos = 1;
      for (final line in instLines) {
        final trimmed = line.replaceAll(RegExp(r'^\d+[\.\s\-]+'), '').trim();
        if (trimmed.isNotEmpty) {
          await RecipeApiService.instance.addInstructionStep(r.id, trimmed, instPos++);
        }
      }

      // Refresh details
      ref.read(recipeDetailProvider(detailModel).notifier).fetchDetails();

      if (mounted) {
        Navigator.of(context).pop(); // Pop loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Preparation updated successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Pop loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating preparation: $e')),
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
        backgroundColor: AppColors.pageBackground,
        body: Column(
          children: [
            // ── Top Title Bar ──
            _EditRecipeHeader(
              padding: padding,
              scale: scale,
              size: size,
            ),
            const SizedBox(height: 12),

            // ── Tab Bar & Content wrapped in a separate floating card ──
            Expanded(
              child: Container(
                margin: EdgeInsets.fromLTRB(16 * scale, 0, 16 * scale, 16 * scale),
                decoration: BoxDecoration(
                  color: AppColors.pureWhite,
                  borderRadius: BorderRadius.circular(32 * scale),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    _EditRecipeTabBar(
                      activeTab: _activeTab,
                      scale: scale,
                      onChanged: (t) => setState(() => _activeTab = t),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: bodyContent,
                    ),
                  ],
                ),
              ),
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

          _SectionLabel(label: 'Cover Picture*', scale: scale),
          const SizedBox(height: 8),
          _CoverPicturePicker(
            imagePath: _coverImagePath,
            onTap: _pickImage,
            scale: scale,
          ),
          const SizedBox(height: 20),

          _SectionLabel(label: "Recipe's Name*", scale: scale),
          const SizedBox(height: 8),
          _LuvcoInputField(
            controller: _nameCtrl,
            hint: 'Cool Recipe',
            scale: scale,
          ),
          const SizedBox(height: 16),

          _SectionLabel(label: 'Description*', scale: scale),
          const SizedBox(height: 8),
          _LuvcoInputField(
            controller: _descCtrl,
            hint: 'Gluten-Free Cool Recipe',
            scale: scale,
          ),
          const SizedBox(height: 16),

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

          _SectionLabel(label: 'Type of Diet*', scale: scale),
          const SizedBox(height: 10),
          _ChipGroup(
            options: _dietOptions,
            selected: _selectedDietTags,
            onToggle: _toggleDiet,
            scale: scale,
          ),
          const SizedBox(height: 16),

          _SectionLabel(label: 'Free of Ingredients', scale: scale),
          const SizedBox(height: 10),
          _ChipGroup(
            options: _freeOfOptions,
            selected: _selectedFreeOf,
            onToggle: _toggleFreeOf,
            scale: scale,
          ),

          const SizedBox(height: 32),

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

    if (!_prepInitialized && (detail.ingredientsList.isNotEmpty || detail.instructionsList.isNotEmpty)) {
      final ingText = detail.ingredientsList.map((e) => e.description).join('\n');
      _ingredientsTextCtrl.text = ingText;

      int stepNum = 1;
      final instText = detail.instructionsList.map((e) => '${stepNum++}. ${e.text}').join('\n');
      _instructionsTextCtrl.text = instText;

      _prepInitialized = true;
    }

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
            'Edit the details of the preparation:',
            style: GoogleFonts.inter(
              fontSize: 18 * scale.clamp(0.85, 1.2),
              fontWeight: FontWeight.w700,
              color: AppColors.black,
            ),
          ),
          _RequiredNote(scale: scale),
          const SizedBox(height: 20),

          _SectionLabel(label: "Recipe's Ingredients*", scale: scale),
          const SizedBox(height: 8),
          TextFormField(
            controller: _ingredientsTextCtrl,
            maxLines: 8,
            style: GoogleFonts.inter(
              fontSize: 14 * scale.clamp(0.85, 1.2),
              color: AppColors.black,
            ),
            decoration: InputDecoration(
              hintText: 'Enter ingredients (one per line)',
              hintStyle: GoogleFonts.inter(
                fontSize: 14 * scale.clamp(0.85, 1.2),
                color: AppColors.neutralGrey,
              ),
              contentPadding: const EdgeInsets.all(14),
              filled: true,
              fillColor: AppColors.pureWhite,
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
          ),
          const SizedBox(height: 20),

          _SectionLabel(label: "Recipe's Instructions*", scale: scale),
          const SizedBox(height: 8),
          TextFormField(
            controller: _instructionsTextCtrl,
            maxLines: 12,
            style: GoogleFonts.inter(
              fontSize: 14 * scale.clamp(0.85, 1.2),
              color: AppColors.black,
            ),
            decoration: InputDecoration(
              hintText: 'Enter instructions (one per line)',
              hintStyle: GoogleFonts.inter(
                fontSize: 14 * scale.clamp(0.85, 1.2),
                color: AppColors.neutralGrey,
              ),
              contentPadding: const EdgeInsets.all(14),
              filled: true,
              fillColor: AppColors.pureWhite,
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
          ),
          const SizedBox(height: 32),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _savePreparation,
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
            'Edit the products attached to the recipe:',
            style: GoogleFonts.inter(
              fontSize: 18 * scale.clamp(0.85, 1.2),
              fontWeight: FontWeight.w700,
              color: AppColors.black,
            ),
          ),
          _RequiredNote(scale: scale),
          const SizedBox(height: 20),

          // Add Products button matching details design
          _AddProductsButton(scale: scale),
          const SizedBox(height: 20),

          if (detail.products.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'No products linked yet.',
                  style: GoogleFonts.inter(color: AppColors.neutralGrey, fontSize: 13),
                ),
              ),
            )
          else
            ...detail.products.map(
              (p) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _ProductCard(
                  product: p,
                  scale: scale,
                  isOwner: detail.isOwner,
                  onDelete: () {
                    ref.read(recipeDetailProvider(detail).notifier).removeProduct(p.id);
                  },
                ),
              ),
            ),

          const SizedBox(height: 32),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(), // Pop edit screen
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
}

// ── Header — back arrow + "Edit Recipe" title ──
class _EditRecipeHeader extends StatelessWidget {
  final EdgeInsets padding;
  final double scale;
  final Size size;

  const _EditRecipeHeader({
    required this.padding,
    required this.scale,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: EdgeInsets.only(
        top: padding.top + 8,
        bottom: 24 * scale,
        left: 8,
        right: 8,
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: AppColors.vibrantPink,
              size: 20,
            ),
          ),
          Expanded(
            child: Text(
              'Edit Recipe',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 18 * scale.clamp(0.85, 1.2),
                fontWeight: FontWeight.w700,
                color: AppColors.vibrantPink,
              ),
            ),
          ),
          const SizedBox(width: 48), // Spacer to balance back button
        ],
      ),
    );
  }
}

// ── Tab Bar — pill style ──
class _EditRecipeTabBar extends StatelessWidget {
  final int activeTab;
  final double scale;
  final ValueChanged<int> onChanged;

  const _EditRecipeTabBar({
    required this.activeTab,
    required this.scale,
    required this.onChanged,
  });

  static const _tabs = ['Details', 'Preparation', 'Products'];

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16 * scale),
      height: 42,
      decoration: BoxDecoration(
        color: const Color(0xFFF0EBF9),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: List.generate(_tabs.length, (i) {
          final isActive = i == activeTab;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: isActive ? AppColors.royalPurple : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Text(
                    _tabs[i],
                    style: GoogleFonts.inter(
                      fontSize: 12 * scale.clamp(0.85, 1.2),
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                      color: isActive
                          ? AppColors.pureWhite
                          : AppColors.neutralGrey,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ── Add Products Button ──
class _AddProductsButton extends StatelessWidget {
  final double scale;
  const _AddProductsButton({required this.scale});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton.icon(
        onPressed: () => context.push('/dashboard-search'),
        icon: Icon(
          Icons.add,
          size: 18 * scale.clamp(0.85, 1.2),
          color: AppColors.royalPurple,
        ),
        label: Text(
          'Add Products',
          style: GoogleFonts.inter(
            fontSize: 14 * scale.clamp(0.85, 1.2),
            fontWeight: FontWeight.w600,
            color: AppColors.royalPurple,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.royalPurple, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          backgroundColor: Colors.transparent,
        ),
      ),
    );
  }
}

// ── Product Card — uses same design as Recipe Detail screen ──
class _ProductCard extends StatelessWidget {
  final RecipeProduct product;
  final double scale;
  final bool isOwner;
  final VoidCallback? onDelete;

  const _ProductCard({
    required this.product,
    required this.scale,
    required this.isOwner,
    this.onDelete,
  });

  Color get _sustainabilityColor {
    switch (product.sustainabilityLevel) {
      case 'Unsustainable':
        return const Color(0xFFEF4444);
      case 'Moderate Impact':
        return const Color(0xFFF59E0B);
      case 'Eco-Friendly':
        return const Color(0xFF22C55E);
      default:
        return AppColors.neutralGrey;
    }
  }

  Color get _safetyColor {
    switch (product.safetyLevel) {
      case 'Avoid':
        return const Color(0xFFF59E0B);
      case 'Safe':
        return const Color(0xFF22C55E);
      default:
        return AppColors.neutralGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 20 * scale),
      child: Stack(
        children: [
          // ── Background Tabs ──
          SizedBox(
            height: 48 * scale,
            width: double.infinity,
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: _sustainabilityColor,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(16 * scale),
                        topRight: Radius.circular(16 * scale),
                      ),
                    ),
                    padding: EdgeInsets.only(top: 8 * scale),
                    alignment: Alignment.topCenter,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.eco_outlined,
                          size: 16,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          product.sustainabilityLevel,
                          style: GoogleFonts.inter(
                            fontSize: 13 * scale.clamp(0.85, 1.2),
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
                    decoration: BoxDecoration(
                      color: _safetyColor,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(16 * scale),
                        topRight: Radius.circular(16 * scale),
                      ),
                    ),
                    padding: EdgeInsets.only(top: 8 * scale),
                    alignment: Alignment.topCenter,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.flag_outlined,
                          size: 16,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          product.safetyLevel,
                          style: GoogleFonts.inter(
                            fontSize: 13 * scale.clamp(0.85, 1.2),
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

          // ── Product Info Area (White Foreground Card) ──
          Container(
            margin: EdgeInsets.only(top: 32 * scale),
            decoration: BoxDecoration(
              color: AppColors.pureWhite,
              borderRadius: BorderRadius.circular(24 * scale),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 15,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: EdgeInsets.symmetric(
              vertical: 20 * scale,
              horizontal: 16 * scale,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 64 * scale,
                  height: 64 * scale,
                  child: product.imageAsset != null
                      ? (product.imageAsset!.startsWith('assets/')
                          ? Image.asset(product.imageAsset!, fit: BoxFit.contain)
                          : Image.network(
                              product.imageAsset!,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => Icon(
                                Icons.image_outlined,
                                size: 32 * scale,
                                color: AppColors.clearGrey,
                              ),
                            ))
                      : Icon(
                          Icons.image_outlined,
                          size: 32 * scale,
                          color: AppColors.clearGrey,
                        ),
                ),
                SizedBox(width: 16 * scale),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: GoogleFonts.inter(
                          fontSize: 14 * scale.clamp(0.85, 1.2),
                          fontWeight: FontWeight.w700,
                          color: AppColors.black,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        product.otherData,
                        style: GoogleFonts.inter(
                          fontSize: 13 * scale.clamp(0.85, 1.2),
                          color: AppColors.darkGrey,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (isOwner && onDelete != null) ...[
                  SizedBox(width: 12 * scale),
                  GestureDetector(
                    onTap: onDelete,
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Icon(
                        Icons.delete_outline_rounded,
                        size: 24 * scale.clamp(0.85, 1.2),
                        color: AppColors.black,
                      ),
                    ),
                  ),
                ],
              ],
            ),
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
        fillColor: AppColors.pureWhite,
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
        color: AppColors.pureWhite,
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
