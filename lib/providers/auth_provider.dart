import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/auth_model.dart';

// ── Form field providers ─────────────────────────────────────────
final emailProvider = StateProvider<String>((ref) => '');
final passwordProvider = StateProvider<String>((ref) => '');
final obscurePasswordProvider = StateProvider<bool>((ref) => true);

// ── Login status ─────────────────────────────────────────────────
enum LoginStatus { idle, loading, success, error }

class LoginState {
  final LoginStatus status;
  final String? errorMessage;

  const LoginState({this.status = LoginStatus.idle, this.errorMessage});

  // Convenient getter used in UI
  bool get hasError => status == LoginStatus.error;

  LoginState copyWith({LoginStatus? status, String? errorMessage}) =>
      LoginState(status: status ?? this.status, errorMessage: errorMessage);
}

class LoginNotifier extends StateNotifier<LoginState> {
  LoginNotifier() : super(const LoginState());

  Future<void> login(AuthModel model) async {
    state = state.copyWith(status: LoginStatus.loading);
    try {
      await Future.delayed(const Duration(seconds: 1));

      // Demo: treat empty fields as wrong credentials
      if (model.email.isEmpty || model.password.isEmpty) {
        state = const LoginState(
          status: LoginStatus.error,
          errorMessage: "We don't recognize the email or password",
        );
        return;
      }
      state = state.copyWith(status: LoginStatus.success);
    } catch (_) {
      state = const LoginState(
        status: LoginStatus.error,
        errorMessage: "We don't recognize the email or password",
      );
    }
  }

  void reset() => state = const LoginState();
}

final loginProvider = StateNotifierProvider<LoginNotifier, LoginState>(
  (_) => LoginNotifier(),
);
