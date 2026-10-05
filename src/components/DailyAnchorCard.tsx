import React from 'react';
import { THEME } from '../constants/theme';
import { ActivityMetadata } from '../types/activity';

interface DailyAnchorCardProps {
  activity: ActivityMetadata;
  durationLabel: string;
  isCompleted?: boolean;
  onStart: () => void;
}

export const DailyAnchorCard: React.FC<DailyAnchorCardProps> = ({
  activity,
  durationLabel,
  isCompleted = false,
  onStart,
}) => {
  return (
    <div
      style={{
        backgroundColor: THEME.colors.surface,
        borderRadius: THEME.borderRadius.lg,
        border: `1px solid ${isCompleted ? THEME.colors.accentEmerald : THEME.colors.surfaceBorder}`,
        padding: '20px',
        display: 'flex',
        flexDirection: 'column',
        gap: '12px',
        boxShadow: THEME.shadows.card,
        position: 'relative',
        overflow: 'hidden',
      }}
    >
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <span
          style={{
            fontSize: '11px',
            textTransform: 'uppercase',
            letterSpacing: '1px',
            color: THEME.colors.accentCyan,
            fontFamily: THEME.typography.fontMono,
          }}
        >
          Daily Anchor • Rep 1
        </span>
        <span
          style={{
            fontSize: '12px',
            color: THEME.colors.textMuted,
            fontFamily: THEME.typography.fontMono,
          }}
        >
          ⏱️ {durationLabel}
        </span>
      </div>

      <div>
        <h3 style={{ margin: 0, fontSize: '18px', color: THEME.colors.textPrimary, fontWeight: 600 }}>
          {activity.name}
        </h3>
        <p style={{ margin: '4px 0 0', fontSize: '13px', color: THEME.colors.textSecondary }}>
          {activity.tagline}
        </p>
      </div>

      <div style={{ display: 'flex', gap: '8px', flexWrap: 'wrap' }}>
        {activity.successMeasures.slice(0, 2).map((measure, idx) => (
          <span
            key={idx}
            style={{
              fontSize: '11px',
              padding: '4px 8px',
              borderRadius: THEME.borderRadius.sm,
              backgroundColor: THEME.colors.surfaceBorder,
              color: THEME.colors.textSecondary,
            }}
          >
            🎯 {measure.split('(')[0]}
          </span>
        ))}
      </div>

      <button
        onClick={onStart}
        style={{
          marginTop: '8px',
          padding: '10px 16px',
          borderRadius: THEME.borderRadius.md,
          backgroundColor: isCompleted ? THEME.colors.surfaceBorder : THEME.colors.accentCyan,
          color: isCompleted ? THEME.colors.textPrimary : THEME.colors.textInverse,
          border: 'none',
          cursor: 'pointer',
          fontWeight: 600,
          fontSize: '13px',
          transition: 'all 0.2s ease',
        }}
      >
        {isCompleted ? '✓ Completed (Review)' : 'Start Practice Drill →'}
      </button>
    </div>
  );
};
