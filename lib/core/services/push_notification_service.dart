import 'dart:async';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../../firebase_options.dart';
import 'google_auth_service.dart';
import 'hakkiri_api_service.dart';

/// FCM only — grabs the device token at app start and syncs it to the API.
class PushNotificationService {
  PushNotificationService._();
  static final PushNotificationService instance = PushNotificationService._();

  String? _token;
  bool _ready = false;
  /// When false (Profile Reminder off), never sync tokens to the API.
  bool allowSync = true;

  String? get token => _token;

  Future<void> init() async {
    if (kIsWeb) return;
    try {
      await GoogleAuthService.bootstrap();
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }

      final messaging = FirebaseMessaging.instance;

      if (Platform.isIOS) {
        await messaging.setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );
      }

      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
      // ignore: avoid_print
      print('FCM permission: ${settings.authorizationStatus}');
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        // ignore: avoid_print
        print('FCM TOKEN: permission denied by user (OS settings)');
        await clearTokenFromApi();
        return;
      }

      // iOS: FCM token ONLY works after APNs token is set.
      if (Platform.isIOS) {
        final apns = await _waitForApnsToken(messaging);
        if (apns == null) {
          // ignore: avoid_print
          print(
            'FCM TOKEN: APNs still null. Use a real iPhone (not Simulator), '
            'enable Push Notifications capability, and ensure network + Apple login.',
          );
        } else {
          // ignore: avoid_print
          print('APNs token OK (${apns.substring(0, apns.length.clamp(0, 12))}…)');
        }
      }

      try {
        _token = await messaging.getToken();
      } catch (e) {
        // ignore: avoid_print
        print('FCM getToken error (will retry via onTokenRefresh): $e');
        _token = null;
      }

      messaging.onTokenRefresh.listen((t) {
        _token = t;
        _logToken(t, source: 'refresh');
        unawaited(syncTokenToApi(forcedToken: t));
      });

      _ready = true;
      if (_token != null && _token!.isNotEmpty) {
        _logToken(_token!, source: 'start');
        await syncTokenToApi();
      } else {
        // ignore: avoid_print
        print('FCM TOKEN: null at start — waiting for onTokenRefresh…');
      }
    } catch (e, st) {
      // ignore: avoid_print
      print('FCM init skipped: $e');
      // ignore: avoid_print
      print(st);
    }
  }

  Future<String?> _waitForApnsToken(FirebaseMessaging messaging) async {
    for (var i = 0; i < 20; i++) {
      try {
        final apns = await messaging.getAPNSToken();
        if (apns != null && apns.isNotEmpty) return apns;
      } catch (e) {
        // ignore: avoid_print
        print('FCM getAPNSToken attempt ${i + 1}: $e');
      }
      await Future<void>.delayed(const Duration(milliseconds: 400));
    }
    return null;
  }

  void _logToken(String token, {required String source}) {
    // ignore: avoid_print
    print('========== FCM DEVICE TOKEN ($source) ==========');
    // ignore: avoid_print
    print(token);
    // ignore: avoid_print
    print('platform=${Platform.isIOS ? "ios" : "android"}');
    // ignore: avoid_print
    print('================================================');
  }

  /// Call after login/register so JWT is present.
  Future<void> syncTokenToApi({String? forcedToken}) async {
    if (!allowSync) {
      // ignore: avoid_print
      print('FCM sync skipped — reminders disabled in Profile.');
      return;
    }
    final t = forcedToken ?? _token;
    if (t == null || t.isEmpty) return;
    final api = HakkiriApiService.instance;
    if (!api.isLoggedIn) {
      // ignore: avoid_print
      print('FCM TOKEN saved locally; will sync after login.');
      return;
    }
    try {
      await api.registerDeviceToken(
        token: t,
        platform: Platform.isIOS ? 'ios' : 'android',
      );
      // ignore: avoid_print
      print('FCM TOKEN synced to API OK');
    } catch (e) {
      // ignore: avoid_print
      print('FCM token sync failed: $e');
    }
  }

  /// Reminder off / OS permission denied — server must not keep this device.
  Future<void> clearTokenFromApi() async {
    allowSync = false;
    final api = HakkiriApiService.instance;
    if (!api.isLoggedIn) return;
    try {
      await api.clearDeviceToken();
      // ignore: avoid_print
      print('FCM tokens cleared on API (reminders off)');
    } catch (e) {
      // ignore: avoid_print
      print('FCM clear failed: $e');
    }
  }

  /// Re-enable sync after user turns Reminder back on.
  Future<void> enableAndSync() async {
    allowSync = true;
    await syncTokenToApi();
  }

  bool get isReady => _ready;
}
