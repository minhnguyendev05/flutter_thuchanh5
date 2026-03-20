import 'package:expense_tracker_app/models/user_model.dart';
import 'package:expense_tracker_app/services/auth_service.dart';
import 'package:expense_tracker_app/services/local_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

  String _friendlyAuthError(Object error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'invalid-email':
          return 'Email không đúng định dạng.';
        case 'user-not-found':
          return 'Không tìm thấy tài khoản với email này.';
        case 'wrong-password':
        case 'invalid-credential':
          return 'Email hoặc mật khẩu không đúng.';
        case 'email-already-in-use':
          return 'Email này đã được đăng ký.';
        case 'weak-password':
          return 'Mật khẩu quá yếu, vui lòng dùng tối thiểu 6 ký tự.';
        case 'too-many-requests':
          return 'Bạn thao tác quá nhiều lần. Vui lòng thử lại sau.';
        case 'network-request-failed':
          return 'Không có kết nối mạng. Vui lòng kiểm tra Internet.';
        case 'popup-closed-by-user':
          return 'Bạn đã đóng cửa sổ đăng nhập.';
        default:
          return 'Xác thực thất bại. Vui lòng thử lại.';
      }
    }

    return 'Đã xảy ra lỗi. Vui lòng thử lại.';
  }

  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void clearError() {
    if (_error == null) {
      return;
    }

    _error = null;
    notifyListeners();
  }

  Future<void> initialize() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final authUser = _authService.getCurrentUser();
      if (authUser != null) {
        _currentUser = authUser;
        await _localService.saveUser(authUser);
      } else {
        _currentUser = await _localService.getUser();
      }
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
      _error = _friendlyAuthError(e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final user = await _authService.signInWithEmailPassword(
        email: email,
        password: password,
      );
      if (user == null) {
        _error = 'Đăng nhập thất bại.';
        return false;
      }

      _currentUser = user;
      await _localService.saveUser(user);
      return true;
    } catch (e) {
      _error = _friendlyAuthError(e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> registerWithEmailPassword({
    required String name,
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final user = await _authService.registerWithEmailPassword(
        email: email,
        password: password,
        displayName: name,
      );
      if (user == null) {
        _error = 'Đăng ký thất bại.';
        return false;
      }

      _currentUser = user;
      await _localService.saveUser(user);
      return true;
    } catch (e) {
      _error = _friendlyAuthError(e);
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
