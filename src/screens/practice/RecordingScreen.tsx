import React, { useState, useEffect } from 'react';
import { THEME } from '../../constants/theme';
import { useActivityStore } from '../../store/useActivityStore';
import { WaveformVisualizer } from '../../components/WaveformVisualizer';
import { SpeechTelemetry } from '../../types/scoring';

interface RecordingScreenProps {
  onRecordingComplete: () => void;
}

export const RecordingScreen: React.FC<RecordingScreenProps> = ({ onRecordingComplete }) => {
  const { currentActivity, activePrompt, stopAndEvaluate } = useActivityStore();

  const prepSeconds = currentActivity?.prepDurationSeconds || 3;
  const drillSeconds = activePrompt?.durationSeconds || 60;

  const [phase, setPhase] = useState<'prep' | 'recording'>('prep');
  const [prepCountdown, setPrepCountdown] = useState(prepSeconds);
  const [recordingLeft, setRecordingLeft] = useState(drillSeconds);

  // Prep Countdown Timer
  useEffect(() => {
    if (phase !== 'prep') return;
    if (prepCountdown <= 0) {
      setPhase('recording');
      return;
    }
    const timer = setTimeout(() => setPrepCountdown((p) => p - 1), 1000);
    return () => clearTimeout(timer);
  }, [phase, prepCountdown]);

  // Recording Timer
  useEffect(() => {
    if (phase !== 'recording') return;
    if (recordingLeft <= 0) {
      handleFinish();
      return;
    }
    const timer = setTimeout(() => setRecordingLeft((r) => r - 1), 1000);
    return () => clearTimeout(timer);
  }, [phase, recordingLeft]);

  const handleFinish = () => {
    // Simulated speech telemetry captured from audio stream
    const simulatedTelemetry: SpeechTelemetry = {
      audioDurationSeconds: drillSeconds - recordingLeft,
      transcription:
        activePrompt?.activityId === 'cut_it_in_half'
          ? 'Starting Monday, to protect personal downtime and sustain daytime focus, team members are not required to respond to Slack messages after 6:00 PM.'
          : 'I believe we should ban video calls on Friday mornings. Basically, constant screen fatigue degrades deep work. By creating quiet blocks, team members can execute deep focus tasks without interruption.',
      wordsPerMinute: 145,
      pauseIntervals: [
        { start: 12.0, end: 13.8, duration: 1.8 }, // 1.8s power pause
        { start: 28.5, end: 30.1, duration: 1.6 }, // 1.6s power pause
      ],
      pitchTrackHz: [130, 135, 142, 138, 145, 150, 132, 128, 130],
      decibelTrackDb: [58, 62, 65, 63, 67, 70, 64, 62, 60],
      fillerWordOccurrences: [{ word: 'basically', timestamp: 8.5 }],
      signalToNoiseRatioDb: 24,
      transcriptionConfidence: 0.94,
    };

    stopAndEvaluate(simulatedTelemetry);
    onRecordingComplete();
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
      {/* Phase: Prep Countdown */}
      {phase === 'prep' ? (
        <div
          style={{
            display: 'flex',
            flexDirection: 'column',
            alignItems: 'center',
            justifyContent: 'center',
            height: '80vh',
            textAlign: 'center',
            gap: '16px',
          }}
        >
          <span style={{ fontSize: '12px', color: THEME.colors.accentCyan, fontFamily: THEME.typography.fontMono, textTransform: 'uppercase' }}>
            Get Ready to Think on Your Feet
          </span>
          <div
            style={{
              fontSize: '84px',
              fontWeight: 900,
              fontFamily: THEME.typography.fontMono,
              color: THEME.colors.accentCyan,
              textShadow: '0 0 30px rgba(0, 240, 255, 0.4)',
            }}
          >
            {prepCountdown}
          </div>
          <span style={{ fontSize: '14px', color: THEME.colors.textSecondary }}>
            Prompt will flash immediately. Mic activates automatically.
          </span>
        </div>
      ) : (
        /* Phase: Live Recording Drill */
        <>
          <div>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '16px' }}>
              <span
                style={{
                  fontSize: '11px',
                  fontFamily: THEME.typography.fontMono,
                  color: THEME.colors.accentRose,
                  textTransform: 'uppercase',
                  letterSpacing: '1px',
                }}
              >
                ● LIVE DRILL IN PROGRESS
              </span>
              <span style={{ fontSize: '12px', color: THEME.colors.textMuted }}>
                {currentActivity?.name}
              </span>
            </div>

            {/* Prompt Flash Card */}
            <div
              style={{
                backgroundColor: THEME.colors.surface,
                borderRadius: THEME.borderRadius.lg,
                border: `1px solid ${THEME.colors.accentCyan}`,
                padding: '20px',
                boxShadow: THEME.shadows.glowCyan,
                marginBottom: '20px',
              }}
            >
              <span style={{ fontSize: '11px', color: THEME.colors.accentCyan, fontFamily: THEME.typography.fontMono, textTransform: 'uppercase' }}>
                Your Speaking Prompt:
              </span>
              <h2 style={{ fontSize: '18px', fontWeight: 700, margin: '8px 0 0', lineHeight: '1.4' }}>
                {activePrompt?.promptText}
              </h2>

              {activePrompt?.secondaryText && (
                <div
                  style={{
                    marginTop: '12px',
                    padding: '12px',
                    backgroundColor: THEME.colors.surfaceBorder,
                    borderRadius: THEME.borderRadius.md,
                    fontSize: '12px',
                    lineHeight: '1.5',
                    color: THEME.colors.textSecondary,
                  }}
                >
                  {activePrompt.secondaryText}
                </div>
              )}
            </div>

            {/* Live Audio Telemetry & Waveform */}
            <WaveformVisualizer
              isRecording={true}
              secondsRemaining={recordingLeft}
              totalSeconds={drillSeconds}
            />
          </div>

          <div style={{ marginTop: '24px' }}>
            <button
              onClick={handleFinish}
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
              Stop & Analyze Speech Output 🎙️
            </button>
          </div>
        </>
      )}
    </div>
  );
};
