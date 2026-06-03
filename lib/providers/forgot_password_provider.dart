import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/network/auth_api_service.dart';

// ── Forgot password email field ──────────────────────────────────
final forgotEmailProvider = StateProvider<String>((ref) => '');

// ── Status ───────────────────────────────────────────────────────
enum ForgotPasswordStatus { idle, loading, success, error }

class ForgotPasswordState {
  final ForgotPasswordStatus status;
  final String? errorMessage;

  const ForgotPasswordState({
    this.status = ForgotPasswordStatus.idle,
    this.errorMessage,
  });

  bool get isLoading => status == ForgotPasswordStatus.loading;
  bool get isSuccess => status == ForgotPasswordStatus.success;

  ForgotPasswordState copyWith({
    ForgotPasswordStatus? status,
    String? errorMessage,
  }) => ForgotPasswordState(
    status: status ?? this.status,
    errorMessage: errorMessage,
  );
}

class ForgotPasswordNotifier extends StateNotifier<ForgotPasswordState> {
  ForgotPasswordNotifier() : super(const ForgotPasswordState());

  Future<void> resetPassword(String email) async {
    state = state.copyWith(status: ForgotPasswordStatus.loading);
    try {
      // The backend always returns success 200 for security (email enumeration prevention),
      // so we treat any 200 as success regardless.
      await AuthApiService.instance.forgotPassword(email);
      state = state.copyWith(status: ForgotPasswordStatus.success);
    } catch (e) {
      state = state.copyWith(
        status: ForgotPasswordStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  void reset() => state = const ForgotPasswordState();
}

final forgotPasswordProvider =
    StateNotifierProvider<ForgotPasswordNotifier, ForgotPasswordState>(
      (_) => ForgotPasswordNotifier(),
    );
