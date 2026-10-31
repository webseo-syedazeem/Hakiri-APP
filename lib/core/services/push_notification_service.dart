import 'dart:async';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../firebase_options.dart';
import 'google_auth_service.dart';
import 'hakkiri_api_service.dart';

/// FCM only — grabs the device token and syncs it to the API.
/// Notification permission is requested on the Home screen, never on the native splash.
class PushNotificationService {
  PushNotificationService._();
  static final PushNotificationService instance = PushNotificationService._();

  static const _pushChannel = MethodChannel('hakkiri/push');

  String? _token;
  bool _ready = false;
  /// When false (Profile Reminder off), never sync tokens to the API.
  bool allowSync = true;
  bool _requestedThisSession = false;
  bool _fetchInFlight = false;
  Timer? _iosRetryTimer;
  int _iosRetryCount = 0;

  String? get token => _token;

  /// Background initialization on app launch. Does NOT prompt for notification permissions.
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
        await messaging.setAutoInitEnabled(true);
      }

      messaging.onTokenRefresh.listen((t) {
        _token = t;
        _iosRetryTimer?.cancel();
        _logToken(t, source: 'refresh');
        unawaited(syncTokenToApi(forcedToken: t));
      });

      _ready = true;

      // If user already granted permission in a previous session, silently fetch & sync token.
      final settings = await messaging.getNotificationSettings();
      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        await _fetchAndSyncToken(messaging);
      }
    } catch (e, st) {
      // ignore: avoid_print
      print('FCM init skipped: $e');
      // ignore: avoid_print
      print(st);
    }
  }

  /// Request notification permission smoothly on the Home screen.
  Future<void> requestPermissionOnHomeScreen() async {
    if (kIsWeb) return;
    if (_requestedThisSession) return;
    _requestedThisSession = true;

    try {
      final messaging = FirebaseMessaging.instance;
      final currentSettings = await messaging.getNotificationSettings();

      // If already authorized, ensure token is synced.
      if (currentSettings.authorizationStatus == AuthorizationStatus.authorized ||
          currentSettings.authorizationStatus == AuthorizationStatus.provisional) {
        await _registerForRemoteNotificationsNative();
        await _fetchAndSyncToken(messaging);
        return;
      }

      // If user previously permanently denied in OS settings, don't spam.
      if (currentSettings.authorizationStatus == AuthorizationStatus.denied) {
        await clearTokenFromApi();
        return;
      }

      // Small delay so home screen UI finishes rendering before system dialog appears
      await Future<void>.delayed(const Duration(milliseconds: 700));

      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      // ignore: avoid_print
      print('FCM permission on Home: ${settings.authorizationStatus}');
      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        // iOS only delivers APNs after permission — re-register then wait.
        await _registerForRemoteNotificationsNative();
        await Future<void>.delayed(const Duration(milliseconds: 800));
        await _fetchAndSyncToken(messaging);
      } else {
        await clearTokenFromApi();
      }
    } catch (e) {
      // ignore: avoid_print
      print('FCM permission request error: $e');
    }
  }

  Future<void> _registerForRemoteNotificationsNative() async {
    if (!Platform.isIOS) return;
    try {
      await _pushChannel.invokeMethod<void>('registerForRemoteNotifications');
    } catch (e) {
      // ignore: avoid_print
      print('FCM native APNs re-register skipped: $e');
    }
  }

  Future<void> _fetchAndSyncToken(FirebaseMessaging messaging) async {
    if (_fetchInFlight) return;
    _fetchInFlight = true;
    try {
      if (Platform.isIOS) {
        final apns = await _waitForApnsToken(messaging);
        if (apns == null) {
          // ignore: avoid_print
          print(
            'FCM: APNs not ready yet — will retry. '
            '(Simulator has no APNs; use a real iPhone with Push capability.)',
          );
          _scheduleIosTokenRetry();
          return; // Do NOT call getToken without APNs — that throws on iOS.
        }
        // ignore: avoid_print
        print('APNs token OK (${apns.substring(0, apns.length.clamp(0, 12))}…)');
      }

      try {
        _token = await messaging.getToken();
      } catch (e) {
        // ignore: avoid_print
        print('FCM getToken error (will retry): $e');
        _token = null;
        if (Platform.isIOS) _scheduleIosTokenRetry();
        return;
      }

      if (_token != null && _token!.isNotEmpty) {
        _iosRetryTimer?.cancel();
        _iosRetryCount = 0;
        _logToken(_token!, source: 'token_ready');
        await syncTokenToApi();
      } else if (Platform.isIOS) {
        // ignore: avoid_print
        print('FCM TOKEN still null — scheduling retry…');
        _scheduleIosTokenRetry();
      } else {
        // ignore: avoid_print
        print('FCM TOKEN: null at start — waiting for onTokenRefresh…');
      }
    } finally {
      _fetchInFlight = false;
    }
  }

  void _scheduleIosTokenRetry() {
    if (!Platform.isIOS) return;
    if (_iosRetryCount >= 12) {
      // ignore: avoid_print
      print(
        'FCM: stopped iOS retries. Confirm Push Notifications capability, '
        'a physical device, and notification permission.',
      );
      return;
    }
    _iosRetryTimer?.cancel();
    final delay = Duration(seconds: 2 + (_iosRetryCount * 2).clamp(0, 20));
    _iosRetryCount += 1;
    _iosRetryTimer = Timer(delay, () async {
      try {
        await _registerForRemoteNotificationsNative();
        await _fetchAndSyncToken(FirebaseMessaging.instance);
      } catch (e) {
        // ignore: avoid_print
        print('FCM iOS retry failed: $e');
      }
    });
  }

  Future<String?> _waitForApnsToken(FirebaseMessaging messaging) async {
    // Permission → APNs can take several seconds on a cold launch.
    for (var i = 0; i < 30; i++) {
      try {
        final apns = await messaging.getAPNSToken();
        if (apns != null && apns.isNotEmpty) return apns;
      } catch (e) {
        if (i == 0 || i % 5 == 4) {
          // ignore: avoid_print
          print('FCM getAPNSToken attempt ${i + 1}: $e');
        }
      }
      await Future<void>.delayed(const Duration(milliseconds: 500));
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
    if (Platform.isIOS) {
      await _registerForRemoteNotificationsNative();
      await _fetchAndSyncToken(FirebaseMessaging.instance);
    } else {
      await syncTokenToApi();
    }
  }

  bool get isReady => _ready;
}
