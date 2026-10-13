import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/constants/app_colors.dart';
import '../models/session_model.dart';

/// Full session review: question, transcript / turns, scores, local playback.
class SessionDetailScreen extends StatefulWidget {
  final PracticeSessionRecord session;

  const SessionDetailScreen({super.key, required this.session});

  @override
  State<SessionDetailScreen> createState() => _SessionDetailScreenState();
}

class _SessionDetailScreenState extends State<SessionDetailScreen> {
  final AudioPlayer _player = AudioPlayer();
  StreamSubscription? _posSub;
  StreamSubscription? _completeSub;
  bool _playing = false;
  bool _hasAudio = false;
  String? _audioPath;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  PracticeSessionRecord get s => widget.session;

  @override
  void initState() {
    super.initState();
    _duration = Duration(seconds: s.durationSeconds.clamp(1, 600));
    _initAudio();
  }

  Future<void> _initAudio() async {
    final path = s.localAudioPath;
    if (path == null || path.isEmpty) return;
    final file = File(path);
    if (!await file.exists()) return;
    try {
      _audioPath = path;
      _posSub = _player.onPositionChanged.listen((p) {
        if (mounted) setState(() => _position = p);
      });
      _completeSub = _player.onPlayerComplete.listen((_) {
        if (mounted) {
          setState(() {
            _playing = false;
            _position = Duration.zero;
          });
        }
      });
      if (mounted) setState(() => _hasAudio = true);
    } catch (_) {
      if (mounted) setState(() => _hasAudio = false);
    }
  }

  Future<void> _togglePlay() async {
    if (!_hasAudio || _audioPath == null) return;
    if (_playing) {
      await _player.pause();
      setState(() => _playing = false);
      return;
    }
    final atEnd = _duration.inMilliseconds > 0 &&
        _position >= _duration - const Duration(milliseconds: 200);
    if (_position == Duration.zero || atEnd) {
      await _player.play(DeviceFileSource(_audioPath!));
      final d = await _player.getDuration();
      if (d != null && d.inMilliseconds > 0 && mounted) {
        setState(() => _duration = d);
      }
    } else {
      await _player.resume();
    }
    setState(() => _playing = true);
  }

  @override
  void dispose() {
    _posSub?.cancel();
    _completeSub?.cancel();
    _player.dispose();
    super.dispose();
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(1, '0');
    final sec = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$sec';
  }

  @override
  Widget build(BuildContext context) {
    final question = s.promptText.isNotEmpty ? s.promptText : s.promptTitle;
    final modeLabel =
        s.isBackAndForth ? 'Back & forth conversation' : 'Single answer';
    final pillars = s.feedback.pillars;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFFBFBF9),
        appBar: AppBar(
          backgroundColor: const Color(0xFFFBFBF9),
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
            color: AppColors.textPrimary,
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            s.activityName,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          centerTitle: true,
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 36),
          children: [
            Row(
              children: [
                _chip(
                  modeLabel,
                  s.isBackAndForth
                      ? const Color(0xFF8B5CF6)
                      : AppColors.royalBlue,
                ),
                const Spacer(),
                Text(
                  _dayLabel(s.timestamp),
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            const Text(
              'QUESTION',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              question.isEmpty ? 'Practice prompt' : question,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w800,
                height: 1.25,
              ),
            ),
            const SizedBox(height: 22),
            _buildAudioCard(),
            const SizedBox(height: 22),
            const Text(
              'MARKS',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.surfaceBorder),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Text(
                        '${s.feedback.overallScore}',
                        style: const TextStyle(
                          color: AppColors.royalBlue,
                          fontSize: 40,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const Text(
                        ' / 5',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${s.durationSeconds}s spoken',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _scoreRow('Executive presence', pillars.executiveScore),
                  _scoreRow('Clarity', pillars.clarityScore),
                  _scoreRow('Impact', pillars.impactScore),
                  _scoreRow('Engagement', pillars.engagementScore),
                ],
              ),
            ),
            const SizedBox(height: 22),
            Text(
              s.isBackAndForth ? 'CONVERSATION' : 'WHAT YOU SAID',
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 10),
            if (s.isBackAndForth && s.conversationTurns.isNotEmpty)
              ...s.conversationTurns.map(_turnBubble)
            else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.surfaceBorder),
                ),
                child: Text(
                  s.transcript.trim().isEmpty
                      ? 'No transcript was captured for this session.'
                      : s.transcript.trim(),
                  style: TextStyle(
                    color: s.transcript.trim().isEmpty
                        ? AppColors.textMuted
                        : AppColors.textPrimary,
                    fontSize: 14.5,
                    height: 1.45,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            if (s.feedback.oneStrength.isNotEmpty) ...[
              const SizedBox(height: 22),
              const Text(
                'FEEDBACK',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 10),
              _feedbackBlock('Strength', s.feedback.oneStrength),
              const SizedBox(height: 8),
              _feedbackBlock('Improve', s.feedback.oneSpecificImprovement),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAudioCard() {
    final progress = _duration.inMilliseconds == 0
        ? 0.0
        : (_position.inMilliseconds / _duration.inMilliseconds).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: _hasAudio ? _togglePlay : null,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _hasAudio
                        ? AppColors.royalBlue
                        : const Color(0xFF334155),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _hasAudio ? 'Your recording' : 'Recording not on this device',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _hasAudio
                          ? '${_fmt(_position)} / ${_fmt(_duration)}'
                          : 'Transcript & scores still available below',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.65),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 44,
            width: double.infinity,
            child: CustomPaint(
              painter: _PlaybackWavePainter(
                progress: progress,
                playing: _playing,
                seed: s.id.hashCode,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _scoreRow(String label, int score) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            '$score/5',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 88,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: score / 5,
                minHeight: 6,
                backgroundColor: const Color(0xFFE2E8F0),
                color: AppColors.royalBlue,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _turnBubble(ConversationTurn turn) {
    final isUser = turn.role != 'coach';
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.82,
        ),
        decoration: BoxDecoration(
          color: isUser ? const Color(0xFFEFF6FF) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isUser ? const Color(0xFFBFDBFE) : AppColors.surfaceBorder,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isUser ? 'You' : 'Coach',
              style: TextStyle(
                color: isUser ? AppColors.royalBlue : AppColors.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              turn.text,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13.5,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _feedbackBlock(String title, String body) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.royalBlue,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            body,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13.5,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  String _dayLabel(DateTime stamp) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(stamp.year, stamp.month, stamp.day);
    if (day == today) return 'Today';
    if (day == today.subtract(const Duration(days: 1))) return 'Yesterday';
    return '${stamp.day}/${stamp.month}/${stamp.year}';
  }
}

class _PlaybackWavePainter extends CustomPainter {
  _PlaybackWavePainter({
    required this.progress,
    required this.playing,
    required this.seed,
  });

  final double progress;
  final bool playing;
  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(seed);
    const bars = 36;
    const barW = 3.2;
    final gap = (size.width - bars * barW) / (bars - 1);
    final paint = Paint()..strokeCap = StrokeCap.round;

    for (var i = 0; i < bars; i++) {
      final t = i / (bars - 1);
      final envelope = math.sin(t * math.pi);
      final jitter = 0.35 + rng.nextDouble() * 0.65;
      final h = size.height * (0.18 + 0.72 * envelope * jitter);
      final x = i * (barW + gap) + barW / 2;
      final active = t <= progress;
      paint.color = active
          ? const Color(0xFF818CF8)
          : const Color(0xFF334155);
      if (playing && active) {
        paint.color = const Color(0xFFA5B4FC);
      }
      canvas.drawLine(
        Offset(x, size.height / 2 - h / 2),
        Offset(x, size.height / 2 + h / 2),
        paint..strokeWidth = barW,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _PlaybackWavePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.playing != playing ||
        oldDelegate.seed != seed;
  }
}
