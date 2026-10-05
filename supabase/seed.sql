-- ========================================================================
-- HAKKIRI SEED DATA: 7 MVP ACTIVITIES & PROMPT REPOSITORY
-- ========================================================================

INSERT INTO public.activities (slug, name, is_mvp, tagline, description, cognitive_mechanism, prep_duration_seconds, default_duration_seconds, benefits, success_measures)
VALUES
(
    'think_fast',
    'Think Fast',
    TRUE,
    'Instant cognitive agility under time pressure',
    'A random high-stakes question flashes on screen with a 3-second delay. You speak for 60 seconds using bottom-line-up-front structure.',
    'Rapid lexical retrieval and on-the-spot framing under stress',
    3,
    60,
    ARRAY['High cognitive agility under stress', 'Higher perceived authority through instant structured answers', 'Eliminates waffle and reduces meeting fatigue'],
    ARRAY['Latency & stall tactics', 'Structural coherence', 'Composition and filler density']
),
(
    'cut_it_in_half',
    'Cut It In Half',
    TRUE,
    'Extreme information synthesis and brevity',
    'Review a lengthy corporate brief in 45 seconds, then summarize the core thesis with at least 50% rate compression.',
    'Information distillation, compression, and high-density verbalization',
    45,
    45,
    ARRAY['Forces deep information synthesis', 'Commands executive respect through brevity', 'Increases stakeholder retention and rapid decision making'],
    ARRAY['Rate compression (40-60%+ word reduction)', 'Time to value (leading with core takeaway in first 5s)', 'Jargon translation (clear active phrasing)']
),
(
    'one_minute_expert',
    '1 Minute Expert',
    TRUE,
    'Thematic chunking and spontaneous authority',
    'Select a broad concept and speak authoritatively for exactly 60 seconds with an attention hook, 2 structured points, and a punchy wrap-up.',
    'Categorical frameworks and executive thesis construction',
    5,
    60,
    ARRAY['Trains the brain to chunk complex topics instantly', 'Builds spontaneous executive presence', 'Eliminates rambling run-on explanations'],
    ARRAY['The Hook (immediate compelling thesis)', 'Information Depth (systemic categorization)', 'Time Management (punchy conclusion before 60s buzzer)']
),
(
    'explain_it_simply',
    'Explain It Simply',
    TRUE,
    'Demystifying complexity for non-experts',
    'Translate a complex domain concept into crystal-clear language for a designated non-expert persona without jargon.',
    'Analogical reasoning and demographic persona calibration',
    10,
    60,
    ARRAY['Unlocks cross-functional leadership credibility', 'Forces deep conceptual mastery through simplification', 'Eliminates meeting friction and misaligned expectations'],
    ARRAY['Persona Calibration (tailored vocabulary matching the listener)', 'Time to value (analogies introduced within first 7–15 seconds)', 'Linguistic fit (short sentence structures, average <12–15 words)']
),
(
    'storytelling_gym',
    'Storytelling Gym',
    TRUE,
    'Transform data dumps into compelling narratives',
    'Deliver a powerful 3-part narrative (Context/Tension, Turning Point, Strategic Lesson) in 60 seconds.',
    'Narrative arc pacing, conflict elevation, and strategic lesson landing',
    10,
    60,
    ARRAY['Significantly higher message retention among listeners', 'Drives alignment and persuasion by emotionally engaging stakeholders', 'Projects relatable, authentic leadership presence'],
    ARRAY['Structural architecture (balanced 3-part arc: ~20s per segment)', 'Tension & conflict density (concrete obstacles, not vague mentions)', 'Significance check (ends with profound workplace or strategic takeaway)']
),
(
    'connect_the_dots',
    'Connect the Dots',
    TRUE,
    'Lateral thinking and the seamless pivot',
    'Connect two completely random concepts with a seamless logical bridge within 60 seconds without stammering or awkward pauses.',
    'Associative retrieval and metaphorical bridge building',
    5,
    60,
    ARRAY['Accelerates neural plasticity and unexpected lexical retrieval', 'Mastery of spontaneous pivots during unpredictable Q&As', 'Unlocks creative problem-solving under public observation'],
    ARRAY['Bridge Logic (seamless metaphorical linkage vs disjointed jumps)', 'Pivot Placement (smoothly bridging by 25–35s mark)', 'Speech Mechanics (zero filler words during transition moments)']
),
(
    'debate_me',
    'Debate Me',
    TRUE,
    'Grace under fire and adversarial pushback',
    'Defend your position against an assertive stakeholder objection, maintaining calm chest resonance and eliminating uptalk.',
    'Emotional de-escalation, power pauses, and counter-framing',
    5,
    60,
    ARRAY['Builds neuromuscular resilience against stage fright and confrontational freeze', 'Trains intentional silence to command psychological control', 'Eliminates defensive, high-pitched vocal reactions'],
    ARRAY['Delivery & Biometrics (steady pitch, no upward question inflections)', 'Rhetorical Integrity (direct counter-framing with zero waste semantics)', 'Perceived Confidence (authoritative executive presence vs defensive posture)']
)
ON CONFLICT (slug) DO NOTHING;

-- Seed Sample Prompts
INSERT INTO public.prompts (activity_slug, difficulty, title, prompt_text, secondary_text, objective, exemplar_response, tags, duration_seconds, prep_seconds)
VALUES
(
    'think_fast',
    'beginner',
    'Friday Video Calls Ban',
    'Should companies completely ban video calls on Fridays? Why or why not?',
    NULL,
    'Fill the silence and survive the 60-second clock with a clear perspective.',
    'I strongly believe companies should ban internal video calls on Fridays. First, continuous screen exposure causes cognitive exhaustion by the end of the workweek. Second, dedicated focus time allows employees to wrap up deep analytical work before the weekend.',
    ARRAY['workplace', 'remote_work'],
    60,
    3
),
(
    'think_fast',
    'intermediary',
    'Missed Milestone Accountability',
    'Your team has missed a major project deadline due to a miscommunication. How do you explain this to your client without blaming your team?',
    NULL,
    'Take immediate accountability, outline corrective sprint, and maintain trust.',
    'We take full responsibility for the milestone delay. A breakdown in our internal review cadence caused an unexpected bottleneck. Here is our recovery plan: we have reallocated senior engineers and deliver by Thursday 2 PM.',
    ARRAY['client_management', 'accountability'],
    60,
    3
),
(
    'cut_it_in_half',
    'beginner',
    'Slack After-Hours Communication Policy',
    'Summarize the core policy announcement with at least 50% rate compression within 30 seconds.',
    'Hey team, I just wanted to jump on here and let everyone know that we’ve been looking at how we manage our internal communications lately. It turns out that a lot of people are feeling pretty overwhelmed by the sheer volume of Slack messages flying around every day, especially after hours. Because of that, leadership has decided that starting next Monday, we are going to implement a new policy where no one is expected to reply to any Slack messages after 6:00 PM. We really want everyone to get some proper downtime so we can keep our productivity high during normal working hours.',
    'State the policy immediately, eliminate fluff, speak steadily.',
    'Starting Monday, to protect personal downtime and sustain daytime focus, team members are not required to respond to Slack messages after 6:00 PM.',
    ARRAY['internal_comms', 'brevity'],
    45,
    45
);
