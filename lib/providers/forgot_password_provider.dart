import 'package:flutter_riverpod/flutter_riverpod.dart';

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
      // TODO: replace with real reset call
      await Future.delayed(const Duration(seconds: 1));
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
