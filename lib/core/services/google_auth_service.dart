import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../firebase_options.dart';

class GoogleAuthResult {
  const GoogleAuthResult({
    required this.idToken,
    required this.email,
    required this.displayName,
    this.photoUrl,
  });

  final String idToken;
  final String email;
  final String displayName;
  final String? photoUrl;
}

class GoogleAuthService {
  GoogleAuthService._();

  /// Web OAuth client from Firebase (used as serverClientId for ID tokens).
  static const String serverClientId =
      '536954543355-0gacrbhba0pinid2v15n5f9b8t18apfv.apps.googleusercontent.com';

  static bool _googleReady = false;
  static bool _firebaseReady = false;

  static Future<void> bootstrap() async {
    await _ensureFirebase();
    await _ensureGoogleSignIn();
  }

  static Future<void> _ensureFirebase() async {
    if (_firebaseReady || Firebase.apps.isNotEmpty) {
      _firebaseReady = true;
      return;
    }
    if (kIsWeb) return;
    if (defaultTargetPlatform != TargetPlatform.android) return;
    try {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.android);
      _firebaseReady = true;
    } catch (e) {
      debugPrint('Firebase init skipped: $e');
    }
  }

  static Future<void> _ensureGoogleSignIn() async {
    if (_googleReady) return;
    await GoogleSignIn.instance.initialize(serverClientId: serverClientId);
    _googleReady = true;
  }

  /// Interactive Google sign-in via Firebase Auth when available.
  static Future<GoogleAuthResult> signIn() async {
    await bootstrap();

    if (!GoogleSignIn.instance.supportsAuthenticate()) {
      throw StateError('Google Sign-In is not supported on this platform.');
    }

    final account = await GoogleSignIn.instance.authenticate();
    final idToken = account.authentication.idToken;
    if (idToken == null || idToken.isEmpty) {
      throw StateError(
        'Google did not return an ID token. Add your Android SHA-1 in Firebase.',
      );
    }

    if (Firebase.apps.isNotEmpty) {
      final credential = GoogleAuthProvider.credential(idToken: idToken);
      await FirebaseAuth.instance.signInWithCredential(credential);
    }

    final email = account.email.trim();
    if (email.isEmpty) {
      throw StateError('Google account has no email address.');
    }

    return GoogleAuthResult(
      idToken: idToken,
      email: email,
      displayName: (account.displayName ?? '').trim().isEmpty
          ? email.split('@').first
          : account.displayName!.trim(),
      photoUrl: account.photoUrl,
    );
  }

  static Future<void> signOut() async {
    try {
      if (_googleReady) await GoogleSignIn.instance.signOut();
    } catch (_) {}
    try {
      if (Firebase.apps.isNotEmpty) await FirebaseAuth.instance.signOut();
    } catch (_) {}
  }
}
