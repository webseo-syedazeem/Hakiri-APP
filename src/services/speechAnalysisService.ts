import { CORPORATE_CRUTCH_PHRASES, GENERIC_FILLER_WORDS, PAUSE_STANDARDS, ENERGY_MAP_STANDARDS } from '../constants/scoringRubrics';
import { SpeechTelemetry, FourPillarScores, ScoreScale } from '../types/scoring';

export class SpeechAnalysisService {
  /**
   * Evaluates the 4 core pillars based on audio telemetry and transcript.
   */
  public static analyzePillars(telemetry: SpeechTelemetry): FourPillarScores {
    const transcriptLower = telemetry.transcription.toLowerCase();

    // 1. Detect Corporate Crutches & Generic Fillers
    const detectedCrutches: string[] = [];
    for (const phrase of CORPORATE_CRUTCH_PHRASES) {
      const regex = new RegExp(`\\b${phrase.replace('?', '\\?')}\\b`, 'gi');
      const matches = transcriptLower.match(regex);
      if (matches) {
        detectedCrutches.push(...matches);
      }
    }

    let genericFillerCount = 0;
    for (const filler of GENERIC_FILLER_WORDS) {
      const regex = new RegExp(`\\b${filler}\\b`, 'gi');
      const matches = transcriptLower.match(regex);
      if (matches) {
        genericFillerCount += matches.length;
      }
    }

    // 2. Power Pauses (1.0 to 2.5s intentional silence)
    const powerPauses = telemetry.pauseIntervals.filter(
      (p) => p.duration >= PAUSE_STANDARDS.MIN_POWER_PAUSE_SECONDS && p.duration <= PAUSE_STANDARDS.MAX_POWER_PAUSE_SECONDS
    );

    // 3. Uptalk Detection: Check rising pitch ending on statements
    // We analyze the pitch trajectory near sentence boundaries.
    const uptalkDetected = this.detectUptalk(telemetry.pitchTrackHz);

    // 4. Energy Map (Anti-monotone check)
    const pitchVariance = this.calculateVariance(telemetry.pitchTrackHz);
    const dbVariance = this.calculateVariance(telemetry.decibelTrackDb);
    const isMonotone =
      pitchVariance < ENERGY_MAP_STANDARDS.MIN_PITCH_VARIANCE_HZ ||
      dbVariance < ENERGY_MAP_STANDARDS.MIN_DECIBEL_VARIANCE_DB;

    // 5. Brevity & Rambling Check
    const totalWords = telemetry.transcription.trim().split(/\s+/).filter(Boolean).length;
    const durationMinutes = (telemetry.audioDurationSeconds || 60) / 60;
    const wpm = Math.round(totalWords / (durationMinutes || 1));
    const ramblingDetected = this.detectRambling(telemetry);

    // 6. Action-Oriented Language vs Passive Voice
    const actionVerbRatio = this.calculateActionVerbRatio(telemetry.transcription);

    // Pillar 1: Executive Presence
    let execScore: ScoreScale = 5;
    if (detectedCrutches.length > 3 || (uptalkDetected && detectedCrutches.length > 1)) {
      execScore = 2;
    } else if (detectedCrutches.length > 1 || uptalkDetected) {
      execScore = 3;
    } else if (detectedCrutches.length === 1 || powerPauses.length === 0) {
      execScore = 4;
    }

    // Pillar 2: Clarity & Articulation
    const trailingOff = this.detectTrailingOff(telemetry.decibelTrackDb);
    let clarityScore: ScoreScale = 5;
    if (telemetry.transcriptionConfidence < 0.80 || trailingOff) {
      clarityScore = 3;
    } else if (wpm > 185 || wpm < 110) {
      clarityScore = 3;
    } else if (wpm > 170 || wpm < 120) {
      clarityScore = 4;
    }

    // Pillar 3: Content Impact & Conciseness
    let impactScore: ScoreScale = 5;
    let brevityScore: ScoreScale = 5;
    if (ramblingDetected) {
      impactScore = 2;
      brevityScore = 2;
    } else if (actionVerbRatio < 40) {
      impactScore = 3;
      brevityScore = 3;
    } else if (actionVerbRatio < 65) {
      impactScore = 4;
      brevityScore = 4;
    }

    // Pillar 4: Engagement Dynamics
    let engagementScore: ScoreScale = 5;
    if (isMonotone) {
      engagementScore = 2;
    } else if (pitchVariance < 35 || dbVariance < 8) {
      engagementScore = 3;
    } else if (pitchVariance < 45) {
      engagementScore = 4;
    }

    return {
      executivePresence: {
        score: execScore,
        crutchCount: detectedCrutches.length + genericFillerCount,
        detectedCrutches,
        uptalkDetected,
        powerPausesCount: powerPauses.length,
        summary: execScore >= 4
          ? 'Authoritative vocal presence with controlled pauses and strong statement closure.'
          : 'High reliance on corporate crutches or rising inflections that diminish perceived authority.',
      },
      clarity: {
        score: clarityScore,
        intelligibilityPercentage: Math.round(telemetry.transcriptionConfidence * 100),
        trailingOffDetected: trailingOff,
        pacingWpm: wpm,
        summary: clarityScore >= 4
          ? `Crisp articulation at ${wpm} WPM without sentence tail-off.`
          : `Pacing or articulation requires discipline (${wpm} WPM).`,
      },
      contentImpact: {
        score: impactScore,
        brevityScore,
        actionVerbRatioPercentage: actionVerbRatio,
        ramblingDetected,
        summary: impactScore >= 4
          ? 'Decisive language, active verbs, and structural breaks that hold attention.'
          : 'Rambling sentences or passive phrasing reduce the punch of your core takeaway.',
      },
      engagementDynamics: {
        score: engagementScore,
        pitchVarianceHz: Math.round(pitchVariance),
        decibelVarianceDb: Math.round(dbVariance),
        isMonotoneWarning: isMonotone,
        summary: engagementScore >= 4
          ? 'Dynamic vocal melody with intentional decibel peaks on key takeaways.'
          : 'Delivery tends toward flatline drone; inject pitch and loudness variance.',
      },
    };
  }

  private static detectUptalk(pitchTrack: number[]): boolean {
    if (!pitchTrack || pitchTrack.length < 10) return false;
    // Check if the final 20% of pitch samples consistently slope upward by >15 Hz
    const tailSlice = pitchTrack.slice(-Math.floor(pitchTrack.length * 0.2));
    if (tailSlice.length < 3) return false;
    const startTail = tailSlice[0];
    const endTail = tailSlice[tailSlice.length - 1];
    return endTail - startTail > 20;
  }

  private static detectTrailingOff(dbTrack: number[]): boolean {
    if (!dbTrack || dbTrack.length < 10) return false;
    const tail = dbTrack.slice(-Math.floor(dbTrack.length * 0.15));
    const meanTail = tail.reduce((a, b) => a + b, 0) / tail.length;
    const overallMean = dbTrack.reduce((a, b) => a + b, 0) / dbTrack.length;
    return overallMean - meanTail > 12; // Volume drops significantly at the end
  }

  private static detectRambling(telemetry: SpeechTelemetry): boolean {
    // If there is any speaking stretch longer than 40 seconds without at least a 0.8s pause
    let maxUnbrokenSpeech = 0;
    let lastPauseEnd = 0;

    for (const pause of telemetry.pauseIntervals) {
      const speechDuration = pause.start - lastPauseEnd;
      if (speechDuration > maxUnbrokenSpeech) {
        maxUnbrokenSpeech = speechDuration;
      }
      lastPauseEnd = pause.end;
    }

    const finalStretch = telemetry.audioDurationSeconds - lastPauseEnd;
    if (finalStretch > maxUnbrokenSpeech) {
      maxUnbrokenSpeech = finalStretch;
    }

    return maxUnbrokenSpeech >= 40;
  }

  private static calculateActionVerbRatio(text: string): number {
    const activeVerbs = [
      'executed', 'built', 'delivered', 'decided', 'pivoted', 'spearheaded',
      'solved', 'accelerated', 'launched', 'optimized', 'reduced', 'increased',
      'aligned', 'secured', 'transitioned', 'isolated', 'mitigated',
    ];
    const passiveMarkers = ['was done', 'were made', 'it was', 'has been', 'is being', 'sort of'];

    const words = text.toLowerCase().split(/\s+/);
    let activeMatches = 0;
    let passiveMatches = 0;

    for (const v of activeVerbs) {
      if (text.toLowerCase().includes(v)) activeMatches++;
    }
    for (const p of passiveMarkers) {
      if (text.toLowerCase().includes(p)) passiveMatches++;
    }

    const total = activeMatches + passiveMatches;
    if (total === 0) return 60; // neutral default
    return Math.min(100, Math.round((activeMatches / total) * 100));
  }

  private static calculateVariance(samples: number[]): number {
    if (!samples || samples.length === 0) return 0;
    const mean = samples.reduce((a, b) => a + b, 0) / samples.length;
    const squaredDiffs = samples.map((x) => Math.pow(x - mean, 2));
    const avgSquaredDiff = squaredDiffs.reduce((a, b) => a + b, 0) / samples.length;
    return Math.sqrt(avgSquaredDiff); // standard deviation as proxy for dynamic variance
  }
}
