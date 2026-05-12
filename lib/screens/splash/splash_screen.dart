import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:luvco_logo/core/theme/app_colors.dart';
import 'package:luvco_logo/providers/splash_provider.dart';
import 'package:luvco_logo/widgets/luvco_logo.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SplashScreen
//
// Architecture notes (for future additions):
//   • The screen is a ConsumerStatefulWidget so it can read Riverpod state.
//   • All animations live in _SplashScreenState with a single controller.
//   • To add a new animated element, add an Animation<T> field, initialise it
//     in _buildAnimations(), and reference it inside _buildContent().
//   • To add a new UI section (e.g. tagline, version text), add a Widget
//     method (e.g. _buildTagline()) and call it from _buildContent().
// ─────────────────────────────────────────────────────────────────────────────
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  // ── Animation controller ──────────────────────────────────────────────────
  late final AnimationController _controller;

  // ── Individual animations (add more here as needed) ───────────────────────
  late final Animation<double> _logoScale;
  late final Animation<double> _logoOpacity;
  late final Animation<double> _logoSlideY;
  // FUTURE: late final Animation<double> _taglineOpacity;
  // FUTURE: late final Animation<double> _versionOpacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _buildAnimations();
    _controller.forward();
  }

  // ── Define all animation intervals here ───────────────────────────────────
  void _buildAnimations() {
    // Logo appears and bounces in during first 70% of the animation
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    _logoScale = Tween<double>(begin: 0.75, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOutBack),
      ),
    );

    _logoSlideY = Tween<double>(begin: 24.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    // FUTURE: uncomment and add your tagline animation below
    // _taglineOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
    //   CurvedAnimation(
    //     parent: _controller,
    //     curve: const Interval(0.5, 1.0, curve: Curves.easeIn),
    //   ),
    // );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // ── Navigation listener ───────────────────────────────────────────────────
  void _listenToSplashState(SplashStatus status) {
    if (status == SplashStatus.done && mounted) {
      context.go('/home');
    }
  }

  // ── Build helpers — add new sections as separate methods ──────────────────

  /// The animated Luvco logo — the centrepiece of the splash.
  Widget _buildLogo(Size size) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Opacity(
          opacity: _logoOpacity.value,
          child: Transform.translate(
            offset: Offset(0, _logoSlideY.value),
            child: Transform.scale(
              scale: _logoScale.value,
              child: LuvcoLogo(
                width: size.width * 0.63,
                color: LuvcoLogoColor.white,
              ),
            ),
          ),
        );
      },
    );
  }

  // FUTURE: Widget _buildTagline() { ... }
  // FUTURE: Widget _buildVersionBadge() { ... }
  // FUTURE: Widget _buildLoadingIndicator() { ... }

  /// Assemble all content here. Add new sections by calling their build methods.
  Widget _buildContent(Size size) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildLogo(size),

        // ── ADD FUTURE SECTIONS BELOW THIS LINE ──────────────────────────
        // e.g. const SizedBox(height: 24), _buildTagline(),
        // e.g. const SizedBox(height: 48), _buildLoadingIndicator(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Listen to state changes and navigate when ready
    ref.listen<SplashStatus>(splashProvider, (_, next) {
      _listenToSplashState(next);
    });

    final size = MediaQuery.sizeOf(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: AppColors.vibrantPink,
      ),
      child: Scaffold(
        backgroundColor: AppColors.vibrantPink,
        body: SafeArea(
          child: Center(
            child: _buildContent(size),
          ),
        ),
      ),
    );
  }
}
