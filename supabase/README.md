# Hakkiri — Supabase Backend Guide

This directory contains the database migrations, RLS policies, storage bucket configurations, and seed data for the **Hakkiri** application.

---

## 🗄️ Database Architecture

1. **`profiles`**: Maps to Supabase `auth.users`, storing biological voice resonance, career stage, field track, confidence level, and personalized AI curriculum.
2. **`subscriptions`**: Handles subscription status (£9.99/mo, £69.99/yr), 7-day trials, and billing cycles.
3. **`user_streaks`**: Manages streak counts, freeze passes, and XP (enforcing fair scoring by keeping XP separate from 1–5 skill scores).
4. **`activities`**: Catalogs the 7 MVP activities and future roadmap items with time limits and success measures.
5. **`prompts`**: Multi-difficulty prompt bank (Beginner, Intermediary, Professional).
6. **`practice_sessions`**: Complete record of user attempts, including 1–5 composite score, 4-pillar breakdowns, detected crutches, power pauses, and strict feedback JSON.
7. **`storage.buckets['speech-recordings']`**: Audio storage bucket with user-isolated RLS policies.

---

## 🚀 Setup Instructions

### 1. Create a Supabase Project
1. Log in to [supabase.com](https://supabase.com) and create a new project named **Hakkiri**.
2. Note your **Project URL** and **anon public key** from `Project Settings` -> `API`.

### 2. Apply Migrations & Seed
You can execute the SQL directly via the Supabase SQL Editor:
1. Run `supabase/migrations/20261005000000_hakkiri_schema.sql`
2. Run `supabase/seed.sql`

Or with the Supabase CLI:
```bash
supabase db push
supabase db reset
```

### 3. Connect in Flutter
In `lib/core/services/supabase_service.dart`, define your project credentials or pass via `--dart-define`:

```dart
await Supabase.initialize(
  url: const String.fromEnvironment('SUPABASE_URL', defaultValue: 'https://xyz.supabase.co'),
  anonKey: const String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: 'public-anon-key'),
);
```

*Note: The app contains an intelligent mock/offline fallback layer so it runs and tests immediately out-of-the-box even prior to pasting credentials!*
