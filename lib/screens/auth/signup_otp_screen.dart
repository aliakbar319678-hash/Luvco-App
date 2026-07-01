import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:luvco_logo/core/theme/app_colors.dart';
import 'package:luvco_logo/core/theme/app_text_styles.dart';
import 'package:luvco_logo/providers/signup_otp_provider.dart';
import 'package:luvco_logo/widgets/auth_header.dart';
import 'package:luvco_logo/widgets/auth_error_row.dart';

class SignupOtpScreen extends ConsumerStatefulWidget {
  final String email;

  const SignupOtpScreen({super.key, required this.email});

  @override
  ConsumerState<SignupOtpScreen> createState() => _SignupOtpScreenState();
}

class _SignupOtpScreenState extends ConsumerState<SignupOtpScreen> {
  final List<TextEditingController> _controllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  final GlobalKey<_CooldownAndResendSectionState> _cooldownKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(signupOtpProvider.notifier).reset();
    });
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String get _fullCode => _controllers.map((c) => c.text).join();
  bool get _isComplete => _fullCode.length == 6;

  void _clearAll() {
    for (final c in _controllers) {
      c.clear();
    }
    ref.read(signupOtpProvider.notifier).reset();
    _focusNodes[0].requestFocus();
    _cooldownKey.currentState?._startCooldown();
    
    // Call the backend to resend/regenerate the signup verification OTP
    ref.read(signupOtpProvider.notifier).resendCode(email: widget.email);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('A new verification code has been requested.')),
    );
  }

  void _onSubmit() {
    if (!_isComplete) return;
    ref
        .read(signupOtpProvider.notifier)
        .verifyCode(email: widget.email, code: _fullCode);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final state = ref.watch(signupOtpProvider);

    ref.listen<SignupOtpState>(signupOtpProvider, (_, next) {
      if (next.isSuccess && context.mounted) {
        context.go('/onboarding');
      }
    });

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: AppColors.pureWhite,
        body: SafeArea(
          child: Container(
            color: AppColors.pageBackground,
            child: Column(
              children: [
            // ── Top white card with logo ──
            const AuthHeader(showLogo: true),

            // ── Content ──
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
                      'Verify Your Account',
                      style: AppTextStyles.heading1(context),
                    ),
                    const SizedBox(height: 8),

                    // ── Subtitle ──
                    Text(
                      "Enter the code we've sent to ${widget.email}",
                      style: AppTextStyles.subtitle(context),
                    ),

                    SizedBox(height: size.height * 0.036),

                    // ── OTP boxes ──
                    _OtpBoxRow(
                      controllers: _controllers,
                      focusNodes: _focusNodes,
                      hasError: state.hasError,
                      onCompleted: _onSubmit,
                    ),

                    const SizedBox(height: 10),

                    if (state.hasError)
                      AuthErrorRow(message: state.errorMessage, centered: true)
                    else
                      _CooldownAndResendSection(
                        key: _cooldownKey,
                        onResend: _clearAll,
                      ),

                    SizedBox(height: size.height * 0.036),

                    // ── Continue button ──
                    _ContinueButton(
                      isComplete: _isComplete,
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
        ),
      ),
    );
  }
}

class _CooldownAndResendSection extends StatefulWidget {
  final VoidCallback onResend;

  const _CooldownAndResendSection({super.key, required this.onResend});

  @override
  State<_CooldownAndResendSection> createState() => _CooldownAndResendSectionState();
}

class _CooldownAndResendSectionState extends State<_CooldownAndResendSection> {
  Timer? _timer;
  int _cooldown = 60;

  @override
  void initState() {
    super.initState();
    _startCooldown();
  }

  void _startCooldown() {
    _timer?.cancel();
    setState(() => _cooldown = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_cooldown > 0) {
        if (mounted) setState(() => _cooldown--);
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ArrivalHint(cooldown: _cooldown),
        const SizedBox(height: 14),
        _ResendRow(
          canResend: _cooldown == 0,
          onResend: widget.onResend,
        ),
      ],
    );
  }
}

class _ArrivalHint extends StatelessWidget {
  final int cooldown;
  const _ArrivalHint({required this.cooldown});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        cooldown > 0
            ? 'The email should arrive within ${cooldown}s'
            : 'You can resend the code now',
        style: GoogleFonts.inter(
          fontSize: 12,
          color: AppColors.neutralGrey,
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }
}

class _ResendRow extends StatelessWidget {
  final bool canResend;
  final VoidCallback onResend;
  const _ResendRow({required this.canResend, required this.onResend});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Didn't receive code? ",
          style: GoogleFonts.inter(fontSize: 13, color: AppColors.darkGrey),
        ),
        GestureDetector(
          onTap: canResend ? onResend : null,
          child: Text(
            'Send Again',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: canResend ? AppColors.black : AppColors.darkGrey,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }
}

class _OtpBoxRow extends StatelessWidget {
  final List<TextEditingController> controllers;
  final List<FocusNode> focusNodes;
  final bool hasError;
  final VoidCallback onCompleted;

  const _OtpBoxRow({
    required this.controllers,
    required this.focusNodes,
    required this.hasError,
    required this.onCompleted,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final boxWidth = (size.width - size.width * 0.116 - 5 * 10) / 6;
    final boxHeight = boxWidth * 1.15;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(6, (index) {
        return _OtpSingleBox(
          controller: controllers[index],
          focusNode: focusNodes[index],
          nextFocus: index < 5 ? focusNodes[index + 1] : null,
          prevFocus: index > 0 ? focusNodes[index - 1] : null,
          hasError: hasError,
          width: boxWidth,
          height: boxHeight,
          onCompleted: onCompleted,
        );
      }),
    );
  }
}

class _OtpSingleBox extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final FocusNode? nextFocus;
  final FocusNode? prevFocus;
  final bool hasError;
  final double width;
  final double height;
  final VoidCallback onCompleted;

  const _OtpSingleBox({
    required this.controller,
    required this.focusNode,
    required this.nextFocus,
    required this.prevFocus,
    required this.hasError,
    required this.width,
    required this.height,
    required this.onCompleted,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = hasError ? AppColors.errorRed : AppColors.inputBorder;
    final focusColor = hasError ? AppColors.errorRed : AppColors.royalPurple;

    return SizedBox(
      width: width,
      height: height,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.black,
        ),
        decoration: InputDecoration(
          counterText: '',
          hintText: controller.text.isEmpty ? '-' : '',
          hintStyle: GoogleFonts.inter(
            fontSize: 18,
            color: AppColors.clearGrey,
          ),
          filled: true,
          fillColor: AppColors.pureWhite,
          contentPadding: EdgeInsets.zero,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: borderColor, width: 1.0),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: focusColor, width: 1.5),
          ),
        ),
        onChanged: (value) {
          if (value.isNotEmpty) {
            if (nextFocus != null) {
              nextFocus!.requestFocus();
            } else {
              focusNode.unfocus();
              onCompleted();
            }
          } else {
            prevFocus?.requestFocus();
          }
        },
      ),
    );
  }
}

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

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFFCF3F8),
          borderRadius: BorderRadius.circular(50),
        ),
        child: Row(
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
        ),
      ),
    );
  }
}
