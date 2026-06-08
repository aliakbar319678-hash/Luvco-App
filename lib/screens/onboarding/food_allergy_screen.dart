import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/onboarding_provider.dart';
import '../../widgets/luvco_button.dart';
import '../../widgets/onboarding_progress_bar.dart';
import '../../widgets/preference_chip.dart';

class FoodAllergyScreen extends ConsumerWidget {
  const FoodAllergyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final size = MediaQuery.sizeOf(context);
    final onboardingState = ref.watch(onboardingProvider);
    final onboardingOptionsAsync = ref.watch(onboardingOptionsProvider);
    final selectedAllergies = onboardingState.selectedAllergies;
    final manualAllergies = onboardingState.manualAllergies;
    final hasSelection =
        selectedAllergies.isNotEmpty || manualAllergies.isNotEmpty;
    final showManualInput = ref.watch(showManualInputProvider);
    final scale = size.width / 390;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: AppColors.pureWhite,
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: size.width * 0.058),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: size.height * 0.022),

                // ── Progress bar — step 3 of 3 ──
                const OnboardingProgressBar(totalSteps: 3, currentStep: 3),

                SizedBox(height: size.height * 0.042),

                // ── Heading ──
                Text(
                  'Select your food\nchallenge or allergies...',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 24 * scale.clamp(0.85, 1.3),
                    fontWeight: FontWeight.w700,
                    color: AppColors.black,
                    height: 1.25,
                  ),
                ),

                SizedBox(height: size.height * 0.010),

                // ── Subtitle ──
                Text(
                  'Select a food item or choose several.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 14 * scale.clamp(0.85, 1.3),
                    fontWeight: FontWeight.w400,
                    color: AppColors.darkGrey,
                  ),
                ),

                SizedBox(height: size.height * 0.028),

                // ── Scrollable content ──
                Expanded(
                  child: onboardingOptionsAsync.when(
                    loading: () => const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.royalPurple,
                      ),
                    ),
                    error: (err, stack) => Center(
                      child: Text(
                        'Failed to load options: $err',
                        style: GoogleFonts.inter(color: AppColors.errorRed),
                      ),
                    ),
                    data: (tags) {
                      final allergyOptions = tags['allergies'] ?? [];
                      return SingleChildScrollView(
                        physics: const ClampingScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ── Allergy chips ──
                            PreferenceChipWrap(
                              options: allergyOptions,
                              selected: selectedAllergies,
                              onTap: (a) => ref
                                  .read(onboardingProvider.notifier)
                                  .toggleAllergy(a),
                            ),

                            SizedBox(height: size.height * 0.020),

                            // ── "Add More Manually" trigger (only shown if input is hidden) ──
                            if (!showManualInput)
                              GestureDetector(
                                onTap: () =>
                                    ref
                                            .read(showManualInputProvider.notifier)
                                            .state =
                                        true,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 22,
                                      height: 22,
                                      decoration: const BoxDecoration(
                                        color: AppColors.black,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.add,
                                        color: Colors.white,
                                        size: 14,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Add More Manually',
                                      style: GoogleFonts.inter(
                                        fontSize: 14 * scale.clamp(0.85, 1.3),
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.darkGrey,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                            // ── Manual input section (shown after tap) ──
                            if (showManualInput) ...[
                              SizedBox(height: size.height * 0.016),

                              Row(
                                children: [
                                  Text(
                                    'Other',
                                    style: GoogleFonts.inter(
                                      fontSize: 13 * scale.clamp(0.85, 1.3),
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.black,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 8),

                              // ── Manual entry field ──
                              _ManualAllergyField(
                                scale: scale,
                                onAdd: (val) {
                                  ref
                                      .read(onboardingProvider.notifier)
                                      .addManualAllergy(val);
                                },
                              ),

                              // ── Already added manual allergies ──
                              ...manualAllergies.map(
                                (item) => _ManualAllergyTag(
                                  label: item,
                                  onRemove: () => ref
                                      .read(onboardingProvider.notifier)
                                      .removeManualAllergy(item),
                                ),
                              ),

                              SizedBox(height: size.height * 0.020),
                            ],

                            SizedBox(height: size.height * 0.020),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                SizedBox(height: size.height * 0.020),

                // ── Get Started button ──
                LuvcoButton(
                  label: 'Get Started!',
                  isDisabled: !hasSelection,
                  onTap: () async {
                    await ref
                        .read(onboardingProvider.notifier)
                        .submitPreferences();
                    if (context.mounted) {
                      context.go('/profile');
                    }
                  },
                ),

                SizedBox(height: size.height * 0.016),

                // ── Set Preferences Later ──
                GestureDetector(
                  onTap: () => context.go('/profile'),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'Set Preferences Later',
                      style: GoogleFonts.inter(
                        fontSize: 14 * scale.clamp(0.85, 1.3),
                        fontWeight: FontWeight.w500,
                        color: AppColors.royalPurple,
                        decoration: TextDecoration.underline,
                        decorationColor: AppColors.royalPurple,
                      ),
                    ),
                  ),
                ),

                SizedBox(height: size.height * 0.028),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Manual allergy text input field with Add button logic
// ─────────────────────────────────────────────────────────────────
class _ManualAllergyField extends StatefulWidget {
  final double scale;
  final Function(String) onAdd;

  const _ManualAllergyField({required this.scale, required this.onAdd});

  @override
  State<_ManualAllergyField> createState() => _ManualAllergyFieldState();
}

class _ManualAllergyFieldState extends State<_ManualAllergyField> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    if (_controller.text.trim().isNotEmpty) {
      widget.onAdd(_controller.text.trim());
      _controller.clear();
      FocusScope.of(context).unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.pureWhite,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.inputBorder),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  onSubmitted: (_) => _handleSubmit(),
                  style: GoogleFonts.inter(
                    fontSize: 14 * widget.scale.clamp(0.85, 1.3),
                    color: AppColors.black,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Food Allergy 01',
                    hintStyle: GoogleFonts.inter(
                      fontSize: 14 * widget.scale.clamp(0.85, 1.3),
                      color: AppColors.neutralGrey,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                ),
              ),
              // ── Clear / X button ──
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: _controller,
                builder: (context, value, child) {
                  if (value.text.isEmpty) return const SizedBox.shrink();
                  return GestureDetector(
                    onTap: () => _controller.clear(),
                    child: const Padding(
                      padding: EdgeInsets.only(right: 12),
                      child: Icon(
                        Icons.close,
                        size: 18,
                        color: AppColors.neutralGrey,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // ── The "Add More Manually" button below the field ──
        GestureDetector(
          onTap: _handleSubmit,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: const BoxDecoration(
                  color: AppColors.black,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.add, color: Colors.white, size: 14),
              ),
              const SizedBox(width: 8),
              Text(
                'Add More Manually',
                style: GoogleFonts.inter(
                  fontSize: 14 * widget.scale.clamp(0.85, 1.3),
                  fontWeight: FontWeight.w500,
                  color: AppColors.darkGrey,
                  decoration: TextDecoration.underline,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Manually added allergy tag row
// ─────────────────────────────────────────────────────────────────
class _ManualAllergyTag extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;
  const _ManualAllergyTag({required this.label, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.pureWhite,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.inputBorder),
        ),
        child: Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.black,
                  ),
                ),
              ),
            ),
            GestureDetector(
              onTap: onRemove,
              child: const Padding(
                padding: EdgeInsets.only(right: 12),
                child: Icon(
                  Icons.close,
                  size: 18,
                  color: AppColors.neutralGrey,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
