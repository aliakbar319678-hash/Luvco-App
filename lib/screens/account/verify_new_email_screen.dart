import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/change_email_provider.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../../widgets/luvco_logo.dart';

// ─────────────────────────────────────────────────────────────────
// Verify New Email Screen — frames 1.6.10 / 1.6.11 / 1.6.12 / 1.6.13
// ─────────────────────────────────────────────────────────────────
class VerifyNewEmailScreen extends ConsumerStatefulWidget {
  final String email;

  const VerifyNewEmailScreen({super.key, required this.email});

  @override
  ConsumerState<VerifyNewEmailScreen> createState() =>
      _VerifyNewEmailScreenState();
      
}

class _VerifyNewEmailScreenState extends ConsumerState<VerifyNewEmailScreen> {
  final List<TextEditingController> _controllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(verifyEmailProvider.notifier).reset();
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
    ref.read(verifyEmailProvider.notifier).reset();
    _focusNodes[0].requestFocus();
  }

  void _onSubmit() {
    if (!_isComplete) return;
    ref.read(verifyEmailProvider.notifier).verifyCode(_fullCode, widget.email);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(verifyEmailProvider);
    final size = MediaQuery.sizeOf(context);
    final padding = MediaQuery.paddingOf(context);
    final scale = size.width / 390;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: AppColors.pureWhite,
        body: SafeArea(
          child: Container(
            color: AppColors.pageBackground,
            child: Stack(
              children: [
            Column(
              children: [
                // ── Header with Luvco logo — matches 1.6.10 ──────
                _VerifyEmailHeader(padding: padding, scale: scale, size: size),

                // ── Scrollable body ──────────────────────────────
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.symmetric(
                      horizontal: size.width * 0.058,
                      vertical: 28,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Title ──
                        Text(
                          'Verify New Email',
                          style: GoogleFonts.inter(
                            fontSize: 26 * scale.clamp(0.85, 1.2),
                            fontWeight: FontWeight.w700,
                            color: AppColors.black,
                          ),
                        ),

                        const SizedBox(height: 8),

                        // ── Subtitle with email ──
                        Text(
                          "Enter the code we've sent  to\n${widget.email}",
                          style: GoogleFonts.inter(
                            fontSize: 13 * scale.clamp(0.85, 1.2),
                            color: AppColors.darkGrey,
                            height: 1.4,
                          ),
                        ),

                        SizedBox(height: size.height * 0.042),

                        // ── 6-box OTP row ──
                        _OtpBoxRow(
                          controllers: _controllers,
                          focusNodes: _focusNodes,
                          hasError: state.hasError,
                          onCompleted: _onSubmit,
                          size: size,
                        ),

                        const SizedBox(height: 10),

                        // ── Error message (frame 1.6.11) ──
                        if (state.hasError) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.info_outline_rounded,
                                color: AppColors.errorRed,
                                size: 14 * scale.clamp(0.85, 1.2),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                state.errorMessage ?? 'Wrong code, try again',
                                style: GoogleFonts.inter(
                                  fontSize: 12 * scale.clamp(0.85, 1.2),
                                  color: AppColors.errorRed,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],

                        // ── Arrive hint (frame 1.6.10 & 1.6.12) ──
                        if (!state.hasError) ...[
                          Center(
                            child: Text(
                              'The email should arrive within 30s',
                              style: GoogleFonts.inter(
                                fontSize: 12 * scale.clamp(0.85, 1.2),
                                color: AppColors.neutralGrey,
                              ),
                            ),
                          ),
                        ],

                        const SizedBox(height: 18),

                        // ── "Didn't receive code? Send Again" ──
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Didn't receive code? ",
                              style: GoogleFonts.inter(
                                fontSize: 13 * scale.clamp(0.85, 1.2),
                                color: AppColors.darkGrey,
                              ),
                            ),
                            GestureDetector(
                              onTap: _clearAll,
                              child: Text(
                                'Send Again',
                                style: GoogleFonts.inter(
                                  fontSize: 13 * scale.clamp(0.85, 1.2),
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.black,
                                  decoration: TextDecoration.underline,
                                  decorationColor: AppColors.black,
                                ),
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: size.height * 0.042),

                        // ── Continue button ──
                        _ContinueButton(
                          isComplete: _isComplete,
                          isLoading: state.isLoading,
                          scale: scale,
                          size: size,
                          onTap: _onSubmit,
                        ),

                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),

                const LuvcoBottomNavBar(),
              ],
            ),

            // ── Success overlay — frame 1.6.13 ──────────────────
            if (state.isSuccess)
              _EmailChangedOverlay(
                scale: scale,
                size: size,
                onDismiss: () {
                  if (context.mounted) {
                    ref.read(verifyEmailProvider.notifier).reset();
                    // Pop both screens → back to account settings
                    Navigator.of(context)
                      ..pop()
                      ..pop();
                  }
                },
              ),
          ],
        ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Header — back arrow (left) + Luvco pink logo (center)
// Matches frames 1.6.10–1.6.13 exactly
// ─────────────────────────────────────────────────────────────────
class _VerifyEmailHeader extends StatelessWidget {
  final EdgeInsets padding;
  final double scale;
  final Size size;

  const _VerifyEmailHeader({
    required this.padding,
    required this.scale,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: 12,
        bottom: 20,
        left: size.width * 0.058,
        right: size.width * 0.058,
      ),
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // ── Back arrow left-aligned ──
          Align(
            alignment: Alignment.centerLeft,
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: AppColors.vibrantPink,
                size: 20 * scale.clamp(0.85, 1.2),
              ),
            ),
          ),
          // ── Luvco pink logo centered ──
          Center(
            child: LuvcoLogo(
              width: size.width * 0.32,
              color: LuvcoLogoColor.pink,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// 6-box OTP row
// Red border + red text on error (1.6.11)
// Grey border + black text on idle/filled (1.6.10 & 1.6.12)
// ─────────────────────────────────────────────────────────────────
class _OtpBoxRow extends StatelessWidget {
  final List<TextEditingController> controllers;
  final List<FocusNode> focusNodes;
  final bool hasError;
  final VoidCallback onCompleted;
  final Size size;

  const _OtpBoxRow({
    required this.controllers,
    required this.focusNodes,
    required this.hasError,
    required this.onCompleted,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
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
    final textColor = hasError ? AppColors.errorRed : AppColors.black;

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
          color: textColor,
        ),
        decoration: InputDecoration(
          counterText: '',
          hintText: '-',
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

// ─────────────────────────────────────────────────────────────────
// Continue button
// Disabled: faint pink + light purple text + grey chevron
// Enabled: royalPurple + white text + white chevron
// ─────────────────────────────────────────────────────────────────
class _ContinueButton extends StatelessWidget {
  final bool isComplete;
  final bool isLoading;
  final double scale;
  final Size size;
  final VoidCallback onTap;

  const _ContinueButton({
    required this.isComplete,
    required this.isLoading,
    required this.scale,
    required this.size,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final height = (size.height * 0.062).clamp(48.0, 58.0);

    return SizedBox(
      width: double.infinity,
      height: height,
      child: ElevatedButton(
        onPressed: (isComplete && !isLoading) ? onTap : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: isComplete
              ? AppColors.royalPurple
              : AppColors.faintPink,
          disabledBackgroundColor: AppColors.faintPink,
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
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Continue',
                    style: GoogleFonts.inter(
                      fontSize: 16 * scale.clamp(0.85, 1.3),
                      fontWeight: FontWeight.w600,
                      color: isComplete
                          ? AppColors.pureWhite
                          : AppColors.lightRoyalPurple,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: isComplete
                        ? AppColors.pureWhite
                        : AppColors.lightRoyalPurple,
                    size: 22 * scale.clamp(0.85, 1.2),
                  ),
                ],
              ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Success overlay — frame 1.6.13
// White card, green circle check, title + subtitle
// Auto-dismisses after 2s, then pops both screens
// ─────────────────────────────────────────────────────────────────
class _EmailChangedOverlay extends StatelessWidget {
  final double scale;
  final Size size;
  final VoidCallback onDismiss;

  const _EmailChangedOverlay({
    required this.scale,
    required this.size,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    Future.delayed(const Duration(seconds: 2), () {
      if (context.mounted) onDismiss();
    });

    return Positioned.fill(
      child: GestureDetector(
        onTap: onDismiss,
        child: Container(
          color: Colors.black.withValues(alpha: 0.18),
          child: Center(
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: size.width * 0.10),
              padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.10),
                    blurRadius: 24,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Green circle checkmark ──
                  Container(
                    width: 66 * scale.clamp(0.85, 1.2),
                    height: 66 * scale.clamp(0.85, 1.2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF43A047),
                        width: 2.5,
                      ),
                    ),
                    child: Icon(
                      Icons.check_rounded,
                      color: const Color(0xFF43A047),
                      size: 38 * scale.clamp(0.85, 1.2),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Title ──
                  Text(
                    'Your mail has been\nchanged successfully!',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 15 * scale.clamp(0.85, 1.2),
                      fontWeight: FontWeight.w700,
                      color: AppColors.black,
                      height: 1.35,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // ── Subtitle ──
                  Text(
                    'Ornare magna lectus id viverra dolor rhoncus nascetur',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 12 * scale.clamp(0.85, 1.2),
                      color: AppColors.neutralGrey,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
