import React, { useState } from 'react';
import { THEME } from '../../constants/theme';
import { ASSESSMENT_QUESTIONS } from '../../constants/assessmentQuestions';
import { useUserStore } from '../../store/useUserStore';
import { AssessmentAnswers } from '../../types/assessment';

interface AssessmentScreenProps {
  onComplete: () => void;
  onBack: () => void;
}

export const AssessmentScreen: React.FC<AssessmentScreenProps> = ({ onComplete, onBack }) => {
  const [currentIndex, setCurrentIndex] = useState(0);
  const { assessmentAnswers, setAssessmentAnswer, completeAssessment } = useUserStore();

  const currentQ = ASSESSMENT_QUESTIONS[currentIndex];
  const selectedValue = assessmentAnswers[currentQ.id];

  const handleSelect = (optionId: string) => {
    setAssessmentAnswer(currentQ.id, optionId as any);

    if (currentIndex < ASSESSMENT_QUESTIONS.length - 1) {
      setCurrentIndex((prev) => prev + 1);
    } else {
      completeAssessment();
      onComplete();
    }
  };

  const handlePrevious = () => {
    if (currentIndex > 0) {
      setCurrentIndex((prev) => prev - 1);
    } else {
      onBack();
    }
  };

  const progressPercentage = ((currentIndex + 1) / ASSESSMENT_QUESTIONS.length) * 100;

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
      {/* Top Progress Bar */}
      <div>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '12px' }}>
          <button
            onClick={handlePrevious}
            style={{
              background: 'none',
              border: 'none',
              color: THEME.colors.textSecondary,
              cursor: 'pointer',
              fontSize: '13px',
            }}
          >
            ← Back
          </button>
          <span
            style={{
              fontFamily: THEME.typography.fontMono,
              fontSize: '12px',
              color: THEME.colors.accentCyan,
            }}
          >
            Step {currentIndex + 1} of {ASSESSMENT_QUESTIONS.length}
          </span>
        </div>

        <div
          style={{
            height: '4px',
            backgroundColor: THEME.colors.surfaceBorder,
            borderRadius: THEME.borderRadius.full,
            overflow: 'hidden',
          }}
        >
          <div
            style={{
              height: '100%',
              width: `${progressPercentage}%`,
              backgroundColor: THEME.colors.accentCyan,
              transition: 'width 0.3s ease',
            }}
          />
        </div>
      </div>

      {/* Question Content */}
      <div style={{ margin: '32px 0', display: 'flex', flexDirection: 'column', gap: '20px' }}>
        <div>
          <h2 style={{ fontSize: '24px', fontWeight: 700, margin: '0 0 8px', color: THEME.colors.textPrimary }}>
            {currentQ.title}
          </h2>
          <p style={{ fontSize: '14px', color: THEME.colors.textSecondary, margin: 0, lineHeight: '1.5' }}>
            {currentQ.subtitle}
          </p>
        </div>

        {/* Options List */}
        <div style={{ display: 'flex', flexDirection: 'column', gap: '12px' }}>
          {currentQ.options.map((opt) => {
            const isSelected = selectedValue === opt.id;
            return (
              <button
                key={opt.id}
                onClick={() => handleSelect(opt.id)}
                style={{
                  backgroundColor: isSelected ? 'rgba(0, 240, 255, 0.08)' : THEME.colors.surface,
                  border: `1px solid ${isSelected ? THEME.colors.accentCyan : THEME.colors.surfaceBorder}`,
                  borderRadius: THEME.borderRadius.lg,
                  padding: '16px',
                  textAlign: 'left',
                  cursor: 'pointer',
                  display: 'flex',
                  flexDirection: 'column',
                  gap: '6px',
                  transition: 'all 0.15s ease',
                  boxShadow: isSelected ? THEME.shadows.glowCyan : 'none',
                }}
              >
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                  <span
                    style={{
                      fontSize: '15px',
                      fontWeight: 600,
                      color: isSelected ? THEME.colors.accentCyan : THEME.colors.textPrimary,
                    }}
                  >
                    {opt.label}
                  </span>
                  <div
                    style={{
                      width: '16px',
                      height: '16px',
                      borderRadius: '50%',
                      border: `2px solid ${isSelected ? THEME.colors.accentCyan : THEME.colors.textMuted}`,
                      backgroundColor: isSelected ? THEME.colors.accentCyan : 'transparent',
                    }}
                  />
                </div>
                <span style={{ fontSize: '12px', color: THEME.colors.textMuted, lineHeight: '1.4' }}>
                  {opt.description}
                </span>
              </button>
            );
          })}
        </div>
      </div>

      <div style={{ textAlign: 'center' }}>
        <span style={{ fontSize: '11px', color: THEME.colors.textMuted }}>
          Tailors industry prompt banks & biometric voice scoring
        </span>
      </div>
    </div>
  );
};
