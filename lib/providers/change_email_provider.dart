import 'package:flutter_riverpod/flutter_riverpod.dart';

// ─────────────────────────────────────────────────────────────────
// Change Email State — drives frames 1.6.8 & 1.6.9
// ─────────────────────────────────────────────────────────────────
class ChangeEmailState {
  final String email;
  final String password;
  final bool isPasswordVisible;
  final bool isLoading;
  final String? errorMessage;

  const ChangeEmailState({
    this.email = '',
    this.password = '',
    this.isPasswordVisible = false,
    this.isLoading = false,
    this.errorMessage,
  });

  // Continue enabled only when both fields are filled
  bool get canContinue =>
      email.trim().isNotEmpty && password.trim().isNotEmpty;

  ChangeEmailState copyWith({
    String? email,
    String? password,
    bool? isPasswordVisible,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) =>
      ChangeEmailState(
        email: email ?? this.email,
        password: password ?? this.password,
        isPasswordVisible: isPasswordVisible ?? this.isPasswordVisible,
        isLoading: isLoading ?? this.isLoading,
        errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      );
}

class ChangeEmailNotifier extends StateNotifier<ChangeEmailState> {
  ChangeEmailNotifier() : super(const ChangeEmailState());

  void setEmail(String value) =>
      state = state.copyWith(email: value, clearError: true);

  void setPassword(String value) =>
      state = state.copyWith(password: value, clearError: true);

  void togglePasswordVisibility() =>
      state = state.copyWith(isPasswordVisible: !state.isPasswordVisible);

  // Simulates verifying current password then sending OTP to new email
  Future<bool> continueToVerify() async {
    if (!state.canContinue) return false;
    state = state.copyWith(isLoading: true);
    await Future.delayed(const Duration(milliseconds: 800));
    state = state.copyWith(isLoading: false);
    return true; // navigate to verify screen
  }
}

final changeEmailProvider =
    StateNotifierProvider<ChangeEmailNotifier, ChangeEmailState>(
  (_) => ChangeEmailNotifier(),
);

// ─────────────────────────────────────────────────────────────────
// Verify New Email OTP State — drives frames 1.6.10 / 1.6.11 /
// 1.6.12 / 1.6.13
// ─────────────────────────────────────────────────────────────────
enum VerifyEmailStatus { idle, loading, error, success }

class VerifyEmailState {
  final VerifyEmailStatus status;
  final String? errorMessage;

  const VerifyEmailState({
    this.status = VerifyEmailStatus.idle,
    this.errorMessage,
  });

  bool get isLoading => status == VerifyEmailStatus.loading;
  bool get hasError => status == VerifyEmailStatus.error;
  bool get isSuccess => status == VerifyEmailStatus.success;

  VerifyEmailState copyWith({
    VerifyEmailStatus? status,
    String? errorMessage,
    bool clearError = false,
  }) =>
      VerifyEmailState(
        status: status ?? this.status,
        errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      );
}

class VerifyEmailNotifier extends StateNotifier<VerifyEmailState> {
  VerifyEmailNotifier() : super(const VerifyEmailState());

  Future<void> verifyCode(String code) async {
    state = state.copyWith(status: VerifyEmailStatus.loading);
    await Future.delayed(const Duration(seconds: 1));
    // Demo: any code other than "123456" fails
    if (code != '123456') {
      state = state.copyWith(
        status: VerifyEmailStatus.error,
        errorMessage: 'Wrong code, try again',
      );
    } else {
      state = state.copyWith(status: VerifyEmailStatus.success);
    }
  }

  void reset() => state = const VerifyEmailState();
}

final verifyEmailProvider =
    StateNotifierProvider<VerifyEmailNotifier, VerifyEmailState>(
  (_) => VerifyEmailNotifier(),
);
