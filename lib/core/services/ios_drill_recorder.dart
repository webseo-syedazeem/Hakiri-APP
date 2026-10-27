import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// iOS-only bridge to native [DrillRecorderPlugin] (AVAudioRecorder).
class IosDrillRecorder {
  IosDrillRecorder._();
  static final IosDrillRecorder instance = IosDrillRecorder._();

  static const _methods = MethodChannel('com.hakkiri.app/drill_recorder');
  static const _amplitude =
      EventChannel('com.hakkiri.app/drill_recorder/amplitude');

  StreamSubscription? _ampSub;

  bool get isSupported => Platform.isIOS;

  Future<bool> hasPermission() async {
    if (!isSupported) return false;
    try {
      final ok = await _methods.invokeMethod<bool>('hasPermission');
      return ok == true;
    } catch (e) {
      debugPrint('[IosDrillRecorder] hasPermission failed: $e');
      return false;
    }
  }

  /// Starts native AAC recording. Returns absolute file path.
  Future<String> start({
    required void Function(double level) onAmplitude,
  }) async {
    await _ampSub?.cancel();
    _ampSub = _amplitude.receiveBroadcastStream().listen((event) {
      if (event is num) {
        onAmplitude(event.toDouble().clamp(0.08, 1.0));
      }
    });

    final raw = await _methods.invokeMethod<dynamic>('start');
    final map = Map<String, dynamic>.from(raw as Map);
    final path = (map['path'] ?? '').toString();
    if (path.isEmpty) {
      throw StateError('Native drill recorder returned empty path');
    }
    return path;
  }

  Future<({String? path, int bytes})> stop() async {
    await _ampSub?.cancel();
    _ampSub = null;
    try {
      final raw = await _methods.invokeMethod<dynamic>('stop');
      if (raw is! Map) return (path: null, bytes: 0);
      final map = Map<String, dynamic>.from(raw);
      return (
        path: map['path']?.toString(),
        bytes: (map['bytes'] as num?)?.toInt() ?? 0,
      );
    } catch (e) {
      debugPrint('[IosDrillRecorder] stop failed: $e');
      return (path: null, bytes: 0);
    }
  }

  Future<void> cancel() async {
    await _ampSub?.cancel();
    _ampSub = null;
    try {
      await _methods.invokeMethod<void>('cancel');
    } catch (_) {}
  }
}
