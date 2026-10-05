import { create } from 'zustand';
import { ActivityId, ActivityDifficulty, ActivityPrompt, ActivityMetadata } from '../types/activity';
import { SpeechTelemetry, StructuredFeedback } from '../types/scoring';
import { ACTIVITIES } from '../constants/activities';
import { PROMPT_BANK } from '../constants/promptBank';
import { ActivityScorer } from '../services/activityScorer';

interface ActivityState {
  currentActivity: ActivityMetadata | null;
  selectedDifficulty: ActivityDifficulty;
  activePrompt: ActivityPrompt | null;
  recordingStatus: 'idle' | 'prep_countdown' | 'recording' | 'evaluating' | 'completed';
  recordingSeconds: number;
  latestFeedback: StructuredFeedback | null;
  practiceHistory: StructuredFeedback[];

  selectActivity: (activityId: ActivityId) => void;
  setDifficultyAndLoadPrompt: (difficulty: ActivityDifficulty) => ActivityPrompt | null;
  startSession: () => void;
  stopAndEvaluate: (telemetry: SpeechTelemetry, isRetry?: boolean) => StructuredFeedback;
  resetSession: () => void;
}

export const useActivityStore = create<ActivityState>((set, get) => ({
  currentActivity: ACTIVITIES[0], // default Think Fast
  selectedDifficulty: 'beginner',
  activePrompt: PROMPT_BANK[0],
  recordingStatus: 'idle',
  recordingSeconds: 0,
  latestFeedback: null,
  practiceHistory: [],

  selectActivity: (activityId) => {
    const meta = ACTIVITIES.find((a) => a.id === activityId) || ACTIVITIES[0];
    set({
      currentActivity: meta,
      recordingStatus: 'idle',
      latestFeedback: null,
    });
    get().setDifficultyAndLoadPrompt(get().selectedDifficulty);
  },

  setDifficultyAndLoadPrompt: (difficulty) => {
    const { currentActivity } = get();
    if (!currentActivity) return null;

    // Handle "I don't know": default to intermediary diagnostic prompt
    const targetDiff = difficulty === 'i_dont_know' ? 'intermediary' : difficulty;

    const matched = PROMPT_BANK.filter(
      (p) => p.activityId === currentActivity.id && p.difficulty === targetDiff
    );

    const prompt = matched.length > 0 ? matched[0] : PROMPT_BANK.find((p) => p.activityId === currentActivity.id) || null;

    set({
      selectedDifficulty: difficulty,
      activePrompt: prompt,
      recordingStatus: 'idle',
    });

    return prompt;
  },

  startSession: () => {
    set({ recordingStatus: 'recording', recordingSeconds: 0 });
  },

  stopAndEvaluate: (telemetry, isRetry = false) => {
    set({ recordingStatus: 'evaluating' });
    const { activePrompt } = get();
    if (!activePrompt) {
      throw new Error('No active prompt to evaluate');
    }

    const feedback = ActivityScorer.evaluate(activePrompt, telemetry, isRetry);

    set((state) => ({
      recordingStatus: 'completed',
      latestFeedback: feedback,
      practiceHistory: [feedback, ...state.practiceHistory],
    }));

    return feedback;
  },

  resetSession: () => {
    set({
      recordingStatus: 'idle',
      recordingSeconds: 0,
      latestFeedback: null,
    });
  },
}));
