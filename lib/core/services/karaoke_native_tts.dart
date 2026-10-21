import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Native karaoke TTS (iOS AVSpeech / Android TextToSpeech).
/// Progress comes from platform word-range callbacks — not a Dart clock.
class KaraokeNativeTts {
  KaraokeNativeTts._();
  static final KaraokeNativeTts instance = KaraokeNativeTts._();

  static const _channel = MethodChannel('com.hakkiri.app/karaoke_tts');

  bool _listening = false;
  void Function(int start, int end, String word)? _onProgress;
  VoidCallback? _onStart;

  bool get isSupported {
    if (kIsWeb) return false;
    return Platform.isIOS || Platform.isAndroid;
  }

  void _ensureListening() {
    if (_listening) return;
    _listening = true;
    _channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'onStart':
          _onStart?.call();
          break;
        case 'onProgress':
          final args = call.arguments;
          if (args is Map) {
            final start = int.tryParse('${args['start']}') ?? 0;
            final end = int.tryParse('${args['end']}') ?? start;
            final word = '${args['word'] ?? ''}';
            _onProgress?.call(start, end, word);
          }
          break;
      }
      return null;
    });
  }

  /// Speaks [text]. [onProgress] receives native character ranges as each
  /// fragment is spoken. Returns when native speech finishes.
  Future<void> speak(
    String text, {
    required double rate,
    required double pitch,
    required void Function(int start, int end, String word) onProgress,
    VoidCallback? onStart,
  }) async {
    if (!isSupported) {
      throw UnsupportedError('Native karaoke TTS unavailable on this platform');
    }
    _ensureListening();
    _onProgress = onProgress;
    _onStart = onStart;
    try {
      await _channel.invokeMethod<void>('speak', {
        'text': text,
        'rate': rate,
        'pitch': pitch,
      });
    } finally {
      _onProgress = null;
      _onStart = null;
    }
  }

  Future<void> stop() async {
    _onProgress = null;
    _onStart = null;
    try {
      if (isSupported) {
        await _channel.invokeMethod<void>('stop');
      }
    } catch (_) {}
  }
}
