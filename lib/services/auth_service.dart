import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import '../models/user.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  User? _currentUser;
  final _auth = fb_auth.FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  User? get currentUser => _currentUser;

  Future<void> initialize() async {}

  Future<bool> register(String email, String password, {UserRole role = UserRole.user}) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      await _firestore.collection('users').doc(cred.user!.uid).set({
        'email': email, 'password': password, 'role': role.toString(),
        'createdAt': FieldValue.serverTimestamp(),
      });
      return true;
    } on fb_auth.FirebaseAuthException {
      return false;
    }
  }

  Future<bool> login(String email, String password) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(email: email, password: password);
      final doc = await _firestore.collection('users').doc(cred.user!.uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        _currentUser = User(
          id: cred.user!.uid.hashCode, email: data['email'] ?? email,
          password: password, role: UserRole.fromString(data['role'] ?? 'UserRole.user'),
        );
        return true;
      }
      return false;
    } on fb_auth.FirebaseAuthException {
      return false;
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
    _currentUser = null;
  }

  bool isLoggedIn() => _currentUser != null;

  Future<List<User>> getAllUsers() async {
    final snapshot = await _firestore.collection('users').get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      return User(
        id: doc.id.hashCode, email: data['email'] ?? '',
        password: data['password'] ?? '', role: UserRole.fromString(data['role'] ?? 'UserRole.user'),
      );
    }).toList();
  }
}