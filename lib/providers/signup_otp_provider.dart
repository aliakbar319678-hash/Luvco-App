import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/network/auth_api_service.dart';

// ── 6-digit OTP slots ─────────────────────────────────────────────
final signupOtpDigitsProvider = StateProvider<List<String>>(
  (ref) => List.filled(6, ''),
);

// ── Resend cooldown (seconds countdown) ──────────────────────────
final signupOtpCooldownProvider = StateProvider<int>((ref) => 20);

// ── Status ────────────────────────────────────────────────────────
enum SignupOtpStatus { idle, loading, error, success }

class SignupOtpState {
  final SignupOtpStatus status;
  final String? errorMessage;

  const SignupOtpState({this.status = SignupOtpStatus.idle, this.errorMessage});

  bool get isLoading => status == SignupOtpStatus.loading;
  bool get hasError => status == SignupOtpStatus.error;
  bool get isSuccess => status == SignupOtpStatus.success;

  SignupOtpState copyWith({SignupOtpStatus? status, String? errorMessage}) =>
      SignupOtpState(
        status: status ?? this.status,
        errorMessage: errorMessage ?? this.errorMessage,
      );
}

class SignupOtpNotifier extends StateNotifier<SignupOtpState> {
  SignupOtpNotifier() : super(const SignupOtpState());

  /// [email] must be passed from the route parameter (e.g. /signup-verify?email=...).
  Future<void> verifyCode({required String email, required String code}) async {
    state = state.copyWith(status: SignupOtpStatus.loading);
    try {
      final res = await AuthApiService.instance.verifyEmail(
        email: email,
        code: code,
      );

      if (res.success) {
        state = state.copyWith(status: SignupOtpStatus.success);
      } else {
        state = state.copyWith(
          status: SignupOtpStatus.error,
          errorMessage: res.message ?? 'Wrong code, try again',
        );
      }
    } catch (e) {
      state = state.copyWith(
        status: SignupOtpStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> resendCode({required String email}) async {
    state = state.copyWith(status: SignupOtpStatus.loading);
    try {
      final res = await AuthApiService.instance.resendVerification(email);
      if (res.success) {
        state = state.copyWith(status: SignupOtpStatus.idle);
      } else {
        state = state.copyWith(
          status: SignupOtpStatus.error,
          errorMessage: res.message ?? 'Failed to resend code',
        );
      }
    } catch (e) {
      state = state.copyWith(
        status: SignupOtpStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  void reset() => state = const SignupOtpState();
}

final signupOtpProvider =
    StateNotifierProvider<SignupOtpNotifier, SignupOtpState>(
      (_) => SignupOtpNotifier(),
    );
