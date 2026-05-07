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

class DietPreferenceScreen extends ConsumerWidget {
  const DietPreferenceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final size = MediaQuery.sizeOf(context);
    final onboardingState = ref.watch(onboardingProvider);
    final selectedDiets = onboardingState.selectedDiets;
    final hasSelection = selectedDiets.isNotEmpty;
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

                // ── Progress bar — step 2 of 3 ──
                const OnboardingProgressBar(totalSteps: 3, currentStep: 2),

                SizedBox(height: size.height * 0.042),

                // ── Heading ──
                Text(
                  'Select your\ndiet preference...',
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
                  'Select a diet item or choose several.',
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
                  child: SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Diet chips ──
                        PreferenceChipWrap(
                          options: kDietOptions,
                          selected: selectedDiets,
                          onTap: (d) => ref
                              .read(onboardingProvider.notifier)
                              .toggleDiet(d),
                        ),

                        SizedBox(height: size.height * 0.020),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: size.height * 0.020),

                // ── Next button ──
                LuvcoButton(
                  label: 'Next',
                  isDisabled: !hasSelection,
                  onTap: () => context.push('/onboarding/allergy'),
                ),

                SizedBox(height: size.height * 0.016),

                // ── Set Preferences Later ──
                GestureDetector(
                  onTap: () => context.go('/home'),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'Set Preferences Later',
                      style: GoogleFonts.inter(
                        fontSize: 14 * scale.clamp(0.85, 1.3),
                        fontWeight: FontWeight.w500,
                        color: AppColors.darkGrey,
                        decoration: TextDecoration.underline,
                        decorationColor: AppColors.darkGrey,
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
