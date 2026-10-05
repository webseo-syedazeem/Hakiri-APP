-- ========================================================================
-- HAKKIRI DATABASE SCHEMA & SECURITY POLICIES (SUPABASE / POSTGRESQL)
-- ========================================================================

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 1. PROFILES (Extends Supabase Auth users)
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT,
    full_name TEXT,
    voice_profile TEXT CHECK (voice_profile IN ('male', 'female', 'non_binary_vocal_alignment')),
    career_stage TEXT CHECK (career_stage IN ('student_early_career', 'mid_level_professional', 'senior_executive_founder', 'general_self_learner')),
    career_type TEXT CHECK (career_type IN ('corporate_finance', 'tech_engineering_product', 'sales_marketing_creator', 'healthcare_education')),
    speaking_confidence TEXT CHECK (speaking_confidence IN ('anxious_shaky', 'moderately_confident', 'highly_confident')),
    primary_roadblock TEXT CHECK (primary_roadblock IN ('fast_talking_mumbling', 'excessive_filler_words', 'monotone_flat_delivery', 'accent_barriers_clarity')),
    primary_goal TEXT CHECK (primary_goal IN ('executive_presence_authority', 'reduce_anxiety_freeze', 'sharp_arguments_debate', 'diction_clarity_stamina')),
    personalized_plan JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. USER SUBSCRIPTIONS
CREATE TABLE IF NOT EXISTS public.subscriptions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    tier TEXT NOT NULL CHECK (tier IN ('free_trial', 'monthly_pro', 'annual_pro', 'enterprise')),
    status TEXT NOT NULL CHECK (status IN ('active', 'trialing', 'past_due', 'canceled')),
    price_gbp NUMERIC(6, 2) NOT NULL,
    trial_end TIMESTAMPTZ,
    current_period_end TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. USER STREAKS & GAMIFICATION (Kept strictly separate from skill scores)
CREATE TABLE IF NOT EXISTS public.user_streaks (
    user_id UUID PRIMARY KEY REFERENCES public.profiles(id) ON DELETE CASCADE,
    current_streak INTEGER DEFAULT 1,
    longest_streak INTEGER DEFAULT 1,
    streak_freeze_count INTEGER DEFAULT 1,
    total_xp INTEGER DEFAULT 100,
    last_practice_date DATE DEFAULT CURRENT_DATE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4. ACTIVITIES CATALOG
CREATE TABLE IF NOT EXISTS public.activities (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    slug TEXT UNIQUE NOT NULL,
    name TEXT NOT NULL,
    is_mvp BOOLEAN DEFAULT FALSE,
    tagline TEXT NOT NULL,
    description TEXT NOT NULL,
    cognitive_mechanism TEXT NOT NULL,
    prep_duration_seconds INTEGER DEFAULT 3,
    default_duration_seconds INTEGER DEFAULT 60,
    benefits TEXT[] DEFAULT '{}',
    success_measures TEXT[] DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 5. ACTIVITY PROMPTS BANK
CREATE TABLE IF NOT EXISTS public.prompts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    activity_slug TEXT REFERENCES public.activities(slug) ON DELETE CASCADE,
    difficulty TEXT NOT NULL CHECK (difficulty IN ('beginner', 'intermediary', 'professional')),
    title TEXT,
    prompt_text TEXT NOT NULL,
    secondary_text TEXT,
    objective TEXT NOT NULL,
    exemplar_response TEXT NOT NULL,
    tags TEXT[] DEFAULT '{}',
    duration_seconds INTEGER DEFAULT 60,
    prep_seconds INTEGER DEFAULT 3,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 6. PRACTICE SESSIONS (Evaluations & 4-Pillar Telemetry)
CREATE TABLE IF NOT EXISTS public.practice_sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    activity_slug TEXT REFERENCES public.activities(slug),
    prompt_id UUID REFERENCES public.prompts(id),
    is_coached_retry BOOLEAN DEFAULT FALSE,
    audio_storage_url TEXT,
    transcript TEXT,
    words_per_minute INTEGER,
    -- 1 to 5 scoring scale
    overall_score INTEGER CHECK (overall_score BETWEEN 1 AND 5),
    executive_presence_score INTEGER CHECK (executive_presence_score BETWEEN 1 AND 5),
    clarity_score INTEGER CHECK (clarity_score BETWEEN 1 AND 5),
    content_impact_score INTEGER CHECK (content_impact_score BETWEEN 1 AND 5),
    engagement_score INTEGER CHECK (engagement_score BETWEEN 1 AND 5),
    crutch_count INTEGER DEFAULT 0,
    power_pause_count INTEGER DEFAULT 0,
    rate_compression_percentage INTEGER,
    -- Strict feedback JSON
    feedback_payload JSONB NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ========================================================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- ========================================================================
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_streaks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.activities ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.prompts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.practice_sessions ENABLE ROW LEVEL SECURITY;

-- Profiles: Users can view and edit their own profile
CREATE POLICY "Users can read own profile" ON public.profiles
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON public.profiles
    FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile" ON public.profiles
    FOR INSERT WITH CHECK (auth.uid() = id);

-- Subscriptions: Users can read their own subscription
CREATE POLICY "Users can read own subscription" ON public.subscriptions
    FOR SELECT USING (auth.uid() = user_id);

-- Streaks: Users can read and update their own streak
CREATE POLICY "Users can read own streaks" ON public.user_streaks
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can update own streaks" ON public.user_streaks
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own streaks" ON public.user_streaks
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Activities & Prompts: Public read access
CREATE POLICY "Activities are readable by everyone" ON public.activities
    FOR SELECT USING (true);

CREATE POLICY "Prompts are readable by everyone" ON public.prompts
    FOR SELECT USING (true);

-- Practice Sessions: Isolated to owner
CREATE POLICY "Users can read own sessions" ON public.practice_sessions
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own sessions" ON public.practice_sessions
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- ========================================================================
-- STORAGE BUCKET CONFIGURATION FOR AUDIO RECORDINGS
-- ========================================================================
INSERT INTO storage.buckets (id, name, public)
VALUES ('speech-recordings', 'speech-recordings', false)
ON CONFLICT (id) DO NOTHING;

CREATE POLICY "Authenticated users can upload speech recordings"
ON storage.objects FOR INSERT TO authenticated
WITH CHECK (bucket_id = 'speech-recordings' AND auth.uid()::text = (storage.foldername(name))[1]);

CREATE POLICY "Users can view their own speech recordings"
ON storage.objects FOR SELECT TO authenticated
USING (bucket_id = 'speech-recordings' AND auth.uid()::text = (storage.foldername(name))[1]);

-- ========================================================================
-- AUTOMATIC PROFILE CREATION TRIGGER ON AUTH SIGNUP
-- ========================================================================
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (id, email, full_name)
    VALUES (NEW.id, NEW.email, COALESCE(NEW.raw_user_meta_data->>'full_name', 'Hakkiri Member'));

    INSERT INTO public.user_streaks (user_id, current_streak, total_xp)
    VALUES (NEW.id, 1, 100);

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
