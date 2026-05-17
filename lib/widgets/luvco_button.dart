import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/app_colors.dart';
import '../core/utils/responsive_utils.dart';

enum LuvcoButtonStyle { filled, outlined }

/// Production-grade Luvco button with:
/// • Press-scale micro-animation (GPU-friendly: transform only, no repaint)
/// • Single [MediaQuery] call via [context.scale]
/// • Consistent sizing across all screen sizes
class LuvcoButton extends StatefulWidget {
  final String label;
  final VoidCallback? onTap;
  final LuvcoButtonStyle style;
  final bool isLoading;
  final bool isDisabled;
  final Color? disabledBackgroundColor;
  final Color? disabledTextColor;

  const LuvcoButton({
    super.key,
    required this.label,
    this.onTap,
    this.style = LuvcoButtonStyle.filled,
    this.isLoading = false,
    this.isDisabled = false,
    this.disabledBackgroundColor,
    this.disabledTextColor,
  });

  @override
  State<LuvcoButton> createState() => _LuvcoButtonState();
}

class _LuvcoButtonState extends State<LuvcoButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
      reverseDuration: const Duration(milliseconds: 140),
      lowerBound: 0.0,
      upperBound: 1.0,
    );
    _scale = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeIn),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  bool get _interactive =>
      !widget.isLoading && !widget.isDisabled && widget.onTap != null;

  void _onTapDown(TapDownDetails _) {
    if (_interactive) _ctrl.forward();
  }

  void _onTapUp(TapUpDetails _) {
    if (!_interactive) return;
    _ctrl.reverse();
    widget.onTap?.call();
  }

  void _onTapCancel() => _ctrl.reverse();

  @override
  Widget build(BuildContext context) {
    // Single MediaQuery call for the whole widget
    final s = context.scale;
    final height = (MediaQuery.sizeOf(context).height * 0.062).clamp(48.0, 58.0);

    return ScaleTransition(
      scale: _scale,
      child: GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        behavior: HitTestBehavior.opaque,
        child: IgnorePointer(
          ignoring: _interactive, // Ignore only if active so it passes taps to GestureDetector.
          child: widget.style == LuvcoButtonStyle.filled
              ? _FilledButton(
                  label: widget.label,
                  isLoading: widget.isLoading,
                  isDisabled: widget.isDisabled,
                  disabledBackgroundColor: widget.disabledBackgroundColor,
                  disabledTextColor: widget.disabledTextColor,
                  height: height,
                  scale: s,
                )
              : _OutlinedButton(
                  label: widget.label,
                  isDisabled: widget.isDisabled,
                  height: height,
                  scale: s,
                ),
        ),
      ),
    );
  }
}

// ── Filled variant ───────────────────────────────────────────────
class _FilledButton extends StatelessWidget {
  final String label;
  final bool isLoading;
  final bool isDisabled;
  final Color? disabledBackgroundColor;
  final Color? disabledTextColor;
  final double height;
  final double scale;

  const _FilledButton({
    required this.label,
    required this.isLoading,
    required this.isDisabled,
    required this.height,
    required this.scale,
    this.disabledBackgroundColor,
    this.disabledTextColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: height,
      child: ElevatedButton(
        // onPressed = null disables the button natively — no tap, no ripple
        onPressed: (isLoading || isDisabled) ? null : () {},
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.royalPurple,
          disabledBackgroundColor:
              disabledBackgroundColor ?? AppColors.faintPink,
          elevation: 0,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(50)),
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
            : Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 16 * scale,
                  fontWeight: FontWeight.w600,
                  color: isDisabled
                      ? (disabledTextColor ?? AppColors.lightRoyalPurple)
                      : AppColors.pureWhite,
                ),
              ),
      ),
    );
  }
}

// ── Outlined variant ─────────────────────────────────────────────
class _OutlinedButton extends StatelessWidget {
  final String label;
  final bool isDisabled;
  final double height;
  final double scale;

  const _OutlinedButton({
    required this.label,
    required this.isDisabled,
    required this.height,
    required this.scale,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: height,
      child: OutlinedButton(
        onPressed: isDisabled ? null : () {},
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.royalPurple,
          side: BorderSide(
            color: isDisabled
                ? AppColors.royalPurple.withValues(alpha: 0.40)
                : AppColors.royalPurple,
            width: 1.5,
          ),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(50)),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 16 * scale,
            fontWeight: FontWeight.w600,
            color: isDisabled
                ? AppColors.royalPurple.withValues(alpha: 0.40)
                : AppColors.royalPurple,
          ),
        ),
      ),
    );
  }
}

