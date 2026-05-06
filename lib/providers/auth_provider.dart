import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/auth_model.dart';

// ── Form fields ──────────────────────────────────────────────────
final emailProvider = StateProvider<String>((ref) => '');
final passwordProvider = StateProvider<String>((ref) => '');
final obscurePasswordProvider = StateProvider<bool>((ref) => true);

// ── Login status ─────────────────────────────────────────────────
enum LoginStatus { idle, loading, success, error }

class LoginState {
  final LoginStatus status;
  final String? errorMessage;

  const LoginState({this.status = LoginStatus.idle, this.errorMessage});

  LoginState copyWith({LoginStatus? status, String? errorMessage}) =>
      LoginState(status: status ?? this.status, errorMessage: errorMessage);
}

class LoginNotifier extends StateNotifier<LoginState> {
  LoginNotifier() : super(const LoginState());

  Future<void> login(AuthModel model) async {
    state = state.copyWith(status: LoginStatus.loading);
    try {
      // TODO: replace with real auth
      await Future.delayed(const Duration(seconds: 1));
      state = state.copyWith(status: LoginStatus.success);
    } catch (e) {
      state = state.copyWith(
        status: LoginStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  void reset() => state = const LoginState();
}

final loginProvider = StateNotifierProvider<LoginNotifier, LoginState>(
  (_) => LoginNotifier(),
);
