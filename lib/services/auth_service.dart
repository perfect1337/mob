import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  // Список зарегистрированных пользователей
  List<User> _registeredUsers = [];

  // Текущий авторизованный пользователь
  User? _currentUser;

  // Ключи для SharedPreferences
  static const String _usersKey = 'registered_users';
  static const String _currentUserKey = 'current_user';

  // Getter для списка пользователей
  List<User> get registeredUsers => _registeredUsers;

  // Getter для текущего пользователя
  User? get currentUser => _currentUser;

  // Инициализация - загрузка данных из SharedPreferences
  Future<void> initialize() async {
    await _loadUsers();
    await _loadCurrentUser();
  }

  // Загрузка пользователей из SharedPreferences
  Future<void> _loadUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final String? usersJson = prefs.getString(_usersKey);
    
    if (usersJson != null) {
      final List<dynamic> usersList = jsonDecode(usersJson);
      _registeredUsers = usersList
          .map((json) => User.fromJson(json as Map<String, dynamic>))
          .toList();
    }
  }

  // Сохранение пользователей в SharedPreferences
  Future<void> _saveUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final List<Map<String, dynamic>> usersJson =
        _registeredUsers.map((user) => user.toJson()).toList();
    await prefs.setString(_usersKey, jsonEncode(usersJson));
  }

  // Загрузка текущего пользователя из SharedPreferences
  Future<void> _loadCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final String? currentUserJson = prefs.getString(_currentUserKey);
    
    if (currentUserJson != null) {
      final Map<String, dynamic> userMap = jsonDecode(currentUserJson);
      _currentUser = User.fromJson(userMap);
    }
  }

  // Сохранение текущего пользователя в SharedPreferences
  Future<void> _saveCurrentUser(User? user) async {
    final prefs = await SharedPreferences.getInstance();
    
    if (user != null) {
      await prefs.setString(_currentUserKey, jsonEncode(user.toJson()));
    } else {
      await prefs.remove(_currentUserKey);
    }
  }

  // Регистрация нового пользователя
  Future<bool> register(String email, String password) async {
    // Проверяем, не существует ли уже пользователь с таким email
    if (_registeredUsers.any((user) => user.email == email)) {
      return false;
    }

    // Добавляем нового пользователя
    final newUser = User(email: email, password: password);
    _registeredUsers.add(newUser);
    
    // Сохраняем в SharedPreferences
    await _saveUsers();
    
    return true;
  }

  // Авторизация пользователя
  Future<bool> login(String email, String password) async {
    try {
      // Ищем пользователя с указанным email и паролем
      _currentUser = _registeredUsers.firstWhere(
        (user) => user.email == email && user.password == password,
      );
      
      // Сохраняем текущего пользователя в SharedPreferences
      await _saveCurrentUser(_currentUser);
      
      return true;
    } catch (e) {
      return false;
    }
  }

  // Выход из аккаунта
  Future<void> logout() async {
    _currentUser = null;
    await _saveCurrentUser(null);
  }

  // Проверка, авторизован ли пользователь
  bool isLoggedIn() {
    return _currentUser != null;
  }
}
