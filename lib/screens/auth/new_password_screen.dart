import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:luvco_logo/core/theme/app_colors.dart';
import 'package:luvco_logo/providers/new_password_provider.dart';
import 'package:luvco_logo/widgets/luvco_button.dart';
import 'package:luvco_logo/widgets/auth_header.dart';

// Providers for typing detection
final newPasswordTypingProvider = StateProvider<bool>((ref) => false);
final newPasswordTypingTimerProvider = StateProvider<Timer?>((ref) => null);

final confirmPasswordTypingProvider = StateProvider<bool>((ref) => false);
final confirmPasswordTypingTimerProvider = StateProvider<Timer?>((ref) => null);

class NewPasswordScreen extends ConsumerStatefulWidget {
  final String email;
  final String code;

  const NewPasswordScreen({
    super.key,
    required this.email,
    required this.code,
  });

  @override
  ConsumerState<NewPasswordScreen> createState() => _NewPasswordScreenState();
}

class _NewPasswordScreenState extends ConsumerState<NewPasswordScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(newPasswordStateProvider.notifier).reset();
      ref.read(newPasswordProvider.notifier).state = '';
      ref.read(confirmPasswordProvider.notifier).state = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final state = ref.watch(newPasswordStateProvider);

    // ── Navigate to confirmation when success ──────────────────
    ref.listen<NewPasswordState>(newPasswordStateProvider, (_, next) {
      if (next.isSuccess && context.mounted) {
        context.go('/password-updated');
      }
    });

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: AppColors.pageBackground,
        body: Column(
          children: [
            // ── Header: white card + logo ──
            const AuthHeader(showLogo: true),

            // ── Scrollable content ──
            Expanded(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: size.width * 0.058),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: size.height * 0.038),

                    // ── Heading ──
                    Text(
                      'New Password',
                      style: GoogleFonts.inter(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: AppColors.black,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // ── Subtitle ──
                    Text(
                      'Assign new password for your account',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: AppColors.darkGrey,
                        height: 1.4,
                      ),
                    ),

                    SizedBox(height: size.height * 0.034),

                    // ── New Password field ──
                    _PasswordField(
                      label: 'New Password',
                      hint: 'Enter your new password',
                      visibilityProvider: newPasswordVisibleProvider,
                      typingProvider: newPasswordTypingProvider,
                      typingTimerProvider: newPasswordTypingTimerProvider,
                      onChanged: (v) =>
                          ref.read(newPasswordProvider.notifier).state = v,
                      hasError: state.hasError,
                    ),

                    // ── Hint text under New Password ──
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 13,
                          color: state.hasError
                              ? AppColors.errorRed
                              : AppColors.neutralGrey,
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            'Use 8 or more characters with a mix of letters,\nnumbers & symbols',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: state.hasError
                                  ? AppColors.errorRed
                                  : AppColors.neutralGrey,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: size.height * 0.024),

                    // ── Confirm Password field ──
                    _PasswordField(
                      label: 'Confirm Password',
                      hint: 'Enter your new password',
                      visibilityProvider: confirmPasswordVisibleProvider,
                      typingProvider: confirmPasswordTypingProvider,
                      typingTimerProvider: confirmPasswordTypingTimerProvider,
                      onChanged: (v) =>
                          ref.read(confirmPasswordProvider.notifier).state = v,
                      hasError: state.hasError,
                    ),

                    SizedBox(height: size.height * 0.036),

                    // ── Done button ──
                    LuvcoButton(
                      label: 'Done',
                      isLoading: state.isLoading,
                      onTap: () {
                        final newPw = ref.read(newPasswordProvider);
                        final confPw = ref.read(confirmPasswordProvider);
                        ref
                            .read(newPasswordStateProvider.notifier)
                            .submit(
                              email: widget.email,
                              code: widget.code,
                              newPassword: newPw,
                              confirmPassword: confPw,
                            );
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
}

// ─────────────────────────────────────────────────────────────────
// Reusable password field with show/hide toggle
// ─────────────────────────────────────────────────────────────────
class _PasswordField extends ConsumerWidget {
  final String label;
  final String hint;
  final StateProvider<bool> visibilityProvider;
  final StateProvider<bool> typingProvider;
  final StateProvider<Timer?> typingTimerProvider;
  final ValueChanged<String> onChanged;
  final bool hasError;

  const _PasswordField({
    required this.label,
    required this.hint,
    required this.visibilityProvider,
    required this.typingProvider,
    required this.typingTimerProvider,
    required this.onChanged,
    this.hasError = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final size = MediaQuery.sizeOf(context);
    final scale = size.width / 390;
    final fontSize = 14 * scale.clamp(0.85, 1.3);
    final fieldHeight = (size.height * 0.062).clamp(48.0, 60.0);

    final isVisible = ref.watch(visibilityProvider);

    final borderColor = hasError ? AppColors.errorRed : AppColors.inputBorder;
    final focusColor = hasError ? AppColors.errorRed : AppColors.royalPurple;

    final defaultBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: borderColor, width: 1.0),
    );
    final focusedBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: focusColor, width: 1.5),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: fontSize,
            fontWeight: FontWeight.w500,
            color: hasError ? AppColors.errorRed : AppColors.black,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: fieldHeight,
          child: TextField(
            onChanged: (v) {
              onChanged(v);
              ref.read(typingProvider.notifier).state = true;
              ref.read(typingTimerProvider.notifier).state?.cancel();
              ref.read(typingTimerProvider.notifier).state = Timer(const Duration(milliseconds: 800), () {
                ref.read(typingProvider.notifier).state = false;
              });
            },
            obscureText: !isVisible,
            keyboardType: TextInputType.visiblePassword,
            style: GoogleFonts.inter(
              fontSize: fontSize,
              color: AppColors.black,
              fontWeight: FontWeight.w400,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.inter(
                fontSize: fontSize,
                color: AppColors.neutralGrey,
                fontWeight: FontWeight.w400,
              ),
              filled: true,
              fillColor: AppColors.pureWhite,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              border: defaultBorder,
              enabledBorder: defaultBorder,
              focusedBorder: focusedBorder,
              suffixIcon: GestureDetector(
                onTap: () =>
                    ref.read(visibilityProvider.notifier).state = !isVisible,
                child: Icon(
                  isVisible
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: hasError
                      ? AppColors.errorRed
                      : (ref.watch(typingProvider) ? Colors.black : AppColors.neutralGrey),
                  size: 20,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
