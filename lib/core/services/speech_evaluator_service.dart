import '../constants/app_strings.dart';
import '../../models/activity_model.dart';
import '../../models/session_model.dart';

class SpeechEvaluatorService {
  /// Evaluates speech input against Hakkiri's 4-pillar executive communication rubric
  static EvaluationFeedback evaluateSpeech({
    required PromptModel prompt,
    required String transcript,
    required int durationSeconds,
    bool isRetry = false,
  }) {
    final lower = transcript.toLowerCase();

    // 1. Detect corporate crutch phrases
    final detectedCrutches = <String>[];
    for (final crutch in AppStrings.corporateCrutches) {
      if (lower.contains(crutch)) {
        detectedCrutches.add(crutch);
      }
    }

    // 2. Count words and words per minute
    final words = transcript.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    final wordCount = words.length;
    final minutes = (durationSeconds > 0 ? durationSeconds : 60) / 60.0;
    final wpm = (wordCount / minutes).round();

    // 3. Simulating acoustic telemetry metrics
    final int powerPauseCount = (durationSeconds > 25) ? 2 : 1;
    final bool uptalk = lower.endsWith('?') || lower.contains('right?');
    final bool isMonotone = wordCount < 30;

    // 4. Calculate Pillar Scores (1 to 5)
    int execScore = 4;
    if (detectedCrutches.length > 2 || uptalk) {
      execScore = 3;
    } else if (detectedCrutches.isEmpty && powerPauseCount >= 2) {
      execScore = 5;
    }

    int clarityScore = 4;
    if (wpm > 180 || wpm < 110) {
      clarityScore = 3;
    } else if (wpm >= 130 && wpm <= 160) {
      clarityScore = 5;
    }

    int impactScore = 4;
    if (prompt.activitySlug == 'cut_it_in_half' && prompt.secondaryText != null) {
      final origCount = prompt.secondaryText!.split(RegExp(r'\s+')).length;
      final compressionPct = ((origCount - wordCount) / origCount * 100).round();
      if (compressionPct >= 50) {
        impactScore = 5;
      } else if (compressionPct < 30) {
        impactScore = 3;
      }
    }

    int engagementScore = isMonotone ? 3 : 5;

    final overall = ((execScore + clarityScore + impactScore + engagementScore) / 4.0).round().clamp(1, 5);

    // 5. Strict Feedback Structure
    String strength = 'Composed baseline cadence with clear vocal projection.';
    if (powerPauseCount >= 2) {
      strength = 'Commanded authority by utilizing $powerPauseCount deliberate power pauses before strategic points.';
    }

    String improvement = 'Reduce subtle permission-seeking crutches at sentence ends.';
    String retryInstruction = 'Lead with the decisive conclusion in the first 5 seconds and maintain flat statement tone.';
    HighlightedPhrase highlight = const HighlightedPhrase(
      timestampRange: '00:14 - 00:20',
      phrase: '...so basically, if that makes sense...',
      critique: 'Uptalk and crutch words dilute executive presence.',
    );

    if (detectedCrutches.isNotEmpty) {
      final firstCrutch = detectedCrutches.first;
      improvement = 'Eliminate the crutch phrase "$firstCrutch" to project unwavering executive conviction.';
      retryInstruction = 'Replace "$firstCrutch" with a 1-second silent power pause before stating your proposal.';
      highlight = HighlightedPhrase(
        timestampRange: '00:18 - 00:24',
        phrase: '...$firstCrutch...',
        critique: 'Crutch word signals cognitive hesitation during unscripted delivery.',
      );
    }

    if (isRetry) {
      strength = 'Coached Retry: Noticeable reduction in filler words and crisper sentence closures.';
    }

    final pillars = FourPillarsScore(
      executiveScore: execScore,
      clarityScore: clarityScore,
      impactScore: impactScore,
      engagementScore: engagementScore,
      crutchCount: detectedCrutches.length,
      powerPauseCount: powerPauseCount,
      pacingWpm: wpm,
      intelligibilityPercentage: 94,
      actionVerbPercentage: 70,
      isMonotoneWarning: isMonotone,
    );

    return EvaluationFeedback(
      overallScore: overall,
      pillars: pillars,
      oneStrength: strength,
      oneSpecificImprovement: improvement,
      highlightedPhrase: highlight,
      retryInstruction: retryInstruction,
      exemplarResponse: prompt.exemplarResponse,
      isCoachedRetry: isRetry,
    );
  }
}
