import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

import '../core/services/session_audio_store.dart';

/// Plays the user's on-device drill recording with a live waveform.
class SessionRecordingPlayButton extends StatefulWidget {
  final String? sessionId;
  final String? audioPath;
  final double size;
  final Color color;

  const SessionRecordingPlayButton({
    super.key,
    this.sessionId,
    this.audioPath,
    this.size = 32,
    this.color = const Color(0xFFEA580C),
  });

  @override
  State<SessionRecordingPlayButton> createState() =>
      _SessionRecordingPlayButtonState();
}

class _SessionRecordingPlayButtonState extends State<SessionRecordingPlayButton>
    with SingleTickerProviderStateMixin {
  final AudioPlayer _player = AudioPlayer();
  StreamSubscription? _completeSub;
  StreamSubscription? _posSub;
  String? _resolvedPath;
  bool _playing = false;
  bool _ready = false;
  double _progress = 0;
  Duration _duration = Duration.zero;
  late final AnimationController _waveCtrl;

  @override
  void initState() {
    super.initState();
    _waveCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _resolve();
    _completeSub = _player.onPlayerComplete.listen((_) {
      if (!mounted) return;
      setState(() {
        _playing = false;
        _progress = 0;
      });
      _waveCtrl.stop();
      _waveCtrl.reset();
    });
    _posSub = _player.onPositionChanged.listen((pos) {
      if (!mounted || _duration.inMilliseconds <= 0) return;
      setState(() {
        _progress =
            (pos.inMilliseconds / _duration.inMilliseconds).clamp(0.0, 1.0);
      });
    });
  }

  Future<void> _resolve() async {
    var path = widget.audioPath;
    if ((path == null || path.isEmpty) &&
        (widget.sessionId?.isNotEmpty ?? false)) {
      path = await SessionAudioStore.instance.pathFor(widget.sessionId!);
    }
    if (path == null || path.isEmpty) {
      if (mounted) setState(() => _ready = false);
      return;
    }
    final exists = await File(path).exists();
    if (!mounted) return;
    setState(() {
      _resolvedPath = exists ? path : null;
      _ready = exists;
    });
  }

  Future<void> _toggle() async {
    if (!_ready || _resolvedPath == null) return;
    if (_playing) {
      await _player.stop();
      _waveCtrl.stop();
      _waveCtrl.reset();
      if (mounted) {
        setState(() {
          _playing = false;
          _progress = 0;
        });
      }
      return;
    }
    await _player.play(DeviceFileSource(_resolvedPath!));
    final d = await _player.getDuration();
    if (d != null && d.inMilliseconds > 0) {
      _duration = d;
    }
    _waveCtrl.repeat();
    if (mounted) setState(() => _playing = true);
  }

  @override
  void dispose() {
    _completeSub?.cancel();
    _posSub?.cancel();
    _waveCtrl.dispose();
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) return const SizedBox.shrink();
    return GestureDetector(
      onTap: _toggle,
      behavior: HitTestBehavior.opaque,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              color: widget.color,
              shape: BoxShape.circle,
            ),
            child: Icon(
              _playing ? Icons.stop_rounded : Icons.play_arrow_rounded,
              color: Colors.white,
              size: widget.size * 0.55,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SizedBox(
              height: 32,
              child: AnimatedBuilder(
                animation: _waveCtrl,
                builder: (context, _) {
                  return CustomPaint(
                    painter: _UserRecordingWavePainter(
                      progress: _progress,
                      playing: _playing,
                      phase: _waveCtrl.value * math.pi * 2,
                      seed: (widget.sessionId ?? widget.audioPath ?? 'rec')
                          .hashCode,
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UserRecordingWavePainter extends CustomPainter {
  _UserRecordingWavePainter({
    required this.progress,
    required this.playing,
    required this.phase,
    required this.seed,
  });

  final double progress;
  final bool playing;
  final double phase;
  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(seed);
    const bars = 42;
    const barW = 2.8;
    final gap = (size.width - bars * barW) / (bars - 1);
    final paint = Paint()..strokeCap = StrokeCap.round;

    for (var i = 0; i < bars; i++) {
      final t = i / (bars - 1);
      final envelope = math.sin(t * math.pi);
      final jitter = 0.3 + rng.nextDouble() * 0.7;
      var live = 1.0;
      if (playing) {
        live = 0.55 +
            0.45 *
                (0.5 +
                    0.5 *
                        math.sin(phase + i * 0.45 + jitter * math.pi));
      }
      final h = size.height * (0.16 + 0.78 * envelope * jitter * live);
      final x = i * (barW + gap) + barW / 2;
      final active = t <= (playing ? math.max(progress, 0.04) : progress);
      paint.color = active
          ? (playing ? const Color(0xFFFB923C) : const Color(0xFFFDBA74))
          : const Color(0xFF334155);
      canvas.drawLine(
        Offset(x, size.height / 2 - h / 2),
        Offset(x, size.height / 2 + h / 2),
        paint..strokeWidth = barW,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _UserRecordingWavePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.playing != playing ||
        oldDelegate.phase != phase ||
        oldDelegate.seed != seed;
  }
}
