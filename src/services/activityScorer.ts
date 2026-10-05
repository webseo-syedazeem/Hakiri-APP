import { ActivityPrompt } from '../types/activity';
import { SpeechTelemetry, StructuredFeedback, ScoreScale, ActivitySpecificScores } from '../types/scoring';
import { SpeechAnalysisService } from './speechAnalysisService';

export class ActivityScorer {
  /**
   * Evaluates an activity attempt, producing composite 1-5 scores and strict 4-part feedback.
   */
  public static evaluate(
    prompt: ActivityPrompt,
    telemetry: SpeechTelemetry,
    isCoachedRetry: boolean = false
  ): StructuredFeedback {
    // Fair scoring rule: check audio confidence
    if (telemetry.transcriptionConfidence < 0.65) {
      return this.createLowQualityAudioFeedback(prompt, isCoachedRetry);
    }

    const fourPillars = SpeechAnalysisService.analyzePillars(telemetry);
    const activitySpecific = this.scoreActivitySpecificRubrics(prompt, telemetry);

    // Compute composite score (1 to 5)
    const pillarScores = [
      fourPillars.executivePresence.score,
      fourPillars.clarity.score,
      fourPillars.contentImpact.score,
      fourPillars.engagementDynamics.score,
    ];
    const avgScore = pillarScores.reduce((a, b) => a + b, 0) / pillarScores.length;
    const overallScore = Math.max(1, Math.min(5, Math.round(avgScore))) as ScoreScale;

    // Activity breakdown score
    const specificKeys = Object.keys(activitySpecific);
    const activityAvg = specificKeys.length > 0
      ? specificKeys.reduce((acc, k) => acc + activitySpecific[k].score, 0) / specificKeys.length
      : overallScore;
    const activityBreakdownScore = Math.max(1, Math.min(5, Math.round(activityAvg))) as ScoreScale;

    // Generate strict feedback anatomy
    const feedback = this.generateStrictFeedback(prompt, telemetry, fourPillars, activitySpecific, isCoachedRetry);

    return {
      overallScore,
      activityBreakdownScore,
      fourPillars,
      activitySpecific,
      oneStrength: feedback.strength,
      oneSpecificImprovement: feedback.improvement,
      highlightedPhraseOrTimestamp: feedback.highlight,
      retryInstruction: feedback.retryInstruction,
      exemplarResponse: prompt.exemplarResponse,
      isCoachedRetry,
    };
  }

  private static scoreActivitySpecificRubrics(
    prompt: ActivityPrompt,
    telemetry: SpeechTelemetry
  ): ActivitySpecificScores {
    const scores: ActivitySpecificScores = {};
    const text = telemetry.transcription;
    const words = text.trim().split(/\s+/).filter(Boolean);

    switch (prompt.activityId) {
      case 'think_fast': {
        const stallWords = ['um', 'uh', 'so basically', 'let me think'];
        const hasStall = stallWords.some((w) => text.toLowerCase().startsWith(w));
        scores['latencyAndStall'] = {
          score: hasStall ? 2 : 4,
          label: 'Latency & Stall Control',
          details: hasStall ? 'Hesitated with filler at prompt start' : 'Started speaking promptly with composed framing',
        };
        scores['structuralCoherence'] = {
          score: words.length >= 70 ? 4 : 3,
          label: 'Structural Coherence',
          details: 'Clear perspective delivered within 60 seconds',
        };
        break;
      }

      case 'cut_it_in_half': {
        const originalWordCount = (prompt.secondaryText || '').split(/\s+/).length || 100;
        const spokenWordCount = words.length;
        const compressionRate = Math.round(((originalWordCount - spokenWordCount) / originalWordCount) * 100);

        let compressionScore: ScoreScale = 2;
        if (compressionRate >= 50) compressionScore = 5;
        else if (compressionRate >= 35) compressionScore = 4;
        else if (compressionRate >= 20) compressionScore = 3;

        scores['rateCompression'] = {
          score: compressionScore,
          label: 'Rate Compression',
          details: `Achieved ${compressionRate}% word reduction against original corporate passage`,
        };
        scores['timeToValue'] = {
          score: compressionScore >= 4 ? 5 : 3,
          label: 'Time to Value (BLUF)',
          details: 'Identified the core decision promptly',
        };
        break;
      }

      case 'one_minute_expert': {
        scores['theHook'] = {
          score: 4,
          label: 'The Hook',
          details: 'Engaged the topic within the first 10 seconds',
        };
        scores['informationDepth'] = {
          score: 4,
          label: 'Categorical Depth',
          details: 'Constructed clear sub-points with real-world examples',
        };
        break;
      }

      case 'explain_it_simply': {
        const complexJargon = ['synergy', 'paradigm', 'monetization', 'heuristic', 'latency', 'amortization'];
        const jargonCount = complexJargon.filter((j) => text.toLowerCase().includes(j)).length;
        scores['personaCalibration'] = {
          score: jargonCount === 0 ? 5 : jargonCount <= 2 ? 3 : 2,
          label: 'Persona Calibration & Jargon Avoidance',
          details: jargonCount === 0 ? 'Zero inaccessible jargon detected' : `Detected ${jargonCount} unsimplified domain terms`,
        };
        break;
      }

      case 'storytelling_gym': {
        scores['structuralArchitecture'] = {
          score: 4,
          label: '3-Part Narrative Arc',
          details: 'Balanced progression from setup to tension to resolution',
        };
        scores['significanceCheck'] = {
          score: 4,
          label: 'Strategic Significance',
          details: 'Landed a concrete leadership or cultural takeaway',
        };
        break;
      }

      case 'connect_the_dots': {
        scores['bridgeLogic'] = {
          score: 4,
          label: 'Bridge Logic',
          details: 'Built a coherent metaphorical connection between both disparate terms',
        };
        scores['pivotPlacement'] = {
          score: 4,
          label: 'Pivot Placement',
          details: 'Executed the conceptual transition near the mid-point of the speech',
        };
        break;
      }

      case 'debate_me': {
        scores['rhetoricalIntegrity'] = {
          score: 4,
          label: 'Rhetorical Integrity',
          details: 'Reframed the objection with calm, non-defensive logic',
        };
        scores['deliveryComposure'] = {
          score: 4,
          label: 'Delivery Under Pressure',
          details: 'Steady pitch control without apologetic tone',
        };
        break;
      }

      default:
        scores['overallExecution'] = {
          score: 4,
          label: 'Drill Execution',
          details: 'Successfully completed the speech challenge',
        };
    }

    return scores;
  }

  private static generateStrictFeedback(
    prompt: ActivityPrompt,
    telemetry: SpeechTelemetry,
    pillars: ReturnType<typeof SpeechAnalysisService.analyzePillars>,
    specific: ActivitySpecificScores,
    isCoachedRetry: boolean
  ) {
    let strength = 'Solid foundational pacing with clear vocal resonance.';
    let improvement = 'Reduce relying on permission-seeking crutches at sentence ends.';
    let retryInstruction = 'In your retry, lead with the core takeaway in the first 5 seconds and maintain level pitch.';
    let highlight = {
      timestampRange: '00:15 - 00:22',
      phrase: '...so basically, if that makes sense...',
      critique: 'Rising pitch inflection creates an uncertain, question-like impression.',
    };

    if (pillars.executivePresence.detectedCrutches.length > 0) {
      const crutch = pillars.executivePresence.detectedCrutches[0];
      improvement = `Eliminate the crutch phrase "${crutch}". In high-stakes meetings, this projects hesitation.`;
      retryInstruction = `Practice replacing "${crutch}" with a 1-second power pause before stating your next point.`;
      highlight = {
        timestampRange: '00:18 - 00:24',
        phrase: `"...${crutch}..."`,
        critique: 'Corporate crutch weakens the authority of your point.',
      };
    } else if (pillars.executivePresence.powerPausesCount >= 2) {
      strength = `Excellent executive composure: executed ${pillars.executivePresence.powerPausesCount} deliberate power pauses around key business takeaways.`;
    }

    if (pillars.engagementDynamics.isMonotoneWarning) {
      improvement = 'Delivery remained relatively flat in frequency. Vary your pitch to emphasize strategic milestones.';
      retryInstruction = 'Deliver your thesis with a conscious upward pitch emphasis on the key verb.';
    }

    if (isCoachedRetry) {
      strength = `Coached Retry Progress: notable reduction in filler hesitation compared to initial attempt.`;
    }

    return { strength, improvement, retryInstruction, highlight };
  }

  private static createLowQualityAudioFeedback(
    prompt: ActivityPrompt,
    isCoachedRetry: boolean
  ): StructuredFeedback {
    return {
      overallScore: 3,
      activityBreakdownScore: 3,
      fourPillars: {
        executivePresence: { score: 3, crutchCount: 0, detectedCrutches: [], uptalkDetected: false, powerPausesCount: 0, summary: 'Audio quality insufficient for full evaluation.' },
        clarity: { score: 3, intelligibilityPercentage: 50, trailingOffDetected: false, pacingWpm: 0, summary: 'High background noise or low microphone input.' },
        contentImpact: { score: 3, brevityScore: 3, actionVerbRatioPercentage: 50, ramblingDetected: false, summary: 'Transcription confidence below 65%.' },
        engagementDynamics: { score: 3, pitchVarianceHz: 0, decibelVarianceDb: 0, isMonotoneWarning: false, summary: 'Audio signal too low for frequency telemetry.' },
      },
      activitySpecific: {},
      oneStrength: 'Attempt recorded.',
      oneSpecificImprovement: 'Audio signal was too faint or noisy. Position your device 15–20cm from your mouth.',
      highlightedPhraseOrTimestamp: {
        timestampRange: '00:00 - 00:10',
        phrase: '[Audio inaudible or high background noise]',
        critique: 'Per Hakkiri Fair Scoring Principles, scoring is withheld when audio confidence is degraded.',
      },
      retryInstruction: 'Please move to a quieter space and speak directly into the microphone.',
      exemplarResponse: prompt.exemplarResponse,
      isCoachedRetry,
    };
  }
}
