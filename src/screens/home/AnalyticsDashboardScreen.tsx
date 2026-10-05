import React from 'react';
import { THEME } from '../../constants/theme';
import { FAIR_SCORING_PRINCIPLES } from '../../constants/scoringRubrics';
import { MetricRadar } from '../../components/MetricRadar';

interface AnalyticsDashboardScreenProps {
  onBack: () => void;
}

export const AnalyticsDashboardScreen: React.FC<AnalyticsDashboardScreenProps> = ({ onBack }) => {
  // Sample aggregate dashboard data across user sessions
  const samplePillars = {
    executivePresence: {
      score: 4 as const,
      crutchCount: 2,
      detectedCrutches: ['basically', 'sort of'],
      uptalkDetected: false,
      powerPausesCount: 3,
      summary: 'High vocal authority; controlled power pauses prior to critical decisions.',
    },
    clarity: {
      score: 4 as const,
      intelligibilityPercentage: 94,
      trailingOffDetected: false,
      pacingWpm: 142,
      summary: 'Cadence is dialed at 142 WPM. Consonants distinct across virtual meeting simulations.',
    },
    contentImpact: {
      score: 4 as const,
      brevityScore: 4 as const,
      actionVerbRatioPercentage: 72,
      ramblingDetected: false,
      summary: 'Active verb ratio at 72%. Clear BLUF structure without 45s run-on clauses.',
    },
    engagementDynamics: {
      score: 5 as const,
      pitchVarianceHz: 48,
      decibelVarianceDb: 11,
      isMonotoneWarning: false,
      summary: 'Wide pitch variance prevents monotone delivery and sustains listener engagement.',
    },
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
        gap: '24px',
        fontFamily: THEME.typography.fontSans,
      }}
    >
      {/* Header */}
      <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
        <button
          onClick={onBack}
          style={{
            background: 'none',
            border: 'none',
            color: THEME.colors.accentCyan,
            cursor: 'pointer',
            fontSize: '16px',
          }}
        >
          ←
        </button>
        <div>
          <h2 style={{ margin: 0, fontSize: '20px', fontWeight: 800 }}>
            Executive Dashboard
          </h2>
          <span style={{ fontSize: '11px', color: THEME.colors.textMuted, fontFamily: THEME.typography.fontMono }}>
            AGGREGATED MULTIMODAL TELEMETRY
          </span>
        </div>
      </div>

      {/* Aggregate Score Card */}
      <div
        style={{
          backgroundColor: THEME.colors.surface,
          borderRadius: THEME.borderRadius.lg,
          border: `1px solid ${THEME.colors.surfaceBorder}`,
          padding: '20px',
          display: 'flex',
          justifyContent: 'space-between',
          alignItems: 'center',
        }}
      >
        <div>
          <span style={{ fontSize: '11px', color: THEME.colors.textMuted, textTransform: 'uppercase', fontFamily: THEME.typography.fontMono }}>
            Overall Aggregate Score
          </span>
          <div style={{ fontSize: '15px', fontWeight: 600, color: THEME.colors.textPrimary, marginTop: '2px' }}>
            Effective Executive Presence
          </div>
        </div>
        <div style={{ textAlign: 'right' }}>
          <span style={{ fontFamily: THEME.typography.fontMono, fontSize: '36px', fontWeight: 800, color: THEME.colors.accentCyan }}>
            4.2
          </span>
          <span style={{ fontSize: '14px', color: THEME.colors.textMuted }}> / 5.0</span>
        </div>
      </div>

      {/* 4 Pillars Breakdown */}
      <MetricRadar pillars={samplePillars} />

      {/* Corporate Crutch & Uptalk Telemetry */}
      <div
        style={{
          backgroundColor: THEME.colors.surface,
          borderRadius: THEME.borderRadius.lg,
          border: `1px solid ${THEME.colors.surfaceBorder}`,
          padding: '20px',
          display: 'flex',
          flexDirection: 'column',
          gap: '14px',
        }}
      >
        <h4 style={{ margin: 0, fontSize: '15px', color: THEME.colors.textPrimary }}>
          Executive Crutch & Acoustic Analysis
        </h4>

        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '10px' }}>
          <div style={{ padding: '12px', backgroundColor: THEME.colors.surfaceBorder, borderRadius: THEME.borderRadius.md }}>
            <span style={{ fontSize: '11px', color: THEME.colors.textMuted }}>Uptalk Penalization</span>
            <div style={{ marginTop: '4px', fontSize: '14px', fontWeight: 600, color: THEME.colors.accentEmerald }}>
              0 Instances (Clean)
            </div>
          </div>

          <div style={{ padding: '12px', backgroundColor: THEME.colors.surfaceBorder, borderRadius: THEME.borderRadius.md }}>
            <span style={{ fontSize: '11px', color: THEME.colors.textMuted }}>Power Pauses (1-2s)</span>
            <div style={{ marginTop: '4px', fontSize: '14px', fontWeight: 600, color: THEME.colors.accentCyan }}>
              3 Executed
            </div>
          </div>

          <div style={{ padding: '12px', backgroundColor: THEME.colors.surfaceBorder, borderRadius: THEME.borderRadius.md }}>
            <span style={{ fontSize: '11px', color: THEME.colors.textMuted }}>Corporate Crutches</span>
            <div style={{ marginTop: '4px', fontSize: '14px', fontWeight: 600, color: THEME.colors.accentAmber }}>
              2 Detected ("basically")
            </div>
          </div>

          <div style={{ padding: '12px', backgroundColor: THEME.colors.surfaceBorder, borderRadius: THEME.borderRadius.md }}>
            <span style={{ fontSize: '11px', color: THEME.colors.textMuted }}>Energy Dynamics</span>
            <div style={{ marginTop: '4px', fontSize: '14px', fontWeight: 600, color: THEME.colors.accentEmerald }}>
              Anti-Monotone Pass
            </div>
          </div>
        </div>
      </div>

      {/* Fair Scoring Principles Banner */}
      <div
        style={{
          backgroundColor: 'rgba(0, 240, 255, 0.04)',
          borderRadius: THEME.borderRadius.md,
          border: `1px solid rgba(0, 240, 255, 0.2)`,
          padding: '16px',
        }}
      >
        <div style={{ fontSize: '12px', fontWeight: 700, color: THEME.colors.accentCyan, textTransform: 'uppercase', marginBottom: '8px' }}>
          ⚖️ Hakkiri Fair Scoring Principles
        </div>
        <ul style={{ margin: 0, paddingLeft: '16px', fontSize: '12px', color: THEME.colors.textSecondary, lineHeight: '1.6' }}>
          {FAIR_SCORING_PRINCIPLES.slice(0, 4).map((p, idx) => (
            <li key={idx}>{p}</li>
          ))}
        </ul>
      </div>
    </div>
  );
};
