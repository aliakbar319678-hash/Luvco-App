import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:luvco_logo/core/theme/app_colors.dart';
import 'package:luvco_logo/providers/splash_provider.dart';
import 'package:luvco_logo/widgets/lucu_logo.dart';

class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<AsyncValue<SplashStatus>>(splashProvider, (_, next) {
      next.whenData((status) {
        if (status == SplashStatus.done) {
          context.go('/login');
        }
      });
    });

    final size = MediaQuery.sizeOf(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: AppColors.vibrantPink,
        body: Stack(
          children: [
            // ── Centered logo ──
            Center(
              child: LuvcoLogo(
                width: size.width * 0.63,
                color: LuvcoLogoColor.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
