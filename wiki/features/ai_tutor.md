---
feature: ai_tutor
last_tested: 2026-05-16
tester: product-tester
verdict: KILLED
killed_date: 2026-05-16
persona: Priya, 10th-grader asking for help with quadratic equations
---

# AI Tutor

## At a Glance
- **Verdict:** KILL — feature is **overlay-only** with no entry screen, no route, and no clear job-to-be-done versus the parent's actual willingness to pay. Likely AI-cost-disaster in production for the Indian K-12 price point.
- **Entry screen:** **NONE** — only `widgets/tutor_chat_overlay.dart` + `providers/ai_tutor_provider.dart`.
- **Roles with access:** undefined — the overlay isn't mounted anywhere in `app_router.dart` that I found.

## Axis 1 — Works?

**Structural fail:**
- `lib/features/ai_tutor/` contains exactly 2 files: a provider and an overlay widget.
- No `presentation/screens/` folder.
- The overlay isn't conspicuously launched from any of the 4 dashboards I read.
- If the overlay is gated by a tutor button somewhere I missed, the discoverability is still ~0.

Without a real entry screen, this is **vapor in the 48-feature sprawl**.

## Axis 2 — Good?

N/A — no surface to evaluate.

## Axis 3 — Necessary?

**No.** Three reasons:

1. **Cost-per-conversation is unbounded.** An AI tutor that does multi-turn Q&A with a 14-year-old will burn through ₹50-200 in tokens per session. Indian K-12 SaaS sells at ₹50-200 per student per month. The unit economics don't work as a base feature.
2. **Overlap.** ChatGPT, Gemini, Khan Academy AI tutor, Photomath are all free or cheaper. Parents will use those. Bundling a worse one inside the school app doesn't add value.
3. **Liability.** A student gets wrong answer from "the school's AI tutor" → parent complaint → school reputation hit. The school is not the right vendor of AI tutoring.

Compare to `ai_insights/` (Risk + Remarks + Digest) which lets the **teacher/principal** use AI to do administrative work — that has clear ROI. `ai_tutor` lets the **student** use AI to do learning work — that's an entire other product category with much harder unit economics.

## Axis 4 — Improvable?

- [ ] **Recommend: delete the folder.** Or at minimum, gate it behind a `JARVIS_AI_TUTOR_ENABLED=false` env flag and a "premium add-on" SKU.
- [ ] If kept, the overlay needs:
  - A per-student token budget enforced server-side (e.g. 10 messages/day).
  - A conversation-history page (currently no UI for that).
  - A "this is not a substitute for your teacher" disclaimer at the top of every conversation.
- [ ] Consider repositioning: `ai_homework_helper` — limited to homework questions the student has been assigned. That bounds scope and cost.

## Notes for the panel

- **Critic:** strongest KILL candidate in this audit. Will the panel concur?
- **Product-intel:** has any Indian K-12 SaaS shipped student-facing AI tutoring at a profitable price? Anti-evidence wanted.
- **Architect:** if KILL, remove the dependency on `tutor_chat_overlay.dart` (grep for callers); if KEEP, scope down to homework-helper and gate.
- **CTO:** AI cost model. What's the floor?

## Killed 2026-05-16

Panel decision (4-of-5 unanimous KILL, product-intel concurred as SCOPE-DOWN = delete now):

- `lib/features/ai_tutor/` deleted. Two files removed: `providers/ai_tutor_provider.dart` and `presentation/widgets/tutor_chat_overlay.dart`.
- Mount removed from `lib/core/shell/main_shell.dart`: the `_AiTutorFab` class (32 lines) and its `floatingActionButton:` reference in `_MainShellState.build` were deleted; import for `tutor_chat_overlay.dart` removed.
- No route was registered in `app_router.dart` (none to remove).
- No pubspec.yaml asset entry existed (none to remove).
- The *idea* is preserved as a future paid SKU concept in `wiki/decisions/2026-05-16-ai-tutor-future-sku.md`.

Rationale: unit economics do not support free bundling at Indian K-12 price points; no entry screen existed making the feature vapor; unbounded per-conversation AI cost; free alternatives (Gemini, Khan Academy AI) outcompete. See panel decision at `wiki/panels/feature-audit-decision-2026-05-16.md`.

## Backlinks

- [[../00 Index]]
- [[../_feature_inventory_2026-05-16]]
- [[../panels/feature-audit-decision-2026-05-16]]
- [[../decisions/2026-05-16-ai-tutor-future-sku]]
