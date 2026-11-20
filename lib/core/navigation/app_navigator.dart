import 'package:flutter/material.dart';

import '../../screens/journey_screen.dart';
import '../services/hakkiri_api_service.dart';

/// Root navigator for notification deep-links (FCM / local tap).
final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

class AppNavigator {
  AppNavigator._();

  static NavigatorState? get nav => appNavigatorKey.currentState;

  static Map<String, dynamic>? _pending;

  /// Open Journey; optionally auto-open chapter review sheet.
  static void openJourney({bool openChapterReview = false}) {
    final navigator = nav;
    if (navigator == null) {
      _pending = {
        'type': 'chapter_complete',
        'screen': 'journey',
        'open_review': openChapterReview ? 'true' : 'false',
      };
      return;
    }
    navigator.push(
      MaterialPageRoute<void>(
        builder: (_) => JourneyScreen(openChapterReview: openChapterReview),
      ),
    );
  }

  static void handleNotificationData(Map<String, dynamic> data) {
    final type = '${data['type'] ?? ''}'.trim();
    final screen = '${data['screen'] ?? ''}'.trim();
    final openReview = '${data['open_review'] ?? ''}'.toLowerCase() == 'true';

    if (type != 'chapter_complete' && screen != 'journey') return;

    // Wait until logged-in UI exists (splash / auth may still be running).
    if (nav == null || !HakkiriApiService.instance.isLoggedIn) {
      _pending = Map<String, dynamic>.from(data);
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      openJourney(openChapterReview: openReview || type == 'chapter_complete');
    });
  }

  /// Call from Home (or after login) to apply a notification that arrived early.
  static void flushPendingNotification() {
    final data = _pending;
    if (data == null) return;
    if (!HakkiriApiService.instance.isLoggedIn || nav == null) return;
    _pending = null;
    handleNotificationData(data);
  }
}
