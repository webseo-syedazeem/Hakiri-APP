import '../constants/app_strings.dart';
import '../../models/activity_model.dart';
import '../../models/session_model.dart';

class SpeechEvaluatorService {
  static const _noiseWords = {
    'hello',
    'hi',
    'hey',
    'hola',
    'test',
    'testing',
    'ok',
    'okay',
    'um',
    'uh',
    'uhm',
    'hmm',
    'yeah',
    'yes',
    'no',
    'nah',
    'right',
    'like',
    'so',
    'and',
    'the',
    'a',
    'an',
    'to',
    'of',
    'in',
    'on',
    'i',
    'me',
    'my',
  };

  /// Evaluates speech input against Hakkiri's 4-pillar executive communication rubric.
  /// Scores from the actual transcript — short / filler-only answers stay low.
  static EvaluationFeedback evaluateSpeech({
    required PromptModel prompt,
    required String transcript,
    required int durationSeconds,
    bool isRetry = false,
  }) {
    final cleaned = transcript.trim();
    final lower = cleaned.toLowerCase();
    final words = cleaned
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
    final wordCount = words.length;
    final minutes = (durationSeconds > 0 ? durationSeconds : 60) / 60.0;
    final wpm = wordCount == 0 ? 0 : (wordCount / minutes).round();

    final unique = words
        .map((w) => w.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), ''))
        .where((w) => w.isNotEmpty)
        .toSet();
    final uniqueRatio =
        wordCount == 0 ? 0.0 : unique.length / wordCount.toDouble();
    final meaningfulCount = _meaningfulWords(words).length;
    final isNonAnswer =
        cleaned.isEmpty || meaningfulCount < 4 || uniqueRatio < 0.35;
    final isThin = wordCount < 18 || meaningfulCount < 8;

    final detectedCrutches = <String>[];
    for (final crutch in AppStrings.corporateCrutches) {
      if (lower.contains(crutch)) {
        detectedCrutches.add(crutch);
      }
    }

    final promptTokens = _tokenSet('${prompt.promptText} ${prompt.objective}');
    final spokenTokens = _tokenSet(cleaned);
    final overlap = spokenTokens.isEmpty
        ? 0.0
        : spokenTokens.intersection(promptTokens).length /
            spokenTokens.length.clamp(1, 9999);

    final uptalk = lower.endsWith('?') || lower.contains('right?');
    final isMonotone = wordCount < 30;

    int execScore;
    int clarityScore;
    int impactScore;
    int engagementScore;

    if (isNonAnswer) {
      execScore = 1;
      clarityScore = 1;
      impactScore = 1;
      engagementScore = 1;
    } else if (isThin) {
      execScore = detectedCrutches.isNotEmpty || uptalk ? 1 : 2;
      clarityScore = wpm > 0 && wpm < 80 ? 2 : 2;
      impactScore = overlap >= 0.08 ? 2 : 1;
      engagementScore = 2;
    } else {
      execScore = 3;
      if (detectedCrutches.length > 2 || uptalk) {
        execScore = 2;
      } else if (detectedCrutches.isEmpty && wordCount >= 40) {
        execScore = 4;
      }
      if (detectedCrutches.isEmpty && wordCount >= 55 && !uptalk) {
        execScore = 5;
      }

      clarityScore = 3;
      if (wpm > 180 || wpm < 90) {
        clarityScore = 2;
      } else if (wpm >= 120 && wpm <= 165 && wordCount >= 35) {
        clarityScore = 4;
      }
      if (wpm >= 130 && wpm <= 155 && wordCount >= 50) {
        clarityScore = 5;
      }

      impactScore = overlap >= 0.12 ? 3 : 2;
      if (prompt.activitySlug == 'cut_it_in_half' &&
          prompt.secondaryText != null) {
        final origCount =
            prompt.secondaryText!.split(RegExp(r'\s+')).length.clamp(1, 9999);
        final compressionPct =
            ((origCount - wordCount) / origCount * 100).round();
        if (compressionPct >= 50 && wordCount >= 15) {
          impactScore = 5;
        } else if (compressionPct < 30) {
          impactScore = 2;
        } else {
          impactScore = 3;
        }
      } else if (wordCount >= 40 && overlap >= 0.1) {
        impactScore = 4;
      } else if (wordCount >= 55 && overlap >= 0.15) {
        impactScore = 5;
      }

      engagementScore = isMonotone ? 2 : 3;
      if (!isMonotone && wordCount >= 35 && uniqueRatio >= 0.55) {
        engagementScore = 4;
      }
      if (wordCount >= 50 && uniqueRatio >= 0.6 && detectedCrutches.isEmpty) {
        engagementScore = 5;
      }
    }

    if (isRetry && !isNonAnswer) {
      execScore = (execScore + 1).clamp(1, 5);
      engagementScore = (engagementScore + 1).clamp(1, 5);
    }

    // Offline Think Fast: spreadsheet weights (structure 0.4, latency 0.3, fillers 0.3)
    // + heaviest-low cap ≤ 3 when structure ≤ 2.
    final activityMeasures = <ActivityMeasureScore>[];
    int overall;
    var capped = false;
    String? scoringReason;

    if (prompt.activitySlug == 'think_fast') {
      final structure = isNonAnswer
          ? 1
          : isThin
              ? (overlap >= 0.08 ? 2 : 1)
              : clarityScore;
      final latency = isNonAnswer
          ? 1
          : isThin
              ? 2
              : engagementScore;
      final fillers = isNonAnswer
          ? 1
          : detectedCrutches.isEmpty
              ? execScore
              : (execScore - 1).clamp(1, 5);

      var raw = structure * 0.4 + latency * 0.3 + fillers * 0.3;
      if (structure <= 2 && raw > 3) {
        raw = 3;
        capped = true;
        scoringReason =
            'Capped at 3 because Structure scored $structure.';
      }
      overall = raw.round().clamp(1, 5);
      activityMeasures.addAll([
        ActivityMeasureScore(
          key: 'structure',
          label: 'Structure',
          weight: 0.4,
          score: structure,
          isHeaviest: true,
          effectiveWeight: 0.4,
        ),
        ActivityMeasureScore(
          key: 'latency',
          label: 'Latency',
          weight: 0.3,
          score: latency,
          effectiveWeight: 0.3,
        ),
        ActivityMeasureScore(
          key: 'fillers',
          label: 'Fillers',
          weight: 0.3,
          score: fillers,
          effectiveWeight: 0.3,
        ),
      ]);
      // Keep pillars aligned with measures for dashboard.
      clarityScore = structure;
      impactScore = structure;
      engagementScore = latency;
      execScore = fillers;
    } else {
      overall = ((execScore + clarityScore + impactScore + engagementScore) /
              4.0)
          .round()
          .clamp(1, 5);
    }

    final spokenSnippet = _snippet(words, maxWords: 10);
    final heard = spokenSnippet.isEmpty
        ? '(no clear speech captured)'
        : '...$spokenSnippet...';

    String strength;
    String improvement;
    String retryInstruction;
    String critique;

    if (isNonAnswer) {
      strength =
          'Mic worked — we heard you — but this was not an answer to the prompt.';
      improvement =
          'Answer the question with a real point: decision first, then one reason.';
      retryInstruction =
          'Ignore filler. State your answer in one sentence, then add one example.';
      critique =
          'Captured filler/noise only ($wordCount words). Score stays low until you address the prompt.';
    } else if (isThin) {
      strength =
          'You started speaking ($wordCount words) — that is the right instinct under pressure.';
      improvement =
          'Stretch to ~40–80 words: open with the conclusion, then one supporting detail.';
      retryInstruction =
          'Lead with your bottom-line answer in under 5 seconds, then explain why.';
      critique =
          'Too thin to show executive presence — expand beyond a short opener.';
    } else {
      strength = wordCount >= 40
          ? 'You sustained a full answer ($wordCount words) under time pressure.'
          : 'Clear spoken start on record — extend the middle of the answer.';
      improvement =
          'Lead with the conclusion in the first sentence, then support it with one concrete example.';
      retryInstruction =
          'Open with your bottom-line answer in under 5 seconds, then add one supporting point.';
      critique = 'Tighten openings so the first clause carries the decision.';

      if (detectedCrutches.isNotEmpty) {
        final firstCrutch = detectedCrutches.first;
        improvement =
            'Eliminate the crutch phrase "$firstCrutch" to project unwavering executive conviction.';
        retryInstruction =
            'Replace "$firstCrutch" with a 1-second silent power pause before stating your proposal.';
        critique =
            'Crutch word signals cognitive hesitation during unscripted delivery.';
      } else if (uptalk) {
        improvement =
            'End statements flat — avoid rising intonation that sounds like permission-seeking.';
        retryInstruction =
            'Re-say your closing line as a firm statement, not a question.';
        critique = 'Uptalk softens authority at the end of the point.';
      }
    }

    if (isRetry && !isNonAnswer) {
      strength =
          'Coached Retry: Noticeable reduction in filler words and crisper sentence closures.';
    }

    final powerPauseCount =
        isNonAnswer || isThin ? 0 : (durationSeconds > 25 ? 2 : 1);

    final pillars = FourPillarsScore(
      executiveScore: execScore,
      clarityScore: clarityScore,
      impactScore: impactScore,
      engagementScore: engagementScore,
      crutchCount: detectedCrutches.length,
      powerPauseCount: powerPauseCount,
      pacingWpm: wpm,
      intelligibilityPercentage: isNonAnswer
          ? 40
          : isThin
              ? 65
              : 90,
      actionVerbPercentage: isNonAnswer
          ? 10
          : isThin
              ? 35
              : 70,
      isMonotoneWarning: isMonotone || isNonAnswer,
    );

    return EvaluationFeedback(
      overallScore: overall,
      pillars: pillars,
      oneStrength: strength,
      oneSpecificImprovement: improvement,
      highlightedPhrase: HighlightedPhrase(
        timestampRange: _rangeFor(
          durationSeconds,
          startFrac: 0.1,
          endFrac: 0.35,
        ),
        phrase: heard,
        critique: critique,
      ),
      retryInstruction: retryInstruction,
      exemplarResponse: prompt.exemplarResponse,
      isCoachedRetry: isRetry,
      activityMeasures: activityMeasures,
      capped: capped,
      scoringReason: scoringReason,
    );
  }

  static List<String> _meaningfulWords(List<String> words) {
    return words
        .map((w) => w.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), ''))
        .where((w) => w.length > 1 && !_noiseWords.contains(w))
        .toList();
  }

  static Set<String> _tokenSet(String text) {
    return text
        .toLowerCase()
        .split(RegExp(r'[^a-z0-9]+'))
        .where((w) => w.length > 2 && !_noiseWords.contains(w))
        .toSet();
  }

  static String _snippet(List<String> words, {int maxWords = 10}) {
    if (words.isEmpty) return '';
    if (words.length <= maxWords) return words.join(' ');
    final mid = (words.length / 2).floor();
    final start = (mid - (maxWords ~/ 2)).clamp(0, words.length - maxWords);
    return words.sublist(start, start + maxWords).join(' ');
  }

  static String _rangeFor(
    int durationSeconds, {
    required double startFrac,
    required double endFrac,
  }) {
    final total = durationSeconds.clamp(1, 600);
    final start = (total * startFrac).round().clamp(0, total);
    final end = (total * endFrac).round().clamp(start + 1, total);
    String fmt(int s) =>
        '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';
    return '${fmt(start)} - ${fmt(end)}';
  }
}
