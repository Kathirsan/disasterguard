import 'package:flutter/foundation.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  final AuthRepository _repository;

  AuthStatus _status = AuthStatus.initial;
  UserModel? _currentUser;
  String? _errorMessage;

  AuthProvider({AuthRepository? repository}) : _repository = repository ?? AuthRepository() {
    checkAuthStatus();
  }

  AuthStatus get status => _status;
  UserModel? get currentUser => _currentUser;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _status == AuthStatus.authenticated && _currentUser != null;

  void _setStatus(AuthStatus status, {String? error}) {
    _status = status;
    _errorMessage = error;
    notifyListeners();
  }

  Future<void> checkAuthStatus() async {
    _setStatus(AuthStatus.loading);
    try {
      final token = await _repository.getSavedToken();
      if (token != null && token.isNotEmpty) {
        final user = await _repository.getMe();
        if (user != null) {
          _currentUser = user;
          _setStatus(AuthStatus.authenticated);
          return;
        }
      }
      _currentUser = null;
      _setStatus(AuthStatus.unauthenticated);
    } catch (_) {
      _currentUser = null;
      _setStatus(AuthStatus.unauthenticated);
    }
  }

  Future<bool> login(String email, String password) async {
    _setStatus(AuthStatus.loading);
    try {
      final user = await _repository.login(email: email, password: password);
      _currentUser = user;
      _setStatus(AuthStatus.authenticated);
      return true;
    } catch (e) {
      _currentUser = null;
      _setStatus(AuthStatus.unauthenticated, error: e.toString());
      return false;
    }
  }

  Future<bool> register({
    required String fullName,
    required String email,
    required String password,
    required UserRole role,
  }) async {
    _setStatus(AuthStatus.loading);
    try {
      final user = await _repository.register(
        fullName: fullName,
        email: email,
        password: password,
        role: role,
      );
      _currentUser = user;
      _setStatus(AuthStatus.authenticated);
      return true;
    } catch (e) {
      _currentUser = null;
      _setStatus(AuthStatus.unauthenticated, error: e.toString());
      return false;
    }
  }

  Future<void> logout() async {
    await _repository.logout();
    _currentUser = null;
    _setStatus(AuthStatus.unauthenticated);
  }

  void clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }
}
