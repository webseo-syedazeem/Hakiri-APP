# 12-Month Scoring — Implementation Notes

Implements Phase 1–2 of *Hakkiri Integrated 12-Month Product & Scoring Plan*.

## Permanent pillars (API field mapping)

| Client pillar | API key | Progress card |
|---------------|---------|---------------|
| Clarity | `clarity_score` | Clarity |
| Structure | `executive_score` | Structure |
| Engagement & Tone | `engagement_score` | Engagement & tone |
| Conciseness | `impact_score` | Conciseness |

Overall (Progress) = equal average of pillars that have evidence.

## Rules shipped

1. Activity measures scored first (weighted + heaviest-cap).
2. Measures map to at most one pillar; diagnostics (`response_readiness`, `transition_timing`) stay out of Progress.
3. Same-pillar measures in one session → one averaged contribution.
4. Unmeasured pillars are `null` / omitted — not invented.
5. Fresh prompts only for rolling Progress; coached retries excluded.
6. Rolling window ≈ last **8** valid observations per pillar.

## Key files

- `backend-deploy/services/scoringEngine.js`
- `backend-deploy/config/ai.js` (`normalizeFeedback`)
- `backend-deploy/controllers/sessionController.js` (dashboard + decimal validation)
- Flutter: `session_model.dart`, `progress_screen.dart`, `metric_radar_card.dart`

## Journey shell (Phases 5–8)

Also shipped:

- `GET /journey`, `/journey/weekly-review`, `/journey/chapter-review`
- `POST /journey/benchmark`, `/journey/complete-chapter`
- Weekly focus shapes AI prompts + retry coaching tips
- Flutter: Home chapter chip, Progress focus line, Reflect weekly review, `JourneyScreen`

Still deferred (Phase 9): missions, certificates, LinkedIn, holiday mode, B2B, etc.
