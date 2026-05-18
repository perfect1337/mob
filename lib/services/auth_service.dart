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

  Stream<fb_auth.User?> get authStateChanges => _auth.authStateChanges();

  Future<void> initialize() async {
    final fbUser = _auth.currentUser;
    if (fbUser != null) {
      await _loadUserFromFirestore(fbUser.uid);
    }
  }

  Future<void> _loadUserFromFirestore(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (doc.exists) {
      final data = doc.data()!;
      _currentUser = User(
        id: uid.hashCode,
        email: data['email'] ?? '',
        password: '',
        role: UserRole.fromString(data['role'] ?? 'UserRole.user'),
      );
    }
  }

  Future<bool> register(String email, String password, {UserRole role = UserRole.user}) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      await _firestore.collection('users').doc(cred.user!.uid).set({
        'email': email,
        'role': role.toString(),
        'createdAt': FieldValue.serverTimestamp(),
      });
      _currentUser = User(
        id: cred.user!.uid.hashCode,
        email: email,
        password: password,
        role: role,
      );
      return true;
    } on fb_auth.FirebaseAuthException {
      return false;
    }
  }

  Future<bool> login(String email, String password) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(email: email, password: password);
      await _loadUserFromFirestore(cred.user!.uid);
      return true;
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
        id: doc.id.hashCode,
        email: data['email'] ?? '',
        password: '',
        role: UserRole.fromString(data['role'] ?? 'UserRole.user'),
      );
    }).toList();
  }
}