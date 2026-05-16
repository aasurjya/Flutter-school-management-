---
feature: ai_insights
last_tested: 2026-05-16
tester: product-tester
verdict: IMPROVE
persona: Mr. Verma, principal evaluating AI risk dashboard during a vendor demo
---

# AI Insights (Risk + Early Warning + Generate Remarks)

## At a Glance
- **Verdict:** IMPROVE — strong concept (Opus-grade reasoning sold to Indian K-12) but the visible entry point most demos will hit (`generate_remarks_screen.dart`) ships with **hardcoded mock IDs**. That blows the demo.
- **Entry screen:** [[../../lib/features/ai_insights/presentation/screens/generate_remarks_screen.dart]] + 12 other screens (risk, trend, parent-digest, alerts, etc.)
- **Roles with access:** admin, principal, teacher

## Axis 1 — Works?

**Mixed:**

`generate_remarks_screen.dart`:
- **Hardcoded `_sections`**: `[{'id': 'sec-1', 'name': 'Class 10 - A'}, ...]` — `generate_remarks_screen.dart:24-28`.
- **Hardcoded `_exams`**: `[{'id': 'exam-1', 'name': 'Mid-Term Exam 2026'}, ...]` — `:30-34`.
- These are **mock dropdowns** that look real. The principal selects "Class 10 - A" → "Mid-Term Exam 2026" → presses Generate → backend gets `sec-1` / `exam-1` which don't exist → silent failure or wrong tenant data. This is the **single most embarrassing bug in the codebase for a vendor demo**.
- Below the mock dropdowns the actual provider chain is real (`generateSectionRemarksProvider`, `remarksNotifierProvider.setRemarks`) — `:67-70`. So the AI generation works once given real IDs.

Other AI Insights screens (not deep-read in this pass): `risk_dashboard_screen.dart`, `trend_dashboard_screen.dart`, `early_warning_dashboard_screen.dart`, `parent_digest_list_screen.dart`, `class_intelligence_screen.dart`, `ai_message_composer_screen.dart`. The admin dashboard's "At-Risk Students" banner pulls from real `riskDistributionProvider(RiskDistributionFilter(academicYearId: year.id))` — `admin_dashboard_screen.dart:391-396`. So the underlying data layer for risk is plausibly real.

## Axis 2 — Good?

- **Taps to generate remarks:** 4 (open AI Insights → Generate Remarks → Section → Exam → Generate). Acceptable.
- **Labels:** "Risk Dashboard / Early Warning / Generate Remarks / Parent Digest / Class Intelligence" — these are mostly clear, except "Class Intelligence" which is dev-speak (what does the persona think it means?).
- **Empty/loading:** generate-remarks shows progress with a fake stream-of-ticks while waiting — `generate_remarks_screen.dart:58-65`. UX is honest about the wait.
- **Reuse:** the AI-text-generator + fallback pattern from `fees_screen.dart` reminder dialog is the canonical pattern. Should be reused everywhere AI text is shown.

## Axis 3 — Necessary?

YES, but as a **tier-1 paid feature**, not free-tier. AI risk-scoring + auto-remarks is the differentiator vs MyClassboard/Edsys. It's also expensive (token cost). Position correctly.

13 AI Insights screens is too many. Several feel demo-y:
- `class_intelligence_screen.dart` — sounds impressive, but what's the actual job-to-be-done?
- `study_recommendations_screen.dart` — overlaps with the homework module.
- `parent_digest_list_screen.dart` + `parent_digest_detail_screen.dart` — overlaps with `communication`'s campaign concept.

Consider merging Parent Digest into Communication and Study Recommendations into Homework.

## Axis 4 — Improvable?

- [ ] **Replace `_sections` and `_exams` mock data** with real providers (`sectionsProvider` + `examsProvider(ExamsFilter(activeOnly: true))`) — `generate_remarks_screen.dart:24-34`. Single highest-priority fix in the AI module.
- [ ] Rename "Class Intelligence" → "Class Insights" (less Skynet).
- [ ] Merge `parent_digest_*` screens under `features/communication` as a campaign type.
- [ ] Merge `study_recommendations_screen.dart` into `features/homework` as a teacher-side recommendation surface.
- [ ] Add cost-per-generation indicator on every AI screen (e.g. "~₹0.5 per remark"). Indian principals are price-sensitive.

## Notes for the panel

- **Critic:** the mock-data issue in `generate_remarks_screen.dart` is a "doesn't deserve to exist in current state" call. Fix or ship-block?
- **Product-intel:** what's the price for AI auto-remarks at Teachmint? Sets the ceiling for our pricing.
- **Architect:** lay out the merge plan — parent_digest → communication, study_recs → homework. Should be one ADR.
- **Security-reviewer:** verify AI prompts don't leak student PII to the LLM provider without consent banners.

## Backlinks

- [[../00 Index]]
- [[../_feature_inventory_2026-05-16]]
