import { AssessmentAnswers } from '../src/types/assessment';
import { AssessmentService } from '../src/services/assessmentService';
import { ActivityScorer } from '../src/services/activityScorer';
import { PROMPT_BANK } from '../src/constants/promptBank';
import { SpeechTelemetry } from '../src/types/scoring';

console.log('=====================================================');
console.log('   HAKKIRI 🎙️ — COMMUNICATION GYM PIPELINE DEMO     ');
console.log('=====================================================\n');

// 1. Simulate 6-question user assessment
const mockAnswers: AssessmentAnswers = {
  voiceProfile: 'male',
  careerStage: 'mid_level_professional',
  careerType: 'corporate_finance',
  confidence: 'moderately_confident',
  roadblock: 'excessive_filler_words',
  primaryGoal: 'executive_presence_authority',
};

console.log('[STEP 1] Generating Personalized AI Roadmap...');
const plan = AssessmentService.generatePlan(mockAnswers);
console.log(`Plan Headline: "${plan.headline}"`);
console.log(`Recommended Track: ${plan.recommendedTrack}`);
console.log(`Initial Daily Drills: ${plan.initialDrillSequence.join(', ')}`);
console.log('Milestones:');
plan.fourWeekMilestones.forEach((m) => {
  console.log(`  Week ${m.week}: ${m.title} -> ${m.focus}`);
});

console.log('\n-----------------------------------------------------');
console.log('[STEP 2] Simulating Drill 1: Think Fast (60s speech)');
const thinkFastPrompt = PROMPT_BANK.find((p) => p.activityId === 'think_fast' && p.difficulty === 'intermediary')!;
console.log(`Prompt: "${thinkFastPrompt.promptText}"`);

const mockThinkFastTelemetry: SpeechTelemetry = {
  audioDurationSeconds: 58,
  transcription:
    'We take full responsibility for the milestone delay. A breakdown in internal review caused this. Basically, here is our recovery plan. We have reallocated senior engineers, and we will deliver by Thursday 2 PM. Does that make sense?',
  wordsPerMinute: 140,
  pauseIntervals: [
    { start: 10.0, end: 11.8, duration: 1.8 }, // 1.8s power pause
  ],
  pitchTrackHz: [130, 134, 138, 142, 145, 140, 138, 140],
  decibelTrackDb: [60, 62, 65, 68, 64, 63, 62],
  fillerWordOccurrences: [
    { word: 'basically', timestamp: 14.2 },
    { word: 'does that make sense', timestamp: 54.0 },
  ],
  signalToNoiseRatioDb: 28,
  transcriptionConfidence: 0.96,
};

const thinkFastFeedback = ActivityScorer.evaluate(thinkFastPrompt, mockThinkFastTelemetry);

console.log('\n[EVALUATION REPORT - THINK FAST]');
console.log(`Overall Composite Score: ${thinkFastFeedback.overallScore} / 5.0`);
console.log(`  Executive Presence: ${thinkFastFeedback.fourPillars.executivePresence.score}/5 (${thinkFastFeedback.fourPillars.executivePresence.summary})`);
console.log(`  Clarity & Articulation: ${thinkFastFeedback.fourPillars.clarity.score}/5 (${thinkFastFeedback.fourPillars.clarity.summary})`);
console.log(`  Content Impact: ${thinkFastFeedback.fourPillars.contentImpact.score}/5 (${thinkFastFeedback.fourPillars.contentImpact.summary})`);
console.log(`  Engagement Dynamics: ${thinkFastFeedback.fourPillars.engagementDynamics.score}/5 (${thinkFastFeedback.fourPillars.engagementDynamics.summary})`);

console.log('\n[STRICT FEEDBACK ANATOMY]');
console.log(`✓ One Strength: ${thinkFastFeedback.oneStrength}`);
console.log(`⚡ One Specific Improvement: ${thinkFastFeedback.oneSpecificImprovement}`);
console.log(`⏱️ Timestamp Highlight: [${thinkFastFeedback.highlightedPhraseOrTimestamp.timestampRange}] "${thinkFastFeedback.highlightedPhraseOrTimestamp.phrase}"`);
console.log(`   Critique: ${thinkFastFeedback.highlightedPhraseOrTimestamp.critique}`);
console.log(`🔄 Retry Instruction: ${thinkFastFeedback.retryInstruction}`);
console.log(`🌟 Exemplar Response: "${thinkFastFeedback.exemplarResponse}"`);

console.log('\n-----------------------------------------------------');
console.log('[STEP 3] Simulating Drill 2: Cut It In Half (Compression)');
const cutPrompt = PROMPT_BANK.find((p) => p.activityId === 'cut_it_in_half' && p.difficulty === 'beginner')!;
console.log(`Original Text Length: ${(cutPrompt.secondaryText || '').split(/\s+/).length} words`);

const mockCutTelemetry: SpeechTelemetry = {
  audioDurationSeconds: 15,
  transcription: 'Starting Monday, to protect personal downtime and sustain daytime focus, team members are not expected to reply to Slack messages after 6:00 PM.',
  wordsPerMinute: 135,
  pauseIntervals: [{ start: 6.0, end: 7.2, duration: 1.2 }],
  pitchTrackHz: [135, 140, 142, 138, 136],
  decibelTrackDb: [62, 65, 68, 64, 61],
  fillerWordOccurrences: [],
  signalToNoiseRatioDb: 30,
  transcriptionConfidence: 0.98,
};

const cutFeedback = ActivityScorer.evaluate(cutPrompt, mockCutTelemetry);

console.log(`Spoken Summary Length: ${mockCutTelemetry.transcription.split(/\s+/).length} words`);
console.log(`Rate Compression Metric: ${cutFeedback.activitySpecific['rateCompression']?.details}`);
console.log(`Rate Compression Score: ${cutFeedback.activitySpecific['rateCompression']?.score} / 5.0`);
console.log(`Overall Score: ${cutFeedback.overallScore} / 5.0`);

console.log('\n=====================================================');
console.log('   PIPELINE DEMO & VERIFICATION COMPLETE! SUCCESS   ');
console.log('=====================================================');
