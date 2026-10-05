import React from 'react';
import { THEME } from '../constants/theme';

interface WaveformVisualizerProps {
  isRecording: boolean;
  secondsRemaining: number;
  totalSeconds: number;
}

export const WaveformVisualizer: React.FC<WaveformVisualizerProps> = ({
  isRecording,
  secondsRemaining,
  totalSeconds,
}) => {
  const bars = [24, 45, 68, 92, 75, 40, 60, 85, 95, 70, 50, 80, 65, 35, 55, 90, 48, 72, 88, 42];

  const formatTime = (secs: number) => {
    const m = Math.floor(secs / 60);
    const s = secs % 60;
    return `${m}:${s < 10 ? '0' : ''}${s}`;
  };

  return (
    <div
      style={{
        backgroundColor: THEME.colors.surface,
        borderRadius: THEME.borderRadius.lg,
        border: `1px solid ${isRecording ? THEME.colors.accentRose : THEME.colors.surfaceBorder}`,
        padding: '24px',
        display: 'flex',
        flexDirection: 'column',
        alignItems: 'center',
        gap: '20px',
      }}
    >
      {/* Timer Display */}
      <div style={{ textAlign: 'center' }}>
        <span
          style={{
            fontFamily: THEME.typography.fontMono,
            fontSize: '48px',
            fontWeight: 700,
            color: isRecording ? THEME.colors.textPrimary : THEME.colors.textMuted,
            letterSpacing: '-1px',
          }}
        >
          {formatTime(secondsRemaining)}
        </span>
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', gap: '8px', marginTop: '4px' }}>
          <div
            style={{
              width: '8px',
              height: '8px',
              borderRadius: '50%',
              backgroundColor: isRecording ? THEME.colors.accentRose : THEME.colors.textMuted,
              boxShadow: isRecording ? `0 0 8px ${THEME.colors.accentRose}` : 'none',
            }}
          />
          <span
            style={{
              fontSize: '12px',
              fontFamily: THEME.typography.fontMono,
              color: isRecording ? THEME.colors.accentRose : THEME.colors.textMuted,
              textTransform: 'uppercase',
            }}
          >
            {isRecording ? 'Live Mic Telemetry Active' : 'Mic Idle'}
          </span>
        </div>
      </div>

      {/* Simulated Live Audio Waveform Bars */}
      <div
        style={{
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          gap: '4px',
          height: '70px',
          width: '100%',
        }}
      >
        {bars.map((height, i) => (
          <div
            key={i}
            style={{
              width: '4px',
              height: isRecording ? `${height}%` : '15%',
              backgroundColor: isRecording ? THEME.colors.accentCyan : THEME.colors.surfaceBorder,
              borderRadius: '2px',
              transition: 'height 0.15s ease',
            }}
          />
        ))}
      </div>
    </div>
  );
};
