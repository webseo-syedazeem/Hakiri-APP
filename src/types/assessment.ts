export type VoiceProfile = 'male' | 'female' | 'non_binary_vocal_alignment';

export type CareerStage =
  | 'student_early_career'
  | 'mid_level_professional'
  | 'senior_executive_founder'
  | 'general_self_learner';

export type CareerType =
  | 'corporate_finance'
  | 'tech_engineering_product'
  | 'sales_marketing_creator'
  | 'healthcare_education';

export type SpeakingConfidence =
  | 'anxious_shaky'
  | 'moderately_confident'
  | 'highly_confident';

export type ProblemRoadblock =
  | 'fast_talking_mumbling'
  | 'excessive_filler_words'
  | 'monotone_flat_delivery'
  | 'accent_barriers_clarity';

export type PrimaryGoal =
  | 'executive_presence_authority'
  | 'reduce_anxiety_freeze'
  | 'sharp_arguments_debate'
  | 'diction_clarity_stamina';

export interface AssessmentAnswers {
  voiceProfile: VoiceProfile;
  careerStage: CareerStage;
  careerType: CareerType;
  confidence: SpeakingConfidence;
  roadblock: ProblemRoadblock;
  primaryGoal: PrimaryGoal;
}

export interface AssessmentQuestionOption<T = string> {
  id: T;
  label: string;
  description: string;
}

export interface AssessmentQuestion<T = string> {
  id: keyof AssessmentAnswers;
  title: string;
  subtitle: string;
  options: AssessmentQuestionOption<T>[];
}

export interface PersonalizedPlan {
  headline: string;
  summary: string;
  recommendedTrack: CareerType;
  primaryRoadblock: ProblemRoadblock;
  initialDrillSequence: string[];
  weeklyCommitmentMinutes: number;
  fourWeekMilestones: {
    week: number;
    title: string;
    focus: string;
  }[];
}
