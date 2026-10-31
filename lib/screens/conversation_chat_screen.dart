import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../models/session_model.dart';

/// Full chat transcript for a back-and-forth voice practice session.
class ConversationChatScreen extends StatelessWidget {
  final List<ConversationTurn> turns;
  final String? title;

  const ConversationChatScreen({
    super.key,
    required this.turns,
    this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          title ?? 'Your conversation',
          style: const TextStyle(
            fontFamily: 'Inter',
            color: Color(0xFF0F172A),
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: true,
      ),
      body: turns.isEmpty
          ? const Center(
              child: Text(
                'No conversation was saved for this session.',
                style: TextStyle(
                  fontFamily: 'Inter',
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
              itemCount: turns.length,
              itemBuilder: (context, index) {
                final turn = turns[index];
                final isUser = turn.role == 'user';
                return Align(
                  alignment:
                      isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.sizeOf(context).width * 0.82,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: isUser
                          ? AppColors.royalBlue
                          : Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: Radius.circular(isUser ? 16 : 4),
                        bottomRight: Radius.circular(isUser ? 4 : 16),
                      ),
                      border: isUser
                          ? null
                          : Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isUser ? 'You' : 'Coach',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.4,
                            color: isUser
                                ? Colors.white.withValues(alpha: 0.75)
                                : AppColors.royalBlue,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          turn.text,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14.5,
                            fontWeight: FontWeight.w600,
                            height: 1.4,
                            color: isUser
                                ? Colors.white
                                : const Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
