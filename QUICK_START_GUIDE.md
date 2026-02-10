# Quick Start Guide - Database Enhancement
**For Developers Working on the School Management System**

---

## 🚀 Getting Started

### 1. Start Local Supabase
```bash
cd /Users/ihub-devs/cascade-projects/School-Management-Flutter
supabase start
```

### 2. Apply All Migrations
```bash
supabase db reset
```

This will apply all 18 migration files including the 10 new ones:
- `00001` through `00008` - Existing schema
- `00009` (20260209...) - AI Predictive Analytics
- `00010` (20260209...) - Advanced Fee Management
- `00011` (20260209...) - Behavioral Tracking
- `00012` (20260209...) - Skills & Competencies
- `00013` (20260209...) - Asset, HR & Alumni
- `00014` (20260209...) - Admissions Pipeline
- `00015` (20260209...) - Audit & Security
- `00016` (20260209...) - Integrations
- `00017` (20260209...) - Performance Optimization
- `00018` (20260209...) - Extended RLS Policies

### 3. Verify Schema
```bash
# Access Postgres shell
supabase db shell

# Count tables
SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public';
# Expected: 100+

# Check RLS enabled
SELECT COUNT(*) FROM pg_tables WHERE schemaname = 'public' AND rowsecurity = true;
# Expected: 100+

# Exit shell
\q
```

---

## 📊 Database Schema Overview

### Core Categories

```
┌─────────────────────────────────────────────────────────────────┐
│                    SCHOOL MANAGEMENT SYSTEM                      │
│                      (100+ Tables)                               │
└─────────────────────────────────────────────────────────────────┘
                                │
        ┌───────────────────────┼───────────────────────┐
        │                       │                       │
   ┌────▼────┐           ┌──────▼──────┐        ┌─────▼──────┐
   │ EXISTING│           │ AI & PREDICT│        │  OPERATIONS│
   │ SCHEMA  │           │  ANALYTICS  │        │ MANAGEMENT │
   │(60 tbl) │           │  (6 tables) │        │(25 tables) │
   └─────────┘           └─────────────┘        └────────────┘
        │                       │                       │
  ┌─────┴─────┐          ┌──────┴──────┐        ┌──────┴──────┐
  │• Tenants  │          │• ML Models  │        │• Assets     │
  │• Students │          │• Predictions│        │• HR/Payroll │
  │• Marks    │          │• Alerts     │        │• Alumni     │
  │• Fees     │          │• Interven-  │        │• Admissions │
  │• Messages │          │  tions      │        │• Audit Logs │
  └───────────┘          └─────────────┘        └─────────────┘
```

---

## 🔑 Key Tables by Feature

### 1. AI & Predictive Analytics
```sql
ml_models                        -- ML model registry
student_performance_predictions  -- Risk assessment & predictions
student_feature_snapshots        -- Time-series data for ML
student_interventions            -- Intervention tracking
early_warning_alerts            -- Automated alerts
alert_rules                     -- Configurable rules
```

### 2. Advanced Fee Management
```sql
fee_payment_plans               -- Payment installment plans
payment_installments            -- Individual installments
fee_dunning_workflows           -- Collection workflows
dunning_actions                 -- Collection action logs
fee_concessions                 -- Scholarships & discounts
concession_applications         -- Applied concessions
```

### 3. Behavioral Tracking
```sql
behavior_incidents              -- Incident records (positive/negative)
disciplinary_actions            -- Disciplinary measures
counseling_sessions             -- Confidential counseling
student_conduct_grades          -- Conduct grading
behavior_intervention_plans     -- BIP for at-risk students
```

### 4. Skills & Competencies
```sql
competency_frameworks           -- Framework definitions
competencies                    -- Individual competencies
student_competency_assessments  -- Student assessments
learning_objectives             -- Curriculum objectives
student_skills_portfolio        -- Skills & certifications
```

### 5. Asset Management
```sql
asset_categories                -- Asset categories
assets                          -- School assets inventory
asset_maintenance               -- Maintenance schedules
```

### 6. Staff HR
```sql
staff_attendance                -- Daily attendance
staff_leave_applications        -- Leave requests
payroll                         -- Monthly payroll
performance_reviews             -- Performance reviews
```

### 7. Alumni Management
```sql
alumni                          -- Alumni database
alumni_events                   -- Events & reunions
alumni_event_registrations      -- Event registrations
alumni_donations                -- Donation tracking
```

### 8. Admissions
```sql
admission_inquiries             -- Lead tracking
admission_applications          -- Application management
admission_entrance_tests        -- Entrance tests
admission_interviews            -- Interview tracking
admission_campaigns             -- Marketing campaigns
```

---

## 🔒 Row Level Security (RLS)

### Testing RLS Policies

```sql
-- Test as Admin
SET request.jwt.claims = '{"sub": "admin-uuid", "app_metadata": {"tenant_id": "tenant-uuid", "roles": ["tenant_admin"]}}';
SELECT COUNT(*) FROM student_performance_predictions;
-- Should see all predictions

-- Test as Student
SET request.jwt.claims = '{"sub": "student-user-uuid", "app_metadata": {"tenant_id": "tenant-uuid", "roles": ["student"]}}';
SELECT COUNT(*) FROM student_performance_predictions;
-- Should see only own predictions

-- Test as Parent
SET request.jwt.claims = '{"sub": "parent-user-uuid", "app_metadata": {"tenant_id": "tenant-uuid", "roles": ["parent"]}}';
SELECT COUNT(*) FROM student_performance_predictions;
-- Should see children's predictions only
```

---

## 🛠 Common Operations

### Create Feature Snapshot
```sql
SELECT create_feature_snapshot(
    '<student-uuid>',
    '<academic-year-uuid>'
);
```

### Generate Payment Installments
```sql
-- First create a payment plan
INSERT INTO fee_payment_plans (...)
RETURNING id;

-- Then generate installments
SELECT auto_generate_installments('<plan-uuid>');
```

### Calculate Conduct Grade
```sql
SELECT calculate_conduct_grade(
    '<student-uuid>',
    '<term-uuid>'
);
```

### Trigger Early Warning Alert
```sql
SELECT trigger_early_warning(
    '<student-uuid>',
    'attendance_issue',
    'critical',
    'Student absent for 5+ consecutive days',
    'Student has been absent without notice'
);
```

### Apply Fee Concession
```sql
SELECT apply_concession_to_invoice(
    '<invoice-uuid>',
    '<concession-uuid>'
);
```

---

## 📈 Performance Optimization

### Query Performance Check
```sql
-- Explain query execution
EXPLAIN ANALYZE
SELECT * FROM student_performance_predictions
WHERE student_id = '<uuid>'
  AND risk_level IN ('high', 'critical')
ORDER BY predicted_at DESC
LIMIT 10;

-- Should use idx_predictions_risk index
```

### Vacuum & Analyze
```bash
# Run daily maintenance
SELECT vacuum_analyze_large_tables();
```

### Refresh Materialized Views
```bash
SELECT refresh_all_materialized_views();
```

---

## 🧪 Testing Checklist

### Schema Validation
- [ ] All tables created (100+)
- [ ] All indexes created (50+)
- [ ] All RLS policies enabled (100+ tables)
- [ ] All stored procedures created (20+)
- [ ] All triggers created (10+)

### Functional Testing
- [ ] ML predictions can be created
- [ ] Payment plans generate installments correctly
- [ ] Dunning workflow processes overdue payments
- [ ] Conduct grades calculate from incidents
- [ ] Early warning alerts trigger correctly
- [ ] Fee concessions apply to invoices
- [ ] Asset maintenance schedules work
- [ ] Alumni event registrations function

### Security Testing
- [ ] Admin sees all tenant data
- [ ] Students see only their own data
- [ ] Parents see only their children's data
- [ ] Teachers see their class data
- [ ] Accountants access fee data only
- [ ] Counseling sessions remain confidential
- [ ] Payroll data is restricted

### Performance Testing
- [ ] Student list query < 100ms
- [ ] Prediction query < 50ms
- [ ] Invoice generation < 200ms
- [ ] Report generation < 500ms
- [ ] Archive operation completes successfully

---

## 🚨 Common Issues & Solutions

### Issue: RLS policy errors
```
Solution: Ensure JWT claims include tenant_id and roles:
{
  "sub": "user-uuid",
  "app_metadata": {
    "tenant_id": "tenant-uuid",
    "roles": ["student"]
  }
}
```

### Issue: Migration fails
```bash
Solution: Check migration order and dependencies
# View migration status
supabase migration list

# Repair if needed
supabase migration repair
```

### Issue: Slow queries
```sql
Solution: Check if indexes are being used
EXPLAIN ANALYZE <your-query>;

-- If not using index, consider adding one or updating statistics
ANALYZE <table_name>;
```

---

## 📝 API Usage Examples (Flutter/Dart)

### Fetch Student Predictions
```dart
final predictions = await supabase
  .from('student_performance_predictions')
  .select('*')
  .eq('student_id', studentId)
  .order('predicted_at', ascending: false);
```

### Create Payment Plan
```dart
final plan = await supabase
  .from('fee_payment_plans')
  .insert({
    'invoice_id': invoiceId,
    'student_id': studentId,
    'plan_name': 'Monthly Installments',
    'total_amount': 50000,
    'installment_amount': 5000,
    'number_of_installments': 10,
    'frequency': 'monthly',
    'start_date': '2026-03-01',
    'end_date': '2026-12-01',
  })
  .select()
  .single();

// Auto-generate installments
await supabase.rpc('auto_generate_installments', {
  'p_plan_id': plan['id'],
});
```

### Log Behavior Incident
```dart
await supabase
  .from('behavior_incidents')
  .insert({
    'student_id': studentId,
    'incident_date': DateTime.now().toIso8601String(),
    'behavior_type': 'negative',
    'behavior_category': 'bullying',
    'severity': 'major',
    'title': 'Bullying incident in cafeteria',
    'description': 'Student was observed...',
    'reported_by': teacherId,
  });
```

### Check Early Warning Alerts
```dart
final alerts = await supabase
  .from('early_warning_alerts')
  .select('*')
  .eq('student_id', studentId)
  .in_('status', ['new', 'acknowledged'])
  .order('created_at', ascending: false);
```

---

## 📚 Additional Resources

- **Full Schema Documentation:** See `DATABASE_ENHANCEMENT_SUMMARY.md`
- **Original Plan:** Refer to plan document for detailed rationale
- **Migration Files:** `supabase/migrations/20260209*.sql`
- **Supabase Docs:** https://supabase.com/docs

---

## ⚡️ Quick Commands Reference

```bash
# Start Supabase
supabase start

# Stop Supabase
supabase stop

# Reset database
supabase db reset

# Create new migration
supabase migration new <name>

# Push to remote
supabase db push

# Pull from remote
supabase db pull

# Generate types for Flutter
supabase gen types typescript --local > lib/types/database.types.ts

# View logs
supabase logs -f

# Access database shell
supabase db shell
```

---

**Happy Coding! 🚀**

*For questions or issues, refer to the comprehensive documentation or migration files.*
