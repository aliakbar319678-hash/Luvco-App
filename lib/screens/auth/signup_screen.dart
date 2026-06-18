import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:luvco_logo/core/theme/app_colors.dart';
import 'package:luvco_logo/core/theme/app_text_styles.dart';
import 'package:luvco_logo/models/signup_model.dart';
import 'package:luvco_logo/providers/signup_provider.dart';
import 'package:luvco_logo/widgets/luvco_button.dart';
import 'package:luvco_logo/widgets/luvco_text_field.dart';
import 'package:luvco_logo/widgets/auth_header.dart';
import 'package:luvco_logo/widgets/auth_error_row.dart';

// Provider to track if the password field is being typed
final signupPasswordTypingProvider = StateProvider<bool>((ref) => false);
// Provider to hold a debouncing timer for typing detection
final signupPasswordTypingTimerProvider = StateProvider<Timer?>((ref) => null);

class SignupScreen extends ConsumerWidget {
  const SignupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final size = MediaQuery.sizeOf(context);

    final signupState = ref.watch(signupProvider);
    final obscure = ref.watch(signupObscurePasswordProvider);
    final termsAccepted = ref.watch(signupTermsAcceptedProvider);
    final privacyAccepted = ref.watch(signupPrivacyAcceptedProvider);

    final isLoading = signupState.status == SignupStatus.loading;
    final passwordHasError = signupState.fieldHasError(
      SignupErrorField.password,
    );

    // ── Listen for success → show confirmation dialog (0.3.5) ──
    ref.listen<SignupState>(signupProvider, (previous, next) {
      if (next.isSuccess) {
        _showAccountConfirmationDialog(context, ref);
      }
    });

    bool fieldError(SignupErrorField field) => signupState.fieldHasError(field);

    void clearIfError() {
      if (signupState.hasError) ref.read(signupProvider.notifier).clearError();
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: AppColors.pageBackground,
        body: Column(
          children: [
            // ── Top nav bar ──
            const AuthHeader(
              title: 'Register Account',
              titleColor: AppColors.vibrantPink,
            ),

            // ── Scrollable form ──
            Expanded(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: size.width * 0.058),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: size.height * 0.032),

                    // ── Title ──
                    Text(
                      'Create New Account',
                      style: AppTextStyles.heading1(context),
                    ),
                    const SizedBox(height: 6),

                    // ── Subtitle ──
                    Text(
                      'Fill in the information to create an account',
                      style: AppTextStyles.subtitle(context),
                    ),
                    const SizedBox(height: 4),

                    Text(
                      '*Mandatory fields',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: AppColors.neutralGrey,
                      ),
                    ),

                    SizedBox(height: size.height * 0.028),

                    // ── First Name ──
                    LuvcoTextField(
                      label: 'First Name*',
                      hintText: 'Enter your first name',
                      hasError: fieldError(SignupErrorField.firstName),
                      onChanged: (v) {
                        ref.read(signupFirstNameProvider.notifier).state = v;
                        clearIfError();
                      },
                    ),
                    if (fieldError(SignupErrorField.firstName))
                      AuthErrorRow(message: signupState.errorMessage),

                    SizedBox(height: size.height * 0.020),

                    // ── Last Name ──
                    LuvcoTextField(
                      label: 'Last Name*',
                      hintText: 'Enter your last name',
                      hasError: fieldError(SignupErrorField.lastName),
                      onChanged: (v) {
                        ref.read(signupLastNameProvider.notifier).state = v;
                        clearIfError();
                      },
                    ),
                    if (fieldError(SignupErrorField.lastName))
                      AuthErrorRow(message: signupState.errorMessage),

                    SizedBox(height: size.height * 0.020),

                    // ── Email ──
                    LuvcoTextField(
                      label: 'Email*',
                      hintText: 'Enter your email',
                      keyboardType: TextInputType.emailAddress,
                      hasError: fieldError(SignupErrorField.email),
                      onChanged: (v) {
                        ref.read(signupEmailProvider.notifier).state = v;
                        clearIfError();
                      },
                    ),
                    if (fieldError(SignupErrorField.email))
                      AuthErrorRow(message: signupState.errorMessage),

                    SizedBox(height: size.height * 0.020),

                    // ── Password ──
                    LuvcoTextField(
                      label: 'Password*',
                      hintText: 'Enter your password',
                      obscureText: obscure,
                      keyboardType: TextInputType.visiblePassword,
                      hasError: passwordHasError,
                      onChanged: (v) {
                        ref.read(signupPasswordProvider.notifier).state = v;
                        clearIfError();
                        // Start typing detection
                        ref.read(signupPasswordTypingProvider.notifier).state =
                            true;
                        // Cancel previous timer if any
                        ref
                            .read(signupPasswordTypingTimerProvider.notifier)
                            .state
                            ?.cancel();
                        // Start new debounce timer (800ms)
                        ref
                            .read(signupPasswordTypingTimerProvider.notifier)
                            .state = Timer(
                          const Duration(milliseconds: 800),
                          () {
                            ref
                                    .read(signupPasswordTypingProvider.notifier)
                                    .state =
                                false;
                          },
                        );
                      },
                      suffixIcon: GestureDetector(
                        onTap: () =>
                            ref
                                    .read(
                                      signupObscurePasswordProvider.notifier,
                                    )
                                    .state =
                                !obscure,
                        child: Icon(
                          obscure
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: passwordHasError
                              ? AppColors.errorRed
                              : (ref.watch(signupPasswordTypingProvider)
                                    ? Colors.black
                                    : AppColors.neutralGrey),
                          size: 20,
                        ),
                      ),
                    ),

                    // ── Password hint row — turns red on error (Figma 0.3.3) ──
                    const SizedBox(height: 6),
                    _PasswordHintRow(isError: passwordHasError),

                    // ── Password error message (below hint, replaces hint on error) ──
                    if (passwordHasError)
                      AuthErrorRow(message: signupState.errorMessage),

                    SizedBox(height: size.height * 0.026),

                    // ── Terms checkbox ──
                    _CheckboxRow(
                      value: termsAccepted,
                      label: 'Accept Terms And Conditions',
                      onChanged: (v) =>
                          ref.read(signupTermsAcceptedProvider.notifier).state =
                              v ?? false,
                    ),

                    const SizedBox(height: 12),

                    // ── Privacy Policy checkbox ──
                    _CheckboxRow(
                      value: privacyAccepted,
                      label: 'Privacy Policy',
                      onChanged: (v) =>
                          ref
                                  .read(signupPrivacyAcceptedProvider.notifier)
                                  .state =
                              v ?? false,
                    ),

                    SizedBox(height: size.height * 0.036),

                    // ── Create Account button ──
                    LuvcoButton(
                      label: 'Create Account',
                      isLoading: isLoading,
                      onTap: () {
                        final model = SignupModel(
                          firstName: ref.read(signupFirstNameProvider),
                          lastName: ref.read(signupLastNameProvider),
                          email: ref.read(signupEmailProvider),
                          password: ref.read(signupPasswordProvider),
                        );
                        ref.read(signupProvider.notifier).signup(model);
                      },
                    ),

                    SizedBox(height: size.height * 0.04),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Shows 0.3.5 confirmation dialog ──────────────────────────────
  void _showAccountConfirmationDialog(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (_) => _AccountConfirmationDialog(
        onVerify: () {
          Navigator.of(context).pop(); // close dialog
          ref.read(signupProvider.notifier).reset();
          // Navigate to OTP verification, passing the registered email
          final email = ref.read(signupEmailProvider);
          context.push('/signup-verify?email=${Uri.encodeComponent(email)}');
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Password hint row — grey normally, red when password has error
// Matches Figma 0.3.3: red info icon + red text
// ─────────────────────────────────────────────────────────────────
class _PasswordHintRow extends StatelessWidget {
  final bool isError;

  const _PasswordHintRow({required this.isError});

  @override
  Widget build(BuildContext context) {
    final color = isError ? AppColors.errorRed : AppColors.neutralGrey;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.info_outline_rounded, size: 14, color: color),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            'Use 8 or more characters with a mix of letters, '
            'numbers & symbols',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Checkbox row — square checkbox + label text
// ─────────────────────────────────────────────────────────────────
class _CheckboxRow extends StatelessWidget {
  final bool value;
  final String label;
  final ValueChanged<bool?> onChanged;

  const _CheckboxRow({
    required this.value,
    required this.label,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 20,
          height: 20,
          child: Checkbox(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.royalPurple,
            side: const BorderSide(color: AppColors.inputBorder, width: 1.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
          ),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: () => onChanged(!value),
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: AppColors.darkGrey,
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Account Confirmation Dialog — Figma 0.3.5
// Green checkmark + success message + Verify My Account button
// ─────────────────────────────────────────────────────────────────
class _AccountConfirmationDialog extends StatelessWidget {
  final VoidCallback onVerify;

  const _AccountConfirmationDialog({required this.onVerify});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 52),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.pureWhite,
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Green checkmark circle ──
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF4CAF50), // success green
                  width: 3.5,
                ),
              ),
              child: const Icon(
                Icons.check_rounded,
                color: Color(0xFF4CAF50),
                size: 42,
              ),
            ),

            const SizedBox(height: 20),

            // ── Title ──
            Text(
              'Your account has been\ncreated successfully!',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.black,
                height: 1.35,
              ),
            ),

            const SizedBox(height: 8),

            // ── Subtitle ──
            Text(
              'We have send you a confirmation\ncode to your email',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: AppColors.darkGrey,
                height: 1.4,
              ),
            ),

            const SizedBox(height: 20),

            // ── Verify My Account button ──
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onVerify,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.royalPurple,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50),
                  ),
                ),
                child: Text(
                  'Verify My Account',
                  style: GoogleFonts.inter(
                    fontSize: 14,
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
