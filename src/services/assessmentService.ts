import { AssessmentAnswers, PersonalizedPlan } from '../types/assessment';

export class AssessmentService {
  /**
   * Generates a tailored 4-week AI communication roadmap based on diagnostic assessment.
   */
  public static generatePlan(answers: AssessmentAnswers): PersonalizedPlan {
    const track = answers.careerType;
    const roadblock = answers.roadblock;

    let headline = 'Executive Spontaneous Presence & Precision Program';
    let summary = 'A curated daily routine engineered to transition you from hesitant thinking to commanding executive clarity.';

    const initialDrills: string[] = [];

    switch (roadblock) {
      case 'excessive_filler_words':
        headline = 'Filler Elimination & Power Pause Mastery';
        summary = 'Targeting corporate crutches and building comfort with intentional 1–2 second power pauses.';
        initialDrills.push('think_fast', 'cut_it_in_half', 'debate_me');
        break;
      case 'fast_talking_mumbling':
        headline = 'Cadence Control & Consonant Intelligibility';
        summary = 'Disciplining speaking pace between 130–160 WPM, eliminating trailing off, and commanding virtual meetings.';
        initialDrills.push('cut_it_in_half', 'one_minute_expert', 'explain_it_simply');
        break;
      case 'monotone_flat_delivery':
        headline = 'Vocal Dynamic Range & Anti-Monotone Training';
        summary = 'Injecting pitch variance (Hz) and strategic volume peaks to captivate executive rooms and video calls.';
        initialDrills.push('storytelling_gym', 'debate_me', 'think_fast');
        break;
      case 'accent_barriers_clarity':
        headline = 'Global Intelligibility & Structural Framing';
        summary = 'Focusing on crystal-clear consonant endings and universal BLUF structure without compromising your authentic identity.';
        initialDrills.push('explain_it_simply', 'cut_it_in_half', 'connect_the_dots');
        break;
      default:
        initialDrills.push('think_fast', 'cut_it_in_half', 'one_minute_expert');
    }

    const milestones = [
      {
        week: 1,
        title: 'Cognitive Agility & Crutch Decoupling',
        focus: 'Eliminating instinctive "um", "sort of", and "basically" during sudden 60s questions.',
      },
      {
        week: 2,
        title: 'Brevity & Bottom-Line-Up-Front (BLUF)',
        focus: 'Compressing complex ideas by 50% and hitting key decisions within the first 5 seconds.',
      },
      {
        week: 3,
        title: 'Executive Presence & Power Silence',
        focus: 'Commanding high-stakes meetings with 1–2s power pauses and eliminating upward question inflections.',
      },
      {
        week: 4,
        title: 'Cross-Functional Mastery & High-Stakes Debate',
        focus: 'Reframing hostile pushback and translating technical jargon seamlessly for any boardroom.',
      },
    ];

    return {
      headline,
      summary,
      recommendedTrack: track,
      primaryRoadblock: roadblock,
      initialDrillSequence: initialDrills,
      weeklyCommitmentMinutes: 15,
      fourWeekMilestones: milestones,
    };
  }
}
