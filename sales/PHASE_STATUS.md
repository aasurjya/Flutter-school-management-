# Phase Status — School Management SaaS

**Last updated:** 2026-05-17
**Owner:** Product
**Scope:** Indian schools (CBSE / ICSE / state board). Colleges and universities are deferred to v3.0.

This is the single source of truth for **what is shipped (v1.0, in the pitch deck)** and **what is pending (v1.1 → v3.0)**. Sales must not demo anything marked pending. The pitch deck (`PITCH_DECK_SEGMENT_A.html`) only shows the v1.0 column. Pending items appear on Slide 12 of the deck as "What we are adding next."

---

## v1.0 — SHIPPED (this is what the pitch deck demos today)

| Feature | Plain-English name | Tech module | Pitch deck slide | Confidence |
|---|---|---|---|---|
| Multi-tenant + role-based dashboard | "One app, every role, one login" | `lib/features/super_admin/`, `lib/core/router/app_router.dart` | Slide 3 | ✅ Solid |
| Attendance (manual + bulk) | "Mark a class in 30 seconds" | `lib/features/attendance/` | Slide 4 | ✅ Solid |
| Attendance offline sync | "Works when the internet is down" | `lib/core/services/offline_sync_service.dart` | Slide 4 | ✅ Solid |
| QR code attendance | "Scan and done" | `lib/features/qr_scan/` | Slide 4 | ✅ Solid |
| Report card generation | "Report cards in one click" | `lib/features/report_card/` | Slide 5 | ✅ Solid |
| Certificate (TC / bonafide) | "TC in 10 seconds" | `lib/features/certificate/` | Slide 6 | ✅ Solid |
| Student ID card PDF | "Bulk ID cards with QR" | `lib/features/qr_scan/services/id_card_pdf_service.dart` | Slide 6 | ✅ Solid |
| Parent dashboard | "Parents see marks and attendance" | `lib/features/parent/` | Slide 7 | ✅ Solid |
| Live bus tracking | "Live bus on a map" | `lib/features/bus_tracking/` | Slide 7 | ✅ Solid |
| Gamification + leaderboard | "Reward top students" | `lib/features/gamification/` | Slide 8 | ✅ Solid |
| Discipline / incident log | "Track every incident" | `lib/features/discipline/` | Slide 9 | ✅ Solid |
| Localization (EN / HI / FR / AR) | "Works in Hindi" | `lib/l10n/app_*.arb` | Slide 10 | ✅ Solid |
| Row-level tenant isolation | "Your data locked to your school" | `supabase/migrations/00006_rls_policies.sql` | Slide 11 | ✅ Solid |
| CSV data export | "No vendor lock-in" | various repositories | Slide 11, 14 | ⚠️ Per-screen; not bulk |
| Notice board + announcements | "Notice feed for parents" | `lib/features/notice_board/`, `lib/features/announcements/` | Slide 7 | ✅ Solid |
| In-app messaging | "Threaded inbox" | `lib/features/messaging/` | Slide 7 | ⚠️ Single screen |
| Manual fee entry + PDF receipt | "Record offline payments" | `lib/features/fees/utils/fees_pdf_builder.dart` | Slide 14 (FAQ) | ⚠️ No GST template yet |

### What sales can confidently say about v1.0

- *"Attendance, report cards, parent visibility, transport, certificates — all live."*
- *"Works offline. Works in Hindi. Works on a ₹6,000 phone."*
- *"Your data is locked to your school — even our own staff can't peek."*
- *"30-day free pilot. CSV export anytime. No lock-in."*

---

## v1.1 — INDIA POLISH (next 1–2 weeks)

The four items below unblock the most-asked Indian school objections. None ship in v1.0.

| Feature | Why it matters | Files to touch | Effort |
|---|---|---|---|
| Razorpay / UPI SDK wired | "Online fees with UPI" — #1 Indian school objection | `lib/core/services/payment_gateway_service.dart`, `lib/features/fees/presentation/screens/payment_gateway_screen.dart`, new webhook handler in `supabase/functions/` | M (3–5 days) |
| WhatsApp Business API send | "Where is the WhatsApp integration?" — every Indian school asks | `lib/features/communication/providers/whatsapp_provider.dart`, `lib/data/repositories/whatsapp_repository.dart`, new edge function | M (3–5 days) |
| GST-compliant receipt template + invoice numbering | Accountants block deals if no GST | `lib/features/fees/utils/fees_pdf_builder.dart`, new template file | S (1–2 days) |
| CBSE / ICSE report card presets | "Will it match our board's format?" | `lib/features/report_card/` — add preset template files | S (2 days) |

**Outcome:** every objection a Tier-2 Indian school principal raises is answered by a demoable feature, not a roadmap promise.

---

## v1.5 — PARENT TRUST (next 3–4 weeks)

Items that increase parent retention and reduce churn after onboarding.

| Feature | Why it matters | Files to touch | Effort |
|---|---|---|---|
| Push notification on attendance mark | Parent buzz the moment attendance is taken | `lib/features/attendance/` + FCM trigger; Firebase already in stack | S (2 days) |
| Push on bus geofence event | "Bus 5 min away" buzz | `lib/features/bus_tracking/` + FCM | S (2 days) |
| Automated fee reminder cron | Reduces late fees without office work | Supabase scheduled function + `whatsapp_provider` (needs v1.1 first) | M (3 days) |
| Threaded parent inbox | Today the messaging screen is single-screen | `lib/features/messaging/` | M (4 days) |
| Subscription tier enforcement | Block paid features at free tier (today the plan field is stored but not enforced) | Feature-flag gate in `app_router.dart` + each feature provider | M (4 days) |

---

## v2.0 — AI DIFFERENTIATION (next 6–8 weeks)

The features Slide 12 promises under "AI." None are wired in v1.0 — the tables exist (`00010_ai_phase1.sql`, `00013_fee_default_prediction.sql`, `00014_substitution_ai.sql`) but no model is deployed.

| Feature | Why it matters | Files to touch | Effort |
|---|---|---|---|
| Dropout-risk model deployed | "Students at risk" flag for counsellors | New Supabase edge function + `lib/features/ai_insights/providers/risk_score_provider.dart` | L (1–2 weeks) |
| Fee-default prediction | Flag families likely to default before due date | Migration 00013 + UI in `fees/` | L (1–2 weeks) |
| Attendance anomaly flag | Detect sudden drop in a student's attendance | Rules engine first, ML second | M (1 week) |
| AI report-card commentary | LLM-drafted remarks per student | `lib/core/services/ai_text_generator.dart` + report-card template hook | M (1 week) |

---

## v2.5 — PREMIUM POLISH (after v2.0)

The differentiation items for premium private schools and ambitious mid-tier schools.

| Feature | Why it matters | Files to touch | Effort |
|---|---|---|---|
| White-label tenant branding | "Your logo, your colours, your school" | `lib/core/theme/`, tenant settings | M (4 days) |
| Online-exam proctoring enforcement | Today the proctoring toggle exists but does nothing | `lib/features/online_exam/presentation/screens/take_exam_screen.dart` — server timer + tab-kick + webcam check | L (1–2 weeks) |
| Alumni donor pipeline | Donations → Razorpay → receipt | `lib/features/alumni/presentation/screens/donations_screen.dart` + payment gateway | M (4 days) |
| HR payroll calculation engine | Today payroll screens are UI mocks | `lib/features/hr/presentation/screens/payroll_run_screen.dart` + new calc service | L (1–2 weeks) |
| Admission online payment + entrance scoring | Today admission form captures data, no payment, no scoring | `lib/features/admission/` + payment gateway | M (5 days) |

---

## v3.0 — COLLEGE / UNIVERSITY (deferred; not in current sales focus)

Out of scope for the current pitch deck. Listed only to capture decisions made earlier.

| Feature | Why deferred |
|---|---|
| NAAC / NBA / AICTE / UGC reporting | Requires multi-campus first; sales focus is schools |
| Multi-campus tenant nesting | Today tenants are flat; needs parent-tenant hierarchy |
| Faculty appraisal cycle | HR module needs payroll first (v2.5) |
| Hostel allocation engine | Today is STUB; mess-billing + waitlist + room allocation needed |
| LMS live class (Jitsi / Zoom SDK) | Course catalog works; live streaming SDK not in `pubspec` |
| On-prem deployment + Docker compose | Cloud-only today |

---

## Cross-references

- **Sales playbook:** `sales/BUYER_INSIGHTS.md` — buyer language, objection bank, discovery questions. Note: the existing `BUYER_INSIGHTS.md` over-promises on WhatsApp and AI (lines 172 + 196); flag for a truth-pass once v1.1 ships.
- **Pitch deck:** `sales/PITCH_DECK_SEGMENT_A.html` — only v1.0 features are pitched. Slide 12 names v1.1 / v1.5 / v2.0 / v2.5 honestly.
- **Demo script:** `sales/DEMO_SCRIPT.md` — needs an alignment pass to match the new 15-slide structure (currently aligned to the old 14-slide deck).

---

## Definition of Done (per phase)

A phase only moves from "pending" to "shipped" when:

1. Every feature in the phase passes an end-to-end smoke test on a fresh tenant.
2. The pitch deck slide is updated to demo the new feature (added or moved from Slide 12 into a numbered feature slide).
3. Slide 12 ("What's coming next") is updated to drop the shipped item and add the next pending item.
4. `BUYER_INSIGHTS.md` objection bank is updated — any objection that was answered with "coming in vX.Y" gets rewritten to "live today."
5. `PHASE_STATUS.md` row moves from the pending table to the v1.0 SHIPPED table.

---

## How to read this doc in a sales call

1. Open the deck. Demo v1.0 features only.
2. When the buyer asks about anything NOT in v1.0, point to Slide 12 — "here is when it ships."
3. If they need it sooner, this doc is the prioritisation conversation with product. Do not promise dates outside what is written here.
