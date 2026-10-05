import React from 'react';
import { THEME } from '../constants/theme';
import { FourPillarScores } from '../types/scoring';

interface MetricRadarProps {
  pillars: FourPillarScores;
}

export const MetricRadar: React.FC<MetricRadarProps> = ({ pillars }) => {
  const metrics = [
    {
      label: 'Executive Presence',
      score: pillars.executivePresence.score,
      sublabel: `${pillars.executivePresence.crutchCount} crutches • ${pillars.executivePresence.powerPausesCount} power pauses`,
      color: THEME.colors.accentCyan,
    },
    {
      label: 'Clarity & Articulation',
      score: pillars.clarity.score,
      sublabel: `${pillars.clarity.pacingWpm} WPM • ${pillars.clarity.intelligibilityPercentage}% intelligibility`,
      color: THEME.colors.accentBlue,
    },
    {
      label: 'Content Impact & Conciseness',
      score: pillars.contentImpact.score,
      sublabel: `${pillars.contentImpact.actionVerbRatioPercentage}% active verbs • BLUF check`,
      color: THEME.colors.accentPurple,
    },
    {
      label: 'Engagement Dynamics',
      score: pillars.engagementDynamics.score,
      sublabel: `Δ ${pillars.engagementDynamics.pitchVarianceHz}Hz pitch • ${pillars.engagementDynamics.decibelVarianceDb}dB variance`,
      color: THEME.colors.accentEmerald,
    },
  ];

  return (
    <div
      style={{
        backgroundColor: THEME.colors.surface,
        borderRadius: THEME.borderRadius.lg,
        border: `1px solid ${THEME.colors.surfaceBorder}`,
        padding: '20px',
        display: 'flex',
        flexDirection: 'column',
        gap: '16px',
      }}
    >
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <h4 style={{ margin: 0, fontSize: '15px', color: THEME.colors.textPrimary }}>
          Four Pillars Executive Analysis
        </h4>
        <span
          style={{
            fontFamily: THEME.typography.fontMono,
            fontSize: '11px',
            color: THEME.colors.accentCyan,
          }}
        >
          1–5 Scale
        </span>
      </div>

      <div style={{ display: 'flex', flexDirection: 'column', gap: '14px' }}>
        {metrics.map((m) => {
          const percentage = (m.score / 5) * 100;
          return (
            <div key={m.label} style={{ display: 'flex', flexDirection: 'column', gap: '6px' }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'baseline' }}>
                <span style={{ fontSize: '13px', fontWeight: 500, color: THEME.colors.textPrimary }}>
                  {m.label}
                </span>
                <span
                  style={{
                    fontFamily: THEME.typography.fontMono,
                    fontSize: '13px',
                    fontWeight: 700,
                    color: m.color,
                  }}
                >
                  {m.score}.0 / 5.0
                </span>
              </div>

              {/* Progress Bar Track */}
              <div
                style={{
                  height: '8px',
                  backgroundColor: THEME.colors.metricTrack,
                  borderRadius: THEME.borderRadius.full,
                  overflow: 'hidden',
                }}
              >
                <div
                  style={{
                    height: '100%',
                    width: `${percentage}%`,
                    backgroundColor: m.color,
                    borderRadius: THEME.borderRadius.full,
                    transition: 'width 0.5s ease',
                  }}
                />
              </div>

              <span style={{ fontSize: '11px', color: THEME.colors.textMuted }}>{m.sublabel}</span>
            </div>
          );
        })}
      </div>
    </div>
  );
};
