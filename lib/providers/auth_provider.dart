import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../models/user.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  String? _error;

  AuthProvider() {
    _init();
  }

  Future<void> _init() async {
    await _authService.initialize();
    notifyListeners();
  }

  User? get currentUser => _authService.currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _authService.isLoggedIn();

  Future<bool> register(String email, String password, {UserRole role = UserRole.user}) async {
    _setLoading(true);
    _clearError();
    final success = await _authService.register(email, password, role: role);
    _setLoading(false);
    if (!success) _setError('Email уже используется');
    notifyListeners();
    return success;
  }

  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _clearError();
    final success = await _authService.login(email, password);
    _setLoading(false);
    if (!success) _setError('Неверный email или пароль');
    notifyListeners();
    return success;
  }

  Future<void> logout() async {
    await _authService.logout();
    notifyListeners();
  }

  Future<List<User>> getAllUsers() async {
    return await _authService.getAllUsers();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }
}