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
}
