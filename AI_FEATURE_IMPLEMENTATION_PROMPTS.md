# AI & Discovery Feature Implementation Prompts

> **Project:** School Management SaaS (Flutter + Supabase + Riverpod)
> **Generated:** 2026-02-24 | **Last Updated:** 2026-02-24
> **Purpose:** Step-by-step implementation prompts for AI features, ordered by priority and grouped into phases.
> **AI Backend:** DeepSeek API via `AITextGenerator` (11 specialized generators) + fallback pattern

---

## Implementation Status Dashboard

### Current AI Infrastructure

| Component | Status | File |
|-----------|--------|------|
| DeepSeek Service | LIVE | `lib/core/services/deepseek_service.dart` |
| AI Text Generator (11 methods) | LIVE | `lib/core/services/ai_text_generator.dart` |
| OpenRouter Image Service | LIVE | `lib/core/services/openrouter_image_service.dart` |
| AI Provider (conditional init) | LIVE | `lib/core/providers/ai_providers.dart` |
| AI Insights Module (37 files) | LIVE | `lib/features/ai_insights/` |
| QR Scan Module | LIVE | `lib/features/qr_scan/` |
| Syllabus AI Module | LIVE | `lib/features/syllabus/` |

### Feature Status Summary

| # | Feature | Status | Model | Repo | Provider | Screens | Widgets | AI |
|---|---------|--------|-------|------|----------|---------|---------|-----|
| 1 | Student Risk Score Engine | COMPLETE | Y | Y | Y | 2 | 2 | Y |
| 2 | Weekly Parent Digest | COMPLETE | Y | Y | Y | 2 | 2 | Y |
| 3 | Smart Attendance Insights | COMPLETE | Y | Y | Y | 1 | 3 | Y |
| 4 | Trend Prediction Dashboard | COMPLETE | Y | Y | Y | 1 | 2 | Y |
| 5 | AI Homework Helper Chat | NOT STARTED | - | - | - | - | - | - |
| 6 | Question Paper Generator | NOT STARTED | - | - | - | - | - | - |
| 7 | Multilingual Notifications | NOT STARTED | - | - | - | - | - | - |
| 8 | Daily Challenges | NOT STARTED | - | - | - | - | - | - |
| 9 | AI Study Plan Generator | NOT STARTED | - | - | - | - | - | - |
| 10 | Homework Photo Scanner | NOT STARTED | - | - | - | - | - | - |
| 11 | Smart Resource Recs (pgvector) | NOT STARTED | - | - | - | - | - | - |
| 12 | Predictive Fee Collection | NOT STARTED | - | - | - | - | - | - |

### Bonus Features (Not in Original 12 — Built Separately)

| # | Feature | Status | Notes |
|---|---------|--------|-------|
| B1 | Class Intelligence Dashboard | COMPLETE | Full stack: model, repo, provider, screen, widgets, AI narrative |
| B2 | Early Warning Alerts System | COMPLETE | Full stack: 3 screens, severity badges, configurable rules |
| B3 | Study Recommendations | COMPLETE | Model, provider, screen, AI-generated plans |
| B4 | Report Card Commentary (AI Remarks) | COMPLETE | Model, provider, screen, `generateReportRemark()` |
| B5 | AI Message Composer | COMPLETE | Model, provider, screen, `generateParentMessage()` |
| B6 | QR Student Checkins | COMPLETE | Full stack: scanner, ID card, PDF export, action sheets |
| B7 | AI Syllabus Generator | COMPLETE | Full stack: AI wizard, preview, bulk save, tree editor |
| B8 | AI Lesson Plan Generator | COMPLETE | Model, repo, screens, `generateLessonPlan()` |
| B9 | Topic Coverage Tracking | COMPLETE | Full stack: teacher + admin dashboards, section comparison |
| B10 | Student/Parent Syllabus View | COMPLETE | Read-only view with progress bars on dashboards |

**Total: 14 AI-powered features COMPLETE, 8 features NOT STARTED**

---

## Architecture Overview

All AI features follow this consistent pattern:

```
Flutter UI --> Riverpod Provider --> Repository --> DeepSeek API (via AITextGenerator)
                                         |                    |
                                         v                    v
                                  Supabase PostgreSQL    Fallback Text
                                  (aggregation, views,   (when API unavailable)
                                   feature snapshots)
```

**Current infrastructure (already built):**
- `AITextGenerator` with 11 specialized generators, each with graceful fallback
- `DeepSeekService` for chat completions ($0.28/M input, $1.10/M output tokens)
- Conditional initialization via `AppEnvironment.deepSeekApiKey`
- `LinearRegression` utility for client-side trend analysis

**Infrastructure still needed for remaining features:**
- Supabase Edge Functions runtime (Deno) — for server-side scheduled jobs
- `pg_cron` extension for scheduled jobs (digests, challenges, predictions)
- WhatsApp Business API integration (Gupshup/Wati) — for parent communication
- `pgvector` extension — for resource recommendations (Prompt 11)
- Google Cloud Translation / Bhashini API — for multilingual support (Prompt 7)
- Vision API (GPT-4o or Gemini) — for photo scanning (Prompt 10)

---

## Table of Contents

### Phase 1: Quick Wins (1-2 weeks each)
1. [Multi-Factor Student Risk Score Engine](#prompt-1-multi-factor-student-risk-score-engine) — COMPLETE
2. [AI-Powered Weekly Parent Digest](#prompt-2-ai-powered-weekly-parent-digest) — COMPLETE
3. [Smart Attendance Insights for Teachers](#prompt-3-smart-attendance-insights-for-teachers) — COMPLETE
4. [Trend Prediction Dashboard](#prompt-4-trend-prediction-dashboard) — COMPLETE

### Phase 2: Differentiators (2-4 weeks each)
5. [AI Homework Helper Chat (Socratic)](#prompt-5-ai-homework-helper-chat-socratic-method) — NOT STARTED
6. [One-Click Question Paper Generator](#prompt-6-one-click-question-paper-generator) — NOT STARTED
7. [Multilingual Smart Notifications](#prompt-7-multilingual-smart-notifications) — NOT STARTED
8. [AI-Driven Daily Challenges](#prompt-8-ai-driven-daily-challenges) — NOT STARTED

### Phase 3: Advanced AI (4-6 weeks each)
9. [AI Study Plan Generator](#prompt-9-ai-study-plan-generator) — NOT STARTED
10. [Homework Photo Scanner](#prompt-10-homework-photo-scanner-with-ai-explanation) — NOT STARTED
11. [Smart Resource Recommendations (pgvector)](#prompt-11-smart-resource-recommendations-with-pgvector) — NOT STARTED
12. [Predictive Fee Collection Intelligence](#prompt-12-predictive-fee-collection-intelligence) — NOT STARTED

### Phase 4: Growth & Revenue AI (NEW — CEO/CFO Priority)
13. [AI-Powered Admission Inquiry Chatbot](#prompt-13-ai-powered-admission-inquiry-chatbot) — NEW
14. [Intelligent Timetable Generator](#prompt-14-intelligent-timetable-generator) — NEW
15. [AI Exam Answer Script Evaluation](#prompt-15-ai-exam-answer-script-evaluation-assistance) — NEW
16. [Predictive Enrollment Forecasting](#prompt-16-predictive-enrollment-forecasting) — NEW
17. [AI-Driven Transport Route Optimization](#prompt-17-ai-driven-transport-route-optimization) — NEW

### Phase 5: Engagement & Wellbeing AI (NEW)
18. [AI Behavioral & Sentiment Analysis](#prompt-18-ai-behavioral--sentiment-analysis) — NEW
19. [AI Substitution Teacher Assignment](#prompt-19-ai-substitution-teacher-assignment) — NEW
20. [AI Canteen Menu Optimization](#prompt-20-ai-canteen-menu-optimization--nutrition-analysis) — NEW

---

## CEO/CFO STRATEGIC ANALYSIS

### Market Context (2025-2026)

- Global AI in education market: **$7.57B (2025)** → projected **$112B by 2034**
- SaaS deployments account for **60%+ of global EdTech spend**
- Teachers using AI weekly save **5.9 hours/week** (six full weeks per year)
- **85% of teachers** have used AI tools in the past school year
- **74% of SaaS companies** are already monetizing AI features
- Students on AI-driven platforms score **12.4% higher** than peers

### Competitive Landscape

| Competitor | AI Features | Gap We Can Exploit |
|------------|------------|-------------------|
| Google Classroom | AI-suggested feedback (Feb 2026), Gemini lesson plans | No school management, no Indian board alignment |
| PowerSchool | PowerBuddy AI assistant, predictive dashboards | Enterprise-only, expensive, US-focused |
| Teachmint | Basic analytics, live class recording | No AI-generated content, no risk scoring |
| Classera | Gamification, basic analytics | No AI insights, no multilingual |
| LEAD School | Curriculum-in-a-box, some AI | Closed ecosystem, not SaaS |

**Our Advantage: 14 AI features already built + DeepSeek at $0.28/M tokens = unbeatable cost-to-feature ratio**

### Revenue Strategy (CFO Perspective)

| Tier | Features | Suggested Price (INR/school/month) |
|------|----------|----------------------------------|
| **Basic** | Core management (no AI) | Free / Rs 2,000 |
| **Standard** | + Risk Scores, Attendance Insights, Report Remarks | Rs 5,000 |
| **Premium** | + All AI features, Parent Digest, Syllabus AI | Rs 10,000 |
| **Enterprise** | + Admission Chatbot, Timetable AI, Multilingual | Rs 25,000 |

**Unit Economics per School (1,000 students):**
- Total DeepSeek API cost for ALL features: **$55-150/year** (~Rs 4,500-12,500/year)
- Revenue at Standard tier: Rs 60,000/year
- Revenue at Premium tier: Rs 1,20,000/year
- **Gross margin on AI features: 85-95%**

### Priority Matrix (CEO Perspective)

```
                    HIGH IMPACT
                        |
    SHIP NOW            |     BUILD NEXT
    (Already Built)     |     (High ROI)
                        |
  - Risk Scores [done]  |  - Question Paper Gen [P6]
  - Parent Digest [done]|  - Fee Collection AI [P12]
  - Attendance AI [done]|  - Admission Chatbot [P13]
  - Trend Pred [done]   |  - Timetable Gen [P14]
  - Class Intel [done]  |  - Multilingual [P7]
  - Report Remarks[done]|  - Study Plan Gen [P9]
  - Message Composer    |
  - Syllabus AI [done]  |
  - Lesson Plans [done] |
                        |
 -------LOW EFFORT------+------HIGH EFFORT-------
                        |
    NICE TO HAVE        |     FUTURE ROADMAP
                        |
  - Daily Challenges[P8]|  - Homework Chat [P5]
  - Substitution AI[P19]|  - Photo Scanner [P10]
  - Canteen AI [P20]    |  - Answer Eval [P15]
                        |  - Transport AI [P17]
                        |  - pgvector Recs [P11]
                        |  - Behavioral AI [P18]
                        |  - Enrollment Pred [P16]
                        |
                    LOW IMPACT
```

---

## PHASE 1: QUICK WINS

---

### PROMPT 1: Multi-Factor Student Risk Score Engine

**Priority:** P0 | **Effort:** 1 week | **Impact:** Prevents student dropouts and academic failure

> **STATUS: COMPLETE**
>
> | Component | File | Done |
> |-----------|------|------|
> | Model | `lib/data/models/student_risk_score.dart` | Y |
> | Repository | `lib/data/repositories/risk_score_repository.dart` | Y |
> | Provider | `lib/features/ai_insights/providers/risk_score_provider.dart` | Y |
> | Dashboard Screen | `lib/features/ai_insights/presentation/screens/risk_dashboard_screen.dart` | Y |
> | Detail Screen | `lib/features/ai_insights/presentation/screens/student_risk_detail_screen.dart` | Y |
> | Risk Badge Widget | `lib/features/ai_insights/presentation/widgets/risk_score_badge.dart` | Y |
> | Factor Bar Widget | `lib/features/ai_insights/presentation/widgets/risk_factor_bar.dart` | Y |
> | AI Integration | `AITextGenerator.generateRiskExplanation()` | Y |
> | Route Integration | `app_router.dart` | Y |
> | Dashboard Integration | Teacher + Admin dashboards show at-risk students | Y |
>
> **What was built:** 5-factor composite risk scoring (attendance, academic, assignment, behavioral, fee), risk distribution cards, filtered risk list, individual student risk analysis with factor breakdown, AI-generated explanations with fallback text.

#### Context

The database already has complete schema for AI predictions in `supabase/migrations/20260209112622_ai_predictive_analytics.sql`:
- `early_warning_alerts` table with `alert_category`, `severity`, `status`, `confidence_score`
- `alert_rules` table with `condition_logic` JSONB and `auto_assign_to_role`
- `student_feature_snapshots` table with `current_gpa`, `attendance_percentage`, `assignment_completion_rate`, `discipline_incidents_count`
- `student_performance_predictions` table with `risk_level`, `dropout_probability`, `intervention_required`
- The `check_alert_rules()` function exists but has minimal implementation
- The `v_student_risk_scores` view exists in `supabase/migrations/00008_new_features.sql`

#### Task

Implement the complete risk scoring pipeline from database function to Flutter UI.

#### Step 1: Database — Implement Risk Scoring Function

Create a new migration file `supabase/migrations/20260224_risk_scoring_engine.sql` that:

1. **Creates or replaces the `calculate_student_risk_score` function** that computes a composite score (0-100) per student:
   - **Attendance factor (25% weight):** Query `attendance` table for the current term. Calculate `(absent_days + 0.5 * late_days) / total_school_days`. If attendance < 75%, flag as high risk. Map to 0-25 score where 25 = perfect attendance, 0 = never attends.
   - **Academic factor (30% weight):** Query `mv_student_performance` materialized view. Calculate average percentage across all exams in current term. Compare against class average. If student is >20% below class average, flag high risk. Map to 0-30 score.
   - **Assignment factor (20% weight):** Query `submissions` table joined with `assignments`. Calculate `submitted_on_time / total_assigned`. If completion rate < 50%, flag. Map to 0-20.
   - **Behavioral factor (15% weight):** Query `behavior_incidents` table (if data exists, else default to full score). Count negative incidents in current term. Deduct points per severity: minor=-2, moderate=-5, major=-10, severe=-15. Cap at 0. Map to 0-15.
   - **Fee factor (10% weight):** Query `invoices` table. Check for overdue invoices. If total overdue > 30 days, flag. Map to 0-10.
   - Return: `total_score`, `risk_level` (low >70, medium 50-70, high 30-50, critical <30), individual factor scores, and `flags` text array.

2. **Creates a `refresh_risk_scores` function** that:
   - Loops through all active students in a given tenant
   - Calls `calculate_student_risk_score` for each
   - Upserts into `student_performance_predictions` table
   - Creates `early_warning_alerts` for any student whose risk level changed from low/medium to high/critical
   - Auto-assigns alerts to the student's class teacher (via `sections.class_teacher_id` from `student_enrollments`)

3. **Schedules the function** via `pg_cron`:
   ```sql
   SELECT cron.schedule('refresh-risk-scores', '0 6 * * 1-5', $$SELECT refresh_risk_scores()$$);
   ```
   This runs every weekday at 6 AM before school starts.

4. **Creates helper view `v_student_risk_dashboard`** that joins:
   - `student_performance_predictions` (latest prediction per student)
   - `students` (name, photo, admission number)
   - `student_enrollments` -> `sections` -> `classes` (current class/section)
   - `early_warning_alerts` (unresolved alerts count)
   - Order by `risk_level` DESC (critical first), then by total score ASC

#### Step 2: Supabase Repository

Create `lib/data/repositories/risk_score_repository.dart`:

```dart
class RiskScoreRepository extends BaseRepository {
  // getStudentRiskScores(sectionId) — fetch from v_student_risk_dashboard
  //   Filter by tenant_id and optionally section_id
  //   Return List<StudentRiskScore>

  // getStudentRiskDetail(studentId) — full prediction with factor breakdown
  //   Join student_performance_predictions with student_feature_snapshots
  //   Return StudentRiskDetail with all factor scores and history

  // getRiskAlerts(sectionId, status) — fetch early_warning_alerts
  //   Filter by status (new, acknowledged, in_progress)
  //   Join with students for display names
  //   Return List<RiskAlert>

  // acknowledgeAlert(alertId) — update status to 'acknowledged'
  // resolveAlert(alertId, notes) — update status to 'resolved' with notes

  // getRiskTrend(studentId, months) — fetch historical risk scores
  //   Query student_performance_predictions ordered by predicted_at
  //   Return List<RiskTrendPoint> for charting
}
```

#### Step 3: Data Models

Create `lib/data/models/risk_score.dart`:

- `StudentRiskScore`: `studentId`, `studentName`, `photoUrl`, `className`, `sectionName`, `totalScore` (0-100), `riskLevel` (enum: low/medium/high/critical), `attendanceFactor`, `academicFactor`, `assignmentFactor`, `behavioralFactor`, `feeFactor`, `flags` (List<String>), `alertCount`, `lastUpdated`
- `StudentRiskDetail`: Extends above with `trend` (List<RiskTrendPoint>), `recommendedActions` (List<String>), `interventions` (List<Intervention>)
- `RiskAlert`: `id`, `studentId`, `studentName`, `category`, `severity`, `title`, `description`, `status`, `createdAt`, `assignedTo`
- `RiskTrendPoint`: `date`, `score`, `riskLevel`

#### Step 4: Provider

Create `lib/features/insights/providers/risk_score_provider.dart`:

- `riskScoreRepositoryProvider` — provides RiskScoreRepository
- `sectionRiskScoresProvider(sectionId)` — FutureProvider.family returning List<StudentRiskScore>
- `studentRiskDetailProvider(studentId)` — FutureProvider.family returning StudentRiskDetail
- `riskAlertsProvider(sectionId)` — FutureProvider.family returning List<RiskAlert>

#### Step 5: Flutter UI — Risk Dashboard Screen

Create `lib/features/insights/presentation/screens/risk_dashboard_screen.dart`:

**Layout:**
```
+------------------------------------------+
| AppBar: "Student Risk Monitor"    [Filter]|
+------------------------------------------+
| Risk Summary Cards (horizontal scroll):  |
| +------+ +------+ +------+ +------+     |
| |CRIT:2| |HIGH:5| |MED:12| |LOW:31|     |
| +------+ +------+ +------+ +------+     |
+------------------------------------------+
| Section Selector: [Class 10-A v]         |
+------------------------------------------+
| Alerts Tab | All Students Tab            |
+------------------------------------------+
| Student Risk Cards (sorted by risk):     |
| +--------------------------------------+ |
| | Aarav Sharma    Class 10-A           | |
| | Score: 28/100  [CRITICAL]            | |
| | Attendance: 58%  Assignments: 30%    | |
| | 2 unresolved alerts                  | |
| | [View Detail] [Create Intervention]  | |
| +--------------------------------------+ |
+------------------------------------------+
```

- Tapping a card navigates to a **Risk Detail Screen** showing:
  - Radar chart of 5 factor scores (using `fl_chart`)
  - Risk trend line chart (last 3 months)
  - Active alerts list
  - Recommended actions
  - "Create Intervention" button that opens a form linked to `student_interventions`

#### Step 6: Route Registration

Add to `lib/core/router/app_router.dart`:
- `/risk-dashboard` -> RiskDashboardScreen (teacher/admin only)
- `/risk-detail/:studentId` -> StudentRiskDetailScreen
- Add "Risk Monitor" to teacher dashboard quick actions

#### Step 7: Integration Points

- Add a small risk indicator badge to the existing student list cards in `students_list_screen.dart` — a colored dot (red/orange/yellow/green) next to each student's name
- Add "At Risk Students" section to `teacher_dashboard_screen.dart` showing top 3 critical/high risk students from teacher's classes
- Link from `student_detail_screen.dart` to risk detail

---

### PROMPT 2: AI-Powered Weekly Parent Digest

**Priority:** P0 | **Effort:** 1 week | **Impact:** 40-60% increase in parent app engagement

> **STATUS: COMPLETE**
>
> | Component | File | Done |
> |-----------|------|------|
> | Model | `lib/data/models/parent_digest.dart` | Y |
> | Sub-models | `WeeklyAttendance`, `AcademicHighlight`, `UpcomingEvent` | Y |
> | Repository | `lib/data/repositories/parent_digest_repository.dart` | Y |
> | Provider | `lib/features/ai_insights/providers/parent_digest_provider.dart` | Y |
> | List Screen | `lib/features/ai_insights/presentation/screens/parent_digest_list_screen.dart` | Y |
> | Detail Screen | `lib/features/ai_insights/presentation/screens/parent_digest_detail_screen.dart` | Y |
> | Digest Card Widget | `lib/features/ai_insights/presentation/widgets/digest_card.dart` | Y |
> | Template Engine | `lib/features/ai_insights/utils/digest_template_engine.dart` | Y |
> | AI Integration | `AITextGenerator.generateDigestSummary()` | Y |
> | Dashboard Integration | Parent dashboard digest banner | Y |
>
> **What was built:** Weekly digest with attendance tracking, academic highlights, upcoming events, warm personalized AI summaries, unread count badge, template engine for section formatting.

#### Context

The app already has:
- `lib/features/dashboard/presentation/screens/parent_dashboard_screen.dart` — shows children overview
- `lib/features/notifications/` — notification system with push support
- `lib/data/models/notification.dart` — AppNotification model
- `lib/data/repositories/notification_repository.dart` — notification CRUD
- Firebase messaging configured in `pubspec.yaml`
- `notifications` table with `type`, `priority`, `title`, `body`, `data` JSONB, `action_data` JSONB
- All required data exists: attendance, exams, assignments, achievements

#### Task

Build an automated weekly digest system that generates personalized parent summaries every Friday.

#### Step 1: Supabase Edge Function — Digest Generator

Create `supabase/functions/weekly-parent-digest/index.ts`:

```typescript
// This Deno Edge Function:
// 1. Queries all active students grouped by parent
// 2. For each student, aggregates this week's data:
//    a. Attendance: days present/absent/late this week
//    b. Recent exam scores with comparison to previous
//    c. Assignments due and submitted status
//    d. Achievements earned this week
//    e. Any behavioral notes (positive or negative)
//    f. Upcoming events next week (exams, PTM, holidays)
// 3. Sends the aggregated data to an LLM (DeepSeek or GPT-4o-mini)
//    with this system prompt:
//    """
//    You are a school assistant writing a brief weekly update for a parent.
//    Be warm, encouraging, and specific. Mention the child's name.
//    Highlight positives first, then areas needing attention.
//    End with one specific actionable suggestion.
//    Keep it under 150 words. Use simple English.
//    Format: short paragraphs, no bullet points, conversational tone.
//    """
// 4. Inserts the generated text into the `notifications` table with:
//    type: 'weekly_digest'
//    priority: 'normal'
//    action_type: 'open_child_insights'
//    action_data: { studentId: '...' }
// 5. Sends FCM push notification to parent's device via fcm_token from users table
```

**SQL Query Template for Data Aggregation** (include in the Edge Function):
```sql
-- Attendance this week
SELECT status, COUNT(*)
FROM attendance
WHERE student_id = $1
  AND date >= date_trunc('week', CURRENT_DATE)
  AND date <= CURRENT_DATE
GROUP BY status;

-- Recent exam scores
SELECT e.name, es.subject_id, s.name as subject_name,
       m.marks_obtained, es.max_marks,
       ROUND(m.marks_obtained/es.max_marks * 100, 1) as percentage
FROM marks m
JOIN exam_subjects es ON m.exam_subject_id = es.id
JOIN exams e ON es.exam_id = e.id
JOIN subjects s ON es.subject_id = s.id
WHERE m.student_id = $1
  AND e.start_date >= CURRENT_DATE - INTERVAL '14 days'
ORDER BY e.start_date DESC;

-- Assignments status
SELECT a.title, a.due_date, sub.status, sub.marks_obtained
FROM assignments a
LEFT JOIN submissions sub ON sub.assignment_id = a.id AND sub.student_id = $1
WHERE a.section_id = $2
  AND a.due_date >= date_trunc('week', CURRENT_DATE)
  AND a.due_date <= CURRENT_DATE + INTERVAL '7 days';

-- Achievements earned
SELECT ach.name, ach.category, sa.earned_at
FROM student_achievements sa
JOIN achievements ach ON sa.achievement_id = ach.id
WHERE sa.student_id = $1
  AND sa.earned_at >= date_trunc('week', CURRENT_DATE);
```

#### Step 2: Schedule the Edge Function

Use Supabase `pg_cron` or an external cron (e.g., GitHub Actions) to call the Edge Function every Friday at 4 PM:

```sql
-- Option A: pg_cron calling Edge Function via pg_net
SELECT cron.schedule(
  'weekly-parent-digest',
  '0 16 * * 5',  -- Friday 4 PM
  $$SELECT net.http_post(
    url := 'https://YOUR_PROJECT.supabase.co/functions/v1/weekly-parent-digest',
    headers := '{"Authorization": "Bearer SERVICE_ROLE_KEY"}'::jsonb
  )$$
);
```

#### Step 3: Flutter UI — Digest Display

Add to the existing `notification_center_screen.dart`:
- A new "Weekly Digest" tab or filter
- Digest cards with a special visual treatment: gradient background, child avatar, and the generated text
- Tapping the card navigates to `ChildInsightsScreen` for that child

Create a new widget `lib/features/notifications/presentation/widgets/weekly_digest_card.dart`:
- Child's avatar and name at top
- Generated digest text (markdown rendered)
- "View Full Insights" button
- Week date range label
- Distinct visual style (light blue or green background to differentiate from alerts)

#### Step 4: Parent Dashboard Integration

In `parent_dashboard_screen.dart`, add a "This Week's Summary" section at the top (above existing children selector) that shows a condensed version of the latest digest. If no digest exists yet, show "Weekly summaries start this Friday."

#### Step 5: Settings

Add to parent profile/settings:
- `digest_enabled` (bool, default true) — opt out of weekly digests
- `digest_day` (enum: friday/saturday/sunday) — preferred delivery day
- Store as JSONB in `users.settings` or a new `user_preferences` table

---

### PROMPT 3: Smart Attendance Insights for Teachers

**Priority:** P0 | **Effort:** 1 week | **Impact:** Transforms raw data into actionable intelligence

> **STATUS: COMPLETE**
>
> | Component | File | Done |
> |-----------|------|------|
> | Model | `lib/data/models/attendance_insights.dart` | Y |
> | Sub-models | `DayPattern`, `ChronicAbsentee`, `AttendanceAnomaly`, `StudentStreak` | Y |
> | Repository | `lib/data/repositories/attendance_insights_repository.dart` | Y |
> | Provider | `lib/features/ai_insights/providers/attendance_insights_provider.dart` | Y |
> | Insights Screen | `lib/features/ai_insights/presentation/screens/attendance_insights_screen.dart` | Y |
> | Day Pattern Chart | `lib/features/ai_insights/presentation/widgets/day_pattern_chart.dart` | Y |
> | Trend Chart | `lib/features/ai_insights/presentation/widgets/attendance_trend_chart.dart` | Y |
> | Absentee Card | `lib/features/ai_insights/presentation/widgets/chronic_absentee_card.dart` | Y |
> | AI Integration | `AITextGenerator.generateAttendanceNarrative()` | Y |
> | Route Integration | `app_router.dart` | Y |
>
> **What was built:** Day-of-week pattern analysis, chronic absentee identification, anomaly detection, perfect attendance streaks, AI-generated narrative summaries with pattern-specific language.

#### Context

The app already has:
- `lib/features/attendance/presentation/screens/attendance_screen.dart` — existing attendance view
- `lib/features/teacher/presentation/screens/class_teacher_dashboard_screen.dart` — teacher's class overview
- `attendance` table with full daily records per student
- `v_attendance_summary` and `v_section_daily_attendance` views
- Teacher can see raw attendance data but no patterns or insights

#### Task

Add an AI-generated insights panel to the teacher's attendance view that surfaces patterns invisible to manual inspection.

#### Step 1: Database — Attendance Pattern Analysis Function

Create migration `supabase/migrations/20260224_attendance_insights.sql`:

```sql
CREATE OR REPLACE FUNCTION get_attendance_insights(
  p_section_id UUID,
  p_start_date DATE DEFAULT CURRENT_DATE - INTERVAL '30 days',
  p_end_date DATE DEFAULT CURRENT_DATE
) RETURNS JSONB AS $$
DECLARE
  result JSONB;
BEGIN
  -- Build a JSON object with these analytics:

  -- 1. Day-of-week pattern: average absence rate per weekday
  --    "Monday has 18% absence rate vs 5% on other days"

  -- 2. Chronic absentees: students absent >= 20% of school days in period
  --    List with name, absence count, percentage

  -- 3. Declining attendance: students whose monthly attendance dropped >15%
  --    Compare current month to previous month

  -- 4. Consecutive absences: students with 3+ consecutive absent days
  --    Flag with last seen date

  -- 5. Late patterns: students who are late >= 3 times this month
  --    With most common late day

  -- 6. Perfect attendance streak: students with 0 absences in period
  --    For positive recognition

  -- 7. Section trend: overall attendance trend (improving/stable/declining)
  --    Compare current 2-week average to previous 2-week average

  -- 8. Predicted absences: based on day-of-week pattern,
  --    predict expected absent count for tomorrow

  RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

#### Step 2: Supabase Edge Function — Natural Language Formatting

Create `supabase/functions/attendance-insights/index.ts`:

```typescript
// 1. Call get_attendance_insights() SQL function
// 2. Send the JSON result to DeepSeek/GPT-4o-mini with system prompt:
//    """
//    You are a school data analyst assistant. Given attendance analytics JSON
//    for a class section, generate 4-6 concise, actionable insights.
//
//    Format each insight as:
//    - A bold heading (5-8 words)
//    - One sentence of context with specific numbers
//    - One sentence of recommended action
//
//    Prioritize: chronic absentees first, then declining trends, then patterns.
//    Always include one positive insight (e.g., perfect attendance students).
//    Use student first names. Be specific about days and percentages.
//    """
// 3. Return formatted insights as JSON array
```

#### Step 3: Repository and Provider

Add methods to `lib/data/repositories/attendance_repository.dart`:
- `getAttendanceInsights(sectionId, startDate, endDate)` — calls the Edge Function
- Returns `List<AttendanceInsight>` where each has: `title`, `description`, `action`, `severity` (info/warning/critical), `relatedStudentIds`

Add provider in `lib/features/attendance/providers/attendance_provider.dart`:
- `attendanceInsightsProvider(sectionId)` — FutureProvider.family

#### Step 4: Flutter UI

Add an **"AI Insights" card** to the top of `attendance_screen.dart` (teacher view):

```
+------------------------------------------+
| AI Attendance Insights             [Refresh]|
+------------------------------------------+
| Monday Absence Spike                      |
| Mondays average 18% absence vs 5%        |
| other days. Consider Monday engagement    |
| activities.                               |
+------------------------------------------+
| 3 Students Need Attention                 |
| Aarav (8 absences), Priya (6 absences),  |
| Rahul (5 absences) are chronically       |
| absent this month. Reach out to parents.  |
+------------------------------------------+
| 12 Students — Perfect Attendance!         |
| Recognize these students for their        |
| commitment this month.                    |
+------------------------------------------+
```

- Each insight card is tappable — navigates to the relevant student or filter
- Refresh button re-fetches from Edge Function
- Cache insights for 24 hours locally using shared_preferences
- Show shimmer loading while fetching

Also add a condensed version (top 2 insights) to `class_teacher_dashboard_screen.dart`.

---

### PROMPT 4: Trend Prediction Dashboard

**Priority:** P1 | **Effort:** 1.5 weeks | **Impact:** Proactive intervention 4-6 weeks before problems

> **STATUS: COMPLETE**
>
> | Component | File | Done |
> |-----------|------|------|
> | Model | `lib/data/models/trend_prediction.dart` | Y |
> | Sub-models | `DataPoint` (x, y, label) | Y |
> | Repository | `lib/data/repositories/trend_prediction_repository.dart` | Y |
> | Provider | `lib/features/ai_insights/providers/trend_prediction_provider.dart` | Y |
> | Dashboard Screen | `lib/features/ai_insights/presentation/screens/trend_dashboard_screen.dart` | Y |
> | Trend Line Chart | `lib/features/ai_insights/presentation/widgets/trend_line_chart.dart` | Y |
> | Confidence Badge | `lib/features/ai_insights/presentation/widgets/prediction_confidence_badge.dart` | Y |
> | Linear Regression | `lib/features/ai_insights/utils/linear_regression.dart` | Y |
> | AI Integration | `AITextGenerator.generateTrendNarrative()` | Y |
> | Route Integration | `app_router.dart` | Y |
>
> **What was built:** Linear regression trend analysis with historical + predicted data points, slope/intercept/R-squared confidence metrics, trend line visualization with dashed prediction extension, AI-generated trend narratives.

#### Context

The app already has:
- `lib/features/insights/presentation/screens/child_insights_screen.dart` — shows current performance
- `lib/features/insights/presentation/widgets/` — charts including radar, attendance, performance summary
- `lib/data/models/student_insights.dart` — SubjectInsight with `trend` (improving/declining/stable)
- `student_performance_predictions` table ready for predicted GPA and factors
- `fl_chart` dependency for charting

#### Task

Extend the existing Child Insights screen with AI-generated performance trajectory predictions.

#### Step 1: Supabase Edge Function — Performance Prediction

Create `supabase/functions/predict-performance/index.ts`:

```typescript
// Input: studentId, academicYearId
//
// 1. Query historical performance data:
//    - All exam scores from mv_student_performance (last 2 years if available)
//    - Attendance trend (monthly percentages)
//    - Assignment completion rates per month
//    - Quiz scores and attempts
//
// 2. For simple prediction (no ML model needed initially):
//    Calculate linear regression on exam percentage data points
//    Project next exam score based on trend line
//    Calculate confidence interval based on variance
//
// 3. For enhanced prediction, call LLM with structured data:
//    System prompt:
//    """
//    You are an academic performance analyst. Given a student's historical
//    data, provide:
//    1. Predicted end-of-term percentage (with confidence range)
//    2. Top 3 subjects likely to improve
//    3. Top 3 subjects at risk of declining
//    4. The single most impactful action to improve overall score
//    5. Risk assessment: probability of failing any subject (0-100%)
//
//    Return as JSON: {
//      predicted_percentage: number,
//      confidence_low: number,
//      confidence_high: number,
//      improving_subjects: [{name, predicted_score, reason}],
//      declining_subjects: [{name, predicted_score, risk, action}],
//      top_action: string,
//      failure_risk_percent: number
//    }
//    """
//
// 4. Upsert result into student_performance_predictions table
// 5. Return prediction JSON
```

#### Step 2: Flutter UI — Prediction Widget

Create `lib/features/insights/presentation/widgets/performance_prediction_card.dart`:

**Design:**
```
+------------------------------------------+
| Performance Prediction                    |
|                                           |
| Predicted End-of-Term: 78%               |
| (Confidence: 73% - 83%)                  |
|                                           |
| +-------------------------------------+  |
| |  Chart: Historical scores as        |  |
| |  dots, trend line extended to       |  |
| |  future with dashed line and        |  |
| |  shaded confidence interval         |  |
| +-------------------------------------+  |
|                                           |
| Likely to improve: Math, English          |
| Watch out: Science, Hindi                 |
|                                           |
| Top action: Focus 30 min daily on         |
|    Science practical concepts             |
|                                           |
| Failure risk: 12% (1 subject)            |
+------------------------------------------+
```

- Use `fl_chart` `LineChart` with:
  - Solid line for historical data points
  - Dashed line extending the trend into the future
  - Shaded area for confidence interval
  - Color: green if improving, red if declining, gray if stable

#### Step 3: Integration

Add this widget to the existing `ChildInsightsScreen` between the performance summary and subject radar chart. Also add a condensed "Predicted Score" stat card to the `parent_dashboard_screen.dart` next to the existing Attendance % and Class Rank stats.

---

## PHASE 2: DIFFERENTIATORS

---

### PROMPT 5: AI Homework Helper Chat (Socratic Method)

**Priority:** P1 | **Effort:** 3 weeks | **Impact:** Top parent pain point in India — "my child is stuck and I cannot help"

> **STATUS: NOT STARTED**
>
> **CEO Note:** This is the highest-impact unbuilt feature. Parents in India spend Rs 10,000-50,000/year on tutoring. An AI Socratic tutor built into the school app adds enormous perceived value and creates a premium revenue stream. Khan Academy's Khanmigo validates the concept.
>
> **CFO Note:** API cost ~$15-30/month per school (100 active students x 10 msgs/day). Can be monetized as a parent subscription at Rs 100-300/month per child = Rs 1,200-3,600/child/year. If 20% of 1,000 students subscribe = Rs 2.4-7.2 lakh/school/year.

#### Context

- No chat/AI helper feature currently exists in the app
- The app has `supabase_flutter` for backend, `flutter_riverpod` for state
- Students have class/section/subject context from `student_enrollments`
- The `question_bank` table has chapter/topic organization per subject
- `image_picker: ^1.0.7` already in pubspec.yaml for photo capture

#### Task

Build a Socratic AI tutor chat that helps students solve problems without giving direct answers.

#### Step 1: Database Schema

Create migration `supabase/migrations/20260224_ai_chat.sql`:

```sql
-- Chat sessions table
CREATE TABLE chat_sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id),
  student_id UUID NOT NULL REFERENCES students(id),
  subject_id UUID REFERENCES subjects(id),
  title VARCHAR(255),
  topic VARCHAR(100),
  chapter VARCHAR(100),
  message_count INT DEFAULT 0,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Chat messages table
CREATE TABLE chat_messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id UUID NOT NULL REFERENCES chat_sessions(id) ON DELETE CASCADE,
  role VARCHAR(20) NOT NULL CHECK (role IN ('user', 'assistant', 'system')),
  content TEXT NOT NULL,
  image_url TEXT,  -- for homework photo uploads
  tokens_used INT DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Rate limiting table
CREATE TABLE chat_usage (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  student_id UUID NOT NULL REFERENCES students(id),
  usage_date DATE NOT NULL DEFAULT CURRENT_DATE,
  message_count INT DEFAULT 0,
  tokens_used INT DEFAULT 0,
  UNIQUE(student_id, usage_date)
);

-- Indexes
CREATE INDEX idx_chat_sessions_student ON chat_sessions(student_id);
CREATE INDEX idx_chat_messages_session ON chat_messages(session_id);
CREATE INDEX idx_chat_usage_student ON chat_usage(student_id, usage_date);

-- RLS
ALTER TABLE chat_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE chat_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE chat_usage ENABLE ROW LEVEL SECURITY;

-- Students can only see their own chats
CREATE POLICY chat_sessions_student ON chat_sessions
  FOR ALL USING (student_id IN (
    SELECT s.id FROM students s
    JOIN users u ON s.user_id = u.id
    WHERE u.id = auth.uid()
  ));

-- Teachers and admins can view chat sessions for their students
CREATE POLICY chat_sessions_teacher ON chat_sessions
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM teacher_assignments ta
      JOIN student_enrollments se ON se.section_id = ta.section_id
      WHERE se.student_id = chat_sessions.student_id
        AND ta.teacher_id = auth.uid()
    )
    OR public.is_admin()
  );
```

#### Step 2: Supabase Edge Function — Chat Handler

Create `supabase/functions/ai-chat/index.ts`:

```typescript
// Input: { sessionId, message, imageUrl? }
//
// 1. Validate rate limit: max 30 messages/day per student
//    Query chat_usage, return 429 if exceeded
//
// 2. Load session context:
//    - Student's class, section, subjects from student_enrollments
//    - Session's subject/chapter/topic if set
//    - Last 10 messages from chat_messages for conversation history
//
// 3. Build system prompt:
//    """
//    You are a patient, encouraging tutor for a Class {X} student in an
//    Indian school following the {CBSE/ICSE} curriculum.
//
//    RULES:
//    1. NEVER give direct answers to homework or exam questions
//    2. Use the Socratic method: ask guiding questions that lead the
//       student to discover the answer themselves
//    3. Break complex problems into smaller steps
//    4. When the student is stuck, give a hint, not the answer
//    5. Encourage effort and persistence
//    6. If the question is outside the student's syllabus, say so
//    7. Keep responses concise (under 100 words)
//    8. Use simple language appropriate for the grade level
//    9. For math: show step-by-step approach without solving
//    10. If an image is provided, analyze the problem in the image
//
//    Subject context: {subject_name}
//    Chapter: {chapter} / Topic: {topic}
//    Student grade level: Class {X}
//    """
//
// 4. If imageUrl provided, include as vision input to GPT-4o or Gemini
//
// 5. Call LLM API with messages array (system + history + new message)
//
// 6. Save both user message and assistant response to chat_messages
//
// 7. Update chat_usage counts
//
// 8. Return assistant response
```

#### Step 3: Data Models

Create `lib/data/models/chat.dart`:

- `ChatSession`: `id`, `studentId`, `subjectId`, `title`, `topic`, `chapter`, `messageCount`, `isActive`, `createdAt`, `subjectName` (joined)
- `ChatMessage`: `id`, `sessionId`, `role` (user/assistant), `content`, `imageUrl`, `createdAt`
- `ChatUsage`: `messageCount`, `tokensUsed`, `limit` (30), `remaining`

#### Step 4: Repository

Create `lib/data/repositories/chat_repository.dart`:

```dart
class ChatRepository extends BaseRepository {
  // getSessions() — list student's chat sessions, ordered by updatedAt
  // getSession(sessionId) — single session with last 20 messages
  // createSession(subjectId, title) — create new chat session
  // sendMessage(sessionId, content, imageUrl?) — call Edge Function
  //   Returns ChatMessage (assistant response)
  // getUsage() — today's usage stats
  // deleteSession(sessionId) — soft delete
}
```

#### Step 5: Provider

Create `lib/features/ai_chat/providers/chat_provider.dart`:

- `chatSessionsProvider` — FutureProvider listing all sessions
- `chatMessagesProvider(sessionId)` — StreamProvider or FutureProvider
- `chatUsageProvider` — FutureProvider for rate limit display
- `ChatNotifier` — StateNotifier managing:
  - Current session state
  - Sending state (loading while waiting for AI)
  - Optimistic UI (show user message immediately, then AI response)

#### Step 6: Flutter UI

Create `lib/features/ai_chat/presentation/screens/chat_screen.dart`:

**Chat List Screen (sessions):**
```
+------------------------------------------+
| AppBar: "AI Study Helper"  [+ New Chat]   |
+------------------------------------------+
| Today's usage: 12/30 messages remaining   |
+------------------------------------------+
| +--------------------------------------+ |
| | Math — Quadratic Equations            | |
| | "How do I find the discriminant?"     | |
| | 3 messages - 2 hours ago              | |
| +--------------------------------------+ |
| +--------------------------------------+ |
| | Science — Chemical Bonding            | |
| | "What is electronegativity?"          | |
| | 8 messages - Yesterday                | |
| +--------------------------------------+ |
+------------------------------------------+
```

**Chat Detail Screen:**
```
+------------------------------------------+
| <- Math — Quadratic Equations       [...]  |
+------------------------------------------+
|                                           |
|    +----------------------------+        |
|    | I need to solve x^2 + 5x  |        |
|    | + 6 = 0 but I'm stuck     | <--    |
|    +----------------------------+        |
|                                           |
| +----------------------------+           |
| | Great question! Let's think |           |
| | about this step by step.    | -->      |
| |                             |           |
| | Can you tell me what method |           |
| | you've learned for solving  |           |
| | quadratic equations? Do you |           |
| | remember factoring?         |           |
| +----------------------------+           |
|                                           |
+------------------------------------------+
| [Camera] [Type your question...]   [Send] |
+------------------------------------------+
```

- Message bubbles: user on right (blue), assistant on left (gray)
- Photo button opens `image_picker` -> upload to Supabase storage -> send URL
- Typing indicator while waiting for AI response
- Auto-scroll to latest message
- Empty state: "Ask me anything about your subjects! I'll help you think through problems."

#### Step 7: Route and Navigation

Add routes:
- `/ai-chat` -> ChatListScreen
- `/ai-chat/:sessionId` -> ChatDetailScreen

Add "AI Study Helper" button to:
- `student_dashboard_screen.dart` — prominent card or FAB
- Student bottom navigation (if space allows)

#### Step 8: Teacher Visibility

Add to teacher dashboard:
- "Student Chat Activity" section showing which students used the chat helper this week
- Teachers can tap to read conversation transcripts (read-only)
- This provides visibility without surveillance — teachers see what topics students struggle with

---

### PROMPT 6: One-Click Question Paper Generator

**Priority:** P1 | **Effort:** 2 weeks | **Impact:** Saves 2-4 hours per question paper for teachers

> **STATUS: NOT STARTED**
>
> **CEO Note:** 81% of teachers say AI saves them time on preparation. This is the #1 teacher feature request across EdTech platforms. CBSE/ICSE board-aligned paper generation is a massive differentiator against Teachmint and Classera. Eklavvya and CogniGuide are already offering this commercially.
>
> **CFO Note:** DeepSeek cost: $0.01-0.05 per paper. 100 teachers x 2 papers/month = $24-120/year. Can be monetized as "AI Exam Suite" at Rs 200-500/month per school = Rs 2,400-6,000/school/year.

#### Context

- `question_bank` table exists with difficulty levels (1-5), question types, chapter/topic tags
- `quizzes` and `quiz_questions` tables exist
- `assignments` table supports attachments
- `subjects` and `class_subjects` provide curriculum structure
- PDF generation available via `pdf: ^3.10.7` and `printing: ^5.12.0` in pubspec
- No question paper generation UI exists

#### Task

Build a question paper generator that uses AI to create complete papers aligned to Indian board patterns.

#### Step 1: Database Schema

Create migration `supabase/migrations/20260224_question_papers.sql`:

```sql
CREATE TYPE paper_status AS ENUM ('draft', 'generated', 'reviewed', 'finalized', 'used');

CREATE TABLE question_paper_templates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id),
  name VARCHAR(255) NOT NULL,
  board VARCHAR(50) DEFAULT 'CBSE',  -- CBSE, ICSE, State
  class_id UUID REFERENCES classes(id),
  subject_id UUID REFERENCES subjects(id),
  total_marks INT NOT NULL,
  duration_minutes INT NOT NULL DEFAULT 180,
  sections JSONB NOT NULL DEFAULT '[]',
  -- sections example: [
  --   {"name": "Section A", "type": "mcq", "marks_per_q": 1, "count": 20, "total": 20},
  --   {"name": "Section B", "type": "short_answer", "marks_per_q": 2, "count": 5, "total": 10},
  --   {"name": "Section C", "type": "long_answer", "marks_per_q": 5, "count": 6, "total": 30}
  -- ]
  difficulty_distribution JSONB DEFAULT '{"easy": 30, "medium": 50, "hard": 20}',
  chapter_distribution JSONB DEFAULT '{}',  -- optional per-chapter weightage
  instructions TEXT,
  is_default BOOLEAN DEFAULT false,
  created_by UUID REFERENCES users(id),
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE generated_papers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id),
  template_id UUID REFERENCES question_paper_templates(id),
  title VARCHAR(255) NOT NULL,
  class_id UUID REFERENCES classes(id),
  subject_id UUID REFERENCES subjects(id),
  total_marks INT NOT NULL,
  duration_minutes INT NOT NULL,
  status paper_status DEFAULT 'generated',
  questions JSONB NOT NULL DEFAULT '[]',
  -- Each question: {section, question_text, type, marks, difficulty,
  --                 options?, correct_answer, marking_scheme, chapter, topic}
  answer_key JSONB DEFAULT '[]',
  marking_scheme JSONB DEFAULT '[]',
  pdf_url TEXT,
  answer_key_pdf_url TEXT,
  generated_by UUID REFERENCES users(id),
  reviewed_by UUID REFERENCES users(id),
  reviewed_at TIMESTAMPTZ,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_paper_templates_tenant ON question_paper_templates(tenant_id);
CREATE INDEX idx_generated_papers_tenant ON generated_papers(tenant_id);
CREATE INDEX idx_generated_papers_subject ON generated_papers(subject_id);
```

#### Step 2: Supabase Edge Function

Create `supabase/functions/generate-paper/index.ts`:

```typescript
// Input: { templateId, chapters[], additionalInstructions? }
//
// 1. Load template with sections, difficulty distribution, subject info
// 2. Load class syllabus context (class name, subject chapters/topics)
// 3. Check question bank for existing questions matching criteria:
//    Query question_bank WHERE subject_id = X AND chapter IN [...]
//    Group by difficulty and question_type
// 4. Build LLM prompt:
//    """
//    You are an experienced Indian school teacher creating a {CBSE/ICSE}
//    exam paper for Class {X} {Subject}.
//
//    PAPER STRUCTURE:
//    {sections from template}
//
//    DIFFICULTY DISTRIBUTION: 30% Easy, 50% Medium, 20% Hard
//
//    CHAPTERS TO COVER: {chapter list with weightage}
//
//    RULES:
//    1. Follow exact section structure and marks allocation
//    2. Questions must be grade-appropriate and board-pattern aligned
//    3. Include a mix of knowledge, understanding, application, and analysis
//    4. For MCQ: provide 4 options with exactly one correct answer
//    5. For long answers: include sub-parts (a, b, c) if marks > 3
//    6. Include internal choice where appropriate (OR questions)
//    7. Provide complete answer key with step-by-step solutions
//    8. Include marking scheme showing partial marks allocation
//
//    OUTPUT FORMAT: JSON with structure:
//    {
//      "header": { "school_name": "...", "exam_name": "...", ... },
//      "general_instructions": ["..."],
//      "sections": [
//        {
//          "name": "Section A",
//          "instructions": "All questions are compulsory. Each carries 1 mark.",
//          "questions": [
//            {
//              "number": 1,
//              "text": "...",
//              "type": "mcq",
//              "marks": 1,
//              "difficulty": "easy",
//              "chapter": "...",
//              "options": ["A) ...", "B) ...", "C) ...", "D) ..."],
//              "correct_answer": "B",
//              "solution": "Step-by-step solution...",
//              "marking_scheme": "1 mark for correct answer"
//            }
//          ]
//        }
//      ]
//    }
//    """
// 5. Parse LLM response, validate structure
// 6. Save to generated_papers table
// 7. Return paper data
```

#### Step 3: Flutter UI

Create `lib/features/assessments/presentation/screens/paper_generator_screen.dart`:

**Paper Configuration Form:**
```
+------------------------------------------+
| <- Generate Question Paper                |
+------------------------------------------+
| Subject:    [Mathematics      v]          |
| Class:      [Class 10         v]          |
| Template:   [CBSE Board Pattern v]        |
|                                           |
| Total Marks: [80]  Duration: [3 hrs]      |
|                                           |
| Chapters to Cover:                        |
| [x] Ch 1: Real Numbers (15%)             |
| [x] Ch 2: Polynomials (10%)              |
| [x] Ch 3: Linear Equations (15%)         |
| [ ] Ch 4: Quadratic Equations             |
| [x] Ch 5: Triangles (20%)                |
|                                           |
| Difficulty: Easy [======----] 30%         |
|             Med  [========--] 50%         |
|             Hard [====------] 20%         |
|                                           |
| Additional instructions:                  |
| +--------------------------------------+ |
| | Focus on application-based...        | |
| +--------------------------------------+ |
|                                           |
| [Generate Paper]                          |
+------------------------------------------+
```

**Paper Preview/Edit Screen:**
- Display generated paper in a read-friendly format
- Each question is an editable card — teacher can modify text, swap questions, reorder
- "Regenerate Question" button per question to get an alternative
- "Download PDF" button generating:
  - Question paper PDF (formatted for printing)
  - Answer key PDF (separate document)
  - Marking scheme PDF
- "Save to Question Bank" — adds generated questions to the `question_bank` table for reuse
- "Assign as Test" — creates a quiz or assignment from the paper

#### Step 4: PDF Generation

Use the existing `pdf` package to generate formatted question papers:
- School header with logo
- Exam name, class, subject, date, duration
- General instructions
- Section-wise questions with proper numbering
- Footer with page numbers
- Answer key on separate pages

---

### PROMPT 7: Multilingual Smart Notifications

**Priority:** P1 | **Effort:** 2 weeks | **Impact:** Removes biggest parent engagement barrier in non-metro India

> **STATUS: NOT STARTED**
>
> **CEO Note:** India has 22 official languages. Most parents in tier-2/tier-3 cities prefer regional languages. Bhashini APIs are FREE (government-funded). This unlocks the massive vernacular market and government school segment. Google Classroom has no multilingual support for Indian languages.
>
> **CFO Note:** Bhashini APIs: FREE. DeepSeek Hindi/regional: ~$0.001-0.005/translation. For 10,000 messages/month = $10-50/month. Opens an entirely new market segment. TAM expansion is massive with near-zero marginal cost.

#### Context

- `notifications` table with all notification infrastructure
- `announcements` table with `target_roles` array
- `users` table has `settings` but no language preference
- Most parents in Indian schools outside metros prefer regional languages
- Google Cloud Translation API supports all 22 Indian scheduled languages
- AI4Bharat IndicTrans2 is open-source and free for Indian languages
- Bhashini APIs (government of India) are free for all 22 scheduled languages

#### Task

Add language preference to user profiles and auto-translate all parent-facing notifications.

#### Step 1: Database Changes

```sql
-- Add language preference to users
ALTER TABLE users ADD COLUMN preferred_language VARCHAR(10) DEFAULT 'en';
-- Values: en, hi, ta, te, kn, ml, bn, mr, gu, pa, or, as

-- Translation cache to avoid re-translating same content
CREATE TABLE translation_cache (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  source_text_hash VARCHAR(64) NOT NULL,  -- SHA-256 of source
  source_language VARCHAR(10) DEFAULT 'en',
  target_language VARCHAR(10) NOT NULL,
  translated_text TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(source_text_hash, target_language)
);

CREATE INDEX idx_translation_cache_lookup
  ON translation_cache(source_text_hash, target_language);
```

#### Step 2: Supabase Edge Function — Translation Service

Create `supabase/functions/translate/index.ts`:

```typescript
// Input: { text: string, targetLanguage: string }
//
// 1. Check translation_cache by SHA-256 hash of text + targetLanguage
// 2. If cached, return immediately
// 3. If not cached, call Bhashini API (FREE) or Google Cloud Translation:
//    POST https://translation.googleapis.com/language/translate/v2
//    { q: text, source: 'en', target: targetLanguage, format: 'text' }
// 4. Cache the result
// 5. Return translated text
//
// Batch variant: translate_batch([{text, targetLanguage}])
// for translating multiple notifications at once
```

#### Step 3: Integrate with Notification System

Modify the notification sending pipeline (wherever `send_notification()` is called):

1. Before inserting into `notifications`, check the target user's `preferred_language`
2. If not 'en', call the translate Edge Function for `title` and `body`
3. Store both original and translated text:
   ```sql
   INSERT INTO notifications (title, body, data)
   VALUES (
     translated_title,
     translated_body,
     jsonb_build_object(
       'original_title', original_title,
       'original_body', original_body,
       'translated_from', 'en',
       'translated_to', target_language
     )
   );
   ```

#### Step 4: Flutter UI

Add to user profile/settings screen:
- "Preferred Language" dropdown with native script labels:
  - English, हिन्दी (Hindi), தமிழ் (Tamil), తెలుగు (Telugu), ಕನ್ನಡ (Kannada), മലയാളം (Malayalam), বাংলা (Bengali), मराठी (Marathi), ગુજરાતી (Gujarati)
- Display the option label in the native script so non-English readers can find their language
- Save to `users.preferred_language`

In notification display widgets, show translated text with a small "Translated from English" label and a "Show original" toggle.

---

### PROMPT 8: AI-Driven Daily Challenges

**Priority:** P2 | **Effort:** 2 weeks | **Impact:** Daily engagement hook — habit formation like Duolingo

> **STATUS: NOT STARTED**
>
> **CEO Note:** Duolingo's streak mechanism drives 40M+ daily active users. Applying this to academics creates a daily engagement hook. Combined with the existing gamification/leaderboard system (already built), this creates a powerful retention loop.
>
> **CFO Note:** Can be rule-based (no LLM needed) = $0 API cost. Uses existing gamification tables. Implementation: 2 weeks. ROI: increased daily active usage metrics improve SaaS retention.

#### Context

- `achievements`, `student_points`, `point_transactions` tables exist
- `LeaderboardScreen` and `AchievementsScreen` already implemented
- Gamification provider and repository functional
- Student dashboard exists with quick stats

#### Task

Create a personalized daily challenge system that adapts to each student's needs.

#### Step 1: Database Schema

```sql
CREATE TYPE challenge_type AS ENUM ('academic', 'attendance', 'social', 'wellness');
CREATE TYPE challenge_status AS ENUM ('active', 'completed', 'expired', 'skipped');

CREATE TABLE daily_challenges (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id),
  student_id UUID NOT NULL REFERENCES students(id),
  challenge_date DATE NOT NULL DEFAULT CURRENT_DATE,
  challenge_type challenge_type NOT NULL,
  title VARCHAR(255) NOT NULL,
  description TEXT NOT NULL,
  target_metric VARCHAR(100),  -- e.g., 'quiz_score >= 80', 'attendance = present'
  target_value NUMERIC,
  points_reward INT NOT NULL DEFAULT 10,
  bonus_points INT DEFAULT 0,  -- for streak bonus
  status challenge_status DEFAULT 'active',
  completed_at TIMESTAMPTZ,
  streak_count INT DEFAULT 0,  -- consecutive days completing all 3
  created_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(student_id, challenge_date, challenge_type)
);

CREATE TABLE challenge_streaks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  student_id UUID NOT NULL REFERENCES students(id),
  current_streak INT DEFAULT 0,
  longest_streak INT DEFAULT 0,
  last_completed_date DATE,
  total_challenges_completed INT DEFAULT 0,
  updated_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(student_id)
);

CREATE INDEX idx_daily_challenges_student ON daily_challenges(student_id, challenge_date);
CREATE INDEX idx_challenge_streaks_student ON challenge_streaks(student_id);
```

#### Step 2: Challenge Generation (Supabase Edge Function)

Create `supabase/functions/generate-daily-challenges/index.ts`:

```typescript
// Runs daily at 5 AM via pg_cron
// For each active student:
//
// 1. Load student context:
//    - Recent exam scores (identify weak subjects)
//    - Attendance pattern (identify absence risk days)
//    - Assignment completion rate
//    - Current streak count
//
// 2. Generate 3 personalized challenges:
//
//    ACADEMIC challenge (based on weakest subject):
//    - "Score 80%+ on today's Math mini-quiz" (if Math is weak)
//    - "Complete the Science assignment before 6 PM" (if assignment pending)
//    - "Review Chapter 5 notes and answer 3 practice questions"
//
//    ATTENDANCE/PUNCTUALITY challenge:
//    - "Arrive before the bell today" (if student is often late)
//    - "Maintain your perfect attendance streak!" (if doing well)
//    - "Attend all classes today" (if frequently absent)
//
//    SOCIAL/ENGAGEMENT challenge:
//    - "Ask one question in class today"
//    - "Help a classmate with homework"
//    - "Submit your assignment on time"
//
// 3. Streak bonus: Add +5 bonus points if student has a 5+ day streak
//
// 4. Insert into daily_challenges table
```

#### Step 3: Flutter UI

Add **"Today's Challenges" card** to `student_dashboard_screen.dart`:

```
+------------------------------------------+
| Today's Challenges        5-day streak    |
+------------------------------------------+
| +--------------------------------------+ |
| | Score 80%+ on Math mini-quiz         | |
| |    +15 pts  [Take Quiz ->]           | |
| +--------------------------------------+ |
| +--------------------------------------+ |
| | Attend all classes today             | |
| |    +10 pts  [Auto-tracked]   Done   | |
| +--------------------------------------+ |
| +--------------------------------------+ |
| | Submit Science assignment            | |
| |    +10 pts  [Go to Assignments ->]   | |
| +--------------------------------------+ |
|                                           |
| Complete all 3 for +5 streak bonus!       |
+------------------------------------------+
```

- Challenges with action buttons that deep-link to relevant screens
- Auto-completion detection for attendance challenges (check at end of day)
- Streak counter with fire animation on milestone (7, 14, 30 days)
- Expired challenges (from yesterday) shown grayed out with "Missed" label

---

## PHASE 3: ADVANCED AI

---

### PROMPT 9: AI Study Plan Generator

**Priority:** P1 | **Effort:** 3 weeks | **Impact:** Board exam preparation differentiator

> **STATUS: NOT STARTED**
>
> **CEO Note:** Board exam preparation is where families spend the most on supplementary education (Rs 10,000-50,000/year on coaching). A built-in AI study planner that generates personalized, day-by-day schedules is a massive differentiator. No major competitor offers this.
>
> **CFO Note:** API cost: ~$0.003 per study plan. ~100 plans/term = $5-10. Can be monetized as premium parent feature. Students on AI-driven platforms score 12.4% higher, which improves school reputation and enrollment.

#### Context

- Students in Class 10 and 12 preparing for CBSE/ICSE board exams need structured study plans
- Student performance data exists per subject/topic
- Timetable and exam schedule data available
- No study planning feature currently exists
- `study_recommendation.dart` model and `study_recommendations_screen.dart` exist (basic recommendations) but no day-by-day planner

#### Task

Build an AI-powered personalized study plan that generates a day-by-day schedule based on the student's upcoming exams, current performance levels, and available time.

#### Step 1: Database

```sql
CREATE TABLE study_plans (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id),
  student_id UUID NOT NULL REFERENCES students(id),
  academic_year_id UUID REFERENCES academic_years(id),
  title VARCHAR(255) NOT NULL,
  start_date DATE NOT NULL,
  end_date DATE NOT NULL,
  exam_name VARCHAR(255),
  target_score DECIMAL(5,2),  -- "I want to score 90%"
  study_hours_per_day DECIMAL(3,1) DEFAULT 3.0,
  plan_data JSONB NOT NULL,
  is_active BOOLEAN DEFAULT true,
  progress_percentage DECIMAL(5,2) DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE study_plan_progress (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  plan_id UUID NOT NULL REFERENCES study_plans(id) ON DELETE CASCADE,
  plan_date DATE NOT NULL,
  session_index INT NOT NULL,
  completed BOOLEAN DEFAULT false,
  actual_duration_minutes INT,
  difficulty_rating INT CHECK (difficulty_rating BETWEEN 1 AND 5),
  notes TEXT,
  completed_at TIMESTAMPTZ,
  UNIQUE(plan_id, plan_date, session_index)
);
```

#### Step 2: Edge Function

Create `supabase/functions/generate-study-plan/index.ts`:

```typescript
// Input: { studentId, startDate, endDate, examName, targetScore, hoursPerDay, excludedDays[] }
//
// 1. Gather student data:
//    - Subject performance: average scores per subject, weak vs strong topics
//    - Upcoming exams with dates and subjects
//    - Current timetable (to avoid scheduling during school hours)
//    - Assignment due dates (to factor in homework time)
//
// 2. LLM prompt:
//    """
//    You are an expert Indian education counselor creating a personalized
//    study plan for a Class {X} student preparing for {exam_name}.
//
//    STUDENT PROFILE:
//    - Subjects and scores: {subject_scores}
//    - Weak topics: {weak_topics}
//    - Strong topics: {strong_topics}
//    - Available study hours: {hours_per_day} hours/day
//    - Excluded days: {excluded_days}
//
//    EXAM SCHEDULE:
//    {exam_dates_per_subject}
//
//    PLANNING RULES:
//    1. Allocate more time to weak subjects (up to 2x normal allocation)
//    2. Use spaced repetition: review topics at increasing intervals
//    3. Schedule harder subjects in the morning/early sessions
//    4. Include 10-min breaks between subjects
//    5. Plan revision days before each exam (at least 2 days before)
//    6. Include practice test days (1 per week)
//    7. Balance new learning with revision (60/40 split)
//    8. Keep sessions 30-45 minutes max per topic (Pomodoro-style)
//    9. Include specific NCERT exercise references where possible
//    10. Last 3 days before each exam: only that subject + light revision
//
//    OUTPUT: JSON following the study_plans.plan_data structure
//    """
//
// 3. Save to study_plans table
// 4. Return plan
```

#### Step 3: Flutter UI

Create `lib/features/student/presentation/screens/study_plan_screen.dart`:

**Plan Setup Wizard (3 steps):**
1. "What are you preparing for?" — Select exam, enter target score
2. "How much time can you study?" — Hours per day slider, exclude rest days
3. "Generating your personalized plan..." — Loading animation

**Plan View:**
- Calendar view showing study sessions per day (color-coded by subject)
- Today's sessions highlighted with checkboxes
- Tap a session to mark complete + rate difficulty (1-5 stars)
- Progress bar showing overall plan completion %
- "Adjust Plan" button to regenerate based on actual progress

**Streak and Motivation:**
- Show daily study streak
- Celebrate milestone completions
- "You're 65% through your plan — keep going!"

---

### PROMPT 10: Homework Photo Scanner with AI Explanation

**Priority:** P1 | **Effort:** 3 weeks | **Impact:** Addresses #1 parent pain point

> **STATUS: NOT STARTED**
>
> **CEO Note:** "My child is stuck on homework and I can't help" is the #1 parent pain point in Indian schools. Photo-to-explanation using vision AI directly addresses this. Google Lens + AI tutoring is the fastest-growing EdTech category.
>
> **CFO Note:** Vision API cost: ~$0.02-0.05 per scan. ~50 scans/day across school = $10-20/month. Premium feature for parent subscription tier.

#### Context

- `image_picker: ^1.0.7` already in pubspec.yaml
- Supabase storage available for image uploads
- Gemini Vision API or GPT-4o supports image analysis
- AI Chat infrastructure (from Prompt 5) can be reused

#### Task

Add a "Scan Problem" feature allowing students to photograph a textbook problem or handwritten work and get step-by-step Socratic guidance.

#### Step 1: Integration with AI Chat

This feature extends the AI Chat (Prompt 5). Add a prominent "Scan Homework" button that:
1. Opens camera (or gallery picker)
2. Student takes photo of the problem
3. Optionally selects subject context
4. Creates a new chat session with the image
5. AI analyzes the image and begins Socratic dialogue

#### Step 2: Edge Function Enhancement

Modify `supabase/functions/ai-chat/index.ts` to handle image inputs:

```typescript
// If imageUrl is provided:
// 1. Download image from Supabase storage
// 2. Send to Gemini Vision API or GPT-4o with vision:
//    {
//      model: "gpt-4o",
//      messages: [{
//        role: "user",
//        content: [
//          { type: "text", text: "The student has shared a photo of a problem..." },
//          { type: "image_url", image_url: { url: imageUrl } }
//        ]
//      }]
//    }
// 3. System prompt addition for image analysis:
//    """
//    The student has shared a photo. First, describe what you see in the image
//    (the problem/question). Then, WITHOUT solving it directly, guide the
//    student through the approach using the Socratic method.
//
//    For math: identify the concept, ask what formulas they know, guide
//    through the first step.
//    For science: identify the concept, ask about relevant principles.
//    For language: identify the task type, ask about relevant grammar rules.
//    """
```

#### Step 3: Flutter UI

Add to the student dashboard or AI chat entry point:

```
+---------------------------+
|  Scan Homework             |
|                            |
|  Take a photo of any       |
|  problem — I'll help       |
|  you solve it!             |
|                            |
|  [Open Camera]             |
|  [Choose from Gallery]     |
+---------------------------+
```

After capture:
- Show image preview with crop/rotate
- Subject selector dropdown (Math, Science, English, etc.)
- "Get Help" button -> creates chat session with image
- Transitions to chat screen with AI response

---

### PROMPT 11: Smart Resource Recommendations with pgvector

**Priority:** P2 | **Effort:** 4 weeks | **Impact:** Transforms static library into personalized learning companion

> **STATUS: NOT STARTED**
>
> **CEO Note:** Personalized resource recommendations transform a static digital library into an intelligent learning companion. Netflix-style "recommended for you" in an education context is a strong differentiator.
>
> **CFO Note:** Embedding cost: $0.02/1M tokens (text-embedding-3-small). For 1,000 resources = one-time ~$0.10. Weekly recs for 1,000 students = $3-5/month. Requires pgvector extension (free on Supabase).

#### Context

- `study_resources` table with title, description, tags, subject_id, class_id
- `resource_library_screen.dart` exists with basic browse/search
- Supabase supports pgvector extension natively
- Student performance data shows weak topics per student

#### Task

Build a recommendation engine that surfaces relevant study materials based on each student's knowledge gaps.

#### Step 1: Enable pgvector and Create Embeddings

```sql
-- Enable pgvector
CREATE EXTENSION IF NOT EXISTS vector;

-- Add embedding column to resources
ALTER TABLE study_resources ADD COLUMN embedding vector(1536);

-- Create HNSW index for fast similarity search
CREATE INDEX idx_resource_embeddings ON study_resources
  USING hnsw (embedding vector_cosine_ops);

-- Student topic mastery for matching
CREATE TABLE student_topic_mastery (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  student_id UUID NOT NULL REFERENCES students(id),
  subject_id UUID NOT NULL REFERENCES subjects(id),
  chapter VARCHAR(100),
  topic VARCHAR(100),
  mastery_level DECIMAL(5,2) DEFAULT 0,  -- 0-100%
  last_assessed_at TIMESTAMPTZ,
  needs_improvement BOOLEAN DEFAULT false,
  updated_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(student_id, subject_id, topic)
);
```

#### Step 2: Embedding Generation (Edge Function)

Create `supabase/functions/embed-resource/index.ts`:

```typescript
// Triggered when a resource is created/updated
// 1. Concatenate: title + description + tags + subject_name + chapter + topic
// 2. Call OpenAI embeddings API:
//    model: "text-embedding-3-small" (1536 dimensions, $0.02/1M tokens)
// 3. Update study_resources.embedding with the result vector
```

#### Step 3: Recommendation Engine (Edge Function)

Create `supabase/functions/recommend-resources/index.ts`:

```typescript
// Input: { studentId }
//
// 1. Get student's weak topics from student_topic_mastery
//    WHERE needs_improvement = true
// 2. For each weak topic, create a query string:
//    "{subject} {chapter} {topic} study material for Class {X}"
// 3. Generate embedding for the query string
// 4. Query pgvector for top 5 similar resources:
//    SELECT *, 1 - (embedding <=> query_embedding) as similarity
//    FROM study_resources
//    WHERE class_id = student_class_id
//    ORDER BY embedding <=> query_embedding
//    LIMIT 5
// 5. Combine results across all weak topics, deduplicate, rank by relevance
// 6. Return top 10 recommended resources
```

#### Step 4: Flutter UI

Add "Recommended for You" section to `resource_library_screen.dart`:

```
+------------------------------------------+
| Recommended for You                       |
| Based on your recent performance          |
+------------------------------------------+
| +------+ Quadratic Equations - Video      |
| |  >   | "Clear explanation of the        |
| |      |  discriminant method"            |
| +------+ Math - Ch 4 - 94% match         |
+------------------------------------------+
| +------+ Chemical Bonding Worksheet       |
| |      | "Practice problems with          |
| |      |  step-by-step solutions"         |
| +------+ Science - Ch 3 - 89% match      |
+------------------------------------------+
```

---

### PROMPT 12: Predictive Fee Collection Intelligence

**Priority:** P2 | **Effort:** 2 weeks | **Impact:** Direct revenue impact — recover 15-25% more fees

> **STATUS: NOT STARTED**
>
> **CEO Note:** Fee collection is the lifeline of private schools. AI-optimized collections improve on-time payment by 20-35%. TrackFee.ai reports 80% reduction in manual follow-up. WhatsApp-based AI reminders at optimal timing per family = game changer.
>
> **CFO Note:** For a school with Rs 2 crore annual fee revenue and 15% default rate, improving collection by 5 percentage points = Rs 10 lakh additional per school per year. Prediction is rule-based (no LLM cost). Reminder messages via WhatsApp = Rs 0.35/message.

#### Context

- `invoices` and `payments` tables with full transaction history
- `fee_default_prediction` is already an enum value in `ml_model_type`
- `student_feature_snapshots` already tracks `fee_payment_status` and `days_overdue`
- `dunning_actions` table and `fee_dunning_workflows` exist in advanced fee migration
- `fees_screen.dart` has admin overview with collection stats

#### Task

Build a fee default prediction system that flags at-risk accounts 2-4 weeks before due dates.

#### Step 1: Prediction Function

```sql
CREATE OR REPLACE FUNCTION predict_fee_defaults(p_tenant_id UUID)
RETURNS TABLE(
  student_id UUID,
  student_name TEXT,
  class_name TEXT,
  invoice_id UUID,
  invoice_number VARCHAR,
  amount_due DECIMAL,
  due_date DATE,
  risk_score INT,  -- 0-100
  risk_factors TEXT[],
  recommended_action TEXT
) AS $$
BEGIN
  RETURN QUERY
  WITH payment_history AS (
    -- Calculate historical payment patterns per student
    SELECT
      i.student_id,
      AVG(EXTRACT(DAY FROM p.paid_at::date - i.due_date)) as avg_days_late,
      COUNT(*) FILTER (WHERE i.status = 'overdue') as overdue_count,
      COUNT(*) as total_invoices,
      MAX(EXTRACT(DAY FROM p.paid_at::date - i.due_date)) as max_days_late
    FROM invoices i
    LEFT JOIN payments p ON p.invoice_id = i.id AND p.status = 'completed'
    WHERE i.tenant_id = p_tenant_id
    GROUP BY i.student_id
  ),
  pending_invoices AS (
    SELECT i.*, s.first_name || ' ' || s.last_name as student_name,
           c.name as class_name
    FROM invoices i
    JOIN students s ON i.student_id = s.id
    JOIN student_enrollments se ON se.student_id = s.id
    JOIN sections sec ON se.section_id = sec.id
    JOIN classes c ON sec.class_id = c.id
    WHERE i.tenant_id = p_tenant_id
      AND i.status IN ('pending', 'partial')
      AND i.due_date <= CURRENT_DATE + INTERVAL '30 days'
  )
  SELECT
    pi.student_id,
    pi.student_name,
    pi.class_name,
    pi.id as invoice_id,
    pi.invoice_number,
    (pi.total_amount - pi.paid_amount) as amount_due,
    pi.due_date,
    -- Risk score calculation
    LEAST(100, GREATEST(0,
      CASE WHEN ph.avg_days_late > 30 THEN 40 ELSE (ph.avg_days_late / 30.0 * 40)::INT END
      + CASE WHEN ph.overdue_count > 2 THEN 30 ELSE (ph.overdue_count / 2.0 * 30)::INT END
      + CASE WHEN pi.due_date < CURRENT_DATE THEN 30 ELSE 0 END
    ))::INT as risk_score,
    -- Risk factors
    ARRAY_REMOVE(ARRAY[
      CASE WHEN ph.avg_days_late > 15 THEN 'History of late payments (avg ' || ROUND(ph.avg_days_late) || ' days)' END,
      CASE WHEN ph.overdue_count > 0 THEN ph.overdue_count || ' previous overdue invoices' END,
      CASE WHEN pi.due_date < CURRENT_DATE THEN 'Already overdue by ' || (CURRENT_DATE - pi.due_date) || ' days' END,
      CASE WHEN (pi.total_amount - pi.paid_amount) > 10000 THEN 'High amount pending: Rs ' || (pi.total_amount - pi.paid_amount) END
    ], NULL) as risk_factors,
    -- Recommended action
    CASE
      WHEN ph.avg_days_late > 30 OR ph.overdue_count > 2
        THEN 'Offer installment payment plan'
      WHEN pi.due_date < CURRENT_DATE
        THEN 'Send payment reminder immediately'
      WHEN pi.due_date <= CURRENT_DATE + INTERVAL '7 days'
        THEN 'Send proactive reminder with payment link'
      ELSE 'Monitor — low risk currently'
    END as recommended_action
  FROM pending_invoices pi
  LEFT JOIN payment_history ph ON pi.student_id = ph.student_id
  ORDER BY risk_score DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

#### Step 2: Flutter UI

Add "Collection Risk" tab to `fees_screen.dart` (admin view):

```
+------------------------------------------+
| Fee Collection Risk                       |
| 8 accounts at risk - Rs 2,45,000 at stake |
+------------------------------------------+
| HIGH RISK (3)                             |
| +--------------------------------------+ |
| | Aarav Sharma - Class 10-A            | |
| | Rs 15,000 due - 12 days overdue      | |
| | Risk: 85/100                         | |
| | -> 3 previous overdue, avg 25 days   | |
| | Recommended: Offer installment plan  | |
| | [Send Reminder] [Create Plan]        | |
| +--------------------------------------+ |
|                                           |
| MEDIUM RISK (5)                           |
| ...                                       |
+------------------------------------------+
```

---

## PHASE 4: GROWTH & REVENUE AI (NEW)

> **These features were identified through market research and competitive analysis. They represent the highest-impact opportunities for growth (CEO) and revenue (CFO).**

---

### PROMPT 13: AI-Powered Admission Inquiry Chatbot

**Priority:** P0 | **Effort:** 5 weeks | **Impact:** Direct revenue generation — 20-35% improvement in lead-to-enrollment conversion

> **STATUS: NEW**
>
> **CEO Note:** Most schools lose 40-60% of inquiry leads due to delayed responses (parents inquire after office hours, on weekends). A 24/7 AI chatbot captures every lead instantly. SmatBot reports that school chatbots handle 60-80% of common queries without human intervention. This is a direct revenue generator.
>
> **CFO Note:** Cost of missed admission = Rs 50,000-1,50,000 (full year fee). Converting 5 additional admissions/year = Rs 2.5-7.5 lakh additional revenue per school. Chatbot cost: ~$0.003/conversation via DeepSeek + Rs 0.35/WhatsApp message. SaaS upsell: Rs 2,000-5,000/month per school for "AI Admissions Module."

#### Task

Build a 24/7 intelligent chatbot for school websites and WhatsApp that handles admission inquiries, answers FAQs about fee structure/curriculum/facilities, collects lead information, schedules campus visits, and routes qualified leads to admissions staff.

#### Step 1: Database Schema

```sql
CREATE TABLE admission_faq (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id),
  question TEXT NOT NULL,
  answer TEXT NOT NULL,
  category VARCHAR(50),  -- 'fees', 'curriculum', 'facilities', 'transport', 'admission_process'
  priority INT DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE admission_leads (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id),
  parent_name VARCHAR(255),
  phone VARCHAR(20),
  email VARCHAR(255),
  child_name VARCHAR(255),
  child_class VARCHAR(20),  -- class seeking admission for
  source VARCHAR(50) DEFAULT 'chatbot',  -- chatbot, website, walk-in, referral
  chat_session_id UUID,
  status VARCHAR(20) DEFAULT 'new',  -- new, contacted, visit_scheduled, enrolled, lost
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE chatbot_conversations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id),
  channel VARCHAR(20) NOT NULL,  -- 'whatsapp', 'web', 'app'
  phone_number VARCHAR(20),
  messages JSONB NOT NULL DEFAULT '[]',
  lead_id UUID REFERENCES admission_leads(id),
  is_handoff_to_human BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);
```

#### Step 2: RAG Pipeline (Edge Function)

Create `supabase/functions/admission-chatbot/index.ts`:

```typescript
// 1. Load school-specific FAQ data from admission_faq table
// 2. Build context-aware system prompt:
//    """
//    You are a helpful admissions assistant for {School Name}.
//    Answer inquiries about: fees, admission process, curriculum, facilities, transport.
//    Be warm, professional, and encouraging.
//    If you don't know, say "Let me connect you with our admissions team."
//    Collect: parent name, child name, class seeking, phone number.
//    After collecting info, offer to schedule a campus visit.
//    """
// 3. Use RAG: embed FAQ, retrieve relevant answers, augment LLM response
// 4. Save conversation and create lead when contact info is collected
```

#### Step 3: WhatsApp Integration

Integrate with WhatsApp Business API (via Gupshup or Wati):
- Webhook receives incoming WhatsApp messages
- Routes to chatbot Edge Function
- Sends AI response back via WhatsApp API
- Handoff to human when chatbot is unsure

#### Step 4: Admin Dashboard

- Lead management screen: list of leads with status pipeline
- Chat transcript viewer
- FAQ management (add/edit/delete FAQs)
- Conversion analytics: leads -> visits -> enrollments

---

### PROMPT 14: Intelligent Timetable Generator

**Priority:** P1 | **Effort:** 4 weeks | **Impact:** Eliminates 2-4 weeks of admin work per term

> **STATUS: NEW**
>
> **CEO Note:** Timetable creation is the single most dreaded administrative task at the start of every term. A school admin who generates a conflict-free timetable in 30 minutes instead of 2 weeks will never switch platforms. TimetableMaster serves 45,000+ schools with this feature alone. This is a "hero feature" for demos and sales.
>
> **CFO Note:** Saves 80-200 person-hours per school per year. Can command premium module fee of Rs 5,000-15,000/school/year. Uses Google OR-Tools (free, open-source) for constraint solving. Zero API cost for the solver. 4 weeks development.

#### Task

Build an AI-optimized automatic timetable generator that considers teacher availability, room constraints, subject distribution, consecutive period limits, lab scheduling, and student elective combinations.

#### Step 1: Constraint Definition

```sql
CREATE TABLE timetable_constraints (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id),
  academic_year_id UUID REFERENCES academic_years(id),
  constraint_type VARCHAR(50) NOT NULL,
  -- Types: 'max_consecutive_periods', 'teacher_unavailable', 'room_capacity',
  --        'subject_distribution', 'lab_period_grouping', 'break_time',
  --        'no_heavy_subject_last_period', 'elective_grouping'
  constraint_data JSONB NOT NULL,
  priority INT DEFAULT 1,  -- 1=must, 2=should, 3=nice-to-have
  created_at TIMESTAMPTZ DEFAULT now()
);
```

#### Step 2: Solver (Microservice or Edge Function)

- Use Google OR-Tools CP-SAT solver (Python)
- Deploy as a separate microservice or Supabase Edge Function
- Input: teachers, sections, subjects, rooms, periods per day, constraints
- Output: complete timetable as JSONB array
- Fallback: for smaller schools (< 20 teachers), use DeepSeek to generate timetable with validation

#### Step 3: Flutter UI

- Constraint configuration wizard
- "Generate Timetable" button with progress indicator
- Visual timetable grid with drag-and-drop manual adjustments
- Conflict detection and resolution suggestions
- Export to PDF and share with teachers

---

### PROMPT 15: AI Exam Answer Script Evaluation Assistance

**Priority:** P2 | **Effort:** 7 weeks | **Impact:** Saves 15-30 hours per teacher per exam cycle

> **STATUS: NEW**
>
> **CEO Note:** Exam grading is the second-biggest teacher pain point. 79% of teachers say AI saves them time on grading. CBSE is actively exploring AI for evaluation. First-mover advantage is significant in Indian school SaaS.
>
> **CFO Note:** API cost: ~$0.02-0.05 per script page. For 1,000 students x 5 subjects x 4 exams = $400-1,000/year. Premium feature: Rs 500-1,000/month per school. Higher cost but high perceived value.

#### Task

Build a system where teachers upload photos of student answer scripts, AI performs OCR and provides suggested scores based on a rubric/marking scheme. Teacher reviews and confirms.

#### Key Components

1. **OCR Integration:** Google Vision API or Tesseract for handwriting recognition
2. **Rubric-Based Evaluation:** DeepSeek compares extracted text against marking scheme
3. **Teacher Review Interface:** Side-by-side view of script image and AI suggestions
4. **Batch Processing:** Process entire class at once with parallel API calls
5. **Start with printed/typed answers first, expand to handwritten later**

---

### PROMPT 16: Predictive Enrollment Forecasting

**Priority:** P2 | **Effort:** 3 weeks | **Impact:** Prevents enrollment decline — existential for schools

> **STATUS: NEW**
>
> **CEO Note:** Knowing 6 months in advance that Class 6 enrollment will drop by 15% allows proactive intervention. This is a "principal's crystal ball" — extremely high perceived value at the executive level.
>
> **CFO Note:** Preventing enrollment decline of 10 students = Rs 5-15 lakh saved per school. Modeling is simple regression in PostgreSQL. DeepSeek generates narrative interpretation at negligible cost. 3 weeks development.

#### Task

Use historical enrollment data, demographic trends, fee collection patterns, and parent satisfaction metrics to predict next year's enrollment numbers by class. Identify classes at risk of decline and suggest interventions.

#### Key Components

1. **Data Aggregation:** Historical enrollment by class, section fill rates, sibling enrollment patterns
2. **Prediction Model:** Linear/polynomial regression on enrollment time series (PostgreSQL function)
3. **AI Narrative:** DeepSeek interprets trends and suggests interventions
4. **Admin Dashboard:** Class-by-class forecast with confidence intervals and risk flags
5. **Action Recommendations:** Fee discount targeting, re-engagement campaigns, parent satisfaction surveys

---

### PROMPT 17: AI-Driven Transport Route Optimization

**Priority:** P2 | **Effort:** 7 weeks | **Impact:** Reduces transport costs 15-25%, improves parent satisfaction

> **STATUS: NEW**
>
> **CEO Note:** Transport is a major parent satisfaction factor. Late buses and long routes are top complaints. AI-optimized routes with real-time ETA reduce complaints by 40-60%. One Colorado district increased bus utilization by 46% using AI optimization.
>
> **CFO Note:** Route optimization reduces fuel costs by 15-25% and can eliminate 1-2 buses (savings of Rs 3-6 lakh/year per bus). Google Maps API cost: ~$0.005-0.01/route. GPS tracking needs driver app.

#### Task

Optimize school bus routes using student home locations, traffic patterns, and capacity constraints. Provide real-time tracking with AI-predicted ETAs for parents.

#### Key Components

1. **Student Address Geocoding:** Google Maps Geocoding API
2. **Route Optimization:** Google OR-Tools or HERE API routing
3. **Real-Time Tracking:** Driver app with GPS + parent-facing ETA notifications
4. **Constraints:** Max 45-min ride, bus capacity, pickup time windows
5. **Re-optimization:** Automatic route adjustment when students join/leave mid-year

---

## PHASE 5: ENGAGEMENT & WELLBEING AI (NEW)

---

### PROMPT 18: AI Behavioral & Sentiment Analysis

**Priority:** P3 | **Effort:** 5 weeks | **Impact:** Early mental health intervention

> **STATUS: NEW**
>
> **CEO Note:** Student mental health is the fastest-growing concern for schools and parents. Schools with proactive wellbeing programs attract more families. Must be handled with extreme sensitivity — privacy, consent, and ethical guardrails are critical.
>
> **CFO Note:** Implementation cost: medium. API cost: ~$0.005/analysis. Must budget for privacy compliance. Premium "Student Wellbeing Module" positioning.

#### Task

Analyze patterns in behavioral incidents, teacher remarks, and counselor notes to identify students showing signs of emotional distress, bullying involvement, or disengagement. Generate confidential alerts for counselors with suggested intervention approaches.

**Ethical Requirements:**
- Parental consent required before enrollment
- Data retention policy (auto-delete after 12 months)
- Counselor-only access (not teacher or admin)
- No surveillance of digital communications
- Transparent about what is analyzed and what isn't

---

### PROMPT 19: AI Substitution Teacher Assignment

**Priority:** P2 | **Effort:** 2 weeks | **Impact:** Saves 30-60 minutes/day of coordinator time

> **STATUS: NEW**
>
> **CEO Note:** Substitution management is a daily pain point. Automating it creates deep operational dependency on the platform = low churn. The coordinator spends 30-60 minutes every morning on this.
>
> **CFO Note:** Rule-based logic (no LLM needed) = $0 API cost. Uses existing timetable and teacher data. 2 weeks development. Saves 150-300 hours/year.

#### Task

When a teacher reports absent, automatically suggest optimal substitutes based on: subject qualification, free periods, workload balance, and historical substitution patterns. Generate the substitution timetable and notify affected teachers.

#### Key Components

1. **Absence Reporting:** Teacher marks leave via app
2. **Constraint Matching:** Find teachers with free periods + matching subject qualification
3. **Workload Balance:** Prefer teachers with fewer substitutions this month
4. **Auto-Notification:** Push notification to substitute teacher with class details
5. **Admin Override:** Manual adjustment capability

---

### PROMPT 20: AI Canteen Menu Optimization & Nutrition Analysis

**Priority:** P3 | **Effort:** 3 weeks | **Impact:** Reduces food waste 15-25%, parent satisfaction

> **STATUS: NEW**
>
> **CEO Note:** Parents increasingly care about school nutrition. An AI-powered "nutrition dashboard" showing what their child eats and its nutritional value is a unique differentiator.
>
> **CFO Note:** Food waste reduction saves Rs 50,000-2,00,000/year. Demand prediction uses simple time-series. Canteen data model is comprehensive. 3 weeks development.

#### Task

Analyze canteen order history to predict demand, reduce food waste, and optimize menu planning. Provide nutritional analysis per student for parent visibility.

#### Key Components

1. **Demand Prediction:** Time-series analysis on historical order data by day/item
2. **Menu Optimization:** Balance nutrition, popularity, and cost
3. **Nutrition Analysis:** Food nutrition database + AI interpretation
4. **Parent Dashboard:** "Your child's nutrition this week" summary
5. **Procurement Planning:** Auto-generate ingredient purchase lists based on predicted demand

---

## Shared Infrastructure Setup

Before implementing any of the above features, set up this shared infrastructure:

### 1. Supabase Edge Functions Project Structure

```
supabase/functions/
├── _shared/
│   ├── llm-client.ts      -- Shared DeepSeek/OpenAI API client
│   ├── supabase-client.ts  -- Shared Supabase admin client
│   └── rate-limiter.ts     -- Shared rate limiting utility
├── admission-chatbot/index.ts     [NEW - Phase 4]
├── ai-chat/index.ts
├── attendance-insights/index.ts
├── generate-daily-challenges/index.ts
├── generate-paper/index.ts
├── generate-study-plan/index.ts
├── predict-performance/index.ts
├── recommend-resources/index.ts
├── translate/index.ts
└── weekly-parent-digest/index.ts
```

### 2. Flutter AI Service Layer

Already built:

```dart
// lib/core/services/ai_text_generator.dart — 11 methods:
// 1. generateDigestSummary()       — Parent digest (LIVE)
// 2. generateRiskExplanation()     — Risk scoring (LIVE)
// 3. generateAttendanceNarrative() — Attendance insights (LIVE)
// 4. generateAlertExplanation()    — Early warnings (LIVE)
// 5. generateStudyPlan()           — Study recommendations (LIVE)
// 6. generateReportRemark()        — Report cards (LIVE)
// 7. generateParentMessage()       — Message composer (LIVE)
// 8. generateClassNarrative()      — Class intelligence (LIVE)
// 9. generateLessonPlan()          — Lesson plans (LIVE)
// 10. generateSyllabusStructure()  — Syllabus AI (LIVE)
// 11. generateTrendNarrative()     — Trend prediction (LIVE)

// lib/core/services/deepseek_service.dart — DeepSeek API wrapper (LIVE)
// lib/core/services/openrouter_image_service.dart — Image generation (LIVE)
```

For Edge Function-based features, create `lib/core/services/ai_service.dart`:

```dart
class AIService {
  final SupabaseClient _client;

  Future<Map<String, dynamic>> callEdgeFunction(
    String functionName,
    Map<String, dynamic> body,
  ) async {
    final response = await _client.functions.invoke(
      functionName,
      body: body,
    );
    if (response.status != 200) {
      throw AIServiceException(response.data['error'] ?? 'Unknown error');
    }
    return response.data;
  }
}
```

### 3. API Key Configuration

Store API keys in Supabase Vault (not in client code):
```sql
SELECT vault.create_secret('deepseek_api_key', 'sk-...');
SELECT vault.create_secret('google_translate_key', 'AIza...');
SELECT vault.create_secret('whatsapp_api_key', '...');
```

Access in Edge Functions via `Deno.env.get('DEEPSEEK_API_KEY')`.

### 4. Cost Monitoring

Create a `ai_usage_tracking` table:
```sql
CREATE TABLE ai_usage_tracking (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID REFERENCES tenants(id),
  function_name VARCHAR(100),
  model_used VARCHAR(50),
  tokens_input INT,
  tokens_output INT,
  estimated_cost_usd DECIMAL(8,6),
  created_at TIMESTAMPTZ DEFAULT now()
);
```

Log every LLM call for cost monitoring and tenant billing.

---

## Estimated API Costs Per Feature (per school of 1,000 students)

### DeepSeek Pricing (as of Feb 2026)
- Input tokens: $0.28/M (cache miss), $0.07/M (cache hit)
- Output tokens: $1.10/M
- 5 million free tokens for new accounts

### Cost Breakdown

| # | Feature | Frequency | Est. Monthly Cost | Status |
|---|---------|-----------|-------------------|--------|
| 1 | Risk Scores | Daily (client-side calc) | ~$1-3 (AI explanations) | LIVE |
| 2 | Weekly Digest | Weekly x 1000 | $5-10 | LIVE |
| 3 | Attendance Insights | Daily x 30 sections | $2-5 | LIVE |
| 4 | Trend Predictions | Weekly x 1000 | $5-10 | LIVE |
| 5 | AI Chat | ~100 students x 10 msgs/day | $15-30 | NOT STARTED |
| 6 | Question Papers | ~20 papers/month | $5-10 | NOT STARTED |
| 7 | Translation | ~500 notifications/week | $2-5 (Bhashini = FREE) | NOT STARTED |
| 8 | Daily Challenges | Daily x 1000 | $0 (rule-based) | NOT STARTED |
| 9 | Study Plans | ~100 plans/term | $5-10 | NOT STARTED |
| 10 | Photo Scanner | ~50 scans/day | $10-20 (Vision API) | NOT STARTED |
| 11 | Resource Recs | Weekly x 1000 | $3-5 (embeddings) | NOT STARTED |
| 12 | Fee Predictions | Weekly (SQL only) | $0 (pure SQL) | NOT STARTED |
| 13 | Admission Chatbot | ~50 conversations/month | $3-5 + WhatsApp | NEW |
| 14 | Timetable Gen | 2-3x/year | $0 (OR-Tools solver) | NEW |
| 15 | Answer Eval | 20,000 scripts/year | $30-80/month (Vision) | NEW |
| 16 | Enrollment Forecast | Monthly | $1-2 | NEW |
| 17 | Transport Routes | Monthly recalc | $5-10 (Maps API) | NEW |
| 18 | Behavioral Analysis | Weekly batch | $3-5 | NEW |
| 19 | Substitution AI | Daily | $0 (rule-based) | NEW |
| 20 | Canteen Optimization | Daily | $1-3 | NEW |
| | **TOTAL (all features)** | | **$95-215/month** | |

**This is $0.095-0.215 per student per month — easily bundled into subscription fees.**

---

## Implementation Roadmap

### Immediate (Ship Now — Already Built, Just Polish)
1. Risk Score Engine (P1) — LIVE
2. Parent Digest (P2) — LIVE
3. Attendance Insights (P3) — LIVE
4. Trend Prediction (P4) — LIVE
5. Class Intelligence (B1) — LIVE
6. Early Warning Alerts (B2) — LIVE
7. Study Recommendations (B3) — LIVE
8. Report Card Remarks (B4) — LIVE
9. AI Message Composer (B5) — LIVE
10. QR Student Checkins (B6) — LIVE
11. AI Syllabus Generator (B7) — LIVE
12. AI Lesson Plans (B8) — LIVE
13. Topic Coverage Tracking (B9) — LIVE
14. Student/Parent Syllabus View (B10) — LIVE

### Next Sprint (Highest ROI — Build Next)
15. Question Paper Generator (P6) — 2 weeks
16. Predictive Fee Collection (P12) — 2 weeks
17. Substitution Teacher AI (P19) — 2 weeks

### Q2 2026 (Growth Features)
18. Multilingual Notifications (P7) — 2 weeks
19. Admission Chatbot (P13) — 5 weeks
20. Intelligent Timetable (P14) — 4 weeks
21. AI Study Plan Generator (P9) — 3 weeks

### Q3 2026 (Premium Features)
22. AI Homework Helper Chat (P5) — 3 weeks
23. Homework Photo Scanner (P10) — 3 weeks
24. Daily Challenges (P8) — 2 weeks
25. Enrollment Forecasting (P16) — 3 weeks

### Q4 2026 (Advanced)
26. Answer Script Evaluation (P15) — 7 weeks
27. Transport Route Optimization (P17) — 7 weeks
28. Smart Resource Recs/pgvector (P11) — 4 weeks
29. Behavioral Sentiment Analysis (P18) — 5 weeks
30. Canteen Optimization (P20) — 3 weeks

---

## Sources & Market Research

- [Gallup: Three in 10 Teachers Use AI Weekly, Saving Six Weeks/Year](https://news.gallup.com/poll/691967/three-teachers-weekly-saving-six-weeks-year.aspx)
- [PowerSchool: 2026 K-12 EdTech Pulse Report](https://www.powerschool.com/blog/k12-edtech-pulse-2026/)
- [Google Blog: Gemini in Classroom — No-cost AI tools (Feb 2026)](https://blog.google/outreach-initiatives/education/classroom-ai-features/)
- [K-12 Dive: 3 trends shaping EdTech in 2026](https://www.k12dive.com/news/3-trends-that-will-shape-ed-tech-in-2026/810645/)
- [eSchool News: 49 predictions about EdTech and AI in 2026](https://www.eschoolnews.com/innovative-teaching/2026/01/01/draft-2026-predictions/)
- [TCS: EdTech in 2026 — Intelligence Redefining Learning](https://www.tcs.com/what-we-do/industries/education/article/edtech-trends-2026-intelligence-redefining-learning-systems)
- [Programs.com: AI in Education Statistics 2026](https://programs.com/resources/ai-education-statistics/)
- [WolfMatrix: How AI in Education Cuts Costs By 2026](https://wolfmatrix.com/ai-in-education-cutting-costs-2026/)
- [DeepSeek API Pricing (Feb 2026)](https://costgoat.com/pricing/deepseek-api)
- [TrackFee: AI-Powered Automated Fee Collection](https://www.trackfee.ai/)
- [SmatBot: School Communication Chatbot](https://www.smatbot.com/blog/school-communication-chatbot/)
- [Eklavvya: AI Question Paper Generator](https://www.eklavvya.com/blog/ai-question-paper-generator/)
- [TimetableMaster: AI Timetable Generator for Schools](https://www.timetablemaster.com/timetable-generator-ai)
- [Zylo: 74% of SaaS companies monetizing AI](https://zylo.com/blog/ai-in-saas/)
