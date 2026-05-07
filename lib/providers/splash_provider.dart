import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Splash Status
// Add more states here in the future (e.g., SplashStatus.fetchingConfig)
// ─────────────────────────────────────────────────────────────────────────────
enum SplashStatus { loading, done }

// ─────────────────────────────────────────────────────────────────────────────
// Splash Provider
// This is the central controller for what the splash screen does.
// In the future, replace the delay with real async work:
//   - Auth token refresh
//   - Remote config fetch
//   - Asset preloading
// ─────────────────────────────────────────────────────────────────────────────
final splashProvider =
    StateNotifierProvider<SplashNotifier, SplashStatus>((ref) {
  return SplashNotifier();
});

class SplashNotifier extends StateNotifier<SplashStatus> {
  SplashNotifier() : super(SplashStatus.loading) {
    _init();
  }

  Future<void> _init() async {
    // ── Perform any async startup work here in the future ──
    // e.g., await ref.read(authProvider.notifier).refreshToken();
    // e.g., await RemoteConfig.instance.fetchAndActivate();

    // Minimum display duration so the animation completes gracefully
    await Future.delayed(const Duration(milliseconds: 2500));

    state = SplashStatus.done;
  }
}
