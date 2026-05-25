# School-Management-Flutter — Stakeholder Feature Audit & Deepening Plan

> **Goal:** Take every "shallow / generic / stub" admin feature to ship-ready, end-to-end, with PDF view + print where applicable. Audit other roles in parallel, log gaps here.
> **Started:** 2026-05-25 (Tarun / tenant_admin focus)
> **Reference scaffolding:** `LOGIN_CREDENTIALS.md`, `AGENTS.md`, `docs/context-map.json`.

---

## 0. Demo Logins (from `LoginScreen` panel)

| Role | Email | Verdict on role's feature depth |
| --- | --- | --- |
| `tenant_admin` | `admin@demoschool.edu` | **MIXED** — Students/Staff/Academic/Announcements ship-ready. Exam Mgmt entirely stub. Fees half-real (stats real, recording fake). Timetable admin UI missing. Report Card uses mock exam list. |
| `principal` | `principal@demoschool.edu` | Uses admin surfaces (router treats both as `/admin`). Same gaps as above. |
| `teacher` (×3) | `teacher{1..3}@demoschool.edu` | Mostly real (attendance, gradebook, classes, assignments, homework). Earlier sprint hardened Apple UX + undo. **Out of current scope** but smoke-test after admin changes. |
| `accountant` | `accountant@demoschool.edu` | Uses `/staff/accountant` dashboard. Touches Fees screens — so fixing Fee Mgmt deepens this role too. |
| `librarian` | `librarian@demoschool.edu` | Not in current depth audit — flagged for follow-up. |
| `transport_manager` | `transport@demoschool.edu` | Bus tracking module exists; admin connection minimal. Flagged. |
| `hostel_warden` | `hostel@demoschool.edu` | Hostel module exists; depth not re-audited. Flagged. |
| `canteen_staff` | `canteen@demoschool.edu` | Canteen module exists; depth not re-audited. Flagged. |
| `receptionist` | `reception@demoschool.edu` | Touches Visitor module — Visitor mostly real but **badge print missing**. Flagged. |
| `student` (×5) | `student{1..5}@demoschool.edu` | Out of this audit's scope; smoke-test after admin work. |
| `parent` | `parent1@demoschool.edu` | Out of this audit's scope; smoke-test after admin work. |
| `super_admin` | `superadmin@demoschool.edu` | Tenants list / create / detail — separate sprint. |

---

## 1. Admin Feature Map (verdict per surface)

| # | Surface | File | Verdict | Notes |
| --- | --- | --- | --- | --- |
| A1 | Dashboard | `lib/features/dashboard/.../admin_dashboard_screen.dart` | **SHALLOW** | Timetable tile points at an unregistered route. Need to either register a timetable builder OR re-point tile. |
| A2 | Student Mgmt | `lib/features/admin/.../student_management_screen.dart` | **SHIP-READY** | Optional: bulk CSV import, hard-delete path. |
| A3 | Staff Mgmt | `lib/features/admin/.../staff_management_screen.dart` | **SHIP-READY** | Optional: bulk CSV import. |
| A4 | Academic Config | `lib/features/admin/.../academic_config_screen.dart` | **SHIP-READY** | 5-entity CRUD all wired. |
| A5 | Announcements | `lib/features/admin/.../announcements_screen.dart` | **SHIP-READY** | Push notification on publish not confirmed. |
| **A6** | **Exam Mgmt** | `lib/features/admin/.../exam_management_screen.dart` | **STUB ⚠️** | **100% hardcoded** `_exams` list. 7 menu actions are snackbars. Create sheet doesn't persist. **TOP PRIORITY**. |
| **A7** | **Fee Mgmt** | `lib/features/admin/.../fee_management_screen.dart` | **SHALLOW ⚠️** | Stats/heads/overdue real. `_RecordPaymentSheet` doesn't write. `_generateInvoices` doesn't write. `_exportReport` is a snackbar. **TOP PRIORITY**. |
| **A8** | **Timetable Builder** | *(missing)* | **MISSING ⚠️** | No admin screen exists. Route `/timetable` declared but no `GoRoute`. **TOP PRIORITY**. |
| A9 | Report Card | `lib/features/report_card/.../*` | **SHALLOW** | PDF preview is production-grade. But `_mockExams` (line 446) and mock dashboard summary (line 285) break trust. |
| A10 | Admission | `lib/features/admission/.../*` | **SHALLOW** | Class field is free-text. No "accept → enroll student" workflow. No offer letter PDF. |
| A11 | Discipline | `lib/features/discipline/.../*` | **SHIP-READY** | Edit/delete + report PDF would polish it. |
| A12 | HR | `lib/features/hr/.../*` | **SHALLOW** | Payroll real; one contract action snackbar-only. No bulk slip download. |
| A13 | Inventory | `lib/features/inventory/.../*` | **SHALLOW** | Provider layer real, action verification partial. Asset register export missing. |
| A14 | Visitor | `lib/features/visitor/.../*` | **SHIP-READY** (gap) | Badge widget exists but **no print/share action**. |
| A15 | Certificate | `lib/features/certificate/.../*` | **SHALLOW** | Bulk issuance / digital seal not confirmed. |
| A16 | Online Exam | `lib/features/online_exam/.../*` | **SHIP-READY** | PDF results sheet would polish it. |
| A17 | Communication Hub | `lib/features/communication/.../*` | (Not audited this round) | Flagged for next sprint. |
| A18 | Substitution | `lib/features/substitution/.../*` | **SHIP-READY** | Report export missing. |

---

## 2. Phased Plan

Each phase is independently shippable, has its own commit, and updates this file's status table.

### Phase 1 — Exam Management end-to-end (**A6**) ✅ TODAY

**Why first:** Highest-impact stub. Every other admin workflow (report cards, marks entry) depends on real exams.

**Outcome:** Admin can create / edit / delete / publish exams, configure subjects, navigate to marks entry. All snackbar stubs replaced with real Supabase calls. Report Card generator picks from real exams instead of `_mockExams`.

**Files touched:**
- `lib/features/admin/presentation/screens/exam_management_screen.dart` — rewrite to use `examsProvider` (build it if missing) instead of hardcoded list.
- `lib/features/exams/providers/*` — add admin-scoped `examsAdminProvider` with full CRUD if not present.
- `lib/data/repositories/exam_repository.dart` — ensure CRUD methods exist.
- `lib/features/report_card/presentation/screens/generate_report_cards_screen.dart` — replace `_mockExams` (line 446) with real provider.

**Done = `flutter analyze` clean + manual smoke against `admin@demoschool.edu`.**

### Phase 2 — Fee Management persistence (**A7**) — NEXT

**Outcome:**
- `_RecordPaymentSheet` actually writes a payment row + decrements invoice balance.
- `_generateInvoices` writes invoice rows via existing `generate_class_invoices()` RPC.
- `_exportReport` produces a real PDF using the `pdf` + `printing` packages already in `pubspec.yaml`.
- "Edit fee head", "Add fee structure", "Apply discount" all wired.
- Receipt PDF + print after a recorded payment.

### Phase 3 — Timetable admin builder (**A8**)

**Outcome:**
- New `TimetableBuilderScreen` under `lib/features/timetable/presentation/screens/`.
- Register `/timetable` GoRoute in `app_router.dart`.
- Grid of weekday × period; tap a cell → assign subject + teacher (`teacher_assignments` table).
- Auto-detect teacher-double-book conflicts.

### Phase 4 — Report Card mock removal (**A9**)

**Outcome:**
- Replace `_mockExams` with `examsByYearProvider` (built in Phase 1).
- Replace mock dashboard summary at `report_card_dashboard_screen.dart:285` with `v_report_card_summary` view (or equivalent aggregation query).

### Phase 5 — Admission deepening (**A10**)

**Outcome:**
- Class picker reads `classesProvider`.
- "Accept application" → creates `students` + auth user + emails credentials.
- Generates offer-letter PDF (uses `pdf` package).

### Phase 6 — Visitor badge print (**A14**)

**Outcome:**
- Add `Printing.layoutPdf(...)` action to `visitor_check_in_screen.dart` / `visitor_badge.dart`.
- Receptionist can print a 4×6 badge after check-in.

### Phase 7 — Polish pass (HR / Inventory / Certificate)

- HR contract action wiring (`contract_management_screen.dart:234`).
- Inventory asset register PDF export.
- Certificate bulk issuance for class.

---

## 3. Cross-Cutting Tasks

- [ ] Verify `pdf`, `printing`, `flutter_html` (PDF viewer) are in `pubspec.yaml`. PDF viewer in-app: `Printing.layoutPdf` already opens system PDF viewer; for in-app viewing add `syncfusion_flutter_pdfviewer` if needed.
- [ ] After each phase: `flutter analyze` must be clean.
- [ ] After each phase: smoke-test in browser at the deployed Pages link with `admin@demoschool.edu` / `Demo@2026`.
- [ ] After Phase 3: re-test teacher and student timetable views (data shape unchanged).

---

## 4. Status Tracker

| Phase | State | PR | Notes |
| --- | --- | --- | --- |
| 1. Exam Mgmt | ✅ Done | — | Real CRUD + publish/unpublish + configure subjects + navigate to marks. `_mockExams` replaced. |
| 2. Fee Mgmt persistence | ✅ Done | — | `_RecordPaymentSheet` writes payments; `_generateInvoices` calls `generate_class_invoices` RPC; PDF receipt + collection report + defaulter report + statement; discount + edit head + add structure all real. |
| 3. Timetable builder | ✅ Done | — | New `TimetableBuilderScreen` + `/timetable` GoRoute + role guard + teacher conflict detection. |
| 4. Report Card mock removal | ✅ Done | — | `_mockExams` replaced with `examsProvider`. Year/term/class/section dropdowns now real. Dashboard `_OverviewStats` + `_ClassStatusGrid` wired to `rcDashboardSummaryProvider`. `?examId=` query param prefills selection. |
| 5. Admission deepening | ✅ Done | `98dec3f` | Real class picker, Accept-and-Enroll runs 5-step pathway: student row + enrollment + auth user + parents + status update. Offer letter PDF action. |
| 6. Visitor badge print | ✅ Done | `c723f98` | `VisitorBadgePdfBuilder` (4×6 inch with QR) wired into check-in success. |
| 7. HR / Inventory / Certificate polish | ✅ Done | `cee55e5` | HR contract action wired; bulk salary slip PDF; inventory register PDF; certificate auto-PDF on issue + new bulk-issue sheet. |
| 8. Librarian issue/return | ✅ Done | `cee55e5` | New `librarian_loans_screen` + issue book sheet + return action; role-guarded `/library/loans` route. |
| 14. AI bug fixes | ✅ Done | `fdd5fc3` | Generate Remarks save + real student context in Message Composer + Send via Chat + spinner bug + sentinel + Child Insights LLM tips. |

---

## 5. Other-Role Audit Findings (operational staff dashboards)

Audited 2026-05-25 via Explore agent. Common pattern: all 6 dashboards are
pure `StatelessWidget` with zero providers and delegate to
`StaffPortalScaffold`. Verdict depends entirely on the destination screens
each tile points to.

| Role | Verdict | Top gap |
| --- | --- | --- |
| **Receptionist** | ✅ SHIP-READY | None blocking. Could add live count badge. |
| **Accountant** | 🟡 SHALLOW | "Collections" and "Reminders" tiles collapse to same `/fees` root — should land on tab 2 / overdue filter. |
| **Librarian** | 🟡 SHALLOW | NO ISSUE/RETURN WRITE FLOW. Sees student-facing catalogue only. |
| **Transport mgr** | 🟡 SHALLOW | "Live tracking" tile duplicates "All routes". No map / GPS. |
| **Hostel warden** | 🟡 SHALLOW | NO check-in / check-out resident action. Two tiles collapse to same destination. |
| **Canteen staff** | 🟡 SHALLOW | ALL tiles point at consumer flows (cart). No order queue, no availability toggle. |

### Phase 8 — Librarian issue/return (top of next sprint)

**Outcome:** Librarian can issue a book to a student, mark it returned,
view active loans, see overdue list with fines.
- Repo methods: `issueBook`, `returnBook`, `getActiveLoans`, `getOverdueLoans`.
- Action sheet on `library_screen.dart` when role is librarian: "Issue book"
  scans QR/searches student → assigns to selected book.
- New screen `librarian_loans_screen.dart` for active loans + overdue.

### Phase 9 — Canteen order queue

**Outcome:** Canteen staff sees a real-time order queue, can mark items
ready / served, can toggle item availability.

### Phase 10 — Transport live tracking

**Outcome:** Live map showing bus positions, driver assignment write flow,
route capacity vs students assigned.

### Phase 11 — Hostel warden write flows

**Outcome:** Check-in/check-out resident on `hostel_detail_screen.dart`,
allocation flow, mess attendance.

### Phase 12 — Accountant tile precision

Small: route accountant tiles to specific filtered views, not generic `/fees`.

### Phase 13 — Super admin tenant CRUD audit

Out of current scope.

---

## 6. AI Features Audit (added 2026-05-26)

Audited 14 AI-branded screens + `ai_text_generator.dart`. Headline: the
LLM infrastructure is REAL (OpenRouter gateway → DeepSeek fallback,
quota-gated). Most screens are SHALLOW (display-only) — actions are the
weak link.

| Screen | Verdict | Top issue |
| --- | --- | --- |
| Risk Dashboard | ✅ SHIP-READY | No "Recalculate" affordance when empty. |
| Student Risk Detail | 🟡 SHALLOW | No share / regenerate; recommendations vs LLM disconnected. |
| Attendance Insights | 🟡 SHALLOW | Silent failure mode for empty LLM response. |
| Trend Dashboard | 🟡 SHALLOW | Display-only; no academic year context. |
| Parent Digest List | ✅ SHIP-READY | No manual "Generate digest" trigger. |
| Parent Digest Detail | 🟡 SHALLOW | Sections are template-filled (not LLM); no share. |
| Early Warning Dashboard | ✅ SHIP-READY | No bulk acknowledge. |
| Alert Detail | ✅ SHIP-READY | **BUG**: permanent spinner on null explanation. |
| Alert Rules Config | ✅ SHIP-READY | No edit / delete on existing rules. |
| Study Recommendations | 🟡 SHALLOW | LLM real; no save / share. |
| **Generate Remarks** | 🔴 STUB | **`_saveAllApproved()` writes NOTHING despite success snackbar.** |
| **AI Message Composer** | 🟡 SHALLOW | `parentName='Parent'` + `contextData={}` hardcoded; "Send via Chat" is stub. |
| Class Intelligence | 🟡 SHALLOW | `_academicYearId='current'` brittle sentinel. |
| Child Insights "Tips" | 🟡 MOCK | Tips are rule-based; no LLM despite AI-branded section. |

### Phase 14 — AI bug & gap fixes (next)

**Outcomes:**
1. **Generate Remarks → real save**: persist approved remarks to a
   `report_remarks` table (add migration only if absent, else use existing).
2. **AI Message Composer → real context**: resolve student name to record;
   pass attendance + fee + grade snapshot as `contextData`; wire "Send via
   Chat" to the messaging module.
3. **Alert Detail spinner bug**: replace permanent spinner with
   "No analysis available" when `aiExplanation == null` after load.
4. **`'current'` sentinel removal**: pass academic year id explicitly.
5. **Child Insights "Tips" → LLM**: swap rule-based tips for
   `studyRecommendationsProvider` output.
