export type ActivityId =
  | 'think_fast'
  | 'cut_it_in_half'
  | 'one_minute_expert'
  | 'explain_it_simply'
  | 'storytelling_gym'
  | 'connect_the_dots'
  | 'debate_me'
  | 'build_your_point'
  | 'vocabulary_upgrade'
  | 'listen_and_respond'
  | 'conversation_flow'
  | 'speak_up';

export type ActivityDifficulty =
  | 'beginner'
  | 'intermediary'
  | 'professional'
  | 'i_dont_know';

export interface ActivityPrompt {
  id: string;
  activityId: ActivityId;
  difficulty: 'beginner' | 'intermediary' | 'professional';
  track?: string;
  title?: string;
  promptText: string;
  secondaryText?: string; // e.g. text to cut, or second concept in connect the dots
  objective: string;
  durationSeconds: number;
  preparationSeconds?: number;
  exemplarResponse: string;
  tags: string[];
}

export interface ActivityMetadata {
  id: ActivityId;
  name: string;
  isMvp: boolean;
  tagline: string;
  cognitiveMechanism: string;
  iconName: string;
  defaultDurationSeconds: number;
  prepDurationSeconds: number;
  description: string;
  benefits: string[];
  successMeasures: string[];
}
