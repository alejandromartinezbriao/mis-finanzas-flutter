import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Cache de perfil para eliminar latencia en operaciones de escritura
  Map<String, dynamic>? _userProfile;
  StreamSubscription? _profileSub;

  Stream<User?> get user => _auth.authStateChanges().map((user) {
    if (user == null) {
      _userProfile = null;
      _profileSub?.cancel();
    } else {
      _startProfileListener(user.uid);
    }
    return user;
  });

  void _startProfileListener(String uid) {
    _profileSub?.cancel();
    _profileSub = _db.collection('users').doc(uid).snapshots().listen((doc) {
      _userProfile = doc.data();
    });
  }

  // Getters instantáneos (Zero Latency)
  bool get isPremium => _userProfile?['isPremium'] == true;
  String? get familyId => _userProfile?['familyId'];

  Future<UserCredential?> signIn(String email, String password) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(email: email, password: password);
      if (cred.user != null) _startProfileListener(cred.user!.uid);
      return cred;
    } catch (e) {
      rethrow;
    }
  }

  Future<UserCredential?> signUp(String email, String password) async {
    try {
      return await _auth.createUserWithEmailAndPassword(email: email, password: password);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signOut() async {
    _userProfile = null;
    await _profileSub?.cancel();
    await _auth.signOut();
  }

  String? get currentUserUid => _auth.currentUser?.uid;
}
