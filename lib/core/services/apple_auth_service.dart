import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import 'google_auth_service.dart';

class AppleAuthResult {
  const AppleAuthResult({
    required this.idToken,
    required this.email,
    required this.displayName,
    this.appleUserId,
  });

  final String idToken;
  final String email;
  final String displayName;
  final String? appleUserId;
}

class AppleAuthService {
  AppleAuthService._();

  static String _rawNonce(int length) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)])
        .join();
  }

  static String _sha256of(String input) {
    final bytes = utf8.encode(input);
    return sha256.convert(bytes).toString();
  }

  /// Native Apple Sign-In (iOS / macOS). Android needs Services ID + web flow.
  static Future<AppleAuthResult> signIn() async {
    await GoogleAuthService.bootstrap();

    final available = await SignInWithApple.isAvailable();
    if (!available) {
      throw StateError(
        'Sign in with Apple is not available on this device. Use an iPhone or email.',
      );
    }

    final rawNonce = _rawNonce(32);
    final nonce = _sha256of(rawNonce);

    final apple = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      nonce: nonce,
    );

    final idToken = apple.identityToken;
    if (idToken == null || idToken.isEmpty) {
      throw StateError('Apple did not return an identity token.');
    }

    if (Firebase.apps.isNotEmpty) {
      final oauth = OAuthProvider('apple.com').credential(
        idToken: idToken,
        rawNonce: rawNonce,
      );
      await FirebaseAuth.instance.signInWithCredential(oauth);
    }

    final firebaseUser = FirebaseAuth.instance.currentUser;
    final email = (apple.email ?? firebaseUser?.email ?? '').trim().toLowerCase();
    final given = (apple.givenName ?? '').trim();
    final family = (apple.familyName ?? '').trim();
    final fromApple = '$given $family'.trim();
    final displayName = fromApple.isNotEmpty
        ? fromApple
        : (firebaseUser?.displayName ?? '').trim().isNotEmpty
            ? firebaseUser!.displayName!.trim()
            : (email.isNotEmpty ? email.split('@').first : 'Hakkiri member');

    if (email.isEmpty && (apple.userIdentifier == null || apple.userIdentifier!.isEmpty)) {
      throw StateError(
        'Apple did not share an email. Try again or use Google / email signup.',
      );
    }

    return AppleAuthResult(
      idToken: idToken,
      email: email.isNotEmpty
          ? email
          : 'apple_${apple.userIdentifier}@privaterelay.hakkiri.app',
      displayName: displayName,
      appleUserId: apple.userIdentifier,
    );
  }
}
