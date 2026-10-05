import React from 'react';
import { THEME } from '../../constants/theme';
import { useActivityStore } from '../../store/useActivityStore';
import { ActivityDifficulty } from '../../types/activity';

interface ActivityDetailScreenProps {
  onStartDrill: () => void;
  onBack: () => void;
}

export const ActivityDetailScreen: React.FC<ActivityDetailScreenProps> = ({
  onStartDrill,
  onBack,
}) => {
  const { currentActivity, selectedDifficulty, setDifficultyAndLoadPrompt } = useActivityStore();

  if (!currentActivity) return null;

  const difficultyOptions: { id: ActivityDifficulty; label: string; desc: string }[] = [
    { id: 'beginner', label: 'Beginner', desc: 'Survive the clock, fill the silence, steady pace.' },
    { id: 'intermediary', label: 'Intermediary', desc: 'Use a clear structure, eliminate panic, active verbs.' },
    { id: 'professional', label: 'Professional', desc: 'Executive presence, power pauses, high-impact BLUF.' },
    { id: 'i_dont_know', label: "I don't know", desc: 'AI evaluates your baseline with a balanced diagnostic prompt.' },
  ];

  const handleDifficultySelect = (diff: ActivityDifficulty) => {
    setDifficultyAndLoadPrompt(diff);
  };

  return (
    <div
      style={{
        backgroundColor: THEME.colors.background,
        color: THEME.colors.textPrimary,
        minHeight: '100vh',
        padding: '24px 20px',
        maxWidth: '480px',
        margin: '0 auto',
        display: 'flex',
        flexDirection: 'column',
        justifyContent: 'space-between',
        fontFamily: THEME.typography.fontSans,
      }}
    >
      <div>
        <button
          onClick={onBack}
          style={{
            background: 'none',
            border: 'none',
            color: THEME.colors.textSecondary,
            fontSize: '13px',
            cursor: 'pointer',
            padding: 0,
            marginBottom: '16px',
          }}
        >
          ← Back to Drills
        </button>

        <div
          style={{
            display: 'inline-block',
            padding: '4px 10px',
            borderRadius: THEME.borderRadius.full,
            backgroundColor: 'rgba(0, 240, 255, 0.1)',
            color: THEME.colors.accentCyan,
            fontSize: '11px',
            fontFamily: THEME.typography.fontMono,
            marginBottom: '8px',
          }}
        >
          ⏱️ {currentActivity.defaultDurationSeconds}s Drill • {currentActivity.prepDurationSeconds}s Prep
        </div>

        <h1 style={{ fontSize: '26px', fontWeight: 800, margin: '0 0 8px' }}>
          {currentActivity.name}
        </h1>
        <p style={{ fontSize: '14px', color: THEME.colors.textSecondary, margin: '0 0 24px', lineHeight: '1.5' }}>
          {currentActivity.description}
        </p>

        {/* Benefits Box */}
        <div
          style={{
            backgroundColor: THEME.colors.surface,
            borderRadius: THEME.borderRadius.md,
            border: `1px solid ${THEME.colors.surfaceBorder}`,
            padding: '16px',
            marginBottom: '24px',
          }}
        >
          <div style={{ fontSize: '11px', fontWeight: 700, color: THEME.colors.accentCyan, textTransform: 'uppercase', marginBottom: '8px' }}>
            Core Neuromuscular Benefits
          </div>
          <ul style={{ margin: 0, paddingLeft: '16px', fontSize: '12px', color: THEME.colors.textSecondary, lineHeight: '1.6' }}>
            {currentActivity.benefits.map((b, i) => (
              <li key={i}>{b}</li>
            ))}
          </ul>
        </div>

        {/* Difficulty Selection */}
        <div>
          <span style={{ fontSize: '12px', fontWeight: 700, color: THEME.colors.textPrimary, textTransform: 'uppercase', letterSpacing: '0.5px' }}>
            Select Difficulty Level
          </span>
          <div style={{ display: 'flex', flexDirection: 'column', gap: '10px', marginTop: '10px' }}>
            {difficultyOptions.map((opt) => {
              const isSelected = selectedDifficulty === opt.id;
              return (
                <button
                  key={opt.id}
                  onClick={() => handleDifficultySelect(opt.id)}
                  style={{
                    backgroundColor: isSelected ? 'rgba(0, 240, 255, 0.08)' : THEME.colors.surface,
                    border: `1px solid ${isSelected ? THEME.colors.accentCyan : THEME.colors.surfaceBorder}`,
                    borderRadius: THEME.borderRadius.md,
                    padding: '12px 16px',
                    textAlign: 'left',
                    cursor: 'pointer',
                    display: 'flex',
                    flexDirection: 'column',
                    gap: '4px',
                  }}
                >
                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                    <span style={{ fontSize: '14px', fontWeight: 600, color: isSelected ? THEME.colors.accentCyan : THEME.colors.textPrimary }}>
                      {opt.label}
                    </span>
                    {isSelected && <span style={{ color: THEME.colors.accentCyan, fontSize: '13px' }}>●</span>}
                  </div>
                  <span style={{ fontSize: '11px', color: THEME.colors.textMuted }}>{opt.desc}</span>
                </button>
              );
            })}
          </div>
        </div>
      </div>

      <div style={{ marginTop: '28px' }}>
        <button
          onClick={onStartDrill}
          style={{
            width: '100%',
            padding: '16px',
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
          Begin Drill ({currentActivity.prepDurationSeconds}s Countdown) →
        </button>
      </div>
    </div>
  );
};
