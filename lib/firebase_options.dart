// File generated from android/app/google-services.json for the Hakkiri Firebase project.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError('Web Firebase is not configured for Hakkiri yet.');
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        throw UnsupportedError(
          'iOS Firebase needs GoogleService-Info.plist from the Firebase console.',
        );
      default:
        throw UnsupportedError(
          'Firebase is not configured for this platform yet.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAAt8TzOMRs_PaeSCmg9BXDOm45ga3pyOE',
    appId: '1:536954543355:android:2706b6b3c9221c81d6245e',
    messagingSenderId: '536954543355',
    projectId: 'hakkiri-ff46a',
    storageBucket: 'hakkiri-ff46a.firebasestorage.app',
  );
}
