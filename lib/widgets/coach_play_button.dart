import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/services/coach_tts_service.dart';
import '../providers/app_state_provider.dart';

/// Blue circular play/stop control that speaks [text] in the selected coach voice.
class CoachPlayButton extends StatefulWidget {
  final String text;
  final double size;

  const CoachPlayButton({
    super.key,
    required this.text,
    this.size = 36,
  });

  @override
  State<CoachPlayButton> createState() => _CoachPlayButtonState();
}

class _CoachPlayButtonState extends State<CoachPlayButton> {
  bool _loading = false;
  bool _playing = false;

  String get _profile {
    final appStateVoice =
        context.read<AppStateProvider>().answers.voiceProfile;
    return CoachTtsService.normalizeCoachId(
      (appStateVoice != null && appStateVoice.trim().isNotEmpty)
          ? appStateVoice
          : CoachTtsService.instance.activeCoachId,
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final text = widget.text.trim();
      if (text.isEmpty || !mounted) return;
      // Warm cache so the first tap feels faster.
      CoachTtsService.instance.prefetch(text, voiceProfile: _profile);
    });
  }

  @override
  void didUpdateWidget(covariant CoachPlayButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text.trim() != widget.text.trim()) {
      final text = widget.text.trim();
      if (text.isNotEmpty) {
        CoachTtsService.instance.prefetch(text, voiceProfile: _profile);
      }
    }
  }

  Future<void> _toggle() async {
    final text = widget.text.trim();
    if (text.isEmpty) return;

    if (_loading || _playing) {
      await CoachTtsService.instance.stop();
      if (mounted) {
        setState(() {
          _loading = false;
          _playing = false;
        });
      }
      return;
    }

    setState(() {
      _loading = true;
      _playing = false;
    });
    try {
      await CoachTtsService.instance.speak(
        text,
        voiceProfile: _profile,
        onPlaybackStarted: () {
          if (!mounted) return;
          setState(() {
            _loading = false;
            _playing = true;
          });
        },
      );
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
          _playing = false;
        });
      }
    }
  }

  @override
  void dispose() {
    if (_loading || _playing) {
      CoachTtsService.instance.stop();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.text.trim().isNotEmpty;
    return GestureDetector(
      onTap: enabled ? _toggle : null,
      child: Container(
        width: widget.size,
        height: widget.size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: enabled
              ? const Color(0xFF2563EB)
              : const Color(0xFF334155),
          shape: BoxShape.circle,
        ),
        child: _loading
            ? SizedBox(
                width: widget.size * 0.45,
                height: widget.size * 0.45,
                child: const CircularProgressIndicator(
                  strokeWidth: 2.4,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Icon(
                _playing ? Icons.stop_rounded : Icons.play_arrow_rounded,
                color: Colors.white,
                size: widget.size * 0.6,
              ),
      ),
    );
  }
}
