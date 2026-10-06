import 'dart:async';
import 'package:flutter/material.dart';

class AudioPlayerChip extends StatefulWidget {
  final String timestamp;
  final String phrase;

  const AudioPlayerChip({
    super.key,
    required this.timestamp,
    required this.phrase,
  });

  @override
  State<AudioPlayerChip> createState() => _AudioPlayerChipState();
}

class _AudioPlayerChipState extends State<AudioPlayerChip> {
  bool _isPlaying = false;
  int _currentSecond = 14;
  Timer? _timer;

  void _togglePlay() {
    if (_isPlaying) {
      _stop();
    } else {
      _play();
    }
  }

  void _play() {
    setState(() {
      _isPlaying = true;
      _currentSecond = 14;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_currentSecond < 20) {
        setState(() => _currentSecond += 1);
      } else {
        _stop();
      }
    });
  }

  void _stop() {
    _timer?.cancel();
    setState(() {
      _isPlaying = false;
      _currentSecond = 14;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _togglePlay,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: _isPlaying ? const Color(0xFF282B45) : const Color(0xFF1E2033),
          borderRadius: BorderRadius.circular(10),
          border: _isPlaying ? Border.all(color: const Color(0xFF5B6BFF), width: 1.2) : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
              color: const Color(0xFF6B7BFF),
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              '0:${_currentSecond < 10 ? '0' : ''}$_currentSecond',
              style: const TextStyle(
                color: Color(0xFF6B7BFF),
                fontSize: 12,
                fontWeight: FontWeight.w800,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: RichText(
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                text: TextSpan(
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w500,
                  ),
                  children: [
                    const TextSpan(text: '“', style: TextStyle(color: Colors.white)),
                    WidgetSpan(
                      alignment: PlaceholderAlignment.middle,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: const Color(0x33FF443A),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'So basically,',
                          style: TextStyle(
                            color: Color(0xFFFF6B6B),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ),
                    const TextSpan(
                      text: ' I think the main reason is…”',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
