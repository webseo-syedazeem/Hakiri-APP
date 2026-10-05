import React from 'react';
import { THEME } from '../constants/theme';
import { StructuredFeedback } from '../types/scoring';
import { MetricRadar } from './MetricRadar';

interface FeedbackReportProps {
  feedback: StructuredFeedback;
  onRetry: () => void;
  onDone: () => void;
}

export const FeedbackReport: React.FC<FeedbackReportProps> = ({
  feedback,
  onRetry,
  onDone,
}) => {
  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: '20px' }}>
      {/* Header Score Card */}
      <div
        style={{
          backgroundColor: THEME.colors.surface,
          borderRadius: THEME.borderRadius.lg,
          border: `1px solid ${THEME.colors.surfaceBorder}`,
          padding: '24px',
          display: 'flex',
          justifyContent: 'space-between',
          alignItems: 'center',
          boxShadow: THEME.shadows.card,
        }}
      >
        <div>
          <span
            style={{
              fontSize: '11px',
              fontFamily: THEME.typography.fontMono,
              color: THEME.colors.accentCyan,
              textTransform: 'uppercase',
              letterSpacing: '1px',
            }}
          >
            {feedback.isCoachedRetry ? 'Coached Retry Evaluation' : 'Initial Evaluation'}
          </span>
          <h2 style={{ margin: '4px 0 0', color: THEME.colors.textPrimary, fontSize: '24px' }}>
            Executive Presence Score
          </h2>
        </div>

        <div style={{ textAlign: 'right' }}>
          <span
            style={{
              fontFamily: THEME.typography.fontMono,
              fontSize: '40px',
              fontWeight: 800,
              color: THEME.colors.accentCyan,
            }}
          >
            {feedback.overallScore}.0
          </span>
          <span style={{ fontSize: '16px', color: THEME.colors.textMuted }}> / 5.0</span>
        </div>
      </div>

      {/* 4 Pillars Breakdown */}
      <MetricRadar pillars={feedback.fourPillars} />

      {/* Mandatory Strict Feedback Card */}
      <div
        style={{
          backgroundColor: THEME.colors.surface,
          borderRadius: THEME.borderRadius.lg,
          border: `1px solid ${THEME.colors.surfaceBorder}`,
          padding: '24px',
          display: 'flex',
          flexDirection: 'column',
          gap: '18px',
        }}
      >
        <h3 style={{ margin: 0, fontSize: '16px', color: THEME.colors.textPrimary }}>
          Coaching Directives & Action Items
        </h3>

        {/* 1. One Strength */}
        <div
          style={{
            padding: '14px',
            borderRadius: THEME.borderRadius.md,
            backgroundColor: 'rgba(16, 185, 129, 0.08)',
            borderLeft: `4px solid ${THEME.colors.accentEmerald}`,
          }}
        >
          <div style={{ fontSize: '11px', fontWeight: 700, color: THEME.colors.accentEmerald, textTransform: 'uppercase' }}>
            ✓ Verified Strength
          </div>
          <div style={{ marginTop: '4px', fontSize: '13px', color: THEME.colors.textPrimary }}>
            {feedback.oneStrength}
          </div>
        </div>

        {/* 2. One Specific Improvement */}
        <div
          style={{
            padding: '14px',
            borderRadius: THEME.borderRadius.md,
            backgroundColor: 'rgba(244, 63, 94, 0.08)',
            borderLeft: `4px solid ${THEME.colors.accentRose}`,
          }}
        >
          <div style={{ fontSize: '11px', fontWeight: 700, color: THEME.colors.accentRose, textTransform: 'uppercase' }}>
            ⚡ Primary Area for Improvement
          </div>
          <div style={{ marginTop: '4px', fontSize: '13px', color: THEME.colors.textPrimary }}>
            {feedback.oneSpecificImprovement}
          </div>
        </div>

        {/* 3. Highlighted Phrase / Timestamp */}
        <div
          style={{
            padding: '14px',
            borderRadius: THEME.borderRadius.md,
            backgroundColor: THEME.colors.surfaceBorder,
          }}
        >
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <span style={{ fontSize: '11px', color: THEME.colors.accentCyan, fontFamily: THEME.typography.fontMono }}>
              ⏱️ Timestamp {feedback.highlightedPhraseOrTimestamp.timestampRange}
            </span>
          </div>
          <div
            style={{
              margin: '6px 0',
              fontStyle: 'italic',
              fontSize: '13px',
              color: THEME.colors.textPrimary,
              fontFamily: THEME.typography.fontMono,
            }}
          >
            "{feedback.highlightedPhraseOrTimestamp.phrase}"
          </div>
          <div style={{ fontSize: '12px', color: THEME.colors.textSecondary }}>
            {feedback.highlightedPhraseOrTimestamp.critique}
          </div>
        </div>

        {/* 4. Clear Instruction for the Retry */}
        <div
          style={{
            padding: '14px',
            borderRadius: THEME.borderRadius.md,
            backgroundColor: 'rgba(0, 240, 255, 0.06)',
            borderLeft: `4px solid ${THEME.colors.accentCyan}`,
          }}
        >
          <div style={{ fontSize: '11px', fontWeight: 700, color: THEME.colors.accentCyan, textTransform: 'uppercase' }}>
            🔄 Next Rep Coaching Objective
          </div>
          <div style={{ marginTop: '4px', fontSize: '13px', color: THEME.colors.textPrimary }}>
            {feedback.retryInstruction}
          </div>
        </div>

        {/* Exemplar Response Modal / Accordion */}
        <div
          style={{
            marginTop: '8px',
            padding: '16px',
            borderRadius: THEME.borderRadius.md,
            backgroundColor: '#0F141E',
            border: `1px solid ${THEME.colors.surfaceBorder}`,
          }}
        >
          <div style={{ fontSize: '12px', fontWeight: 600, color: THEME.colors.accentPurple, textTransform: 'uppercase' }}>
            🌟 Exemplar High-Impact Response
          </div>
          <p
            style={{
              margin: '8px 0 0',
              fontSize: '13px',
              lineHeight: '1.6',
              color: THEME.colors.textSecondary,
            }}
          >
            "{feedback.exemplarResponse}"
          </p>
        </div>
      </div>

      {/* Action Buttons */}
      <div style={{ display: 'flex', gap: '12px' }}>
        <button
          onClick={onRetry}
          style={{
            flex: 1,
            padding: '14px 20px',
            borderRadius: THEME.borderRadius.md,
            backgroundColor: THEME.colors.accentCyan,
            color: THEME.colors.textInverse,
            border: 'none',
            cursor: 'pointer',
            fontWeight: 700,
            fontSize: '14px',
            boxShadow: THEME.shadows.glowCyan,
          }}
        >
          Start Coached Retry 🔄
        </button>

        <button
          onClick={onDone}
          style={{
            padding: '14px 24px',
            borderRadius: THEME.borderRadius.md,
            backgroundColor: THEME.colors.surface,
            color: THEME.colors.textPrimary,
            border: `1px solid ${THEME.colors.surfaceBorder}`,
            cursor: 'pointer',
            fontWeight: 600,
            fontSize: '14px',
          }}
        >
          Finish Drill ✓
        </button>
      </div>
    </div>
  );
};
