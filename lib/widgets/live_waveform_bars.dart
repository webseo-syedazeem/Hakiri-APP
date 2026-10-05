import 'dart:math';
import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

class LiveWaveformBars extends StatefulWidget {
  final int barCount;
  final double maxHeight;
  final Color color;
  final bool isAnimated;

  const LiveWaveformBars({
    super.key,
    this.barCount = 24,
    this.maxHeight = 48.0,
    this.color = AppColors.royalBlue,
    this.isAnimated = true,
  });

  @override
  State<LiveWaveformBars> createState() => _LiveWaveformBarsState();
}

class _LiveWaveformBarsState extends State<LiveWaveformBars>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<double> _baseMultipliers = [];

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < widget.barCount; i++) {
      // Create bell curve centered wave shape with organic variance
      final centerDist = (i - widget.barCount / 2).abs() / (widget.barCount / 2);
      final bellFactor = 1.0 - (centerDist * 0.7);
      _baseMultipliers.add(bellFactor.clamp(0.25, 1.0));
    }

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    if (widget.isAnimated) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return SizedBox(
          height: widget.maxHeight,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: List.generate(widget.barCount, (i) {
              final phase = (i * 0.35);
              final dynamicFactor = widget.isAnimated
                  ? (0.5 + 0.5 * sin(_controller.value * 2 * pi + phase))
                  : 0.8;
              final height = (widget.maxHeight *
                      _baseMultipliers[i] *
                      (0.4 + 0.6 * dynamicFactor))
                  .clamp(8.0, widget.maxHeight);

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 2.0),
                width: 3.4,
                height: height,
                decoration: BoxDecoration(
                  color: widget.color,
                  borderRadius: BorderRadius.circular(2.5),
                ),
              );
            }),
          ),
        );
      },
    );
  }
}
