import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:luvco_logo/screens/auth/forgot_password_screen.dart';
import 'package:luvco_logo/screens/auth/login_screen.dart';
import 'package:luvco_logo/screens/auth/new_password_screen.dart'; // ← NEW
import 'package:luvco_logo/screens/auth/otp_verification_screen.dart';
import 'package:luvco_logo/screens/auth/password_updated_screen.dart'; // ← NEW
import 'package:luvco_logo/screens/auth/signup_otp_screen.dart';
import 'package:luvco_logo/screens/auth/signup_screen.dart';
import 'package:luvco_logo/screens/splash/splash_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/otp-verification',
        builder: (context, state) {
          final email = state.uri.queryParameters['email'] ?? '';
          return OtpVerificationScreen(email: email);
        },
      ),
      GoRoute(
        path: '/new-password', // ← NEW
        builder: (context, state) => const NewPasswordScreen(),
      ),
      GoRoute(
        path: '/password-updated', // ← NEW
        builder: (context, state) => const PasswordUpdatedScreen(),
      ),

      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: '/signup-verify',
        builder: (context, state) {
          final email = state.uri.queryParameters['email'] ?? '';
          return SignupOtpScreen(email: email);
        },
      ),
    ],
  );
});
