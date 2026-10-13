import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

/// Centralized Firebase Crashlytics Service for Hakkiri.
/// Catches unhandled framework exceptions, async platform errors,
/// logs breadcrumbs, and reports non-fatal errors.
class CrashlyticsService {
  CrashlyticsService._();
  static final CrashlyticsService instance = CrashlyticsService._();

  FirebaseCrashlytics? _crashlytics;
  bool _initialized = false;

  bool get isReady => _initialized && _crashlytics != null;

  /// Initializes Crashlytics hooks for Flutter & Dart error handlers.
  Future<void> init() async {
    if (kIsWeb) return;
    try {
      _crashlytics = FirebaseCrashlytics.instance;

      // Enable collection in release and profile modes (and debug if desired for testing)
      await _crashlytics!.setCrashlyticsCollectionEnabled(true);

      // Pass all uncaught "fatal" errors from the framework to Crashlytics
      FlutterError.onError = (FlutterErrorDetails details) {
        FlutterError.presentError(details);
        _crashlytics?.recordFlutterFatalError(details);
      };

      // Pass all uncaught asynchronous errors that aren't handled by Flutter to Crashlytics
      PlatformDispatcher.instance.onError = (error, stack) {
        _crashlytics?.recordError(error, stack, fatal: true);
        return true;
      };

      _initialized = true;
      log('Crashlytics initialized successfully');
    } catch (e, st) {
      debugPrint('Crashlytics initialization error: $e\n$st');
    }
  }

  /// Sets the user identifier for crash reports.
  Future<void> setUserId(String? userId) async {
    if (!_initialized || _crashlytics == null) return;
    try {
      await _crashlytics!.setUserIdentifier(userId ?? '');
    } catch (e) {
      debugPrint('Crashlytics setUserId error: $e');
    }
  }

  /// Sets a custom key-value pair attached to subsequent crash reports.
  Future<void> setCustomKey(String key, Object value) async {
    if (!_initialized || _crashlytics == null) return;
    try {
      await _crashlytics!.setCustomKey(key, value);
    } catch (e) {
      debugPrint('Crashlytics setCustomKey error: $e');
    }
  }

  /// Logs a breadcrumb message to Crashlytics.
  void log(String message) {
    if (!_initialized || _crashlytics == null) return;
    try {
      _crashlytics!.log(message);
    } catch (_) {}
  }

  /// Records a caught exception or non-fatal error.
  Future<void> recordError(
    dynamic exception,
    StackTrace? stack, {
    dynamic reason,
    Iterable<Object> information = const [],
    bool fatal = false,
  }) async {
    if (!_initialized || _crashlytics == null) {
      debugPrint('Non-fatal error: $exception\n$stack');
      return;
    }
    try {
      await _crashlytics!.recordError(
        exception,
        stack,
        reason: reason,
        information: information,
        fatal: fatal,
      );
    } catch (e) {
      debugPrint('Crashlytics recordError failed: $e');
    }
  }
}
