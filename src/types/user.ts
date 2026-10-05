import { AssessmentAnswers, PersonalizedPlan } from './assessment';
import { ScoreScale } from './scoring';

export type SubscriptionTier = 'free_trial' | 'monthly_pro' | 'annual_pro' | 'enterprise';

export interface UserSubscription {
  tier: SubscriptionTier;
  isActive: boolean;
  renewsAt?: string;
  priceFormatted: string; // "£9.99/mo" or "£69.99/yr"
  trialDaysRemaining?: number;
}

export interface UserProfile {
  id: string;
  name: string;
  email: string;
  assessmentAnswers?: AssessmentAnswers;
  personalizedPlan?: PersonalizedPlan;
  subscription: UserSubscription;
  createdAt: string;
}

export interface UserEngagementStats {
  currentStreakDays: number;
  longestStreakDays: number;
  streakFreezeAvailable: number;
  totalXp: number; // Kept strictly separate from skill scores
  totalSessionsCompleted: number;
  lastSessionDate?: string;
}

export interface SkillRadarMetrics {
  executivePresenceAverage: number; // 1.0 - 5.0
  clarityAverage: number;
  contentImpactAverage: number;
  engagementDynamicsAverage: number;
  overallAverage: number;
}
