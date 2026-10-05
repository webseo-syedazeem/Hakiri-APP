import React from 'react';
import { THEME } from '../../constants/theme';
import { useUserStore } from '../../store/useUserStore';

interface PersonalizedPlanScreenProps {
  onProceedToPaywall: () => void;
}

export const PersonalizedPlanScreen: React.FC<PersonalizedPlanScreenProps> = ({
  onProceedToPaywall,
}) => {
  const { personalizedPlan } = useUserStore();

  const plan = personalizedPlan || {
    headline: 'Executive Spontaneous Presence & Precision Program',
    summary: 'A curated daily routine engineered to transition you from hesitant thinking to commanding executive clarity.',
    recommendedTrack: 'corporate_finance' as any,
    primaryRoadblock: 'excessive_filler_words' as any,
    initialDrillSequence: ['think_fast', 'cut_it_in_half'],
    weeklyCommitmentMinutes: 15,
    fourWeekMilestones: [
      { week: 1, title: 'Cognitive Agility & Crutch Decoupling', focus: 'Eliminating instinctive "um" and "basically" under sudden 60s questions.' },
      { week: 2, title: 'Brevity & Bottom-Line-Up-Front (BLUF)', focus: 'Compressing complex ideas by 50%.' },
      { week: 3, title: 'Executive Presence & Power Silence', focus: 'Commanding meetings with 1–2s power pauses.' },
      { week: 4, title: 'High-Stakes Debate Mastery', focus: 'Reframing hostile pushback and managing adversarial pressure.' },
    ],
  };

  return (
    <div
      style={{
        backgroundColor: THEME.colors.background,
        color: THEME.colors.textPrimary,
        minHeight: '100vh',
        padding: '32px 20px',
        maxWidth: '480px',
        margin: '0 auto',
        display: 'flex',
        flexDirection: 'column',
        justifyContent: 'space-between',
        fontFamily: THEME.typography.fontSans,
      }}
    >
      <div>
        <div
          style={{
            display: 'inline-block',
            padding: '4px 10px',
            borderRadius: THEME.borderRadius.full,
            backgroundColor: 'rgba(16, 185, 129, 0.1)',
            border: `1px solid rgba(16, 185, 129, 0.3)`,
            color: THEME.colors.accentEmerald,
            fontSize: '11px',
            fontFamily: THEME.typography.fontMono,
            marginBottom: '12px',
          }}
        >
          ✓ Diagnostic Complete • Plan Formulated
        </div>

        <h1 style={{ fontSize: '26px', fontWeight: 800, margin: '0 0 10px', lineHeight: '1.2' }}>
          {plan.headline}
        </h1>
        <p style={{ fontSize: '14px', color: THEME.colors.textSecondary, margin: '0 0 24px', lineHeight: '1.5' }}>
          {plan.summary}
        </p>

        {/* 4-Week Milestones Architecture */}
        <div style={{ display: 'flex', flexDirection: 'column', gap: '12px' }}>
          <span style={{ fontSize: '12px', fontWeight: 700, color: THEME.colors.accentCyan, textTransform: 'uppercase', letterSpacing: '0.5px' }}>
            Your 4-Week Communication Roadmap
          </span>

          {plan.fourWeekMilestones.map((m) => (
            <div
              key={m.week}
              style={{
                backgroundColor: THEME.colors.surface,
                borderRadius: THEME.borderRadius.md,
                border: `1px solid ${THEME.colors.surfaceBorder}`,
                padding: '14px 16px',
                display: 'flex',
                gap: '14px',
                alignItems: 'flex-start',
              }}
            >
              <div
                style={{
                  width: '28px',
                  height: '28px',
                  borderRadius: '50%',
                  backgroundColor: 'rgba(0, 240, 255, 0.1)',
                  color: THEME.colors.accentCyan,
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  fontSize: '12px',
                  fontWeight: 700,
                  fontFamily: THEME.typography.fontMono,
                  flexShrink: 0,
                }}
              >
                W{m.week}
              </div>
              <div>
                <h4 style={{ margin: '0 0 4px', fontSize: '14px', color: THEME.colors.textPrimary }}>
                  {m.title}
                </h4>
                <p style={{ margin: 0, fontSize: '12px', color: THEME.colors.textMuted }}>
                  {m.focus}
                </p>
              </div>
            </div>
          ))}
        </div>
      </div>

      <div style={{ marginTop: '32px', display: 'flex', flexDirection: 'column', gap: '12px' }}>
        <button
          onClick={onProceedToPaywall}
          style={{
            padding: '16px 24px',
            backgroundColor: THEME.colors.accentCyan,
            color: THEME.colors.textInverse,
            borderRadius: THEME.borderRadius.md,
            border: 'none',
            fontSize: '15px',
            fontWeight: 700,
            cursor: 'pointer',
            boxShadow: THEME.shadows.glowCyan,
          }}
        >
          Unlock Your Plan & Start Daily Workout →
        </button>
        <span style={{ textAlign: 'center', fontSize: '11px', color: THEME.colors.textMuted }}>
          Commitment: Just 3–5 minutes per day
        </span>
      </div>
    </div>
  );
};
