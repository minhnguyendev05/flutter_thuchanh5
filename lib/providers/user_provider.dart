import 'package:expense_tracker_app/models/user_model.dart';
import 'package:expense_tracker_app/services/auth_service.dart';
import 'package:expense_tracker_app/services/local_service.dart';
import 'package:flutter/material.dart';

class UserProvider extends ChangeNotifier {
  UserProvider({AuthService? authService, LocalService? localService})
      : _authService = authService ?? AuthService(),
        _localService = localService ?? LocalService();

  final AuthService _authService;
  final LocalService _localService;

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _error;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> initialize() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentUser = await _localService.getUser();
    } catch (e) {
      _error = 'Cannot load user: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> signInWithGoogle() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final user = await _authService.signInWithGoogle();
      if (user == null) {
        _error = 'Google Sign-In bị hủy.';
        return false;
      }

      _currentUser = user;
      await _localService.saveUser(user);
      return true;
    } catch (e) {
      _error = 'Google Sign-In thất bại: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.signOut();
      await _localService.clearUser();
      _currentUser = null;
    } catch (e) {
      _error = 'Sign out thất bại: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
