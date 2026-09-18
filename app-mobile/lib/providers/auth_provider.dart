import 'dart:convert' show utf8;
import 'dart:math';
import 'package:crypto/crypto.dart' show sha256;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import '../models/user_model.dart';
import '../services/functions/user_service.dart';

// Web requires an explicit OAuth client ID; native platforms read it from
// google-services.json / GoogleService-Info.plist instead.
const _webGoogleClientId =
    '6748865044-5b0sbthk9abobn9t4not9e02sv91g209.apps.googleusercontent.com';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth      _auth   = FirebaseAuth.instance;
  final FirebaseFirestore _db     = FirebaseFirestore.instance;
  final GoogleSignIn      _google =
      GoogleSignIn(clientId: kIsWeb ? _webGoogleClientId : null);

  User?      _firebaseUser;
  UserModel? _userData;
  bool       _isLoading = true;
  String?    _error;

  User?      get firebaseUser => _firebaseUser;
  UserModel? get userData     => _userData;
  bool       get isLoading    => _isLoading;
  String?    get error        => _error;

  // ── Auth state convenience getters ────────────────────────────────────────

  /// True when any user is signed in (including anonymous guest).
  bool get isSignedIn  => _firebaseUser != null;

  /// True when signed in as anonymous guest (no real account).
  bool get isGuest     => _firebaseUser?.isAnonymous ?? false;

  /// True when signed in with a real (non-anonymous) account.
  bool get hasAccount  => isSignedIn && !isGuest;

  AuthProvider() {
    _auth.authStateChanges().listen(_onAuthStateChanged);
  }

  Future<void> _onAuthStateChanged(User? user) async {
    _firebaseUser = user;
    if (user != null && !user.isAnonymous) {
      await _fetchUserData(user.uid);
    } else if (user == null) {
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
      // If currently a guest, link the new account instead of creating fresh.
      UserCredential cred;
      if (isGuest && _firebaseUser != null) {
        final emailCred = EmailAuthProvider.credential(
            email: email, password: password);
        cred = await _firebaseUser!.linkWithCredential(emailCred);
      } else {
        cred = await _auth.createUserWithEmailAndPassword(
            email: email, password: password);
      }

      if (cred.user != null) {
        UserService.createUserMetadata(name: name, email: email, phone: phone)
            .catchError((Object e) {
          debugPrint('[AuthProvider] createUserMetadata: $e');
        });
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

  // ── Google Sign-In ────────────────────────────────────────────────────────

  /// Signs in with Google. If the user is currently a guest, links the
  /// Google account to their anonymous session (preserving any data).
  Future<bool> signInWithGoogle() async {
    _setLoading(true);
    try {
      final googleUser = await _google.signIn();
      if (googleUser == null) {
        // User cancelled the picker — not an error.
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken:     googleAuth.idToken,
      );

      UserCredential cred;
      if (isGuest && _firebaseUser != null) {
        // Upgrade guest → real account by linking Google credential.
        try {
          cred = await _firebaseUser!.linkWithCredential(credential);
        } on FirebaseAuthException catch (e) {
          // If Google account already exists, sign in directly.
          if (e.code == 'credential-already-in-use' ||
              e.code == 'email-already-in-use') {
            cred = await _auth.signInWithCredential(credential);
          } else {
            rethrow;
          }
        }
      } else {
        cred = await _auth.signInWithCredential(credential);
      }

      if (cred.user != null) {
        final name  = cred.user!.displayName ?? googleUser.displayName ?? '';
        final email = cred.user!.email       ?? googleUser.email;
        // Fire-and-forget — ignore errors silently; Firestore doc is best-effort.
        UserService.createUserMetadata(name: name, email: email, phone: '')
            .catchError((Object e) {
          debugPrint('[AuthProvider] Google createUserMetadata: $e');
        });
        await _fetchUserData(cred.user!.uid);
      }
      return true;
    } catch (e) {
      _error = _authMessage(e);
      _setLoading(false);
      return false;
    }
  }

  // ── Sign in with Apple ────────────────────────────────────────────────────

  /// Signs in with Apple. If the user is currently a guest, links the
  /// Apple credential to their anonymous session (preserving any data).
  Future<bool> signInWithApple() async {
    _setLoading(true);
    try {
      final rawNonce = _generateNonce();
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: sha256.convert(utf8.encode(rawNonce)).toString(),
      );

      final oauthCredential = OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        rawNonce: rawNonce,
        accessToken: appleCredential.authorizationCode,
      );

      UserCredential cred;
      if (isGuest && _firebaseUser != null) {
        try {
          cred = await _firebaseUser!.linkWithCredential(oauthCredential);
        } on FirebaseAuthException catch (e) {
          if (e.code == 'credential-already-in-use' ||
              e.code == 'email-already-in-use') {
            cred = await _auth.signInWithCredential(oauthCredential);
          } else {
            rethrow;
          }
        }
      } else {
        cred = await _auth.signInWithCredential(oauthCredential);
      }

      if (cred.user != null) {
        // Apple only returns the name on the *first* authorization ever —
        // fall back to whatever Firebase already has on subsequent sign-ins.
        final appleName = [
          appleCredential.givenName,
          appleCredential.familyName,
        ].where((s) => s != null && s.isNotEmpty).join(' ');
        final name  = cred.user!.displayName ?? appleName;
        final email = cred.user!.email ?? appleCredential.email ?? '';
        if (appleName.isNotEmpty && cred.user!.displayName == null) {
          await cred.user!.updateDisplayName(appleName);
        }
        UserService.createUserMetadata(name: name, email: email, phone: '')
            .catchError((Object e) {
          debugPrint('[AuthProvider] Apple createUserMetadata: $e');
        });
        await _fetchUserData(cred.user!.uid);
      }
      return true;
    } on SignInWithAppleAuthorizationException catch (e) {
      _isLoading = false;
      // User cancelled the sheet — not an error.
      if (e.code != AuthorizationErrorCode.canceled) {
        _error = 'Apple sign-in failed. Please try again.';
      }
      notifyListeners();
      return false;
    } catch (e) {
      _error = _authMessage(e);
      _setLoading(false);
      return false;
    }
  }

  /// Cryptographically secure random nonce for the Apple sign-in request,
  /// hashed with SHA-256 before being sent — required so Firebase can
  /// verify the ID token was issued for *this* request, not replayed.
  String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)])
        .join();
  }

  // ── Guest (anonymous) sign-in ─────────────────────────────────────────────

  /// Signs in anonymously so the user can explore without registering.
  /// If already signed in as guest, does nothing and returns true.
  Future<bool> signInAsGuest() async {
    if (isGuest) return true;
    _setLoading(true);
    try {
      await _auth.signInAnonymously();
      return true;
    } catch (e) {
      _error = _authMessage(e);
      _setLoading(false);
      return false;
    }
  }

  // ── Sign out ──────────────────────────────────────────────────────────────

  Future<void> signOut() async {
    try { await _google.signOut(); } catch (_) {}
    await _auth.signOut();
  }

  // ── Password reset ────────────────────────────────────────────────────────

  Future<bool> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return true;
    } catch (e) {
      _error = _authMessage(e);
      return false;
    }
  }

  // ── Profile update ────────────────────────────────────────────────────────

  Future<bool> updateProfile({
    required String name,
    String? phone,
  }) async {
    if (_firebaseUser == null) return false;
    _setLoading(true);
    try {
      await _firebaseUser!.updateDisplayName(name);
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
  Future<void> deleteAccount() async {
    if (_firebaseUser == null) return;
    try {
      await UserService.deleteAccount();
    } catch (e) {
      debugPrint('[AuthProvider] deleteAccount: $e');
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void _setLoading(bool v) {
    _isLoading = v;
    _error = null;
    notifyListeners();
  }

  String _authMessage(Object e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'user-not-found':        return 'No account found with that email.';
        case 'wrong-password':        return 'Incorrect password.';
        case 'invalid-credential':    return 'Invalid email or password.';
        case 'email-already-in-use':  return 'That email is already registered.';
        case 'weak-password':         return 'Password must be at least 6 characters.';
        case 'invalid-email':         return 'Please enter a valid email address.';
        case 'too-many-requests':     return 'Too many attempts. Try again later.';
        case 'operation-not-allowed':
        case 'admin-restricted-operation':
          return 'This sign-in method is not enabled. Please contact support.';
        case 'account-exists-with-different-credential':
          return 'An account already exists with this email. Try signing in differently.';
        default: return e.message ?? 'Authentication error.';
      }
    } else if (e is PlatformException) {
      // Google Sign-In PlatformExceptions
      switch (e.code) {
        case 'sign_in_failed':
          // Code 10 = SHA-1 fingerprint not registered in Firebase Console
          final msg = e.message ?? '';
          if (msg.contains('10:') || msg.contains('DEVELOPER_ERROR')) {
            return 'Google Sign-In is not configured for this device. Please try email sign-in.';
          }
          return 'Google Sign-In failed. Check your internet connection.';
        case 'network_error':
          return 'No internet connection. Please check your network.';
        case 'sign_in_canceled':
          return ''; // Silent — user cancelled
        default:
          return e.message ?? 'Google sign-in error.';
      }
    } else if (e is FirebaseException) {
      return e.message ?? 'Firebase error occurred.';
    }
    return e.toString();
  }
}
