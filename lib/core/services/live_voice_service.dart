import 'dart:async';

import 'package:flutter/services.dart';

import 'hakkiri_api_service.dart';

class LiveVoiceService {
  LiveVoiceService._();
  static final LiveVoiceService instance = LiveVoiceService._();

  static const _method = MethodChannel('com.hakkiri.app/live_voice');
  static const _events = EventChannel('com.hakkiri.app/live_voice_events');

  final HakkiriApiService _api = HakkiriApiService.instance;
  StreamSubscription? _sub;
  final _controller = StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get events => _controller.stream;
  bool isActive = false;

  Future<void> start({
    String? systemInstruction,
    String? kickoff,
  }) async {
    await _sub?.cancel();
    _sub = _events.receiveBroadcastStream().listen((event) {
      if (event is Map) {
        _controller.add(Map<String, dynamic>.from(event));
      }
    }, onError: (Object error) {
      _controller.add({'type': 'error', 'message': error.toString()});
    });

    // One token mint + Constrained URL first. Only fall back once if needed.
    // (Old path: 3 mints × 3 URLs × 25s setup ≈ 30s+ connecting.)
    final data =
        await _api.createLiveToken(systemInstruction: systemInstruction);
    final live = (data['live'] as Map<String, dynamic>?) ?? {};
    final model = (live['model'] ?? 'gemini-3.8-live').toString();
    final instruction =
        (live['system_instruction'] ?? systemInstruction ?? '').toString();
    final accessToken = (live['access_token'] ?? '').toString();
    final authHeader = (live['auth_header'] ?? '').toString();
    final wsUrl = (live['ws_url'] ?? '').toString();
    final wsHeader = (live['ws_url_header'] ?? '').toString();

    final urls = <Map<String, String>>[];
    if (wsUrl.isNotEmpty) {
      urls.add({'ws_url': wsUrl, 'auth_header': ''});
    }
    if (wsHeader.isNotEmpty &&
        (authHeader.isNotEmpty || accessToken.isNotEmpty)) {
      urls.add({
        'ws_url': wsHeader,
        'auth_header':
            authHeader.isNotEmpty ? authHeader : 'Token $accessToken',
      });
    }
    if (urls.isEmpty) {
      throw HakkiriApiException(
        'Live voice token did not include a WebSocket URL.',
      );
    }

    Object? lastErr;
    for (final entry in urls) {
      try {
        await _method.invokeMethod('stop');
      } catch (_) {}
      try {
        await _method.invokeMethod('start', {
          'ws_url': entry['ws_url'],
          'model': model,
          'system_instruction': instruction,
          if ((entry['auth_header'] ?? '').isNotEmpty)
            'auth_header': entry['auth_header'],
          if (kickoff != null && kickoff.trim().isNotEmpty)
            'kickoff': kickoff.trim(),
        });
        isActive = true;
        return;
      } catch (e) {
        lastErr = e;
      }
    }

    throw HakkiriApiException(_friendlyStartError(lastErr));
  }

  String _friendlyStartError(Object? err) {
    if (err is PlatformException) {
      final code = err.code;
      final message = (err.message ?? '').trim();
      if (code == 'setup_timeout') {
        return 'Live coach could not finish connecting. Check your connection and try again.';
      }
      if (code == 'mic_permission') {
        return message.isNotEmpty
            ? message
            : 'Microphone permission is required.';
      }
      if (message.isNotEmpty) return message;
    }
    final raw = err?.toString() ?? 'Could not start live voice.';
    return raw
        .replaceFirst('PlatformException(', '')
        .replaceAll(RegExp(r',\s*null,\s*null\)$'), '')
        .trim();
  }

  Future<void> stop() async {
    try {
      await _method.invokeMethod('stop');
    } catch (_) {
      // Native side may already be closed.
    }
    isActive = false;
    await _sub?.cancel();
    _sub = null;
  }

  Future<void> dispose() async {
    await stop();
    await _controller.close();
  }
}
