import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:luvco_logo/core/theme/app_colors.dart';
import 'package:luvco_logo/providers/otp_provider.dart';
import 'package:luvco_logo/providers/forgot_password_provider.dart';
import 'package:luvco_logo/widgets/auth_header.dart';
import 'package:luvco_logo/widgets/auth_error_row.dart';

class OtpVerificationScreen extends ConsumerStatefulWidget {
  final String email;

  const OtpVerificationScreen({super.key, required this.email});

  @override
  ConsumerState<OtpVerificationScreen> createState() =>
      _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends ConsumerState<OtpVerificationScreen> {
  final List<TextEditingController> _controllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(otpProvider.notifier).reset();
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
    ref.read(otpProvider.notifier).reset();
    _focusNodes[0].requestFocus();
    
    // Actually call the backend to resend the forgot password code
    ref.read(forgotPasswordProvider.notifier).resetPassword(widget.email);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('A new code has been requested.')),
    );
  }

  void _onSubmit() {
    if (!_isComplete) return;
    ref.read(otpProvider.notifier).verifyCode(
      email: widget.email,
      code: _fullCode,
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final state = ref.watch(otpProvider);

    ref.listen<OtpState>(otpProvider, (_, next) {
      if (next.isSuccess && context.mounted) {
        context.push(
          '/new-password?email=${Uri.encodeComponent(widget.email)}&code=${Uri.encodeComponent(_fullCode)}',
        );
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
                      'Forgot Password',
                      style: GoogleFonts.inter(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: AppColors.black,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // ── Subtitle ──
                    Text(
                      "Enter the code we've sent to ${widget.email}",
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: AppColors.darkGrey,
                      ),
                    ),

                    SizedBox(height: size.height * 0.036),

                    // ── OTP boxes ──
                    _OtpBoxRow(
                      controllers: _controllers,
                      focusNodes: _focusNodes,
                      hasError: state.hasError,
                      onCompleted: _onSubmit,
                    ),

                    // ── Error message ──
                    if (state.hasError)
                      AuthErrorRow(
                        message: state.errorMessage ?? 'Wrong code, try again',
                        centered: true,
                      ),

                    // ── "Email should arrive" hint ──
                    if (!state.hasError) ...[
                      const SizedBox(height: 8),
                      Center(
                        child: Text(
                          'The email should arrive within 30s',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.neutralGrey,
                          ),
                        ),
                      ),
                    ],

                    SizedBox(height: size.height * 0.020),

                    // ── Resend link ──
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Didn't receive code? ",
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppColors.darkGrey,
                          ),
                        ),
                        GestureDetector(
                          onTap: _clearAll,
                          child: Text(
                            'Send Again',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.black,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: size.height * 0.034),

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
