import React from 'react';
import { THEME } from '../../constants/theme';
import { ACTIVITIES } from '../../constants/activities';
import { useUserStore } from '../../store/useUserStore';
import { useActivityStore } from '../../store/useActivityStore';
import { DailyAnchorCard } from '../../components/DailyAnchorCard';
import { ActivityId } from '../../types/activity';

interface HomeScreenProps {
  onOpenActivity: (id: ActivityId) => void;
  onOpenAnalytics: () => void;
}

export const HomeScreen: React.FC<HomeScreenProps> = ({
  onOpenActivity,
  onOpenAnalytics,
}) => {
  const { engagementStats } = useUserStore();
  const { selectActivity } = useActivityStore();

  const dailyAnchorActivity = ACTIVITIES[0]; // Think Fast

  const handleStartActivity = (id: ActivityId) => {
    selectActivity(id);
    onOpenActivity(id);
  };

  const mvpActivities = ACTIVITIES.filter((a) => a.isMvp);

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
      {/* Header & Streak Status */}
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <div>
          <span style={{ fontSize: '12px', color: THEME.colors.textMuted, fontFamily: THEME.typography.fontMono }}>
            DAILY COMMUNICATION GYM
          </span>
          <h2 style={{ margin: '2px 0 0', fontSize: '22px', fontWeight: 800 }}>
            Today's Workout
          </h2>
        </div>

        {/* Streak and XP Badges (Kept strictly separate from skill scores) */}
        <div style={{ display: 'flex', gap: '8px' }}>
          <div
            style={{
              display: 'flex',
              alignItems: 'center',
              gap: '4px',
              backgroundColor: 'rgba(245, 158, 11, 0.1)',
              border: '1px solid rgba(245, 158, 11, 0.3)',
              borderRadius: THEME.borderRadius.full,
              padding: '4px 10px',
            }}
          >
            <span style={{ fontSize: '13px' }}>🔥</span>
            <span style={{ fontFamily: THEME.typography.fontMono, fontSize: '12px', fontWeight: 700, color: THEME.colors.accentAmber }}>
              {engagementStats.currentStreakDays}d
            </span>
          </div>

          <div
            style={{
              display: 'flex',
              alignItems: 'center',
              gap: '4px',
              backgroundColor: 'rgba(139, 92, 246, 0.1)',
              border: '1px solid rgba(139, 92, 246, 0.3)',
              borderRadius: THEME.borderRadius.full,
              padding: '4px 10px',
            }}
          >
            <span style={{ fontSize: '13px' }}>⚡</span>
            <span style={{ fontFamily: THEME.typography.fontMono, fontSize: '12px', fontWeight: 700, color: THEME.colors.accentPurple }}>
              {engagementStats.totalXp} XP
            </span>
          </div>
        </div>
      </div>

      {/* Daily Anchor Section */}
      <div>
        <DailyAnchorCard
          activity={dailyAnchorActivity}
          durationLabel="60s Drill"
          onStart={() => handleStartActivity(dailyAnchorActivity.id)}
        />
      </div>

      {/* Analytics Shortcut Banner */}
      <div
        onClick={onOpenAnalytics}
        style={{
          backgroundColor: THEME.colors.surface,
          borderRadius: THEME.borderRadius.lg,
          border: `1px solid ${THEME.colors.surfaceBorder}`,
          padding: '16px 20px',
          display: 'flex',
          justifyContent: 'space-between',
          alignItems: 'center',
          cursor: 'pointer',
        }}
      >
        <div>
          <span style={{ fontSize: '11px', color: THEME.colors.accentCyan, textTransform: 'uppercase', fontFamily: THEME.typography.fontMono }}>
            Executive Presence Analytics
          </span>
          <div style={{ fontSize: '15px', fontWeight: 600, color: THEME.colors.textPrimary, marginTop: '2px' }}>
            Current Composite: 4.2 / 5.0
          </div>
        </div>
        <span style={{ fontSize: '14px', color: THEME.colors.accentCyan }}>View Radar →</span>
      </div>

      {/* All MVP Drills Hub */}
      <div>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'baseline', marginBottom: '12px' }}>
          <h3 style={{ margin: 0, fontSize: '16px', color: THEME.colors.textPrimary }}>
            Explore Core Drills
          </h3>
          <span style={{ fontSize: '12px', color: THEME.colors.textMuted }}>
            {mvpActivities.length} MVP Drills
          </span>
        </div>

        <div style={{ display: 'flex', flexDirection: 'column', gap: '10px' }}>
          {mvpActivities.map((act) => (
            <div
              key={act.id}
              onClick={() => handleStartActivity(act.id)}
              style={{
                backgroundColor: THEME.colors.surface,
                borderRadius: THEME.borderRadius.md,
                border: `1px solid ${THEME.colors.surfaceBorder}`,
                padding: '14px 16px',
                display: 'flex',
                justifyContent: 'space-between',
                alignItems: 'center',
                cursor: 'pointer',
                transition: 'border-color 0.15s ease',
              }}
            >
              <div>
                <h4 style={{ margin: 0, fontSize: '14px', color: THEME.colors.textPrimary }}>
                  {act.name}
                </h4>
                <p style={{ margin: '2px 0 0', fontSize: '12px', color: THEME.colors.textSecondary }}>
                  {act.tagline}
                </p>
              </div>
              <span style={{ fontSize: '12px', fontFamily: THEME.typography.fontMono, color: THEME.colors.accentCyan }}>
                {act.defaultDurationSeconds}s →
              </span>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
};
