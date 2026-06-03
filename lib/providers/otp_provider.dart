import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/network/auth_api_service.dart';

// ── OTP digits (6 slots) ─────────────────────────────────────────
final otpDigitsProvider = StateProvider<List<String>>(
  (ref) => List.filled(6, ''),
);

// ── Status ───────────────────────────────────────────────────────
enum OtpStatus { idle, loading, error, success }

class OtpState {
  final OtpStatus status;
  final String? errorMessage;

  const OtpState({this.status = OtpStatus.idle, this.errorMessage});

  bool get isLoading => status == OtpStatus.loading;
  bool get hasError => status == OtpStatus.error;
  bool get isSuccess => status == OtpStatus.success;

  OtpState copyWith({OtpStatus? status, String? errorMessage}) =>
      OtpState(status: status ?? this.status, errorMessage: errorMessage);
}

class OtpNotifier extends StateNotifier<OtpState> {
  OtpNotifier() : super(const OtpState());

  /// [email] is required to verify the reset code against the backend.
  Future<void> verifyCode({required String email, required String code}) async {
    state = state.copyWith(status: OtpStatus.loading);
    try {
      final res = await AuthApiService.instance.verifyResetCode(
        email: email,
        code: code,
      );

      if (res.success) {
        state = state.copyWith(status: OtpStatus.success);
      } else {
        state = state.copyWith(
          status: OtpStatus.error,
          errorMessage: res.message ?? 'Wrong code, try again',
        );
      }
    } catch (e) {
      state = state.copyWith(
        status: OtpStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  void reset() {
    state = const OtpState();
  }
}

final otpProvider = StateNotifierProvider<OtpNotifier, OtpState>(
  (_) => OtpNotifier(),
);
