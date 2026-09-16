import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/local_storage_service.dart';
import '../services/notification_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final LocalStorageService _storage = LocalStorageService();
  final NotificationService _notificationService = NotificationService();

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  bool get isOrganizer => _currentUser?.isOrganizer ?? false;
  bool get isUser => _currentUser?.isUser ?? false;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Check auto-login session
  Future<bool> checkAuthStatus() async {
    _isLoading = true;
    notifyListeners();

    try {
      final savedUser = _storage.getSavedUser();
      if (savedUser != null) {
        // Refresh user from server if available, fallback to saved session
        try {
          final refreshedUser = await _authService.getUserById(savedUser.id);
          _currentUser = refreshedUser;
          await _storage.saveUserSession(refreshedUser);
        } catch (_) {
          _currentUser = savedUser;
        }
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      _errorMessage = e.toString();
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  // Login
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await _authService.login(
        email: email,
        password: password,
      );
      _currentUser = user;
      await _storage.saveUserSession(user);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Register
  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String role,
    String? profileImage,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await _authService.register(
        name: name,
        email: email,
        password: password,
        phone: phone,
        role: role,
        profileImage: profileImage,
      );

      _currentUser = user;
      await _storage.saveUserSession(user);

      // Send welcome notification
      await _notificationService.showWelcomeNotification(userName: user.name);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Update Profile
  Future<bool> updateProfile({
    required String name,
    required String phone,
    String? profileImage,
    String? newPassword,
  }) async {
    if (_currentUser == null) return false;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updatedUser = await _authService.updateProfile(
        userId: _currentUser!.id,
        name: name,
        phone: phone,
        profileImage: profileImage,
        newPassword: newPassword,
      );

      _currentUser = updatedUser;
      await _storage.saveUserSession(updatedUser);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Upgrade role to Organizer
  Future<bool> becomeOrganizer() async {
    if (_currentUser == null) return false;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updatedUser = await _authService.changeRole(
        userId: _currentUser!.id,
        newRole: 'Organizer',
      );

      _currentUser = updatedUser;
      await _storage.saveUserSession(updatedUser);

      // Notification
      await _notificationService.showEventUpdateNotification(
        eventName: 'Account Upgraded',
        updateMessage: 'Congratulations! You are now an Event Organizer on EventHub.',
      );

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Logout
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    await _storage.clearUserSession();
    _currentUser = null;
    _errorMessage = null;
    _isLoading = false;
    notifyListeners();
  }
}
