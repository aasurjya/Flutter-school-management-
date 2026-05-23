# Pitch Deck Audit — claims vs reality

> Last audited: **2026-05-23** against `sales/PITCH_DECK_SEGMENT_A.html` (on
> parked WIP branch `fix/fees-export-test-viewport`, commit `0a8289b`).

The deck is already honest. It has an explicit *"We don't pretend. Here is
what's coming"* section that admits the two AI features (students-at-risk,
report-card remarks) aren't shipped yet. This audit confirms each
"here-today" claim is genuinely demo-ready and flags where the OpenRouter
gateway (PR #14) lets us **upgrade two "coming soon" items to "here today"**
in the next deck revision.

## Claim ledger

| # | Deck claim | Status | Notes / where it lives |
|---|------------|--------|------------------------|
| 1 | "Take attendance in 30 seconds. Even when internet is down." | ✅ Shipped | Stage 3 PR #11 hardened the offline sync — idempotency + per-record retry + 7-day age TTL + dead-letter to Sentry. Demo: airplane mode → mark class → reconnect → verify single row per student. |
| 2 | "Report cards in one click. Clean PDF, ready to print." | ✅ Shipped | `lib/features/fees/utils/fees_pdf_builder.dart` (uses NotoSans for ₹/Unicode). PDF builder ships; manual workflow in v1 — no AI remarks yet. |
| 3 | "TC, bonafide, ID card. Printed in 10 seconds." | ✅ Shipped | `lib/features/certificate/`, `lib/features/id_card/`. ID-card grid generator confirmed. |
| 4 | "Parents see the bus. Parents see the marks. You stop getting calls." | ✅ Shipped | `lib/features/bus_tracking/`, parent dashboards. Realtime bus location uses Supabase realtime channels (PR #11 added the leak-proof subscription helper). |
| 5 | "Top students get badges and points. Parents see the leaderboard." | ✅ Shipped | `lib/features/gamification/`. Per the feature audit, 9 of the gamification UI surfaces are wired. |
| 6 | "Report a student incident in 20 seconds. Track to closure." | ✅ Shipped | `lib/features/discipline/`. Incident tracking + recognition flows exist. |
| 7 | "Works in Hindi. Works in French. Works in Arabic." | ⚠️ Partial | l10n delegates wired (Stage 2 / PR #3) and `lib/l10n/{en,ar,fr,hi}.arb` have 79–80% coverage. However only the AI badge surface is actually migrated to `context.l10n`; ~2,400 strings are still hardcoded English. **Demo risk:** switching language during the demo will only translate dialogs/menus, not screen body copy. Either commit to migrating 10 high-visibility screens before demo or stop offering live language toggle. |
| 8 | "Works on Jio. Works on ₹6,000 phone." | ✅ Shipped | Stage 2 (PR #6) dropped 632 KB of dead Poppins fonts + parallelized cold start (2-3 s → ~1 s) + Android R8 obfuscation. The "Moto G7 over 3G" claim is now defensible. |
| 9 | "Your data is locked to you. No other school sees your data." | ✅ Shipped | RLS on 104 tables; tenant isolation harness from Stage 1 (PR #5) tests this automatically. **Demo asset:** can run the harness live in front of a buyer to prove it. |
| 10 | "Daily backups." | ⚠️ Manual | Free Supabase tier provides daily snapshots, 7-day retention. PR #5 shipped the `docs/runbooks/restore.md` runbook but the **drill has never been executed**. Risk: this claim is true but unproven. Run the drill once before demo day. |
| 11 | (Coming) "AI: students at risk" | 🟡 **Promotable** | The `student_risk_scores` table + the `compute_student_risk_score()` deterministic SQL function already exist (migration 00010). The risk-score-explanation UI shipped in PR #1 with the "How is this calculated?" disclosure. **With the new OpenRouter gateway (PR #14), this can be moved from "coming" to "here today"** by migrating the narrative provider to call `feature_type='student_analytics'`. See below. |
| 12 | (Coming) "AI: report-card remarks" | 🟡 **Promotable** | The existing `generateReportRemark` method in `ai_text_generator.dart` is wired but uses the legacy AIRouter path. **Migrate to the gateway** with `feature_type='grade_calculation'` and this moves to "here today." |

## Honest gaps before the demo

These aren't deck issues — they're "claim is true but not yet provable on staging" gaps:

1. **No staging Supabase project yet.** Pitch deck shows screenshots; live demo needs `supabase db push` to a staging project + the OpenRouter gateway deployed. See `docs/runbooks/environments.md` for the setup steps.
2. **OpenRouter `OPENROUTER_KEY` not yet on staging Supabase secrets.** Gateway is shipped (PR #14) but inert until the secret is set.
3. **Restore drill never run** (#10 above). One-time 30-min task before any sales rep makes the "daily backups" claim.
4. **Killswitch never toggled live** (`docs/runbooks/killswitch.md`). One-time 5-min drill.
5. **Sentry account doesn't exist.** Free tier is set up in code (PR #5) but needs an account + DSN. Without it, any demo-day crash is uncatchable.

## Two AI-claim upgrades enabled by PR #14

The gateway lets us move two features from "coming soon" to "here today" with minimal code. After these migrations, the deck's "What's coming" section can be revised to show *only* the genuinely-future items.

### Upgrade 1 — "AI: students at risk" → ready for demo

- **Already exists:**
  - `student_risk_scores` table (migration 00010) — deterministic SQL composite score from attendance / academic / fees / engagement.
  - `risk_score_provider.dart` reads the score, `risk_score_badge.dart` displays it, `risk_score_explanation.dart` shows the per-factor breakdown.
- **Wiring task:** `lib/features/ai_insights/providers/risk_score_provider.dart` already has an `aiInsightProvider` style narrative below the score (per the Stage 1 plan). It currently uses the legacy `generateRiskExplanation()` method. **Add `feature_type: 'student_analytics'`** so it routes through the gateway → OpenRouter `deepseek-v4-flash:free`.
- **What changes for the user:** narrative becomes more contextual + diverse across students. Quota-gated so demo can't accidentally blow free-tier.

### Upgrade 2 — "AI: report-card remarks" → ready for demo

- **Already exists:** `generateReportRemark` in `ai_text_generator.dart` — accepts student name + subject + marks, returns a teacher's-voice remark. Currently called from the report-card builder via the AIRouter legacy path.
- **Wiring task:** Migrate the call site to `featureType: 'grade_calculation'`. JSON-mode reliability concern noted in feature_routes seed — response-healing wrapper recommended for the demo to avoid mangled output on rare days.

## Recommended deck revision after this PR

Move from "coming soon" → "here today":
- AI: students at risk *(with the "verify before action" disclosure)*
- AI: report-card remarks *(teacher reviews before sending; AI generates first draft)*

Leave in "coming soon":
- Multi-tenant SSO
- WhatsApp Business integration
- Razorpay automation (table exists, no live flow)

The deck's current copy *"We will tell you when they ship — and your subscription gets them free"* is excellent positioning and should stay.
