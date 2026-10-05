import { AssessmentQuestion } from '../types/assessment';

export const ASSESSMENT_QUESTIONS: AssessmentQuestion[] = [
  {
    id: 'voiceProfile',
    title: 'Voice Profile & Biological Resonance',
    subtitle: 'Which voice profile best aligns with your biological vocal structure and personalized training goals?',
    options: [
      {
        id: 'male',
        label: 'Male Voice Resonance',
        description: 'Focused on deep chest resonance, diaphragmatic support, and steady projection.',
      },
      {
        id: 'female',
        label: 'Female Voice Resonance',
        description: 'Focused on pitch clarity, throat-to-chest transitions, and authoritative resonance.',
      },
      {
        id: 'non_binary_vocal_alignment',
        label: 'Non-Binary / Vocal Alignment',
        description: 'Focused on customizable pitch matching, vocal stamina, and healthy vocal boundary training.',
      },
    ],
  },
  {
    id: 'careerStage',
    title: 'Career Stage',
    subtitle: 'Where are you currently at in your professional journey?',
    options: [
      {
        id: 'student_early_career',
        label: 'Student / Early Career',
        description: 'Preparing for interviews, assessment centers, and entry-level team entries.',
      },
      {
        id: 'mid_level_professional',
        label: 'Mid-Level Professional',
        description: 'Leading team meetings, cross-functional projects, reviews, and cross-team alignment.',
      },
      {
        id: 'senior_executive_founder',
        label: 'Senior Executive / Founder',
        description: 'Delivering investor pitches, speaking to media, steering all-hands, or board keynotes.',
      },
      {
        id: 'general_self_learner',
        label: 'General Self-Learner',
        description: 'Focused on personal charisma, casual conversational agility, and everyday communication.',
      },
    ],
  },
  {
    id: 'careerType',
    title: 'Career Environment',
    subtitle: 'Which field best describes your primary work environment?',
    options: [
      {
        id: 'corporate_finance',
        label: 'Corporate & Finance',
        description: 'Structured meetings, data reviews, forecasting, and formal boardroom presentations.',
      },
      {
        id: 'tech_engineering_product',
        label: 'Tech, Engineering & Product',
        description: 'Translating complex architecture into simple terms, backlog alignment, and technical roadmaps.',
      },
      {
        id: 'sales_marketing_creator',
        label: 'Sales, Marketing & Content Creator',
        description: 'High-energy persuasion, commercial negotiation, and audience engagement.',
      },
      {
        id: 'healthcare_education',
        label: 'Healthcare & Education',
        description: 'Clear, patient, empathetic, structured, and emotionally calibrated speaking.',
      },
    ],
  },
  {
    id: 'confidence',
    title: 'Verbal Speaking Confidence',
    subtitle: 'How do you honestly feel when you have to speak or present under pressure?',
    options: [
      {
        id: 'anxious_shaky',
        label: 'Anxious & Shaky',
        description: 'Throat tightens, speaking speed runs away, and struggle to find words on the spot.',
      },
      {
        id: 'moderately_confident',
        label: 'Moderately Confident',
        description: 'I can get my point across, but I default to filler words like "um" and "like".',
      },
      {
        id: 'highly_confident',
        label: 'Highly Confident',
        description: 'I control the room well, but I want to master advanced tactics like strategic power pausing.',
      },
    ],
  },
  {
    id: 'roadblock',
    title: 'The Roadblock to Solve',
    subtitle: 'What is the biggest roadblock holding your voice back right now?',
    options: [
      {
        id: 'fast_talking_mumbling',
        label: 'Fast Talking & Mumbling',
        description: 'Losing breath control and pacing when put on the spot; trailing off at sentence ends.',
      },
      {
        id: 'excessive_filler_words',
        label: 'Excessive Filler Words',
        description: 'Relying on "uh", "um", "sort of", "basically", and "does that make sense?" while thinking.',
      },
      {
        id: 'monotone_flat_delivery',
        label: 'Monotone / Flat Delivery',
        description: 'Sounding unengaging or like reading directly from a script without dynamic pitch.',
      },
      {
        id: 'accent_barriers_clarity',
        label: 'Accent Barriers / Intelligibility',
        description: 'Struggling with consonant clarity or feeling misunderstood in global/virtual meetings.',
      },
    ],
  },
  {
    id: 'primaryGoal',
    title: 'Primary Goal',
    subtitle: 'If you could fix one thing by using this app daily, what would it be?',
    options: [
      {
        id: 'executive_presence_authority',
        label: 'Executive Presence & Authority',
        description: 'Speak with authority, project calm competence, and eliminate upward inflections.',
      },
      {
        id: 'reduce_anxiety_freeze',
        label: 'Reduce Anxiety & Conversational Freeze',
        description: 'Stop freezing when put on the spot in unpredictable meetings.',
      },
      {
        id: 'sharp_arguments_debate',
        label: 'Sharp On-The-Fly Arguments',
        description: 'Build persuasive structured rebuttals and counter-proposals in real time.',
      },
      {
        id: 'diction_clarity_stamina',
        label: 'Diction, Clarity & Stamina',
        description: 'Improve daily consonant crispness, projection, and vocal endurance.',
      },
    ],
  },
];
