import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/auth_model.dart';

import '../core/network/auth_api_service.dart';
import '../models/auth/login_request.dart';

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
      final req = LoginRequest(email: model.email, password: model.password);
      final res = await AuthApiService.instance.login(req);

      if (res.success) {
        state = state.copyWith(status: LoginStatus.success);
      } else {
        state = LoginState(
          status: LoginStatus.error,
          errorMessage:
              res.message ?? "We don't recognize the email or password",
        );
      }
    } catch (e) {
      state = LoginState(status: LoginStatus.error, errorMessage: e.toString());
    }
  }

  void reset() => state = const LoginState();
}

final loginProvider = StateNotifierProvider<LoginNotifier, LoginState>(
  (_) => LoginNotifier(),
);
