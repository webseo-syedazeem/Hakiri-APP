import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_colors.dart';
import '../providers/app_state_provider.dart';
import '../widgets/hakkiri_logo.dart';

/// Today-only coaching sheet. One prompt a day; level/plan never change silently.
class CoachingPromptHost extends StatefulWidget {
  const CoachingPromptHost({super.key});

  @override
  State<CoachingPromptHost> createState() => _CoachingPromptHostState();
}

class _CoachingPromptHostState extends State<CoachingPromptHost> {
  static bool _open = false;
  String? _shownKey;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShow());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShow());
  }

  Future<void> _maybeShow() async {
    if (!mounted || _open) return;
    final state = context.read<AppStateProvider>();
    final prompt = state.coachingPrompt;
    if (prompt == null) {
      _shownKey = null;
      return;
    }
    final key = '${prompt['type']}|${prompt['title']}';
    if (_shownKey == key) return;
    _shownKey = key;
    _open = true;
    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.35),
      pageBuilder: (ctx, _, __) {
        return CoachingPromptSheet(prompt: prompt);
      },
    );
    _open = false;
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

class CoachingPromptSheet extends StatefulWidget {
  final Map<String, dynamic> prompt;

  const CoachingPromptSheet({super.key, required this.prompt});

  @override
  State<CoachingPromptSheet> createState() => _CoachingPromptSheetState();
}

class _CoachingPromptSheetState extends State<CoachingPromptSheet> {
  bool _busy = false;
  String? _stepDownPick;

  Map<String, dynamic> get p => widget.prompt;
  String get type => '${p['type'] ?? ''}';

  Future<void> _choose(String choice) async {
    if (_busy) return;
    setState(() => _busy = true);
    await context.read<AppStateProvider>().decideCoachingPrompt(choice);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF7F8FC),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
              child: Row(
                children: [
                  // Horizontal lockup already includes the wordmark — no extra text.
                  const HakkiriLogo(
                    variant: HakkiriLogoVariant.compactMark,
                    size: 28,
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: _busy
                        ? null
                        : () => _choose(
                              type == 'progress_check'
                                  ? 'dismiss'
                                  : 'decline',
                            ),
                    icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 8, 22, 16),
                child: _body(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 0, 22, 16),
              child: _actions(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _body() {
    switch (type) {
      case 'level_up':
        return _levelUp();
      case 'plan_change':
        return _planChange();
      case 'step_down':
        return _stepDown();
      default:
        return _progress();
    }
  }

  Widget _eyebrow(String text, {Color color = const Color(0xFF2563EB)}) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: 'Inter',
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.1,
        color: color,
      ),
    );
  }

  Widget _title(String text, {Color? accentStart}) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 30,
        fontWeight: FontWeight.w900,
        height: 1.15,
        letterSpacing: -0.7,
        color: Color(0xFF0F172A),
      ),
    );
  }

  Widget _levelUp() {
    final scores = (p['last_scores'] as List?) ?? [];
    final path = ((p['path'] as List?) ?? []).whereType<Map>().toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        const Icon(Icons.bolt_rounded, color: Color(0xFF2563EB), size: 36),
        const SizedBox(height: 10),
        _eyebrow('${p['eyebrow'] ?? 'LEVEL UP'}'),
        const SizedBox(height: 8),
        _title('${p['title'] ?? "You're ready."}'),
        const SizedBox(height: 22),
        _levelPath(path),
        const SizedBox(height: 22),
        const Text(
          'YOUR LAST THREE ANSWERS',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.0,
            color: Color(0xFF94A3B8),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: List.generate(math.max(scores.length, 1), (i) {
            final score = i < scores.length ? scores[i] : '—';
            return Expanded(
              child: Container(
                margin: EdgeInsets.only(right: i == scores.length - 1 ? 0 : 8),
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Text(
                      '$score',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      'try ${i + 1}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 22),
        const Text(
          'What changes',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
        ),
        const SizedBox(height: 6),
        Text(
          '${p['what_changes'] ?? ''}',
          style: const TextStyle(
            fontSize: 14,
            height: 1.45,
            color: Color(0xFF475569),
          ),
        ),
      ],
    );
  }

  Widget _levelPath(List<Map> path) {
    if (path.isEmpty) return const SizedBox.shrink();
    return Row(
      children: [
        for (var i = 0; i < path.length; i++) ...[
          _pathNode(path[i]),
          if (i < path.length - 1)
            Expanded(
              child: Container(
                height: 3,
                margin: const EdgeInsets.symmetric(horizontal: 6),
                color: path[i]['state'] == 'done'
                    ? const Color(0xFF22C55E)
                    : const Color(0xFFE2E8F0),
              ),
            ),
        ],
      ],
    );
  }

  Widget _pathNode(Map node) {
    final state = '${node['state']}';
    final done = state == 'done';
    final current = state == 'current';
    return Column(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: done
                ? const Color(0xFF22C55E)
                : current
                    ? const Color(0xFF2563EB)
                    : const Color(0xFFE2E8F0),
            shape: BoxShape.circle,
          ),
          child: Icon(
            done
                ? Icons.check_rounded
                : current
                    ? Icons.bolt_rounded
                    : Icons.circle,
            size: done || current ? 16 : 8,
            color: done || current ? Colors.white : const Color(0xFF94A3B8),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '${node['label']}',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: current ? const Color(0xFF2563EB) : const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  Widget _planChange() {
    final bars = ((p['bars'] as List?) ?? []).whereType<Map>().toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        _eyebrow('${p['eyebrow'] ?? 'CHECK-IN'}', color: const Color(0xFF64748B)),
        const SizedBox(height: 8),
        _title('${p['title'] ?? 'Your plan has a fresh focus.'}'),
        const SizedBox(height: 18),
        const Text(
          'YOUR LAST TWO WEEKS',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.0,
            color: Color(0xFF94A3B8),
          ),
        ),
        const SizedBox(height: 10),
        ...bars.map((bar) {
          final score = (bar['score'] as num?)?.toDouble() ?? 0;
          final weak = bar['weakest'] == true;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                SizedBox(
                  width: 108,
                  child: Text(
                    '${bar['label']}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF334155),
                    ),
                  ),
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                      value: (score / 5).clamp(0.0, 1.0),
                      minHeight: 8,
                      backgroundColor: const Color(0xFFE2E8F0),
                      color: weak
                          ? const Color(0xFFF43F5E)
                          : const Color(0xFF93C5FD),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  score.toStringAsFixed(1),
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 8),
        Text(
          '${p['insight'] ?? ''}',
          style: const TextStyle(fontSize: 14, height: 1.4, color: Color(0xFF475569)),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _swapCard(
                'HERE’S TO ROTATE',
                '${p['from_activity_name'] ?? ''}',
                Icons.forum_outlined,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _swapCard(
                '2 IDEAS DAILY',
                '${p['to_activity_name'] ?? ''}',
                Icons.lightbulb_outline_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          '${p['reassurance'] ?? ''}',
          style: const TextStyle(fontSize: 13, height: 1.4, color: Color(0xFF64748B)),
        ),
      ],
    );
  }

  Widget _swapCard(String kicker, String title, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: const Color(0xFFD97706)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  kicker,
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                    color: Color(0xFFB45309),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 14,
              color: Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _progress() {
    final wins = ((p['wins'] as List?) ?? []).whereType<Map>().toList();
    final points = ((p['points'] as List?) ?? [])
        .map((e) => (e as num?)?.toDouble() ?? 0)
        .toList();
    final colors = [
      const Color(0xFFE0E7FF),
      const Color(0xFFD1FAE5),
      const Color(0xFFFEF3C7),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        _eyebrow('${p['eyebrow'] ?? 'PROGRESS CHECK'}',
            color: const Color(0xFF64748B)),
        const SizedBox(height: 12),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                color: Color(0xFFFFE4E6),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.content_cut_rounded,
                  color: Color(0xFFBE123C), size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(child: _title('${p['title'] ?? "You're getting sharper."}')),
          ],
        ),
        const SizedBox(height: 18),
        if (p['trend_label'] != null) ...[
          Row(
            children: [
              const Text(
                'Your score, last 2 weeks',
                style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
              ),
              const Spacer(),
              Text(
                '${p['trend_label']}',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF2563EB),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 72,
            width: double.infinity,
            child: CustomPaint(painter: _SparklinePainter(points)),
          ),
        ],
        const SizedBox(height: 12),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < wins.length; i++)
                Expanded(
                  child: Container(
                    margin: EdgeInsets.only(right: i == wins.length - 1 ? 0 : 8),
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                    constraints: const BoxConstraints(minHeight: 88),
                    decoration: BoxDecoration(
                      color: colors[i % colors.length],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${wins[i]['label']}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF475569),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${wins[i]['value']}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 17,
                            height: 1.25,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (p['distance_label'] != null) ...[
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '${p['distance_label']}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1D4ED8),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${p['qualifying'] ?? 0} of ${p['needed'] ?? 3}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1D4ED8),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: ((p['qualifying'] as num?)?.toDouble() ?? 0) /
                        math.max(1, (p['needed'] as num?)?.toDouble() ?? 3),
                    minHeight: 7,
                    backgroundColor: Colors.white,
                    color: const Color(0xFF2563EB),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${p['tip'] ?? ''}',
                  style: const TextStyle(
                    fontSize: 12.5,
                    height: 1.35,
                    color: Color(0xFF334155),
                  ),
                ),
              ],
            ),
          ),
        ] else ...[
          const SizedBox(height: 16),
          Text(
            '${p['tip'] ?? ''}',
            style: const TextStyle(fontSize: 14, height: 1.4, color: Color(0xFF475569)),
          ),
        ],
      ],
    );
  }

  Widget _stepDown() {
    final pick = _stepDownPick ?? 'accept';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        _eyebrow('${p['eyebrow'] ?? 'YOUR ADVICE'}', color: const Color(0xFFB45309)),
        const SizedBox(height: 10),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                color: Color(0xFFFEF3C7),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.chat_bubble_outline_rounded,
                  color: Color(0xFFB45309)),
            ),
            const SizedBox(width: 10),
            Expanded(child: _title('${p['title'] ?? 'These questions are tough ones.'}')),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          '${p['body'] ?? ''}',
          style: const TextStyle(fontSize: 14, height: 1.45, color: Color(0xFF475569)),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _choiceCard(
                selected: pick == 'accept',
                title: '${p['build_up_title'] ?? 'Build up first'}',
                body: '${p['build_up_body'] ?? ''}',
                onTap: () => setState(() => _stepDownPick = 'accept'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _choiceCard(
                selected: pick == 'decline',
                title: '${p['stay_title'] ?? 'Stay and stretch'}',
                body: '${p['stay_body'] ?? ''}',
                onTap: () => setState(() => _stepDownPick = 'decline'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFECFDF5),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              const Icon(Icons.check_circle, color: Color(0xFF059669), size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${p['recognition'] ?? ''}',
                  style: const TextStyle(fontSize: 13, height: 1.35),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _choiceCard({
    required bool selected,
    required String title,
    required String body,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(
              body,
              style: const TextStyle(fontSize: 12, height: 1.35, color: Color(0xFF64748B)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actions() {
    if (type == 'progress_check') {
      return _blueButton('${p['primary_label'] ?? 'Keep going'}', () => _choose('dismiss'));
    }
    if (type == 'step_down') {
      final pick = _stepDownPick ?? 'accept';
      final label = pick == 'accept'
          ? '${p['primary_label'] ?? 'Build up first'}'
          : '${p['secondary_label'] ?? 'Stay and stretch'}';
      return Column(
        children: [
          _blueButton(label, () => _choose(pick)),
          TextButton(
            onPressed: _busy
                ? null
                : () => _choose(pick == 'accept' ? 'decline' : 'accept'),
            child: Text(
              pick == 'accept'
                  ? '${p['secondary_label'] ?? 'Stay and stretch'}'
                  : '${p['primary_label'] ?? 'Build up first'}',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: Color(0xFF64748B),
              ),
            ),
          ),
        ],
      );
    }
    return Column(
      children: [
        _blueButton(
          '${p['primary_label'] ?? 'Continue'}',
          () => _choose('${p['primary_choice'] ?? 'accept'}'),
        ),
        TextButton(
          onPressed: _busy
              ? null
              : () => _choose('${p['secondary_choice'] ?? 'decline'}'),
          child: Text(
            '${p['secondary_label'] ?? 'Not now'}',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: Color(0xFF64748B),
            ),
          ),
        ),
      ],
    );
  }

  Widget _blueButton(String label, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: FilledButton(
        onPressed: _busy ? null : onTap,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.royalBlue,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.arrow_forward_rounded, size: 18),
          ],
        ),
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final List<double> points;
  _SparklinePainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;
    final minV = points.reduce(math.min);
    final maxV = points.reduce(math.max);
    final span = (maxV - minV).abs() < 0.01 ? 1.0 : maxV - minV;
    final path = Path();
    for (var i = 0; i < points.length; i++) {
      final x = size.width * (i / (points.length - 1));
      final y = size.height - ((points[i] - minV) / span) * (size.height - 8) - 4;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    final paint = Paint()
      ..color = const Color(0xFF2563EB)
      ..strokeWidth = 2.4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, paint);
    final last = points.length - 1;
    final lx = size.width;
    final ly = size.height - ((points[last] - minV) / span) * (size.height - 8) - 4;
    canvas.drawCircle(Offset(lx, ly), 4.5, Paint()..color = const Color(0xFF2563EB));
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) =>
      oldDelegate.points != points;
}
