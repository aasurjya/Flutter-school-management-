---
feature: admission
last_tested: 2026-05-16
tester: product-tester
verdict: SHIP
persona: Ms. Reddy, receptionist at a 1,000-student school during April admissions season
---

# Admissions

## At a Glance
- **Verdict:** SHIP — coherent end-to-end. Sales-critical feature implemented cleanly.
- **Entry screen:** [[../../lib/features/admission/presentation/screens/admission_dashboard_screen.dart]]
- **Roles with access:** admin, tenant_admin, receptionist

## Axis 1 — Works?

**Pass:**
- `currentAdmissionStatsProvider` powers 4-card grid (Total / Pending / Accepted / Open Inquiries) with subtitle showing `enrolled` and `totalInquiries` — `admission_dashboard_screen.dart:19, 173-208`.
- `admissionApplicationsProvider(ApplicationFilter(limit:5))` shows real recent applications — `:20-24`.
- 3 quick-action buttons (Inquiries / Applications / Interviews) — `:140-171`. All real routes.
- Pipeline chart fed from real stats — `:67-72`.
- FAB → `admissionApplicationForm` — `:132-136`.
- AppBar settings → `admissionSettings` — `:30-37`.
- Tile onTap routes to detail with applicationId — `:220-223`.
- Avatar fallback with initial letter when no photo — `:226-238`. Nice touch.
- Empty state with inbox icon + "No applications yet" — `:96-113`.

No dead buttons. No mocks. No hardcoded IDs.

## Axis 2 — Good?

- **Taps to create a new application:** 2 (open Admissions → FAB). Excellent.
- **Labels:** "Inquiries / Applications / Interviews" — clean, matches Indian K-12 admission funnel terminology.
- **Pipeline chart** is a strong signal — at-a-glance funnel from Inquiry → Enrolled. This is exactly what a principal asks for in April.
- Status badge component (`ApplicationStatusBadge`) is consistent.

Nitpicks:
- Default `limit: 5` on Recent Applications means a busy receptionist in peak season (50 applications/week) only sees ~1 day of work. Bump to 10 for default, add "View All" link.
- No date filter on stats — "Total Applications" is lifetime, but the question is usually "this season".

## Axis 3 — Necessary?

CRITICAL — admissions is the **revenue gate** for the school. A school decides whether to renew their SaaS subscription based on whether the admissions module made April easier. Keep, treat as a tier-1 feature.

No overlap. The `student_management_screen.dart` in `features/admin/` covers post-enrollment management; this covers pre-enrollment. Clean separation.

## Axis 4 — Improvable?

- [ ] Add a "This season" / "All time" toggle on the stats grid.
- [ ] Add a "Convert inquiry → application" CTA on the inquiry list (suspected to exist already but undiscoverable from this dashboard).
- [ ] Add a "Bulk import inquiries from Excel" — schools collect inquiries on paper or WhatsApp groups; bulk import is a real moat over MyClassboard.

## Notes for the panel

- **Product-intel:** what's the conversion benchmark for an Indian K-12 admission funnel (Inquiry → Application → Interview → Accepted → Enrolled)? Worth surfacing per-stage conversion % on the pipeline chart.
- **Architect:** confirm whether `application_form_screen.dart` supports document upload via the same `avatars` bucket policy from Phase α security closure — admissions need to attach birth certificate + transfer certificate.
- **Critic:** is this and `student_management_screen` cleanly enough separated, or do we have a hidden duplication?

## Backlinks

- [[../00 Index]]
- [[../_feature_inventory_2026-05-16]]
