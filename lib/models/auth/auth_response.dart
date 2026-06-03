import 'package:freezed_annotation/freezed_annotation.dart';
import 'user_model.dart';

part 'auth_response.freezed.dart';
part 'auth_response.g.dart';

@freezed
class AuthResponse with _$AuthResponse {
  const factory AuthResponse({
    required bool success,
    String? message,
    String? accessToken,
    String? refreshToken,
    UserModel? user,
  }) = _AuthResponse;

  factory AuthResponse.fromJson(Map<String, dynamic> json) => _$AuthResponseFromJson(json);
}
