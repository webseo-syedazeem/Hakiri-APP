# Hakkiri — Daily Communication Gym

**Hakkiri** is a mobile app that trains professionals to think clearly and speak with purpose under real workplace pressure — timed drills, AI feedback, and a personalised daily plan.

This repository is the **working MVP**. Core product loops are live and shipping. More features will keep being added and refined after MVP (levels, curriculum packs, coaching depth, etc.).

| | |
|---|---|
| **Platforms** | iOS & Android (Flutter) |
| **Version** | See `pubspec.yaml` (`1.0.7+7` at time of writing) |
| **Product status** | **MVP — functional end-to-end** |
| **Backend** | Node.js API (`backend-deploy/`) on Vercel |
| **AI** | Google Gemini (speech analysis + voice practice); ElevenLabs / Gemini TTS for coach voice |
| **Auth** | Firebase Auth (email, Google, Apple) + app session |

---

## Product in one sentence

User completes a short assessment → gets a personalised plan → practices timed speaking drills → receives structured AI feedback → retries and builds a streak — without accent penalty.

---

## What is 100% working (MVP)

These flows are implemented and used in the shipped app. Treat them as the source of truth for “what the product does today.”

### 1. Onboarding & guest funnel
- Landing / marketing pages → **Get started**
- **7-question assessment** (name, voice profile, career stage, career field, confidence, biggest challenge, main goal)
- **Personalised plan** screen (focus drills from goal + challenge)
- Guest **free trial** of one drill
- **IAP paywall** (monthly / annual Pro)
- **Create account** (email, Google, Apple)
- Back navigation through the funnel, including restore after app kill (back can return to Get started)
- Login for existing accounts

### 2. Home — Today’s plan
- Daily **3 core exercises** from the user’s focus plan
- Up-next card, completion state, ~2 min labels
- **Targeted retry** and **Tougher challenge** (unlock after core 3 on longer daily anchors)
- Daily practice length: **5 / 10 / 15 minutes** (settings / profile)
- Changing **main goal** or **biggest challenge** refreshes today’s drills

### 3. Practice drills (MVP activities)
All of the following are live MVP drills with catalog prompts, recording, and scoring:

| Activity | What the user does |
|---|---|
| **Think Fast** | Prompt + short think window → ~60s answer |
| **Cut It In Half** | Longer **passage** to compress → summarise in **60s** (not a quiz) |
| **One Minute Expert** | Topic → clear 60s expert-style answer |
| **Explain It Simply** | Explain a concept simply to a non-expert (5s think) |
| **Storytelling Gym** | 3-part spoken story under time |
| **Connect the Dots** | Link two ideas into one coherent talk |
| **Debate Me** | Opening → AI pushback → rebuttal → scored feedback |

Additional activities exist in catalog as **non-MVP / future** (`isMvp: false`) and are not the primary home loop.

### 4. Recording & feedback
- Mic recording (m4a), prep countdown, speak countdown
- Server **transcribe + score** via `/ai/analyze-speech` (Gemini)
- Feedback: overall / pillars / activity measures, strength, improvement, highlight, retry instruction, **suggested answer**
- **Coach TTS** play button on suggested answer (ElevenLabs preferred; Male / Female voice in Settings + Feedback)
- Session history, local playback where available
- Fair scoring: **no accent penalty**; streaks/XP separate from skill scores

### 5. Progress & coaching UX
- **Progress** tab: skill cards (Clarity / Structure / Engagement / Conciseness), recommended next, recent practice, “Hakkiri grows with you”
- Practice library / activity detail / how-it-works copy per drill
- Profile: goals, practice context (industry), daily minutes, AI coach voice, reminders hooks
- Settings: subscription manage entry, industry, AI coach voice, transparency links

### 6. Voice practice conversation (coach)
- Voice practice session token + WebSocket coach path (Gemini models)
- Used for open practice / back-and-forth voice experiences in-app

### 7. Monetisation & accounts
- Store IAP (monthly_pro / annual_pro)
- Guest purchase → create account → sync assessment / subscription
- Logged-in subscribe → home / full access
- Locked profile path when logged in without active plan

### 8. Backend API (working)
Under `backend-deploy/`:
- Auth-gated bootstrap, profile, settings, plan, sessions
- Catalog activities + prompts (career-aware prompt pick)
- `/ai/analyze-speech`, `/ai/debate-pushback`, `/ai/coach-speak`, `/ai/live-token`
- Daily plan block (core drills + extras)
- Weighted scoring engine (server-side caps / measures)

---

## Architecture (current)

```text
Hakiri-APP/
├── lib/                      # Flutter app
│   ├── core/                 # API client, TTS, IAP, analytics, navigation helpers
│   ├── models/
│   ├── providers/            # AppStateProvider (session, plan, drills, feedback)
│   ├── screens/              # All product surfaces
│   └── widgets/
├── backend-deploy/           # Node/Express API → Vercel
│   ├── controllers/
│   ├── services/             # plan, dailyPlan, scoringEngine, coaching, serializers
│   ├── config/ai.js          # Gemini + ElevenLabs
│   └── data/catalog.js       # Activities + prompts
├── docs/                     # Product specs (PRD, curriculum, scoring)
├── supabase/                 # Legacy / optional schema notes (primary runtime is Node API)
└── README.md                 # This file
```

**Client** talks to the Hakkiri API for catalog, scoring, plan, and TTS.  
**Firebase** handles auth providers.  
**Local prefs** hold guest funnel progress so users can resume or walk back to Get started.

---

## User journey (MVP)

```text
Landing → Assessment → Personalised plan
       → (optional free drill)
       → Paywall (IAP)
       → Create account / Login
       → Home (Today) → Drill → Record → AI Feedback → Retry / Progress
```

Back is available through assessment → plan → paywall → create account, including after app restart mid-funnel.

---

## MVP vs ongoing work

### Shipped MVP (use this as baseline)
- Full guest + paid loop
- 7 MVP drills with prompts, timers, recording, AI feedback
- Personalised daily plan from goal + challenge
- Progress skills UI, coach voice gender, settings calibration
- Debate Me guided pushback flow
- Voice practice token path

### Continues after MVP (expected iteration — not “broken,” just next scope)
- Deeper curriculum / more prompt banks and industries
- Stronger coaching prompts and level progression UX
- Performance polish (scoring latency, TTS caching)
- Non-MVP catalog activities turned on when ready
- Enterprise / meeting companion and multi-language (product roadmap, not current MVP commitment)

When suggesting improvements from this repo, **prefer changes that extend the working MVP** rather than rewriting auth, scoring, or drill loops from scratch unless there is a clear bug.

---

## Key product rules (do not regress)

1. **Accent-fair scoring** — score structure, clarity, relevance, fillers, pace — not accent.
2. **Streaks / XP ≠ skill score.**
3. **Cut It In Half** = compress a given **passage** (60s summarise), not invent quiz answers.
4. **Explain It Simply** think window = **5 seconds** (match How it works copy).
5. Home drills follow **goal + biggest challenge**; updating focus must refresh Today’s list.
6. Guest funnel must remain **reversible** back to Get started.

---

## Docs (deeper specs)

| Doc | Contents |
|---|---|
| [`docs/PRD.md`](docs/PRD.md) | Product requirements & journey |
| [`docs/ACTIVITIES_AND_CURRICULUM.md`](docs/ACTIVITIES_AND_CURRICULUM.md) | Drill curriculum & rubrics |
| [`docs/ASSESSMENT_FRAMEWORK.md`](docs/ASSESSMENT_FRAMEWORK.md) | Assessment logic |
| [`docs/SCORING_AND_FEEDBACK_ENGINE.md`](docs/SCORING_AND_FEEDBACK_ENGINE.md) | Scoring model |
| [`docs/MARKET_COMPETITIVE_ANALYSIS.md`](docs/MARKET_COMPETITIVE_ANALYSIS.md) | Market context |

Note: some older doc timings may lag the app (e.g. Cut It In Half is **60s summarise** in product). Prefer **this README + current Flutter/API code** when they disagree.

---

## Quick start (developers)

```bash
# App
flutter pub get
flutter run

# API (local)
cd backend-deploy
npm install
# Set GEMINI_API_KEY (and optional ELEVENLABS_API_KEY) in env
npm start   # or deploy via Vercel (see backend-deploy/vercel.json)
```

Secrets stay in environment / CI — never commit API keys.

---

## For reviewers / AI assistants reading this repo

- This is a **working communication-training MVP**, not a prototype stub.
- Suggest **incremental improvements** (UX polish, prompt quality, performance, tests, accessibility) on top of existing flows.
- Do **not** assume the product is incomplete because Supabase folders or early PRD text exist — the live path is **Flutter + `backend-deploy` + Gemini**.
- Before large refactors, confirm behaviour against: assessment → plan → drill → `/ai/analyze-speech` → feedback → home plan refresh.

---

## License / ownership

Private product repository. All rights reserved by the Hakkiri product owners unless otherwise stated.
