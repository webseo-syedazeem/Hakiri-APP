import React from 'react';
import { THEME } from '../../constants/theme';
import { useActivityStore } from '../../store/useActivityStore';
import { useUserStore } from '../../store/useUserStore';
import { FeedbackReport } from '../../components/FeedbackReport';

interface FeedbackScreenProps {
  onRetry: () => void;
  onFinish: () => void;
}

export const FeedbackScreen: React.FC<FeedbackScreenProps> = ({ onRetry, onFinish }) => {
  const { latestFeedback } = useActivityStore();
  const { incrementStreak, addXp } = useUserStore();

  if (!latestFeedback) return null;

  const handleFinishDrill = () => {
    incrementStreak();
    addXp(50);
    onFinish();
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
        fontFamily: THEME.typography.fontSans,
      }}
    >
      <FeedbackReport
        feedback={latestFeedback}
        onRetry={onRetry}
        onDone={handleFinishDrill}
      />
    </div>
  );
};
