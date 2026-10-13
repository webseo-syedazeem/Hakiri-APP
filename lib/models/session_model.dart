class FourPillarsScore {
  final int executiveScore; // 1 to 5
  final int clarityScore;
  final int impactScore;
  final int engagementScore;

  final int crutchCount;
  final int powerPauseCount;
  final int pacingWpm;
  final int intelligibilityPercentage;
  final int actionVerbPercentage;
  final bool isMonotoneWarning;

  const FourPillarsScore({
    required this.executiveScore,
    required this.clarityScore,
    required this.impactScore,
    required this.engagementScore,
    required this.crutchCount,
    required this.powerPauseCount,
    required this.pacingWpm,
    required this.intelligibilityPercentage,
    required this.actionVerbPercentage,
    required this.isMonotoneWarning,
  });

  Map<String, dynamic> toJson() => {
        'executive_score': executiveScore,
        'clarity_score': clarityScore,
        'impact_score': impactScore,
        'engagement_score': engagementScore,
        'crutch_count': crutchCount,
        'power_pause_count': powerPauseCount,
        'pacing_wpm': pacingWpm,
        'intelligibility_pct': intelligibilityPercentage,
        'action_verb_pct': actionVerbPercentage,
        'is_monotone': isMonotoneWarning,
      };

  factory FourPillarsScore.fromJson(Map<String, dynamic>? json) {
    final map = json ?? const <String, dynamic>{};
    int read(String key, [int fallback = 3]) {
      final value = map[key];
      if (value is num) return value.round().clamp(1, 5);
      return fallback;
    }

    return FourPillarsScore(
      executiveScore: read('executive_score'),
      clarityScore: read('clarity_score'),
      impactScore: read('impact_score'),
      engagementScore: read('engagement_score'),
      crutchCount: (map['crutch_count'] as num?)?.round() ?? 0,
      powerPauseCount: (map['power_pause_count'] as num?)?.round() ?? 0,
      pacingWpm: (map['pacing_wpm'] as num?)?.round() ?? 0,
      intelligibilityPercentage: (map['intelligibility_pct'] as num?)?.round() ?? 0,
      actionVerbPercentage: (map['action_verb_pct'] as num?)?.round() ?? 0,
      isMonotoneWarning: map['is_monotone'] == true,
    );
  }
}

class HighlightedPhrase {
  final String timestampRange;
  final String phrase;
  final String critique;

  const HighlightedPhrase({
    required this.timestampRange,
    required this.phrase,
    required this.critique,
  });

  Map<String, dynamic> toJson() => {
        'timestamp_range': timestampRange,
        'phrase': phrase,
        'critique': critique,
      };
}

class ConversationTurn {
  final String role; // user | coach
  final String text;

  const ConversationTurn({required this.role, required this.text});

  Map<String, dynamic> toJson() => {
        'role': role,
        'text': text,
      };

  factory ConversationTurn.fromJson(Map<String, dynamic> json) => ConversationTurn(
        role: (json['role'] ?? 'user').toString(),
        text: (json['text'] ?? '').toString(),
      );
}

class EvaluationFeedback {
  final int overallScore; // 1 to 5
  final FourPillarsScore pillars;
  final String oneStrength;
  final String oneSpecificImprovement;
  final HighlightedPhrase highlightedPhrase;
  final String retryInstruction;
  final String exemplarResponse;
  final bool isCoachedRetry;

  const EvaluationFeedback({
    required this.overallScore,
    required this.pillars,
    required this.oneStrength,
    required this.oneSpecificImprovement,
    required this.highlightedPhrase,
    required this.retryInstruction,
    required this.exemplarResponse,
    required this.isCoachedRetry,
  });

  Map<String, dynamic> toJson() => {
        'overall_score': overallScore,
        'pillars': pillars.toJson(),
        'one_strength': oneStrength,
        'one_specific_improvement': oneSpecificImprovement,
        'highlighted_phrase': highlightedPhrase.toJson(),
        'retry_instruction': retryInstruction,
        'exemplar_response': exemplarResponse,
        'is_coached_retry': isCoachedRetry,
      };

  factory EvaluationFeedback.fromJson(Map<String, dynamic>? json) {
    final map = json ?? const <String, dynamic>{};
    final phrase = (map['highlighted_phrase'] as Map<String, dynamic>?) ?? {};
    final overall = map['overall_score'];
    return EvaluationFeedback(
      overallScore: overall is num ? overall.round().clamp(1, 5) : 3,
      pillars: FourPillarsScore.fromJson(map['pillars'] as Map<String, dynamic>?),
      oneStrength: (map['one_strength'] ?? '').toString(),
      oneSpecificImprovement: (map['one_specific_improvement'] ?? '').toString(),
      highlightedPhrase: HighlightedPhrase(
        timestampRange: (phrase['timestamp_range'] ?? '').toString(),
        phrase: (phrase['phrase'] ?? '').toString(),
        critique: (phrase['critique'] ?? '').toString(),
      ),
      retryInstruction: (map['retry_instruction'] ?? '').toString(),
      exemplarResponse: (map['exemplar_response'] ?? '').toString(),
      isCoachedRetry: map['is_coached_retry'] == true,
    );
  }
}

class PracticeSessionRecord {
  final String id;
  final String activitySlug;
  final String activityName;
  final String promptTitle;
  final String promptText;
  final String transcript;
  /// `single` = one-shot drill; `back_and_forth` = live coach conversation.
  final String conversationMode;
  final List<ConversationTurn> conversationTurns;
  final DateTime timestamp;
  final int durationSeconds;
  final EvaluationFeedback feedback;
  /// On-device recording path (never uploaded).
  final String? localAudioPath;

  const PracticeSessionRecord({
    required this.id,
    required this.activitySlug,
    required this.activityName,
    required this.promptTitle,
    this.promptText = '',
    this.transcript = '',
    this.conversationMode = 'single',
    this.conversationTurns = const [],
    required this.timestamp,
    required this.durationSeconds,
    required this.feedback,
    this.localAudioPath,
  });

  bool get isBackAndForth => conversationMode == 'back_and_forth';

  PracticeSessionRecord copyWith({
    String? id,
    String? localAudioPath,
    String? transcript,
    String? promptText,
    String? conversationMode,
    List<ConversationTurn>? conversationTurns,
  }) {
    return PracticeSessionRecord(
      id: id ?? this.id,
      activitySlug: activitySlug,
      activityName: activityName,
      promptTitle: promptTitle,
      promptText: promptText ?? this.promptText,
      transcript: transcript ?? this.transcript,
      conversationMode: conversationMode ?? this.conversationMode,
      conversationTurns: conversationTurns ?? this.conversationTurns,
      timestamp: timestamp,
      durationSeconds: durationSeconds,
      feedback: feedback,
      localAudioPath: localAudioPath ?? this.localAudioPath,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'activity_slug': activitySlug,
        'activity_name': activityName,
        'prompt_title': promptTitle,
        'prompt_text': promptText,
        'transcript': transcript,
        'conversation_mode': conversationMode,
        'conversation_turns': conversationTurns.map((t) => t.toJson()).toList(),
        'timestamp': timestamp.toIso8601String(),
        'duration_seconds': durationSeconds,
        'feedback': feedback.toJson(),
        if (localAudioPath != null) 'local_audio_path': localAudioPath,
      };

  factory PracticeSessionRecord.fromApi(Map<String, dynamic> json) {
    final stamp = DateTime.tryParse((json['timestamp'] ?? '').toString()) ?? DateTime.now();
    final feedbackMap = json['feedback'];
    final turnsRaw = json['conversation_turns'];
    final turns = <ConversationTurn>[];
    if (turnsRaw is List) {
      for (final item in turnsRaw) {
        if (item is Map) {
          turns.add(ConversationTurn.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }
    final mode = (json['conversation_mode'] ?? 'single').toString();
    return PracticeSessionRecord(
      id: (json['id'] ?? '').toString(),
      activitySlug: (json['activity_slug'] ?? '').toString(),
      activityName: (json['activity_name'] ?? 'Practice').toString(),
      promptTitle: (json['prompt_title'] ?? '').toString(),
      promptText: (json['prompt_text'] ?? '').toString(),
      transcript: (json['transcript'] ?? '').toString(),
      conversationMode: mode == 'back_and_forth' ? 'back_and_forth' : 'single',
      conversationTurns: turns,
      timestamp: stamp,
      durationSeconds: (json['duration_seconds'] as num?)?.round() ?? 0,
      feedback: EvaluationFeedback.fromJson(
        feedbackMap is Map<String, dynamic> ? feedbackMap : null,
      ),
      localAudioPath: json['local_audio_path']?.toString(),
    );
  }
}
