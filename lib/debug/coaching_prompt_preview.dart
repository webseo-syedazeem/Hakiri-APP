import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../screens/coaching_prompt_sheet.dart';
import '../widgets/app_snackbar.dart';

/// Debug-only: cycle sample coaching pop-ups without touching real coaching state.
class CoachingPromptPreview {
  CoachingPromptPreview._();

  static int _index = 0;

  static final List<Map<String, dynamic>> samples = [
    {
      'type': 'level_up',
      'activity_slug': 'think_fast',
      'activity_name': 'Think Fast',
      'eyebrow': 'THINK FAST  ·  LEVEL UP',
      'title': "You're ready for Intermediate.",
      'current_level': 'beginner',
      'next_level': 'intermediary',
      'current_label': 'Beginner',
      'next_label': 'Intermediate',
      'path': [
        {'label': 'Beginner', 'state': 'done'},
        {'label': 'Intermediate', 'state': 'current'},
        {'label': 'Pro', 'state': 'locked'},
      ],
      'last_scores': [4.1, 4.3, 4.0],
      'what_changes':
          'Questions become real work moments, like a client asking why your price went up.',
      'primary_label': 'Move up to Intermediate',
      'secondary_label': 'Stay on Beginner for now',
      'primary_choice': 'accept',
      'secondary_choice': 'decline',
    },
    {
      'type': 'plan_change',
      'eyebrow': 'THE-WEEK CHECK-IN',
      'title': 'Your plan has a fresh focus.',
      'insight': 'Fluency is up from 3.2. Clarity is now your area to grow.',
      'bars': [
        {'key': 'fluency', 'label': 'Fluency', 'score': 3.6, 'weakest': false},
        {
          'key': 'conciseness',
          'label': 'Conciseness',
          'score': 3.4,
          'weakest': false
        },
        {
          'key': 'engagement',
          'label': 'Engagement',
          'score': 3.2,
          'weakest': false
        },
        {'key': 'clarity', 'label': 'Clarity', 'score': 2.8, 'weakest': true},
      ],
      'from_activity_slug': 'think_fast',
      'from_activity_name': 'Think Fast',
      'to_activity_slug': 'debate_me',
      'to_activity_name': 'Debate Me',
      'support_slug': 'explain_it_simply',
      'support_name': 'Explain it Simply',
      'next_drills': ['debate_me', 'explain_it_simply'],
      'reassurance':
          'Think Fast still comes round every few days, and it is always in Practice.',
      'primary_label': 'See my new plan',
      'secondary_label': 'Keep my current plan',
      'primary_choice': 'accept',
      'secondary_choice': 'decline',
    },
    {
      'type': 'progress_check',
      'activity_slug': 'cut_it_in_half',
      'activity_name': 'Cut It in Half',
      'eyebrow': 'CUT IT IN HALF  ·  PROGRESS CHECK',
      'title': "You're getting sharper.",
      'mode': 'growth',
      'from_score': 2.9,
      'to_score': 3.6,
      'trend_label': '▲ 2.9 → 3.6',
      'points': [2.9, 3.0, 3.2, 3.1, 3.4, 3.5, 3.6],
      'wins': [
        {'label': 'Personal best', 'value': '3.6'},
        {'label': 'Fillers', 'value': '5 → 2'},
        {'label': 'Sessions', 'value': '9'},
      ],
      'next_level': 'intermediary',
      'next_label': 'Intermediate',
      'qualifying': 2,
      'needed': 3,
      'distance_label': 'Nearly at Intermediate',
      'tip':
          'Keep this up. A strong week at Beginner unlocks Intermediate. Open with your point in the first few seconds.',
      'primary_label': 'Keep going',
      'primary_choice': 'dismiss',
    },
    {
      'type': 'step_down',
      'activity_slug': 'debate_me',
      'activity_name': 'Debate Me',
      'eyebrow': 'DEBATE ME  ·  YOUR ADVICE',
      'title': 'These questions are tough ones.',
      'body':
          'Debate Me questions at Intermediate are hard for most people. A few days of Beginner questions can build the habit faster, then you can move back up.',
      'build_up_title': 'Build up first',
      'build_up_body': 'Beginner for a few days. Your scores carry over.',
      'stay_title': 'Stay and stretch',
      'stay_body': 'Keep Intermediate, with extra tips each time.',
      'recognition':
          "You've answered every question so far. Showing up is the hard part.",
      'primary_label': 'Build up first',
      'secondary_label': 'Stay and stretch',
      'primary_choice': 'accept',
      'secondary_choice': 'decline',
    },
  ];

  static String get nextLabel {
    final i = _index % samples.length;
    return '${samples[i]['type']} (${i + 1}/${samples.length})';
  }

  /// Shows the next sample pop-up. Does not call coaching APIs or change levels.
  static Future<void> showNext(BuildContext context) async {
    if (!kDebugMode) return;
    final i = _index % samples.length;
    final prompt = Map<String, dynamic>.from(samples[i]);
    final type = '${prompt['type']}';
    _index++;

    AppSnackBar.showInfo(
      context,
      'Debug pop-up: $type (${i + 1}/${samples.length})',
    );

    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black.withValues(alpha: 0.35),
      pageBuilder: (ctx, _, __) {
        return CoachingPromptSheet(
          prompt: prompt,
          previewMode: true,
        );
      },
    );
  }
}
