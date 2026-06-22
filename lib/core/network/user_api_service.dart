import 'dart:io';
import 'package:dio/dio.dart';
import '../../models/auth/user_model.dart';
import 'auth_api_service.dart';
import 'api_client.dart';

/// Service class containing all backend user profile endpoints.
class UserApiService {
  UserApiService._internal();
  static final UserApiService instance = UserApiService._internal();

  final Dio _dio = ApiClient.instance.dio;

  /// Helper to extract server-provided error messages or throw generic ones.
  String handleError(dynamic error) {
    return AuthApiService.instance.handleError(error);
  }

  /// GET /users/me
  /// Retrieve currently authorized user profile
  Future<UserModel> getProfile() async {
    try {
      final response = await _dio.get('/users/me');
      if (response.data['success'] == true && response.data['profile'] != null) {
        return UserModel.fromJson(response.data['profile']);
      }
      throw Exception('Failed to load profile');
    } catch (e) {
      throw handleError(e);
    }
  }

  /// PUT /users/me/name
  /// Update profile first and last names
  Future<UserModel> updateName({required String firstName, required String lastName}) async {
    try {
      final response = await _dio.put(
        '/users/me/name',
        data: {'firstName': firstName, 'lastName': lastName},
      );
      if (response.data['success'] == true && response.data['profile'] != null) {
        return UserModel.fromJson(response.data['profile']);
      }
      throw Exception('Failed to update name');
    } catch (e) {
      throw handleError(e);
    }
  }

  /// PUT /users/me/email
  /// Initiate email update. Sends 6-digit OTP code to new address
  Future<String> requestEmailChange(String newEmail) async {
    try {
      final response = await _dio.put(
        '/users/me/email',
        data: {'email': newEmail},
      );
      return response.data['message'] ?? 'Verification code sent';
    } catch (e) {
      throw handleError(e);
    }
  }

  /// POST /users/me/email/confirm
  /// Confirm pending email change using the OTP code sent
  Future<UserModel> confirmEmailChange({required String email, required String code}) async {
    try {
      final response = await _dio.post(
        '/users/me/email/confirm',
        data: {'email': email, 'code': code},
      );
      if (response.data['success'] == true && response.data['user'] != null) {
        return UserModel.fromJson(response.data['user']);
      }
      throw Exception('Failed to confirm email change');
    } catch (e) {
      throw handleError(e);
    }
  }

  /// PUT /users/me/password
  /// Upgrade user account password
  Future<String> changePassword({required String currentPassword, required String newPassword}) async {
    try {
      final response = await _dio.put(
        '/users/me/password',
        data: {'currentPassword': currentPassword, 'newPassword': newPassword},
      );
      return response.data['message'] ?? 'Password updated successfully';
    } catch (e) {
      throw handleError(e);
    }
  }

  /// PUT /users/me/profile-picture/local-upload
  /// Upload profile picture locally
  Future<String> uploadProfilePictureLocal(File imageFile, String fileName) async {
    try {
      // 1. Get the upload url/key parameters
      String mimeType = 'image/jpeg';
      final ext = fileName.split('.').last.toLowerCase();
      if (ext == 'png') mimeType = 'image/png';
      
      final urlResponse = await _dio.get(
        '/users/me/profile-picture/upload-url',
        queryParameters: {
          'fileName': fileName,
          'mimeType': mimeType,
        },
      );
      
      if (urlResponse.data['success'] != true) {
        throw Exception('Failed to get upload parameters');
      }
      
      final fileKey = urlResponse.data['fileKey'];
      
      // 2. Upload the binary data using the local endpoint
      final uploadResponse = await _dio.put(
        '/users/me/profile-picture/local-upload',
        queryParameters: {'key': fileKey},
        data: await imageFile.readAsBytes(),
        options: Options(
          headers: {
            'Content-Type': 'application/octet-stream',
          },
        ),
      );
      
      if (uploadResponse.data['success'] == true) {
        return uploadResponse.data['fileUrl'] ?? '';
      }
      throw Exception('Failed to upload picture');
    } catch (e) {
      throw handleError(e);
    }
  }

  /// DELETE /users/me
  /// Delete currently authorized user account
  Future<void> deleteAccount() async {
    try {
      final response = await _dio.delete('/users/me');
      if (response.data['success'] != true) {
        throw Exception('Failed to delete account');
      }
    } catch (e) {
      throw handleError(e);
    }
  }
}
