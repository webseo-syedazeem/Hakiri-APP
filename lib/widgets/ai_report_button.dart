import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../core/services/hakkiri_api_service.dart';
import 'app_snackbar.dart';

/// Compact, polished control to report AI-generated coaching text (Play policy).
class AiReportButton extends StatelessWidget {
  const AiReportButton({
    super.key,
    required this.contentType,
    required this.contentSnippet,
    this.activitySlug = '',
    this.sessionId = '',
    this.dark = false,
    this.iconOnly = false,
  });

  /// suggested_answer | coaching_feedback | debate_pushback | other
  final String contentType;
  final String contentSnippet;
  final String activitySlug;
  final String sessionId;
  final bool dark;
  /// App-bar style: flag icon only, no label.
  final bool iconOnly;

  @override
  Widget build(BuildContext context) {
    final fg = dark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final bg = dark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9);
    final border = dark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final enabled = contentSnippet.trim().isNotEmpty;

    if (iconOnly) {
      return Material(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: enabled ? () => _openSheet(context) : null,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFFE2E8F0),
                width: 1,
              ),
            ),
            child: Icon(
              Icons.flag_outlined,
              color: enabled ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
              size: 18,
            ),
          ),
        ),
      );
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? () => _openSheet(context) : null,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: border, width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.flag_outlined, size: 15, color: fg),
              const SizedBox(width: 6),
              Text(
                'Report',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                  color: fg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openSheet(BuildContext context) async {
    final sent = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AiReportSheet(
        preview: contentSnippet.trim(),
        contentType: contentType,
        contentSnippet: contentSnippet.trim(),
        activitySlug: activitySlug,
        sessionId: sessionId,
      ),
    );
    if (sent != true || !context.mounted) return;
    AppSnackBar.showSuccess(
      context,
      'Thanks — we received your report.',
    );
  }
}

class _AiReportSheet extends StatefulWidget {
  const _AiReportSheet({
    required this.preview,
    required this.contentType,
    required this.contentSnippet,
    required this.activitySlug,
    required this.sessionId,
  });

  final String preview;
  final String contentType;
  final String contentSnippet;
  final String activitySlug;
  final String sessionId;

  @override
  State<_AiReportSheet> createState() => _AiReportSheetState();
}

class _AiReportSheetState extends State<_AiReportSheet> {
  static const _reasons = <({String id, String label, String hint, IconData icon})>[
    (
      id: 'inaccurate',
      label: 'Inaccurate or unhelpful',
      hint: 'Wrong advice or doesn’t match what I said',
      icon: Icons.psychology_alt_outlined,
    ),
    (
      id: 'offensive',
      label: 'Offensive or inappropriate',
      hint: 'Language or tone that shouldn’t appear',
      icon: Icons.sentiment_dissatisfied_outlined,
    ),
    (
      id: 'harmful',
      label: 'Harmful or unsafe',
      hint: 'Could cause harm if followed',
      icon: Icons.health_and_safety_outlined,
    ),
    (
      id: 'spam',
      label: 'Spam or irrelevant',
      hint: 'Nonsense or unrelated to the drill',
      icon: Icons.block_outlined,
    ),
    (
      id: 'other',
      label: 'Something else',
      hint: 'Tell us briefly below',
      icon: Icons.more_horiz_rounded,
    ),
  ];

  String? _reason;
  final _detailController = TextEditingController();
  final _scrollController = ScrollController();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _detailController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_reason == null || _submitting) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await HakkiriApiService.instance.reportAiContent(
        contentType: widget.contentType,
        reason: _reason!,
        contentSnippet: widget.contentSnippet,
        detail: _detailController.text.trim(),
        activitySlug: widget.activitySlug,
        sessionId: widget.sessionId,
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } on HakkiriApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = 'Could not send the report. Check your connection.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final maxH = MediaQuery.sizeOf(context).height * 0.9;
    final preview = widget.preview.length > 160
        ? '${widget.preview.substring(0, 160)}…'
        : widget.preview;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxH),
          child: Material(
            color: const Color(0xFFFBFBF9),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            clipBehavior: Clip.antiAlias,
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(22, 12, 14, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: const Color(0xFFCBD5E1),
                              borderRadius: BorderRadius.circular(99),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: AppColors.royalBlueSoft,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(
                                Icons.flag_rounded,
                                color: AppColors.royalBlue,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Report this feedback',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 20,
                                      fontWeight: FontWeight.w900,
                                      color: AppColors.textPrimary,
                                      letterSpacing: -0.4,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'Tell us if this coaching note missed the mark.',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 4),
                            Material(
                              color: const Color(0xFFF1F5F9),
                              shape: const CircleBorder(),
                              child: InkWell(
                                customBorder: const CircleBorder(),
                                onTap: _submitting
                                    ? null
                                    : () => Navigator.pop(context),
                                child: const Padding(
                                  padding: EdgeInsets.all(8),
                                  child: Icon(
                                    Icons.close_rounded,
                                    size: 20,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Flexible(
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(22, 16, 22, 12),
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'REPORTING',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.1,
                                    color: Color(0xFF94A3B8),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  preview,
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF334155),
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),
                          const Text(
                            'Why are you reporting this?',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 10),
                          ..._reasons.map((r) {
                            final selected = _reason == r.id;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: _submitting
                                      ? null
                                      : () => setState(() => _reason = r.id),
                                  borderRadius: BorderRadius.circular(16),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 160),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: selected
                                          ? AppColors.royalBlueSoft
                                          : Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: selected
                                            ? AppColors.royalBlue
                                            : const Color(0xFFE2E8F0),
                                        width: selected ? 1.5 : 1,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          r.icon,
                                          size: 20,
                                          color: selected
                                              ? AppColors.royalBlue
                                              : const Color(0xFF64748B),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                r.label,
                                                style: TextStyle(
                                                  fontFamily: 'Inter',
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w700,
                                                  color: selected
                                                      ? AppColors.royalBlue
                                                      : AppColors.textPrimary,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                r.hint,
                                                style: const TextStyle(
                                                  fontFamily: 'Inter',
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500,
                                                  color: Color(0xFF94A3B8),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Icon(
                                          selected
                                              ? Icons.check_circle_rounded
                                              : Icons.circle_outlined,
                                          size: 20,
                                          color: selected
                                              ? AppColors.royalBlue
                                              : const Color(0xFFCBD5E1),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _detailController,
                            maxLines: 3,
                            maxLength: 500,
                            enabled: !_submitting,
                            textInputAction: TextInputAction.done,
                            onTap: () {
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (!_scrollController.hasClients) return;
                                _scrollController.animateTo(
                                  _scrollController.position.maxScrollExtent,
                                  duration: const Duration(milliseconds: 220),
                                  curve: Curves.easeOut,
                                );
                              });
                            },
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                            decoration: InputDecoration(
                              hintText:
                                  'Optional details (helps us review faster)',
                              hintStyle: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 13.5,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF94A3B8),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              counterText: '',
                              contentPadding: const EdgeInsets.all(14),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(
                                  color: Color(0xFFE2E8F0),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(
                                  color: Color(0xFFE2E8F0),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(
                                  color: AppColors.royalBlue,
                                  width: 1.4,
                                ),
                              ),
                            ),
                          ),
                          if (_error != null) ...[
                            const SizedBox(height: 12),
                            Text(
                              _error!,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFFDC2626),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(22, 8, 22, 16),
                    child: SizedBox(
                      height: 54,
                      width: double.infinity,
                      child: FilledButton(
                        onPressed:
                            _reason == null || _submitting ? null : _submit,
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF13141F),
                          disabledBackgroundColor:
                              const Color(0xFF13141F).withValues(alpha: 0.35),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                        ),
                        child: _submitting
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.4,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Submit report',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
