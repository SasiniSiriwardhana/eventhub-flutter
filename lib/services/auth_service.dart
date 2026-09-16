import '../models/user_model.dart';
import 'api_service.dart';

class AuthService {
  final ApiService _apiService = ApiService();

  // Register a new user
  Future<UserModel> register({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String role,
    String? profileImage,
  }) async {
    // 1. Check if user already exists
    final existingUsers = await _apiService.get(
      '/users',
      queryParameters: {'email': email.trim().toLowerCase()},
    );

    if (existingUsers is List && existingUsers.isNotEmpty) {
      throw ApiException(
        message: 'An account with this email address already exists.',
        statusCode: 409,
      );
    }

    // 2. Create user payload
    final newId = 'u_${DateTime.now().millisecondsSinceEpoch}';
    final userPayload = {
      'id': newId,
      'name': name.trim(),
      'email': email.trim().toLowerCase(),
      'password': password,
      'phone': phone.trim(),
      'role': role,
      'profileImage': profileImage ??
          'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=400&auto=format&fit=crop&q=80',
      'createdAt': DateTime.now().toIso8601String(),
    };

    final response = await _apiService.post('/users', data: userPayload);
    if (response is Map<String, dynamic>) {
      return UserModel.fromJson(response);
    }
    throw ApiException(message: 'Failed to create user account.');
  }

  // Login with email and password
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    final response = await _apiService.get(
      '/users',
      queryParameters: {'email': email.trim().toLowerCase()},
    );

    if (response is List) {
      if (response.isEmpty) {
        throw ApiException(
          message: 'No account found with this email address.',
          statusCode: 404,
        );
      }

      final userData = response.first as Map<String, dynamic>;
      final storedPassword = userData['password'] as String?;

      if (storedPassword != password) {
        throw ApiException(
          message: 'Incorrect password. Please try again.',
          statusCode: 401,
        );
      }

      return UserModel.fromJson(userData);
    }

    throw ApiException(message: 'Invalid response from authentication server.');
  }

  // Update profile
  Future<UserModel> updateProfile({
    required String userId,
    required String name,
    required String phone,
    String? profileImage,
    String? newPassword,
  }) async {
    // Fetch current user data first
    final currentUserData = await _apiService.get('/users/$userId');
    if (currentUserData is! Map<String, dynamic>) {
      throw ApiException(message: 'User not found.');
    }

    final updatedPayload = Map<String, dynamic>.from(currentUserData);
    updatedPayload['name'] = name.trim();
    updatedPayload['phone'] = phone.trim();
    if (profileImage != null && profileImage.isNotEmpty) {
      updatedPayload['profileImage'] = profileImage;
    }
    if (newPassword != null && newPassword.isNotEmpty) {
      updatedPayload['password'] = newPassword;
    }

    final response = await _apiService.put(
      '/users/$userId',
      data: updatedPayload,
    );

    if (response is Map<String, dynamic>) {
      return UserModel.fromJson(response);
    }
    throw ApiException(message: 'Failed to update user profile.');
  }

  // Change Role (e.g. from User to Organizer)
  Future<UserModel> changeRole({
    required String userId,
    required String newRole,
  }) async {
    final currentUserData = await _apiService.get('/users/$userId');
    if (currentUserData is! Map<String, dynamic>) {
      throw ApiException(message: 'User not found.');
    }

    final updatedPayload = Map<String, dynamic>.from(currentUserData);
    updatedPayload['role'] = newRole;

    final response = await _apiService.put(
      '/users/$userId',
      data: updatedPayload,
    );

    if (response is Map<String, dynamic>) {
      return UserModel.fromJson(response);
    }
    throw ApiException(message: 'Failed to update user role.');
  }

  // Get user by ID
  Future<UserModel> getUserById(String userId) async {
    final response = await _apiService.get('/users/$userId');
    if (response is Map<String, dynamic>) {
      return UserModel.fromJson(response);
    }
    throw ApiException(message: 'User not found.');
  }
}
