# Hakkiri 🎙️ — Daily Communication Gym for Real-Life Professional Agility

Hakkiri is a mobile application engineered to train working professionals, graduates, and executives in real-time spontaneous thinking, structured articulation, and high-impact speaking.

Built with **Flutter** (Cross-platform iOS & Android), **Supabase** (PostgreSQL, Auth, RLS, Storage), and a multimodal AI speech evaluation engine.

---

## 🧭 Repository & Architecture Overview

```text
hakiri-app/
├── lib/                                # Flutter Mobile Application (Dart)
│   ├── core/
│   │   ├── constants/                  # Design tokens, AppColors, AppStrings
│   │   └── services/                   # SupabaseService & SpeechEvaluatorService
│   ├── models/                         # Data models (Assessment, Activity, Session)
│   ├── providers/                      # AppStateProvider (Provider-based reactive state)
│   ├── widgets/                        # DailyAnchorCard, MetricRadarCard, WaveformVisualizer, FeedbackReportCard
│   ├── screens/                        # Landing, Assessment, PersonalizedPlan, Paywall, Home,
│   │                                   # AnalyticsDashboard, ActivityDetail, Recording, Feedback
│   └── main.dart                       # App entrypoint with Supabase & Dark Theme
│
├── supabase/                           # Supabase Backend & Database Layer
│   ├── migrations/                     # 20261005000000_hakkiri_schema.sql (PostgreSQL, RLS, Storage)
│   ├── seed.sql                        # Initial activities & prompt bank seeds
│   └── README.md                       # Supabase setup, authentication & deployment guide
│
├── docs/                               # Comprehensive Specifications & Documentation
│   ├── PRD.md                          # Product Requirements Document
│   ├── ARCHITECTURE.md                 # System Architecture & Tech Stack
│   ├── ASSESSMENT_FRAMEWORK.md         # 6-Step Onboarding & AI Personalization Engine
│   ├── ACTIVITIES_AND_CURRICULUM.md    # 7 MVP Activities, Prompts & Level Rubrics
│   ├── SCORING_AND_FEEDBACK_ENGINE.md  # 4-Pillar Scoring Model & Fair Evaluation
│   └── MARKET_COMPETITIVE_ANALYSIS.md  # Competitive Analysis (Yoodli, Vocal Image, Orai, Speeko)
│
├── pubspec.yaml                        # Flutter dependencies (supabase_flutter, provider, google_fonts)
├── package.json                        # TypeScript evaluation scripts
└── README.md                           # Main manual
```

---

## 🚀 Key Modules & Capabilities

### 1. Flutter Mobile Experience
- **Dark Tech Aesthetic**: Deep Obsidian (`#0B0F17`), Electric Cyan (`#00F0FF`), Emerald (`#10B981`), and Rose (`#F43F5E`).
- **6-Step Diagnostic Assessment**: Voice profile biological resonance, career stage, field track, speaking confidence, core roadblock, and primary goal.
- **Personalized AI Roadmap**: Curated 4-week progression tailored to user needs.
- **Subscription Paywall**: £9.99/mo and £69.99/yr (with 7-day free trial).
- **Daily Anchor Drills**: Quick-launch 3–5 minute high-yield communication reps.
- **Waveform & Live Telemetry**: Dynamic audio visualization with countdown timer.
- **Strict 4-Part Feedback**: Every evaluation outputs:
  1. One Strength
  2. One Specific Improvement
  3. Timestamped Excerpt Critique
  4. Clear Retry Directive
  5. Exemplar Response

### 2. Supabase Backend
- **PostgreSQL Database Schema**: `profiles`, `subscriptions`, `user_streaks`, `activities`, `prompts`, and `practice_sessions`.
- **Row Level Security (RLS)**: Enforces strict user privacy across all sessions.
- **Storage Buckets**: `speech-recordings` bucket for audio storage.
- **Offline / Local Demo Fallback**: Works immediately out-of-the-box before adding live cloud credentials.

---

## 🛠️ Quick Start

### Run the Flutter App
```bash
# Get dependencies
flutter pub get

# Analyze code
dart analyze lib

# Run on device or emulator
flutter run
```

### Configure Live Supabase Credentials (Optional)
Run with your Supabase credentials:
```bash
flutter run --dart-define=SUPABASE_URL=https://your-project.supabase.co --dart-define=SUPABASE_ANON_KEY=your-anon-key
```
