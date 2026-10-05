export const SCORE_LEVEL_DESCRIPTIONS = {
  1: {
    title: 'Not Demonstrated',
    summary: 'Core objectives unfulfilled; high hesitation, severe crutches, or lack of coherence.',
  },
  2: {
    title: 'Limited',
    summary: 'Basic intent present, but hindered by noticeable crutches, uptalk, or rambling.',
  },
  3: {
    title: 'Partly Demonstrated',
    summary: 'Core point reached, but lacks strategic pacing, executive framing, or dynamic pitch.',
  },
  4: {
    title: 'Effective',
    summary: 'Strong corporate communication, structured framework, minimal crutches, clear articulation.',
  },
  5: {
    title: 'Strongly Demonstrated',
    summary: 'Masterful executive presence, intentional power pausing, sharp BLUF, and vibrant vocal resonance.',
  },
} as const;

export const CORPORATE_CRUTCH_PHRASES = [
  'sort of',
  'kind of',
  'basically',
  'essentially',
  'does that make sense?',
  'does that make sense',
  'you know what i mean',
  'to be honest',
  'at the end of the day',
  'i feel like',
  'if that makes sense',
];

export const GENERIC_FILLER_WORDS = [
  'um',
  'uh',
  'er',
  'ah',
  'like',
  'you know',
  'so yeah',
];

export const PAUSE_STANDARDS = {
  MIN_POWER_PAUSE_SECONDS: 1.0,
  MAX_POWER_PAUSE_SECONDS: 2.5,
  AWKWARD_FREEZE_SECONDS: 4.0,
  TARGET_POWER_PAUSES_PER_MINUTE: 2,
};

export const ENERGY_MAP_STANDARDS = {
  MIN_DECIBEL_VARIANCE_DB: 6.0,
  MIN_PITCH_VARIANCE_HZ: 25.0,
  TARGET_WPM_MIN: 125,
  TARGET_WPM_MAX: 175,
};

export const FAIR_SCORING_PRINCIPLES = [
  'Do not penalize accents; prioritize intelligibility and consonant crispness.',
  'Do not reward one universal speaking pace; respect individual cadence within 120-175 WPM.',
  'Do not treat all filler words as failures; assess cluster density and crutch reliance.',
  'Do not reward complex vocabulary for its own sake; simplicity and clarity command authority.',
  'If audio quality or transcription is poor (<75% confidence), withhold judgment rather than penalizing the user.',
  'Separate progress on a coached retry from progress on a fresh prompt.',
  'Keep streaks and XP strictly separate from 1-5 skill scores.',
];

export const SUBSCRIPTION_PLANS = {
  MONTHLY: {
    id: 'monthly_pro',
    name: 'Monthly Pro',
    priceGbp: 9.99,
    formattedPrice: '£9.99',
    billingInterval: 'month',
    trialDays: 0,
    features: [
      'Unlimited daily communication workouts',
      'Full access to all 7 MVP drills',
      'Instant 1-5 scoring & AI coached retries',
      'Personalized Daily Anchor workouts',
    ],
  },
  ANNUAL: {
    id: 'annual_pro',
    name: 'Annual Pro',
    priceGbp: 69.99,
    formattedPrice: '£69.99',
    billingInterval: 'year',
    equivalentMonthlyPrice: '£5.83',
    savingsPercentage: '42%',
    trialDays: 7,
    isPopular: true,
    features: [
      'Everything in Monthly Pro',
      '7-day unrestricted free trial',
      'Long-term Executive Presence Radar tracking',
      'Industry-specific prompts (Tech, Finance, Sales, Health)',
      'Free streak protection and freeze passes',
    ],
  },
};
