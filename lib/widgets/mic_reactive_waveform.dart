import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

/// Same lavender rounded-bar look as the Think First design,
/// driven by live microphone amplitude instead of a fake loop.
///
/// Pass [externalLevel] (e.g. from speech_to_text) to avoid opening a second
/// mic session that would conflict with transcription.
class MicReactiveWaveform extends StatefulWidget {
  const MicReactiveWaveform({
    super.key,
    this.active = true,
    this.barCount = 28,
    this.width = 220,
    this.height = 48,
    this.color = const Color(0xFF818CF8),
    this.externalLevel,
  });

  final bool active;
  final int barCount;
  final double width;
  final double height;
  final Color color;
  final ValueListenable<double>? externalLevel;

  @override
  State<MicReactiveWaveform> createState() => _MicReactiveWaveformState();
}

class _MicReactiveWaveformState extends State<MicReactiveWaveform> {
  final AudioRecorder _recorder = AudioRecorder();
  StreamSubscription<Amplitude>? _ampSub;
  late List<double> _levels;
  String? _tempPath;
  bool _started = false;

  bool get _usesExternal => widget.externalLevel != null;

  @override
  void initState() {
    super.initState();
    _levels = List<double>.filled(widget.barCount, 0.12);
    widget.externalLevel?.addListener(_onExternalLevel);
    if (widget.active && !_usesExternal) {
      unawaited(_startMic());
    } else if (widget.active && _usesExternal) {
      _pushLevel(widget.externalLevel!.value);
    }
  }

  @override
  void didUpdateWidget(covariant MicReactiveWaveform oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.externalLevel != widget.externalLevel) {
      oldWidget.externalLevel?.removeListener(_onExternalLevel);
      widget.externalLevel?.addListener(_onExternalLevel);
    }
    if (_usesExternal) {
      unawaited(_stopMic());
      return;
    }
    if (widget.active && !oldWidget.active) {
      unawaited(_startMic());
    } else if (!widget.active && oldWidget.active) {
      unawaited(_stopMic());
    }
  }

  void _onExternalLevel() {
    final value = widget.externalLevel?.value;
    if (value == null) return;
    _pushLevel(value);
  }

  void _pushLevel(double level) {
    final clamped = level.clamp(0.08, 1.0);
    if (!mounted) return;
    setState(() {
      for (var i = 0; i < _levels.length - 1; i++) {
        _levels[i] = _levels[i + 1];
      }
      _levels[_levels.length - 1] = clamped;
    });
  }

  Future<void> _startMic() async {
    if (_started || _usesExternal) return;
    try {
      final granted = await _recorder.hasPermission();
      if (!granted) return;

      final dir = await getTemporaryDirectory();
      _tempPath =
          '${dir.path}/hakkiri_wave_${DateTime.now().millisecondsSinceEpoch}.m4a';

      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 64000,
          sampleRate: 16000,
          numChannels: 1,
        ),
        path: _tempPath!,
      );
      _started = true;

      _ampSub = _recorder
          .onAmplitudeChanged(const Duration(milliseconds: 55))
          .listen(_onAmplitude);
    } catch (_) {
      _started = false;
    }
  }

  void _onAmplitude(Amplitude amp) {
    // Current is typically ~-60 (quiet) to 0 (loud).
    final raw = ((amp.current + 50) / 50).clamp(0.0, 1.0);
    // Soften silence / boost speech presence.
    final level = math.pow(raw, 0.72).toDouble().clamp(0.08, 1.0);
    _pushLevel(level);
  }

  Future<void> _stopMic() async {
    await _ampSub?.cancel();
    _ampSub = null;
    try {
      if (await _recorder.isRecording()) {
        await _recorder.stop();
      }
    } catch (_) {}
    _started = false;

    final path = _tempPath;
    _tempPath = null;
    if (path != null) {
      try {
        final file = File(path);
        if (await file.exists()) await file.delete();
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    widget.externalLevel?.removeListener(_onExternalLevel);
    unawaited(_stopMic());
    unawaited(_recorder.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(widget.width, widget.height),
      painter: _MicWavePainter(
        levels: List<double>.from(_levels),
        color: widget.color,
      ),
    );
  }
}

class _MicWavePainter extends CustomPainter {
  _MicWavePainter({required this.levels, required this.color});

  final List<double> levels;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final barPaint = Paint()
      ..color = color
      ..strokeCap = StrokeCap.round;

    final barCount = levels.length;
    const barWidth = 3.6;
    final spacing = (size.width - (barCount * barWidth)) / (barCount - 1);
    final centerY = size.height / 2;

    for (var i = 0; i < barCount; i++) {
      final x = i * (barWidth + spacing) + (barWidth / 2);
      final distFromCenter = (i - (barCount / 2)).abs() / (barCount / 2);
      final envelope = math.exp(-distFromCenter * distFromCenter * 2.5);
      final level = levels[i].clamp(0.0, 1.0);
      final h = (size.height * 0.16) +
          (size.height * 0.82 * envelope * (0.25 + 0.75 * level));

      canvas.drawLine(
        Offset(x, centerY - h / 2),
        Offset(x, centerY + h / 2),
        barPaint..strokeWidth = barWidth,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _MicWavePainter oldDelegate) {
    if (oldDelegate.color != color) return true;
    if (oldDelegate.levels.length != levels.length) return true;
    for (var i = 0; i < levels.length; i++) {
      if ((oldDelegate.levels[i] - levels[i]).abs() > 0.01) return true;
    }
    return false;
  }
}
