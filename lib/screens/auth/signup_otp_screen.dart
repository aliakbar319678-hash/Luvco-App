import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:luvco_logo/core/theme/app_colors.dart';
import 'package:luvco_logo/core/theme/app_text_styles.dart';
import 'package:luvco_logo/providers/signup_otp_provider.dart';
import 'package:luvco_logo/widgets/lucu_logo.dart';

class SignupOtpScreen extends ConsumerStatefulWidget {
  /// Email address shown in the subtitle
  final String email;

  const SignupOtpScreen({super.key, required this.email});

  @override
  ConsumerState<SignupOtpScreen> createState() => _SignupOtpScreenState();
}

class _SignupOtpScreenState extends ConsumerState<SignupOtpScreen> {
  // One controller + focus node per digit slot
  final List<TextEditingController> _controllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  // Resend cooldown timer
  Timer? _timer;
  int _cooldown = 20;

  @override
  void initState() {
    super.initState();
    _startCooldown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _controllers) c.dispose();
    for (final f in _focusNodes) f.dispose();
    super.dispose();
  }

  // ── Helpers ───────────────────────────────────────────────────
  String get _fullCode => _controllers.map((c) => c.text).join();
  bool get _isComplete => _fullCode.length == 6;

  void _startCooldown() {
    _cooldown = 20;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        if (_cooldown > 0) {
          _cooldown--;
        } else {
          t.cancel();
        }
      });
    });
  }

  void _clearAll() {
    for (final c in _controllers) c.clear();
    ref.read(signupOtpProvider.notifier).reset();
    _focusNodes[0].requestFocus();
  }

  void _onDigitChanged(int index, String value) {
    // Clear error as soon as user edits any box
    if (ref.read(signupOtpProvider).hasError) {
      ref.read(signupOtpProvider.notifier).reset();
    }

    if (value.length == 1) {
      // Move forward
      if (index < 5) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
      }
    } else if (value.isEmpty && index > 0) {
      // Backspace — move back
      _focusNodes[index - 1].requestFocus();
    }

    setState(() {}); // refresh button state
  }

  void _onSubmit() {
    if (!_isComplete) return;
    ref.read(signupOtpProvider.notifier).verifyCode(_fullCode);
  }

  // ── Build ─────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final padding = MediaQuery.paddingOf(context);
    final state = ref.watch(signupOtpProvider);

    // Navigate to login (or home) on success
    ref.listen<SignupOtpState>(signupOtpProvider, (_, next) {
      if (next.isSuccess && context.mounted) {
        // After signup OTP success → go to login
        context.go('/login');
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
            // ── White header with Luvco logo ──
            _OtpHeader(size: size, padding: padding),

            // ── Scrollable content ──
            Expanded(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: size.width * 0.058),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: size.height * 0.038),

                    // ── Title ──
                    Text(
                      'Verify Your Account',
                      style: AppTextStyles.heading1(context),
                    ),
                    const SizedBox(height: 8),

                    // ── Subtitle with email ──
                    RichText(
                      text: TextSpan(
                        style: AppTextStyles.subtitle(context),
                        children: [
                          const TextSpan(
                            text: "Enter the code we've sent  to\n",
                          ),
                          TextSpan(
                            text: widget.email,
                            style: AppTextStyles.subtitle(context).copyWith(
                              color: AppColors.black,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: size.height * 0.038),

                    // ── 6-digit OTP boxes ──
                    _OtpBoxRow(
                      controllers: _controllers,
                      focusNodes: _focusNodes,
                      hasError: state.hasError,
                      onChanged: _onDigitChanged,
                    ),

                    const SizedBox(height: 10),

                    // ── Error message OR "email arriving" hint ──
                    if (state.hasError)
                      _ErrorHint(message: state.errorMessage)
                    else
                      _ArrivalHint(cooldown: _cooldown),

                    SizedBox(height: size.height * 0.028),

                    // ── "Didn't receive code?" row ──
                    _ResendRow(
                      canResend: _cooldown == 0,
                      onResend: () {
                        _clearAll();
                        _startCooldown();
                        // TODO: call resend API
                      },
                    ),

                    SizedBox(height: size.height * 0.036),

                    // ── Continue button — two visual states ──
                    _ContinueButton(
                      isComplete: _isComplete && !state.hasError,
                      isLoading: state.isLoading,
                      onTap: _onSubmit,
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
// White header — Luvco logo centered (matches login/splash style)
// ─────────────────────────────────────────────────────────────────
class _OtpHeader extends StatelessWidget {
  final Size size;
  final EdgeInsets padding;

  const _OtpHeader({required this.size, required this.padding});

  @override
  Widget build(BuildContext context) {
    final headerHeight = size.height * 0.14;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: padding.top),
          SizedBox(
            height: headerHeight,
            child: Center(
              child: LuvcoLogo(
                width: size.width * 0.38,
                color: LuvcoLogoColor.pink,
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Row of 6 OTP input boxes
// ─────────────────────────────────────────────────────────────────
class _OtpBoxRow extends StatelessWidget {
  final List<TextEditingController> controllers;
  final List<FocusNode> focusNodes;
  final bool hasError;
  final void Function(int index, String value) onChanged;

  const _OtpBoxRow({
    required this.controllers,
    required this.focusNodes,
    required this.hasError,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final boxSize = (MediaQuery.sizeOf(context).width - 48) / 6 - 6;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(6, (i) {
        return _OtpBox(
          controller: controllers[i],
          focusNode: focusNodes[i],
          hasError: hasError,
          size: boxSize.clamp(42.0, 52.0),
          onChanged: (v) => onChanged(i, v),
        );
      }),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Single OTP box — square, rounded, error-aware
// ─────────────────────────────────────────────────────────────────
class _OtpBox extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool hasError;
  final double size;
  final ValueChanged<String> onChanged;

  const _OtpBox({
    required this.controller,
    required this.focusNode,
    required this.hasError,
    required this.size,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = hasError ? AppColors.errorRed : AppColors.inputBorder;
    final focusedColor = hasError ? AppColors.errorRed : AppColors.royalPurple;
    final isEmpty = controller.text.isEmpty;

    return SizedBox(
      width: size,
      height: size,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        onChanged: onChanged,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: hasError ? AppColors.errorRed : AppColors.black,
        ),
        decoration: InputDecoration(
          counterText: '',
          hintText: isEmpty ? '-' : '',
          hintStyle: GoogleFonts.inter(
            fontSize: 18,
            color: AppColors.clearGrey,
            fontWeight: FontWeight.w400,
          ),
          filled: true,
          fillColor: AppColors.pureWhite,
          contentPadding: EdgeInsets.zero,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: borderColor, width: 1.2),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: borderColor, width: 1.2),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: focusedColor, width: 1.8),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// "Wrong code, try again" — shown on error state (0.3.7)
// ─────────────────────────────────────────────────────────────────
class _ErrorHint extends StatelessWidget {
  final String? message;

  const _ErrorHint({this.message});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(
          Icons.error_outline_rounded,
          color: AppColors.errorRed,
          size: 14,
        ),
        const SizedBox(width: 5),
        Text(
          message ?? 'Wrong code, try again',
          style: GoogleFonts.inter(
            fontSize: 13,
            color: AppColors.errorRed,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// "The email should arrive within Xs" — shown on idle/filled (0.3.6 & 0.3.8)
// ─────────────────────────────────────────────────────────────────
class _ArrivalHint extends StatelessWidget {
  final int cooldown;

  const _ArrivalHint({required this.cooldown});

  @override
  Widget build(BuildContext context) {
    final text = cooldown > 0
        ? 'The email should arrive within ${cooldown}s'
        : 'You can resend the code now';

    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 13,
        color: AppColors.neutralGrey,
        fontWeight: FontWeight.w400,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// "Didn't receive code? Send Again" row
// ─────────────────────────────────────────────────────────────────
class _ResendRow extends StatelessWidget {
  final bool canResend;
  final VoidCallback onResend;

  const _ResendRow({required this.canResend, required this.onResend});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          "Didn't receive code? ",
          style: GoogleFonts.inter(
            fontSize: 13,
            color: AppColors.darkGrey,
            fontWeight: FontWeight.w400,
          ),
        ),
        GestureDetector(
          onTap: canResend ? onResend : null,
          child: Text(
            'Send Again',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: canResend ? AppColors.vibrantPink : AppColors.neutralGrey,
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Continue button — two visual states matching Figma exactly:
//   • Incomplete/error → muted text link "Continue ›"
//   • Complete + no error → full purple filled button "Continue ›"
// ─────────────────────────────────────────────────────────────────
class _ContinueButton extends StatelessWidget {
  final bool isComplete;
  final bool isLoading;
  final VoidCallback onTap;

  const _ContinueButton({
    required this.isComplete,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // ── Active: full purple button ──
    if (isComplete) {
      return SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: isLoading ? null : onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.royalPurple,
            disabledBackgroundColor: AppColors.royalPurple.withValues(
              alpha: 0.5,
            ),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(50),
            ),
          ),
          child: isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Continue',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.pureWhite,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.pureWhite,
                      size: 22,
                    ),
                  ],
                ),
        ),
      );
    }

    // ── Inactive: greyed text link "Continue ›" ──
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Continue',
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: AppColors.neutralGrey,
          ),
        ),
        const SizedBox(width: 4),
        const Icon(
          Icons.chevron_right_rounded,
          color: AppColors.neutralGrey,
          size: 20,
        ),
      ],
    );
  }
}
