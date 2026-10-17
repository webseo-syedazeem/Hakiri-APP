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
  bool _playing = false;

  Future<void> _toggle() async {
    final text = widget.text.trim();
    if (text.isEmpty) return;

    if (_playing) {
      await CoachTtsService.instance.stop();
      if (mounted) setState(() => _playing = false);
      return;
    }

    final appStateVoice =
        context.read<AppStateProvider>().answers.voiceProfile;
    final profile = CoachTtsService.normalizeCoachId(
      (appStateVoice != null && appStateVoice.trim().isNotEmpty)
          ? appStateVoice
          : CoachTtsService.instance.activeCoachId,
    );
    setState(() => _playing = true);
    try {
      await CoachTtsService.instance.speak(text, voiceProfile: profile);
    } finally {
      if (mounted) setState(() => _playing = false);
    }
  }

  @override
  void dispose() {
    if (_playing) {
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
        decoration: BoxDecoration(
          color: enabled
              ? const Color(0xFF2563EB)
              : const Color(0xFF334155),
          shape: BoxShape.circle,
        ),
        child: Icon(
          _playing ? Icons.stop_rounded : Icons.play_arrow_rounded,
          color: Colors.white,
          size: widget.size * 0.6,
        ),
      ),
    );
  }
}
