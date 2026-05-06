import 'package:flutter_riverpod/flutter_riverpod.dart';

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

  Future<void> verifyCode(String code) async {
    state = state.copyWith(status: OtpStatus.loading);
    try {
      await Future.delayed(const Duration(seconds: 1));

      // Simulate wrong code for demo (any code other than "123456" fails)
      if (code != '123456') {
        state = state.copyWith(
          status: OtpStatus.error,
          errorMessage: 'Wrong code, try again',
        );
      } else {
        state = state.copyWith(status: OtpStatus.success);
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
