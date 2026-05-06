import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:luvco_logo/core/theme/app_colors.dart';
import 'package:luvco_logo/providers/otp_provider.dart';
import 'package:luvco_logo/widgets/luvco_button.dart';
import 'package:luvco_logo/widgets/lucu_logo.dart';

class OtpVerificationScreen extends ConsumerStatefulWidget {
  /// Email shown in the subtitle, e.g. "test@email.com"
  final String email;

  const OtpVerificationScreen({super.key, required this.email});

  @override
  ConsumerState<OtpVerificationScreen> createState() =>
      _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends ConsumerState<OtpVerificationScreen> {
  // One controller + focus node per OTP digit
  final List<TextEditingController> _controllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

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

  // ── Collect all digits into a single string ──────────────────
  String get _fullCode => _controllers.map((c) => c.text).join();

  bool get _isComplete => _fullCode.length == 6;

  // ── Wipe all cells and reset provider ────────────────────────
  void _clearAll() {
    for (final c in _controllers) {
      c.clear();
    }
    ref.read(otpProvider.notifier).reset();
    _focusNodes[0].requestFocus();
  }

  void _onSubmit() {
    if (!_isComplete) return;
    ref.read(otpProvider.notifier).verifyCode(_fullCode);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final padding = MediaQuery.paddingOf(context);
    final state = ref.watch(otpProvider);
    ref.listen<OtpState>(otpProvider, (_, next) {
      if (next.isSuccess && context.mounted) {
        context.push('/new-password');
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
            // ── Top white card with logo ──
            _OtpHeader(size: size, padding: padding),

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
                    RichText(
                      text: TextSpan(
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: AppColors.darkGrey,
                        ),
                        children: [
                          const TextSpan(
                            text: "Enter the code we've sent  to ",
                          ),
                          TextSpan(
                            text: widget.email,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
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
                    if (state.hasError) ...[
                      const SizedBox(height: 8),
                      Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: AppColors.errorRed,
                              size: 15,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              state.errorMessage ?? 'Wrong code, try again',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: AppColors.errorRed,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // ── "Email should arrive" hint ──
                    if (!state.hasError) ...[
                      const SizedBox(height: 8),
                      Text(
                        'The email should arrive within 20s',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.neutralGrey,
                        ),
                      ),
                    ],

                    SizedBox(height: size.height * 0.020),

                    // ── Resend link ──
                    Row(
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
                              color: AppColors.vibrantPink,
                            ),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: size.height * 0.034),

                    // ── Continue button ──
                    LuvcoButton(
                      label: 'Continue',
                      isLoading: state.isLoading,
                      isDisabled: !_isComplete,
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
// Header: white card with rounded bottom + Luvco logo
// ─────────────────────────────────────────────────────────────────
class _OtpHeader extends StatelessWidget {
  final Size size;
  final EdgeInsets padding;

  const _OtpHeader({required this.size, required this.padding});

  @override
  Widget build(BuildContext context) {
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
          SizedBox(height: padding.top + 12),
          LuvcoLogo(width: size.width * 0.32, color: LuvcoLogoColor.pink),
          const SizedBox(height: 16),
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

// ─────────────────────────────────────────────────────────────────
// Single OTP box
// ─────────────────────────────────────────────────────────────────
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
            // Move to next box
            if (nextFocus != null) {
              nextFocus!.requestFocus();
            } else {
              // Last box → trigger submit
              focusNode.unfocus();
              onCompleted();
            }
          } else {
            // Digit deleted → move back
            prevFocus?.requestFocus();
          }
        },
      ),
    );
  }
}
