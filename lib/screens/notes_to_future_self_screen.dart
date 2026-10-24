import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state_provider.dart';
import '../widgets/practice_orbital_accent.dart';

class NotesToFutureSelfScreen extends StatefulWidget {
  const NotesToFutureSelfScreen({super.key});

  @override
  State<NotesToFutureSelfScreen> createState() => _NotesToFutureSelfScreenState();
}

class _NotesToFutureSelfScreenState extends State<NotesToFutureSelfScreen> {
  final TextEditingController _learningsController = TextEditingController();
  final TextEditingController _customFocusController = TextEditingController();
  String? _selectedFocus;

  final List<Map<String, dynamic>> _focusOptions = const [
    {
      'label': 'Think more clearly',
      'icon': Icons.bolt_rounded,
      'color': Color(0xFF2563EB),
      'bg': Color(0xFFEFF6FF),
    },
    {
      'label': 'Be more concise',
      'icon': Icons.content_cut_rounded,
      'color': Color(0xFFD97706),
      'bg': Color(0xFFF8FAFC),
    },
    {
      'label': 'Tell better stories',
      'icon': Icons.menu_book_rounded,
      'color': Color(0xFF9333EA),
      'bg': Color(0xFFF3E8FF),
    },
    {
      'label': 'Engage people more',
      'icon': Icons.hub_rounded,
      'color': Color(0xFFEA580C),
      'bg': Color(0xFFFEE2E2),
    },
    {
      'label': 'Build my confidence',
      'icon': Icons.bar_chart_rounded,
      'color': Color(0xFF10B981),
      'bg': Color(0xFFDCFCE7),
    },
  ];

  @override
  void initState() {
    super.initState();
    _learningsController.addListener(() => setState(() {}));
    _customFocusController.addListener(() {
      if (_customFocusController.text.isNotEmpty && _selectedFocus != null) {
        setState(() => _selectedFocus = null);
      } else {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _learningsController.dispose();
    _customFocusController.dispose();
    super.dispose();
  }

  void _saveNote() {
    final learnings = _learningsController.text.trim();
    final focus = _customFocusController.text.trim().isNotEmpty
        ? _customFocusController.text.trim()
        : (_selectedFocus ?? 'General growth');

    if (learnings.isEmpty && focus.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please share a few thoughts before saving.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final firstLine = learnings.split('\n').first;
    final title = firstLine.length > 28
        ? '${firstLine.substring(0, 28)}...'
        : (firstLine.isNotEmpty ? firstLine : focus);

    context.read<AppStateProvider>().addReflectionNote(
          title: title,
          learnings: learnings.isNotEmpty ? learnings : 'Focused on $focus today.',
          focusArea: focus,
        );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Note saved to your reflections!'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Color(0xFF10B981),
        duration: Duration(seconds: 2),
      ),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          const PracticeOrbitalAccent(topOffset: 16, rightOffset: 0),
          SafeArea(
            child: Column(
              children: [
                // Top Navigation Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        behavior: HitTestBehavior.opaque,
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.chevron_left_rounded,
                              size: 28,
                              color: Color(0xFF0F172A),
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Reflect and grow',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Main Scrollable Content
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Note Squircle Icon Badge (orange, matching the design)
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF0DD),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.edit_note_rounded,
                            color: Color(0xFFF59E0B),
                            size: 34,
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Large Headline
                        const Text(
                          'Notes to Future Self',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 34,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0F172A),
                            letterSpacing: -0.9,
                            height: 1.12,
                          ),
                        ),
                        const SizedBox(height: 6),

                        // Subtitle
                        const Text(
                          'Capture what you’ve learned and set a focus for next time.',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13.5,
                            color: Color(0xFF64748B),
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Card 1: What did you learn today?
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: const Color(0xFFF1F5F9)),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF0F172A).withValues(alpha: 0.03),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'What did you learn today?',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Write a few thoughts about what went well or what you’d do differently.',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 12.5,
                                  color: Color(0xFF64748B),
                                  height: 1.3,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                ),
                                padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
                                child: Column(
                                  children: [
                                    TextField(
                                      controller: _learningsController,
                                      maxLines: 5,
                                      minLines: 4,
                                      maxLength: 300,
                                      style: const TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 14,
                                        color: Color(0xFF0F172A),
                                        height: 1.35,
                                      ),
                                      decoration: const InputDecoration(
                                        hintText: 'Start typing...',
                                        hintStyle: TextStyle(
                                          color: Color(0xFF94A3B8),
                                          fontSize: 14,
                                        ),
                                        border: InputBorder.none,
                                        isDense: true,
                                        counterText: '',
                                        contentPadding: EdgeInsets.zero,
                                      ),
                                    ),
                                    Align(
                                      alignment: Alignment.bottomRight,
                                      child: Text(
                                        '${_learningsController.text.length}/300',
                                        style: const TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: 11.5,
                                          color: Color(0xFF94A3B8),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Card 2: What do you want to focus on next time?
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: const Color(0xFFF1F5F9)),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF0F172A).withValues(alpha: 0.03),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'What do you want to focus on next time?',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Choose a focus or write your own.',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 12.5,
                                  color: Color(0xFF64748B),
                                  height: 1.3,
                                ),
                              ),
                              const SizedBox(height: 14),

                              // Selectable chips matching mockup layout
                              Wrap(
                                spacing: 6,
                                runSpacing: 7,
                                children: _focusOptions.map((opt) {
                                  final label = opt['label'] as String;
                                  final icon = opt['icon'] as IconData;
                                  final color = opt['color'] as Color;
                                  final bg = opt['bg'] as Color;
                                  final isSelected = _selectedFocus == label;

                                  return GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        if (isSelected) {
                                          _selectedFocus = null;
                                        } else {
                                          _selectedFocus = label;
                                          _customFocusController.clear();
                                        }
                                      });
                                    },
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 180),
                                      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
                                      decoration: BoxDecoration(
                                        color: isSelected ? const Color(0xFFEFF6FF) : bg,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: isSelected
                                              ? const Color(0xFF2563EB)
                                              : const Color(0xFFE2E8F0),
                                          width: isSelected ? 1.8 : 1.0,
                                        ),
                                        boxShadow: isSelected
                                            ? [
                                                BoxShadow(
                                                  color: const Color(0xFF2563EB).withValues(alpha: 0.15),
                                                  blurRadius: 6,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ]
                                            : null,
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(icon, size: 20, color: color),
                                          const SizedBox(width: 8),
                                          Text(
                                            label,
                                            style: TextStyle(
                                              fontFamily: 'Inter',
                                              fontSize: 13,
                                              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                              color: const Color(0xFF0F172A),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 14),

                              // Custom write-your-own input box
                              Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                ),
                                padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
                                child: Column(
                                  children: [
                                    TextField(
                                      controller: _customFocusController,
                                      maxLines: 2,
                                      minLines: 1,
                                      maxLength: 200,
                                      style: const TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 13.5,
                                        color: Color(0xFF0F172A),
                                        height: 1.3,
                                      ),
                                      decoration: const InputDecoration(
                                        hintText: 'Or write your own focus...',
                                        hintStyle: TextStyle(
                                          color: Color(0xFF94A3B8),
                                          fontSize: 13.5,
                                        ),
                                        border: InputBorder.none,
                                        isDense: true,
                                        counterText: '',
                                        contentPadding: EdgeInsets.zero,
                                      ),
                                    ),
                                    Align(
                                      alignment: Alignment.bottomRight,
                                      child: Text(
                                        '${_customFocusController.text.length}/200',
                                        style: const TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: 11.5,
                                          color: Color(0xFF94A3B8),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Pinned Save Note Button
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _saveNote,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(26),
                        ),
                      ),
                      child: const Text(
                        'Save note',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
