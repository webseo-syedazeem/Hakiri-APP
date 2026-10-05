export type ScoreScale = 1 | 2 | 3 | 4 | 5;

export interface FourPillarScores {
  executivePresence: {
    score: ScoreScale;
    crutchCount: number;
    detectedCrutches: string[];
    uptalkDetected: boolean;
    powerPausesCount: number;
    summary: string;
  };
  clarity: {
    score: ScoreScale;
    intelligibilityPercentage: number;
    trailingOffDetected: boolean;
    pacingWpm: number;
    summary: string;
  };
  contentImpact: {
    score: ScoreScale;
    brevityScore: ScoreScale;
    actionVerbRatioPercentage: number;
    ramblingDetected: boolean;
    summary: string;
  };
  engagementDynamics: {
    score: ScoreScale;
    pitchVarianceHz: number;
    decibelVarianceDb: number;
    isMonotoneWarning: boolean;
    summary: string;
  };
}

export interface ActivitySpecificScores {
  [metricName: string]: {
    score: ScoreScale;
    label: string;
    details: string;
  };
}

export interface StructuredFeedback {
  overallScore: ScoreScale;
  activityBreakdownScore: ScoreScale;
  fourPillars: FourPillarScores;
  activitySpecific: ActivitySpecificScores;
  
  // Strict feedback anatomy
  oneStrength: string;
  oneSpecificImprovement: string;
  highlightedPhraseOrTimestamp: {
    timestampRange: string;
    phrase: string;
    critique: string;
  };
  retryInstruction: string;
  
  exemplarResponse: string;
  isCoachedRetry: boolean;
}

export interface SpeechTelemetry {
  audioDurationSeconds: number;
  transcription: string;
  wordsPerMinute: number;
  pauseIntervals: { start: number; end: number; duration: number }[];
  pitchTrackHz: number[];
  decibelTrackDb: number[];
  fillerWordOccurrences: { word: string; timestamp: number }[];
  signalToNoiseRatioDb: number;
  transcriptionConfidence: number;
}
