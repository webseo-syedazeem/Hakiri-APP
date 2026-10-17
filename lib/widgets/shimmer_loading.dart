import 'package:flutter/material.dart';

/// Reusable shimmer gradient wrapper.
/// Sweeps a smooth highlight across all child placeholders synchronously.
class ShimmerEffect extends StatefulWidget {
  final Widget child;
  final Color baseColor;
  final Color highlightColor;
  final Duration duration;

  const ShimmerEffect({
    super.key,
    required this.child,
    this.baseColor = const Color(0xFFE2E8F0),
    this.highlightColor = const Color(0xFFFFFFFF),
    this.duration = const Duration(milliseconds: 1400),
  });

  @override
  State<ShimmerEffect> createState() => _ShimmerEffectState();
}

class _ShimmerEffectState extends State<ShimmerEffect>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..repeat();
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
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: const Alignment(-1.0, -0.3),
              end: const Alignment(1.0, 0.3),
              colors: [
                widget.baseColor,
                widget.highlightColor,
                widget.baseColor,
              ],
              stops: const [0.1, 0.5, 0.9],
              transform: _SlidingGradientTransform(
                slidePercent: _controller.value,
              ),
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {
  final double slidePercent;
  const _SlidingGradientTransform({required this.slidePercent});

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    // Moves gradient from -bounds.width to +bounds.width smoothly
    return Matrix4.translationValues(
      bounds.width * (slidePercent * 2.5 - 1.25),
      0.0,
      0.0,
    );
  }
}

/// Rounded box placeholder helper for shimmer skeletons.
class ShimmerBox extends StatelessWidget {
  final double? width;
  final double height;
  final double borderRadius;
  final Color color;

  const ShimmerBox({
    super.key,
    this.width,
    required this.height,
    this.borderRadius = 8,
    this.color = const Color(0xFFE2E8F0),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

/// Home tab skeleton — shown instead of default placeholder stats while API loads.
class HomeLoadingShimmer extends StatelessWidget {
  const HomeLoadingShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: ShimmerEffect(
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  ShimmerBox(width: 28, height: 28, borderRadius: 8),
                  ShimmerBox(width: 64, height: 28, borderRadius: 20),
                ],
              ),
              const SizedBox(height: 18),
              const ShimmerBox(width: 56, height: 12, borderRadius: 6),
              const SizedBox(height: 10),
              const ShimmerBox(
                width: double.infinity,
                height: 34,
                borderRadius: 8,
              ),
              const SizedBox(height: 10),
              FractionallySizedBox(
                widthFactor: 0.62,
                alignment: Alignment.centerLeft,
                child: const ShimmerBox(height: 34, borderRadius: 8),
              ),
              const SizedBox(height: 18),
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        ShimmerBox(width: 120, height: 14, borderRadius: 6),
                        ShimmerBox(width: 90, height: 14, borderRadius: 6),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: List.generate(7, (i) {
                        return Expanded(
                          child: Container(
                            height: 7,
                            margin: EdgeInsets.only(right: i < 6 ? 6 : 0),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE2E8F0),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              const ShimmerBox(
                width: double.infinity,
                height: 66,
                borderRadius: 16,
              ),
              const SizedBox(height: 18),
              const ShimmerBox(
                width: double.infinity,
                height: 108,
                borderRadius: 22,
              ),
              const SizedBox(height: 24),
              const ShimmerBox(width: 180, height: 12, borderRadius: 6),
              const SizedBox(height: 12),
              const ShimmerBox(
                width: double.infinity,
                height: 72,
                borderRadius: 16,
              ),
              const SizedBox(height: 10),
              const ShimmerBox(
                width: double.infinity,
                height: 72,
                borderRadius: 16,
              ),
              const SizedBox(height: 10),
              const ShimmerBox(
                width: double.infinity,
                height: 72,
                borderRadius: 16,
              ),
              const SizedBox(height: 18),
              const ShimmerBox(
                width: double.infinity,
                height: 84,
                borderRadius: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Full screen question skeleton shimmer matching Hakkiri's drill question stage.
class QuestionLoadingShimmer extends StatelessWidget {
  final String? activityName;
  final VoidCallback? onBack;

  const QuestionLoadingShimmer({
    super.key,
    this.activityName,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final title = (activityName ?? 'THINK FAST').toUpperCase();

    return Scaffold(
      backgroundColor: const Color(0xFFFBFBF9),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Back button
              GestureDetector(
                onTap: onBack ?? () => Navigator.maybePop(context),
                child: const Icon(
                  Icons.chevron_left_rounded,
                  color: Color(0xFF0F172A),
                  size: 32,
                ),
              ),
              const SizedBox(height: 24),

              // Activity Badge (Icon + Tag)
              Row(
                children: [
                  const Icon(
                    Icons.bolt_rounded,
                    color: Color(0xFF2563EB),
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // Shimmer Skeleton for Question Prompt & Cards
              Expanded(
                child: ShimmerEffect(
                  child: SingleChildScrollView(
                    physics: const NeverScrollableScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Simulating question lines of varying widths
                        const ShimmerBox(
                          width: double.infinity,
                          height: 32,
                          borderRadius: 8,
                        ),
                        const SizedBox(height: 12),
                        FractionallySizedBox(
                          widthFactor: 0.92,
                          alignment: Alignment.centerLeft,
                          child: const ShimmerBox(
                            height: 32,
                            borderRadius: 8,
                          ),
                        ),
                        const SizedBox(height: 12),
                        FractionallySizedBox(
                          widthFactor: 0.65,
                          alignment: Alignment.centerLeft,
                          child: const ShimmerBox(
                            height: 32,
                            borderRadius: 8,
                          ),
                        ),

                        const SizedBox(height: 48),

                        // Context Card Shimmer (Simulates hints / instructions)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: const Color(0xFFE2E8F0),
                              width: 1.0,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: const [
                                  ShimmerBox(
                                    width: 22,
                                    height: 22,
                                    borderRadius: 6,
                                  ),
                                  SizedBox(width: 10),
                                  ShimmerBox(
                                    width: 110,
                                    height: 16,
                                    borderRadius: 6,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              const ShimmerBox(
                                width: double.infinity,
                                height: 14,
                                borderRadius: 6,
                              ),
                              const SizedBox(height: 8),
                              FractionallySizedBox(
                                widthFactor: 0.78,
                                alignment: Alignment.centerLeft,
                                child: const ShimmerBox(
                                  height: 14,
                                  borderRadius: 6,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Secondary pill indicator
                        FractionallySizedBox(
                          widthFactor: 0.42,
                          alignment: Alignment.centerLeft,
                          child: const ShimmerBox(
                            height: 20,
                            borderRadius: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Soft bottom status
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(
                      Icons.auto_awesome_rounded,
                      color: Color(0xFF2563EB),
                      size: 16,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Preparing your drill question…',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        color: Color(0xFF64748B),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
