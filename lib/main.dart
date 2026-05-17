import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

