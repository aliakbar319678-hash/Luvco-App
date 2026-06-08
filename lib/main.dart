import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:luvco_logo/core/network/api_client.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait — done once at startup, not per-frame
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(statusBarColor: Colors.transparent),
  );
  // ── Backend URL Configuration ──────────────────────────────────────────
  // OPTION A: ADB Reverse Tunnel (USB cable required):
  //   Run: adb reverse tcp:3000 tcp:3000
  //   Then use: http://127.0.0.1:3000/api/v1
  //
  // OPTION B (Wi-Fi Mode - ACTIVE ✅): No USB cable needed!
  //   Phone & PC must be on the same Wi-Fi network.
  //   Your PC's Wi-Fi IP: 192.168.1.35  (run `ipconfig` if it changes)
  //
  // OPTION C: Android Emulator only:
  //   Use: http://10.0.2.2:3000/api/v1
  // ─────────────────────────────────────────────────────────────────────────
  ApiClient.instance.setBaseUrl(
    'http://192.168.1.35:3000/api/v1', // ← Wi-Fi: PC IP on local network
  );

  runApp(const ProviderScope(child: LuvcoApp()));
}

/// Root application widget.
///
/// Performance note: [LuvcoApp] is a plain [StatelessWidget] — it does NOT
/// watch any Riverpod provider.  The router is read once via
/// [ProviderContainer] inside [MaterialApp.router] using a [Consumer] wrapper
/// only at the routerConfig slot so only that slot rebuilds if the router
/// ever changes (which it never should in practice).
class LuvcoApp extends ConsumerWidget {
  const LuvcoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // read() instead of watch() — the GoRouter instance is created once and
    // never needs to be rebuilt. Using watch() would rebuild the whole tree.
    final router = ref.read(appRouterProvider);

    return MaterialApp.router(
      title: 'Luvco',
      debugShowCheckedModeBanner: false,
      // Use AppTheme.lightTheme so GoogleFonts.interTextTheme is applied
      // globally and not duplicated on every individual Text widget.
      theme: AppTheme.lightTheme,
      routerConfig: router,
    );
  }
}
