import React from 'react';
import { THEME } from '../../constants/theme';

interface LandingScreenProps {
  onStartAssessment: () => void;
  onLogin: () => void;
}

export const LandingScreen: React.FC<LandingScreenProps> = ({
  onStartAssessment,
  onLogin,
}) => {
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
      {/* Header Brand */}
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
          <div
            style={{
              width: '12px',
              height: '12px',
              borderRadius: '2px',
              backgroundColor: THEME.colors.accentCyan,
              boxShadow: THEME.shadows.glowCyan,
            }}
          />
          <span style={{ fontSize: '20px', fontWeight: 800, letterSpacing: '-0.5px' }}>
            HAKKIRI
          </span>
        </div>
        <button
          onClick={onLogin}
          style={{
            background: 'none',
            border: 'none',
            color: THEME.colors.accentCyan,
            fontSize: '13px',
            cursor: 'pointer',
            fontWeight: 600,
          }}
        >
          Already a member? Log in
        </button>
      </div>

      {/* Hero Body */}
      <div style={{ margin: '40px 0', display: 'flex', flexDirection: 'column', gap: '20px' }}>
        <div
          style={{
            display: 'inline-block',
            padding: '4px 10px',
            borderRadius: THEME.borderRadius.full,
            backgroundColor: 'rgba(0, 240, 255, 0.1)',
            border: `1px solid rgba(0, 240, 255, 0.3)`,
            color: THEME.colors.accentCyan,
            fontSize: '11px',
            fontFamily: THEME.typography.fontMono,
            width: 'fit-content',
          }}
        >
          Daily Communication Gym for High-Stakes Professionals
        </div>

        <h1 style={{ fontSize: '36px', lineHeight: '1.15', fontWeight: 800, margin: 0 }}>
          Train Your Brain to Think Fast & Speak with Authority.
        </h1>

        <p style={{ fontSize: '15px', lineHeight: '1.6', color: THEME.colors.textSecondary, margin: 0 }}>
          Master the art of real-life conversations. Hakkiri gives working professionals, executives, and graduates daily reps to organize ideas, eliminate crutch words, and command any room.
        </p>

        {/* Clinical / Research Evidence Box */}
        <div
          style={{
            backgroundColor: THEME.colors.surface,
            borderRadius: THEME.borderRadius.md,
            border: `1px solid ${THEME.colors.surfaceBorder}`,
            padding: '14px',
            fontSize: '12px',
            color: THEME.colors.textMuted,
            lineHeight: '1.5',
          }}
        >
          <strong style={{ color: THEME.colors.accentAmber }}>Evidence-Based Need:</strong> Workplace miscommunication, active listening breakdowns, and messaging friction cost enterprises billions annually and cause critical errors (<a href="https://pmc.ncbi.nlm.nih.gov/articles/PMC6694717/" target="_blank" rel="noreferrer" style={{ color: THEME.colors.accentCyan }}>PMC6694717</a>).
        </div>

        {/* Dashboard Preview Metric Card */}
        <div
          style={{
            backgroundColor: THEME.colors.surface,
            borderRadius: THEME.borderRadius.lg,
            border: `1px solid ${THEME.colors.surfaceBorder}`,
            padding: '18px',
            display: 'flex',
            justifyContent: 'space-around',
            textAlign: 'center',
          }}
        >
          <div>
            <div style={{ fontFamily: THEME.typography.fontMono, fontSize: '20px', fontWeight: 700, color: THEME.colors.accentCyan }}>
              4.8
            </div>
            <div style={{ fontSize: '11px', color: THEME.colors.textMuted, marginTop: '2px' }}>
              Executive Presence
            </div>
          </div>
          <div style={{ width: '1px', backgroundColor: THEME.colors.surfaceBorder }} />
          <div>
            <div style={{ fontFamily: THEME.typography.fontMono, fontSize: '20px', fontWeight: 700, color: THEME.colors.accentEmerald }}>
              -64%
            </div>
            <div style={{ fontSize: '11px', color: THEME.colors.textMuted, marginTop: '2px' }}>
              Filler Density
            </div>
          </div>
          <div style={{ width: '1px', backgroundColor: THEME.colors.surfaceBorder }} />
          <div>
            <div style={{ fontFamily: THEME.typography.fontMono, fontSize: '20px', fontWeight: 700, color: THEME.colors.accentPurple }}>
              1.8s
            </div>
            <div style={{ fontSize: '11px', color: THEME.colors.textMuted, marginTop: '2px' }}>
              Power Pauses
            </div>
          </div>
        </div>
      </div>

      {/* CTA Footer */}
      <div style={{ display: 'flex', flexDirection: 'column', gap: '12px' }}>
        <button
          onClick={onStartAssessment}
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
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            gap: '8px',
          }}
        >
          Take 2-Minute Diagnostic Assessment →
        </button>
        <span style={{ textAlign: 'center', fontSize: '11px', color: THEME.colors.textMuted }}>
          6 simple diagnostic questions • Personalized training plan generated
        </span>
      </div>
    </div>
  );
};
