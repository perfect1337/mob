import '../models/user.dart';
import 'database_service.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  User? _currentUser;
  final DatabaseService _dbService = DatabaseService();

  User? get currentUser => _currentUser;

  Future<void> initialize() async {
    // Инициализация базы данных
    await _dbService.database;
  }

  Future<bool> register(String email, String password, {UserRole role = UserRole.user}) async {
    try {
      if (await _dbService.emailExists(email)) {
        return false;
      }

      final newUser = User(email: email, password: password, role: role);
      await _dbService.insertUser(newUser);

      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> login(String email, String password) async {
    try {
      final user = await _dbService.getUser(email, password);

      if (user != null) {
        _currentUser = user;
        return true;
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  Future<void> logout() async {
    _currentUser = null;
  }

  bool isLoggedIn() {
    return _currentUser != null;
  }

  Future<List<User>> getAllUsers() async {
    return await _dbService.getAllUsers();
  }
}