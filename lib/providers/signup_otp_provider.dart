import 'package:flutter_riverpod/flutter_riverpod.dart';

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

  Future<void> verifyCode(String code) async {
    state = state.copyWith(status: SignupOtpStatus.loading);
    try {
      // TODO: replace with real API call
      await Future.delayed(const Duration(seconds: 1));

      // Demo: only "123456" is accepted as correct
      if (code != '123456') {
        state = state.copyWith(
          status: SignupOtpStatus.error,
          errorMessage: 'Wrong code, try again',
        );
      } else {
        state = state.copyWith(status: SignupOtpStatus.success);
      }
    } catch (_) {
      state = state.copyWith(
        status: SignupOtpStatus.error,
        errorMessage: 'Something went wrong. Please try again.',
      );
    }
  }

  void reset() => state = const SignupOtpState();
}

final signupOtpProvider =
    StateNotifierProvider<SignupOtpNotifier, SignupOtpState>(
      (_) => SignupOtpNotifier(),
    );
