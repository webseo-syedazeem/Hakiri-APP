import React, { useState } from 'react';
import { THEME } from '../../constants/theme';
import { SUBSCRIPTION_PLANS } from '../../constants/scoringRubrics';
import { useUserStore } from '../../store/useUserStore';

interface PaywallScreenProps {
  onSuccess: () => void;
  onSkip?: () => void;
}

export const PaywallScreen: React.FC<PaywallScreenProps> = ({ onSuccess, onSkip }) => {
  const [selectedPlan, setSelectedPlan] = useState<'monthly_pro' | 'annual_pro'>('annual_pro');
  const { selectSubscription } = useUserStore();

  const handleContinue = () => {
    selectSubscription(selectedPlan);
    onSuccess();
  };

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
      <div>
        <div style={{ display: 'flex', justifyContent: 'flex-end' }}>
          {onSkip && (
            <button
              onClick={onSkip}
              style={{
                background: 'none',
                border: 'none',
                color: THEME.colors.textMuted,
                fontSize: '12px',
                cursor: 'pointer',
              }}
            >
              Skip for now
            </button>
          )}
        </div>

        <div style={{ textAlign: 'center', margin: '20px 0 28px' }}>
          <div
            style={{
              display: 'inline-block',
              padding: '4px 12px',
              borderRadius: THEME.borderRadius.full,
              backgroundColor: 'rgba(0, 240, 255, 0.1)',
              color: THEME.colors.accentCyan,
              fontSize: '11px',
              fontFamily: THEME.typography.fontMono,
              marginBottom: '10px',
            }}
          >
            HAKKIRI PRO MEMBERSHIP
          </div>
          <h1 style={{ fontSize: '28px', fontWeight: 800, margin: '0 0 8px' }}>
            Elevate Your Speech Daily.
          </h1>
          <p style={{ fontSize: '13px', color: THEME.colors.textSecondary, margin: 0 }}>
            Master spontaneous meetings with unscripted drills, executive analytics, and live AI feedback.
          </p>
        </div>

        {/* Pricing Cards */}
        <div style={{ display: 'flex', flexDirection: 'column', gap: '14px' }}>
          {/* Annual Plan Card */}
          <div
            onClick={() => setSelectedPlan('annual_pro')}
            style={{
              backgroundColor: THEME.colors.surface,
              borderRadius: THEME.borderRadius.lg,
              border: `2px solid ${selectedPlan === 'annual_pro' ? THEME.colors.accentCyan : THEME.colors.surfaceBorder}`,
              padding: '18px',
              cursor: 'pointer',
              position: 'relative',
              boxShadow: selectedPlan === 'annual_pro' ? THEME.shadows.glowCyan : 'none',
            }}
          >
            <div
              style={{
                position: 'absolute',
                top: '-10px',
                right: '16px',
                backgroundColor: THEME.colors.accentCyan,
                color: THEME.colors.textInverse,
                fontSize: '10px',
                fontWeight: 700,
                padding: '2px 8px',
                borderRadius: THEME.borderRadius.full,
                fontFamily: THEME.typography.fontMono,
              }}
            >
              SAVE 42% • 7 DAYS FREE
            </div>

            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
              <div>
                <h3 style={{ margin: 0, fontSize: '16px', color: THEME.colors.textPrimary }}>
                  Annual Pro Membership
                </h3>
                <span style={{ fontSize: '12px', color: THEME.colors.textSecondary }}>
                  £69.99 billed annually (£5.83/month)
                </span>
              </div>
              <div style={{ textAlign: 'right' }}>
                <span style={{ fontFamily: THEME.typography.fontMono, fontSize: '20px', fontWeight: 800, color: THEME.colors.accentCyan }}>
                  £69.99
                </span>
                <span style={{ fontSize: '11px', color: THEME.colors.textMuted }}> / yr</span>
              </div>
            </div>
          </div>

          {/* Monthly Plan Card */}
          <div
            onClick={() => setSelectedPlan('monthly_pro')}
            style={{
              backgroundColor: THEME.colors.surface,
              borderRadius: THEME.borderRadius.lg,
              border: `2px solid ${selectedPlan === 'monthly_pro' ? THEME.colors.accentCyan : THEME.colors.surfaceBorder}`,
              padding: '18px',
              cursor: 'pointer',
            }}
          >
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
              <div>
                <h3 style={{ margin: 0, fontSize: '16px', color: THEME.colors.textPrimary }}>
                  Monthly Pro Membership
                </h3>
                <span style={{ fontSize: '12px', color: THEME.colors.textSecondary }}>
                  Flexible recurring access • Cancel anytime
                </span>
              </div>
              <div style={{ textAlign: 'right' }}>
                <span style={{ fontFamily: THEME.typography.fontMono, fontSize: '20px', fontWeight: 800, color: THEME.colors.textPrimary }}>
                  £9.99
                </span>
                <span style={{ fontSize: '11px', color: THEME.colors.textMuted }}> / mo</span>
              </div>
            </div>
          </div>
        </div>

        {/* Features Checklist */}
        <div style={{ marginTop: '24px', display: 'flex', flexDirection: 'column', gap: '8px' }}>
          {SUBSCRIPTION_PLANS.ANNUAL.features.map((feat, idx) => (
            <div key={idx} style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
              <span style={{ color: THEME.colors.accentEmerald, fontSize: '14px' }}>✓</span>
              <span style={{ fontSize: '12px', color: THEME.colors.textSecondary }}>{feat}</span>
            </div>
          ))}
        </div>
      </div>

      <div style={{ marginTop: '32px', display: 'flex', flexDirection: 'column', gap: '10px' }}>
        <button
          onClick={handleContinue}
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
          }}
        >
          {selectedPlan === 'annual_pro' ? 'Start 7-Day Free Trial (£69.99/yr)' : 'Subscribe Now (£9.99/mo)'}
        </button>
        <span style={{ textAlign: 'center', fontSize: '10px', color: THEME.colors.textMuted }}>
          No commitment. Cancel anytime before trial ends to avoid charges.
        </span>
      </div>
    </div>
  );
};
