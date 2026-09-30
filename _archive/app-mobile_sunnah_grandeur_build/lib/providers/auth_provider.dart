import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../services/functions/user_service.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth      _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db   = FirebaseFirestore.instance;

  User?      _firebaseUser;
  UserModel? _userData;
  bool       _isLoading = true;
  String?    _error;

  User?      get firebaseUser => _firebaseUser;
  UserModel? get userData     => _userData;
  bool       get isLoading    => _isLoading;
  String?    get error        => _error;

  AuthProvider() {
    _auth.authStateChanges().listen(_onAuthStateChanged);
  }

  Future<void> _onAuthStateChanged(User? user) async {
    _firebaseUser = user;
    if (user != null) {
      await _fetchUserData(user.uid);
    } else {
      _userData = null;
    }
    _isLoading = false;
    notifyListeners();
  }

  // Direct Firestore read — rules allow owner to read their own document.
  Future<void> _fetchUserData(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (doc.exists) {
        _userData = UserModel.fromMap(doc.data()!, doc.id);
      } else {
        // Firestore doc not yet created (CF pending) — synthesize from Auth data
        // so the UI never shows "Guest User" for a logged-in account.
        final email       = _firebaseUser?.email       ?? '';
        final displayName = _firebaseUser?.displayName ?? '';
        _userData = UserModel(
          id:    uid,
          email: email,
          name:  displayName.isNotEmpty ? displayName : email.split('@').first,
          phone: '',
        );
      }
    } catch (e) {
      debugPrint('[AuthProvider] fetchUserData: $e');
    }
  }

  // ── Auth operations ───────────────────────────────────────────────────────

  Future<bool> signIn({required String email, required String password}) async {
    _setLoading(true);
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return true;
    } catch (e) {
      _error = _authMessage(e);
      _setLoading(false);
      return false;
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
    String phone = '',
  }) async {
    _setLoading(true);
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email, password: password,
      );
      if (cred.user != null) {
        // Fire-and-forget — registration succeeds even if CF not yet deployed.
        // The CF sets role:'user' server-side; client never controls this field.
        UserService.createUserMetadata(name: name, email: email, phone: phone)
            .catchError((e) => debugPrint('[AuthProvider] createUserMetadata: $e'));
        await _fetchUserData(cred.user!.uid);
        return true;
      }
      return false;
    } catch (e) {
      _error = _authMessage(e);
      _setLoading(false);
      return false;
    }
  }

  Future<void> signOut() => _auth.signOut();

  Future<bool> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return true;
    } catch (e) {
      _error = _authMessage(e);
      return false;
    }
  }

  Future<bool> updateProfile({
    required String name,
    String? phone,
  }) async {
    if (_firebaseUser == null) return false;
    _setLoading(true);
    try {
      // Display name update lives in Firebase Auth
      await _firebaseUser!.updateDisplayName(name);

      // Profile fields update via Cloud Function (whitelist-only, no role access)
      await UserService.updateUserProfile(name: name, phone: phone);

      await _fetchUserData(_firebaseUser!.uid);
      _setLoading(false);
      return true;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return false;
    }
  }

  /// Deletes account server-side via Cloud Function.
  /// Never write directly to /users/{uid} from the client for deletion.
  Future<void> deleteAccount() async {
    if (_firebaseUser == null) return;
    try {
      await UserService.deleteAccount();
    } catch (e) {
      debugPrint('[AuthProvider] deleteAccount: $e');
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  void _setLoading(bool v) {
    _isLoading = v;
    _error = null;
    notifyListeners();
  }

  String _authMessage(Object e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'user-not-found':     return 'No account found with that email.';
        case 'wrong-password':     return 'Incorrect password.';
        case 'email-already-in-use': return 'That email is already registered.';
        case 'weak-password':      return 'Password must be at least 6 characters.';
        case 'invalid-email':      return 'Please enter a valid email address.';
        case 'too-many-requests':  return 'Too many attempts. Try again later.';
        default:                   return e.message ?? 'Authentication error.';
      }
    }
    return e.toString();
  }
}
