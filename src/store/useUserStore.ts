import { create } from 'zustand';
import { AssessmentAnswers, PersonalizedPlan } from '../types/assessment';
import { UserProfile, UserSubscription, UserEngagementStats } from '../types/user';
import { AssessmentService } from '../services/assessmentService';

interface UserState {
  profile: UserProfile | null;
  assessmentAnswers: Partial<AssessmentAnswers>;
  personalizedPlan: PersonalizedPlan | null;
  engagementStats: UserEngagementStats;
  isOnboarded: boolean;

  setAssessmentAnswer: <K extends keyof AssessmentAnswers>(key: K, value: AssessmentAnswers[K]) => void;
  completeAssessment: () => PersonalizedPlan;
  selectSubscription: (tier: 'monthly_pro' | 'annual_pro') => void;
  incrementStreak: () => void;
  addXp: (amount: number) => void;
}

export const useUserStore = create<UserState>((set, get) => ({
  profile: null,
  assessmentAnswers: {},
  personalizedPlan: null,
  engagementStats: {
    currentStreakDays: 3,
    longestStreakDays: 12,
    streakFreezeAvailable: 1,
    totalXp: 450, // Kept strictly separate from 1-5 skill scores
    totalSessionsCompleted: 8,
    lastSessionDate: new Date().toISOString(),
  },
  isOnboarded: false,

  setAssessmentAnswer: (key, value) => {
    set((state) => ({
      assessmentAnswers: {
        ...state.assessmentAnswers,
        [key]: value,
      },
    }));
  },

  completeAssessment: () => {
    const answers = get().assessmentAnswers as AssessmentAnswers;
    const plan = AssessmentService.generatePlan(answers);
    
    set({
      personalizedPlan: plan,
      isOnboarded: true,
      profile: {
        id: 'usr_hakkiri_demo',
        name: 'Alex Mercer',
        email: 'alex@example.com',
        assessmentAnswers: answers,
        personalizedPlan: plan,
        subscription: {
          tier: 'free_trial',
          isActive: true,
          priceFormatted: '£0.00 (7-Day Trial)',
          trialDaysRemaining: 7,
        },
        createdAt: new Date().toISOString(),
      },
    });

    return plan;
  },

  selectSubscription: (tier) => {
    const isAnnual = tier === 'annual_pro';
    const sub: UserSubscription = {
      tier,
      isActive: true,
      priceFormatted: isAnnual ? '£69.99/yr' : '£9.99/mo',
      trialDaysRemaining: isAnnual ? 7 : 0,
      renewsAt: new Date(Date.now() + (isAnnual ? 365 : 30) * 86400000).toISOString(),
    };

    set((state) => ({
      profile: state.profile ? { ...state.profile, subscription: sub } : null,
    }));
  },

  incrementStreak: () => {
    set((state) => ({
      engagementStats: {
        ...state.engagementStats,
        currentStreakDays: state.engagementStats.currentStreakDays + 1,
        totalSessionsCompleted: state.engagementStats.totalSessionsCompleted + 1,
        lastSessionDate: new Date().toISOString(),
      },
    }));
  },

  addXp: (amount: number) => {
    set((state) => ({
      engagementStats: {
        ...state.engagementStats,
        totalXp: state.engagementStats.totalXp + amount,
      },
    }));
  },
}));
