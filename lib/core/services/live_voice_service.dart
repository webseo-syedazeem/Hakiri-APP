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

  Future<void> start({String? systemInstruction}) async {
    final data = await _api.createLiveToken(systemInstruction: systemInstruction);
    final live = (data['live'] as Map<String, dynamic>?) ?? {};
    final wsUrl = (live['ws_url'] ?? '').toString();
    final model = (live['model'] ?? 'gemini-3.8-live').toString();
    final instruction = (live['system_instruction'] ?? systemInstruction ?? '').toString();
    if (wsUrl.isEmpty) {
      throw HakkiriApiException('Live voice token did not include a WebSocket URL.');
    }

    await _sub?.cancel();
    _sub = _events.receiveBroadcastStream().listen((event) {
      if (event is Map) {
        _controller.add(Map<String, dynamic>.from(event));
      }
    }, onError: (Object error) {
      _controller.add({'type': 'error', 'message': error.toString()});
    });

    await _method.invokeMethod('start', {
      'ws_url': wsUrl,
      'model': model,
      'system_instruction': instruction,
    });
    isActive = true;
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
