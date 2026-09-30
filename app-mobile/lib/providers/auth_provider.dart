import 'dart:convert' show utf8;
import 'dart:math';
import 'package:crypto/crypto.dart' show sha256;
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
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

// iOS OAuth client (CLIENT_ID in GoogleService-Info.plist). Passed explicitly
// so sign-in never depends on the plist being bundled — without a client ID
// the native GoogleSignIn SDK raises an uncatchable NSException and the app
// crashes the moment the Google button is tapped.
const _iosGoogleClientId =
    '6748865044-i5lbfm7rf493b19u2f3b3k5n7f6mi6pp.apps.googleusercontent.com';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth      _auth   = FirebaseAuth.instance;
  final FirebaseFirestore _db     = FirebaseFirestore.instance;
  // On Android, serverClientId (the *web* OAuth client) is what makes the
  // native picker return an idToken that Firebase Auth can verify.
  final GoogleSignIn      _google = GoogleSignIn(
    clientId:       kIsWeb
        ? _webGoogleClientId
        : (defaultTargetPlatform == TargetPlatform.iOS ? _iosGoogleClientId : null),
    serverClientId: kIsWeb ? null : _webGoogleClientId,
    scopes: const ['email', 'profile'],
  );

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
  /// Google account to their anonymous session (preserving any data). If
  /// that Google account already exists, signs into it and carries the
  /// guest's cart across so nothing added before sign-in is lost.
  ///
  /// Web uses Firebase's own popup flow (the google_sign_in v6 web plugin
  /// no longer returns an idToken). Android/iOS use the native account
  /// picker; `serverClientId` makes Android return an idToken Firebase can
  /// verify.
  Future<bool> signInWithGoogle() async {
    _setLoading(true);
    try {
      final cred = kIsWeb ? await _googleWeb() : await _googleNative();
      if (cred == null) {
        // User cancelled the picker/popup — not an error.
        _isLoading = false;
        notifyListeners();
        return false;
      }

      if (cred.user != null) {
        final name  = cred.user!.displayName ?? '';
        final email = cred.user!.email ?? '';
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

  Future<UserCredential?> _googleWeb() async {
    final provider = GoogleAuthProvider()
      ..setCustomParameters({'prompt': 'select_account'});
    final guest = isGuest ? _firebaseUser : null;
    if (guest == null) return _auth.signInWithPopup(provider);
    try {
      return await guest.linkWithPopup(provider);
    } on FirebaseAuthException catch (e) {
      if ((e.code == 'credential-already-in-use' ||
              e.code == 'email-already-in-use') &&
          e.credential != null) {
        return _switchFromGuest(guest, e.credential!);
      }
      rethrow;
    }
  }

  Future<UserCredential?> _googleNative() async {
    // Always show the account chooser rather than silently reusing the
    // last account (matters on shared family phones).
    try { await _google.signOut(); } catch (_) {}
    final googleUser = await _google.signIn();
    if (googleUser == null) return null;

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken:     googleAuth.idToken,
    );

    final guest = isGuest ? _firebaseUser : null;
    if (guest == null) return _auth.signInWithCredential(credential);
    try {
      return await guest.linkWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'credential-already-in-use' ||
          e.code == 'email-already-in-use') {
        return _switchFromGuest(guest, e.credential ?? credential);
      }
      rethrow;
    }
  }

  /// The guest's Google/Apple account already exists: sign into it, then
  /// copy the guest cart over (carts are owner-only, so it must be read
  /// before switching uid).
  Future<UserCredential> _switchFromGuest(
      User guest, AuthCredential credential) async {
    List<QueryDocumentSnapshot<Map<String, dynamic>>> guestItems = const [];
    try {
      guestItems = (await _db
              .collection('carts').doc(guest.uid).collection('items').get())
          .docs;
    } catch (e) {
      debugPrint('[AuthProvider] read guest cart: $e');
    }

    final cred = await _auth.signInWithCredential(credential);
    final uid = cred.user?.uid;
    if (uid != null && guestItems.isNotEmpty) {
      try {
        final items = _db.collection('carts').doc(uid).collection('items');
        for (final doc in guestItems) {
          final ref = items.doc(doc.id);
          final existing = await ref.get();
          final data = Map<String, dynamic>.from(doc.data());
          if (existing.exists) {
            final prevQty = ((existing.data()?['quantity'] ?? 0) as num).toInt();
            final addQty  = ((data['quantity'] ?? 1) as num).toInt();
            data['quantity'] = prevQty + addQty;
          }
          data['updatedAt'] = FieldValue.serverTimestamp();
          await ref.set(data, SetOptions(merge: true));
        }
      } catch (e) {
        debugPrint('[AuthProvider] carry guest cart: $e');
      }
    }
    return cred;
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
            cred = await _switchFromGuest(
                _firebaseUser!, e.credential ?? oauthCredential);
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

  /// Permanently deletes the account and its data server-side, then signs
  /// out locally. Returns false (with [error] set) if anything failed, so the
  /// UI never tells the user their account is gone when it isn't.
  ///
  /// Sign in with Apple users are asked to re-authorize first so the Apple
  /// token can be revoked — required by App Store guideline 5.1.1(v).
  Future<bool> deleteAccount() async {
    final user = _firebaseUser;
    if (user == null) return false;
    _setLoading(true);
    try {
      final usesApple = user.providerData.any((p) => p.providerId == 'apple.com');
      if (usesApple && !kIsWeb) {
        final appleCredential = await SignInWithApple.getAppleIDCredential(scopes: []);
        await _auth.revokeTokenWithAuthorizationCode(appleCredential.authorizationCode);
      }

      await UserService.deleteAccount();

      try { await _google.signOut(); } catch (_) {}
      await _auth.signOut();
      _userData = null;
      _isLoading = false;
      notifyListeners();
      return true;
    } on SignInWithAppleAuthorizationException catch (e) {
      _error = e.code == AuthorizationErrorCode.canceled
          ? 'Apple re-authorization is required to delete your account.'
          : 'Apple re-authorization failed. Please try again.';
      _setLoading(false);
      return false;
    } catch (e) {
      debugPrint('[AuthProvider] deleteAccount: $e');
      _error = 'We couldn\'t delete your account. Please try again, or email '
          'info@sunnahgrandeur.us and we\'ll delete it for you.';
      _setLoading(false);
      return false;
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void _setLoading(bool v) {
    _isLoading = v;
    // Only clear the previous error when starting a new operation — failure
    // paths set _error and then call _setLoading(false), which must keep it.
    if (v) _error = null;
    notifyListeners();
  }

  String _authMessage(Object e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'user-not-found':        return 'No account found with that email. Create one instead?';
        case 'wrong-password':        return 'That password is incorrect. Try again or reset it.';
        case 'invalid-credential':
        case 'invalid-login-credentials':
          return 'Email or password is incorrect. Please check and try again.';
        case 'user-disabled':         return 'This account has been disabled. Contact support.';
        case 'network-request-failed':return 'No internet connection. Please check your network.';
        case 'popup-closed-by-user':
        case 'cancelled-popup-request':
        case 'web-context-canceled':
          return ''; // Silent — user closed the Google popup
        case 'popup-blocked':
          return 'Your browser blocked the sign-in popup. Allow popups and try again.';
        case 'unauthorized-domain':
          return 'Google sign-in is not enabled on this web address yet.';
        case 'email-already-in-use':  return 'That email is already registered.';
        case 'weak-password':         return 'Password must be at least 6 characters.';
        case 'invalid-email':         return 'Please enter a valid email address.';
        case 'too-many-requests':     return 'Too many attempts. Try again later.';
        case 'operation-not-allowed':
        case 'admin-restricted-operation':
          return 'This sign-in method is not enabled. Please contact support.';
        case 'account-exists-with-different-credential':
          return 'An account already exists with this email. Try signing in differently.';
        default: return 'Sign-in failed (${e.code}). Please try again.';
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
          return 'Google sign-in failed. Please try again.';
      }
    } else if (e is FirebaseException) {
      return 'Something went wrong. Please try again.';
    }
    debugPrint('[AuthProvider] unexpected: $e');
    return 'Something went wrong. Please try again.';
  }
}
