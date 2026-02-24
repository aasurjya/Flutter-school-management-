-- =============================================
-- AI Phase 1: Risk Scoring, Parent Digests,
-- Attendance Intelligence, Trend Predictions
-- Migration 00010
-- =============================================

-- =============================================
-- 1. STUDENT RISK SCORES (cached computations)
-- =============================================

CREATE TABLE IF NOT EXISTS student_risk_scores (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    student_id UUID NOT NULL REFERENCES students(id) ON DELETE CASCADE,
    academic_year_id UUID NOT NULL REFERENCES academic_years(id) ON DELETE CASCADE,
    -- Composite score 0-100
    overall_risk_score DECIMAL(5,2) NOT NULL DEFAULT 0,
    risk_level risk_level NOT NULL DEFAULT 'low',
    -- Factor breakdown (each 0-100)
    attendance_score DECIMAL(5,2) DEFAULT 0,
    academic_score DECIMAL(5,2) DEFAULT 0,
    fee_score DECIMAL(5,2) DEFAULT 0,
    engagement_score DECIMAL(5,2) DEFAULT 0,
    -- Trend tracking
    previous_score DECIMAL(5,2),
    score_trend VARCHAR(20) DEFAULT 'stable', -- 'improving', 'stable', 'declining'
    -- Flags and recommendations
    flags TEXT[] DEFAULT '{}',
    recommended_actions JSONB DEFAULT '[]',
    -- Metadata
    computed_at TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(student_id, academic_year_id)
);

CREATE INDEX idx_risk_scores_tenant ON student_risk_scores(tenant_id);
CREATE INDEX idx_risk_scores_level ON student_risk_scores(risk_level) WHERE risk_level IN ('high', 'critical');
CREATE INDEX idx_risk_scores_section ON student_risk_scores(tenant_id, academic_year_id);

ALTER TABLE student_risk_scores ENABLE ROW LEVEL SECURITY;

CREATE POLICY "View risk scores"
ON student_risk_scores FOR SELECT
USING (
    tenant_id = public.tenant_id() AND (
        public.is_admin() OR
        public.has_role('teacher') OR
        student_id IN (SELECT id FROM students WHERE user_id = auth.uid()) OR
        student_id IN (
            SELECT sp.student_id FROM student_parents sp
            JOIN parents p ON sp.parent_id = p.id
            WHERE p.user_id = auth.uid()
        )
    )
);

CREATE POLICY "Staff manage risk scores"
ON student_risk_scores FOR ALL
USING (
    tenant_id = public.tenant_id() AND (
        public.is_admin() OR public.has_role('teacher')
    )
);

-- =============================================
-- 2. PARENT DIGESTS (weekly summaries)
-- =============================================

CREATE TABLE IF NOT EXISTS parent_digests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    student_id UUID NOT NULL REFERENCES students(id) ON DELETE CASCADE,
    parent_id UUID NOT NULL REFERENCES parents(id) ON DELETE CASCADE,
    -- Week range
    week_start DATE NOT NULL,
    week_end DATE NOT NULL,
    -- Content
    title VARCHAR(255) NOT NULL,
    summary TEXT,
    sections JSONB DEFAULT '[]',
    -- Attendance stats for the week
    attendance_present INT DEFAULT 0,
    attendance_absent INT DEFAULT 0,
    attendance_late INT DEFAULT 0,
    attendance_total INT DEFAULT 0,
    -- Academic highlights
    highlights JSONB DEFAULT '[]',
    -- Upcoming events
    upcoming_events JSONB DEFAULT '[]',
    -- Status
    is_read BOOLEAN DEFAULT false,
    read_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(student_id, parent_id, week_start)
);

CREATE INDEX idx_digests_parent ON parent_digests(parent_id, week_start DESC);
CREATE INDEX idx_digests_student ON parent_digests(student_id, week_start DESC);
CREATE INDEX idx_digests_tenant ON parent_digests(tenant_id);
CREATE INDEX idx_digests_unread ON parent_digests(parent_id) WHERE is_read = false;

ALTER TABLE parent_digests ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Parents view own digests"
ON parent_digests FOR SELECT
USING (
    tenant_id = public.tenant_id() AND (
        public.is_admin() OR
        parent_id IN (SELECT id FROM parents WHERE user_id = auth.uid())
    )
);

CREATE POLICY "Staff manage digests"
ON parent_digests FOR ALL
USING (
    tenant_id = public.tenant_id() AND (
        public.is_admin() OR public.has_role('teacher')
    )
);

-- Parents can mark their digests as read
CREATE POLICY "Parents update own digests"
ON parent_digests FOR UPDATE
USING (
    tenant_id = public.tenant_id() AND
    parent_id IN (SELECT id FROM parents WHERE user_id = auth.uid())
);

-- =============================================
-- 3. ATTENDANCE DAY PATTERNS VIEW
-- =============================================

CREATE OR REPLACE VIEW v_attendance_day_patterns AS
SELECT
    a.tenant_id,
    a.section_id,
    sec.name AS section_name,
    c.name AS class_name,
    EXTRACT(DOW FROM a.date)::INT AS day_of_week,
    TO_CHAR(a.date, 'Day') AS day_name,
    COUNT(*) AS total_records,
    COUNT(*) FILTER (WHERE a.status = 'present') AS present_count,
    COUNT(*) FILTER (WHERE a.status = 'absent') AS absent_count,
    COUNT(*) FILTER (WHERE a.status = 'late') AS late_count,
    ROUND(
        COUNT(*) FILTER (WHERE a.status IN ('present', 'late', 'excused'))::NUMERIC
        / NULLIF(COUNT(*), 0) * 100, 2
    ) AS attendance_percentage
FROM attendance a
JOIN sections sec ON a.section_id = sec.id
JOIN classes c ON sec.class_id = c.id
GROUP BY a.tenant_id, a.section_id, sec.name, c.name,
         EXTRACT(DOW FROM a.date), TO_CHAR(a.date, 'Day');

GRANT SELECT ON v_attendance_day_patterns TO authenticated;

-- =============================================
-- 4. CHRONIC ABSENTEES VIEW
-- =============================================

CREATE OR REPLACE VIEW v_chronic_absentees AS
SELECT
    a.tenant_id,
    a.student_id,
    s.first_name || ' ' || COALESCE(s.last_name, '') AS student_name,
    s.admission_number,
    a.section_id,
    sec.name AS section_name,
    c.name AS class_name,
    COUNT(*) AS total_days,
    COUNT(*) FILTER (WHERE a.status = 'absent') AS absent_days,
    ROUND(
        COUNT(*) FILTER (WHERE a.status = 'absent')::NUMERIC
        / NULLIF(COUNT(*), 0) * 100, 2
    ) AS absence_rate
FROM attendance a
JOIN students s ON a.student_id = s.id
JOIN sections sec ON a.section_id = sec.id
JOIN classes c ON sec.class_id = c.id
GROUP BY a.tenant_id, a.student_id, s.first_name, s.last_name,
         s.admission_number, a.section_id, sec.name, c.name
HAVING ROUND(
    COUNT(*) FILTER (WHERE a.status = 'absent')::NUMERIC
    / NULLIF(COUNT(*), 0) * 100, 2
) > 20;

GRANT SELECT ON v_chronic_absentees TO authenticated;

-- =============================================
-- 5. TREND PREDICTIONS CACHE TABLE
-- =============================================

CREATE TABLE IF NOT EXISTS trend_predictions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    entity_type VARCHAR(50) NOT NULL, -- 'student', 'section'
    entity_id UUID NOT NULL,
    metric_type VARCHAR(50) NOT NULL, -- 'exam_performance', 'attendance'
    -- Regression results
    slope DECIMAL(10,6),
    intercept DECIMAL(10,6),
    r_squared DECIMAL(6,4),
    -- Data points
    historical_data JSONB DEFAULT '[]',
    predicted_data JSONB DEFAULT '[]',
    -- Metadata
    computed_at TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(entity_type, entity_id, metric_type)
);

CREATE INDEX idx_trend_predictions_entity ON trend_predictions(entity_type, entity_id);
CREATE INDEX idx_trend_predictions_tenant ON trend_predictions(tenant_id);

ALTER TABLE trend_predictions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "View trend predictions"
ON trend_predictions FOR SELECT
USING (tenant_id = public.tenant_id());

CREATE POLICY "Staff manage trend predictions"
ON trend_predictions FOR ALL
USING (
    tenant_id = public.tenant_id() AND (
        public.is_admin() OR public.has_role('teacher')
    )
);

-- =============================================
-- 6. COMPUTE STUDENT RISK SCORE FUNCTION
-- =============================================

CREATE OR REPLACE FUNCTION compute_student_risk_score(
    p_student_id UUID,
    p_academic_year_id UUID
)
RETURNS UUID AS $$
DECLARE
    v_id UUID;
    v_tenant_id UUID;
    v_attendance_score DECIMAL(5,2) := 0;
    v_academic_score DECIMAL(5,2) := 0;
    v_fee_score DECIMAL(5,2) := 0;
    v_engagement_score DECIMAL(5,2) := 0;
    v_overall DECIMAL(5,2);
    v_level risk_level;
    v_prev_score DECIMAL(5,2);
    v_trend VARCHAR(20);
    v_flags TEXT[] := '{}';
    v_actions JSONB := '[]';
    v_att_pct DECIMAL(5,2);
    v_exam_pct DECIMAL(5,2);
    v_fee_pending DECIMAL(10,2);
    v_fee_total DECIMAL(10,2);
    v_assignment_rate DECIMAL(5,2);
BEGIN
    -- Get tenant_id
    SELECT tenant_id INTO v_tenant_id FROM students WHERE id = p_student_id;

    -- =========================================
    -- ATTENDANCE FACTOR (30% weight)
    -- =========================================
    SELECT
        ROUND(
            COUNT(*) FILTER (WHERE status IN ('present', 'late', 'excused'))::NUMERIC
            / NULLIF(COUNT(*), 0) * 100, 2
        )
    INTO v_att_pct
    FROM attendance
    WHERE student_id = p_student_id
      AND date >= (SELECT start_date FROM academic_years WHERE id = p_academic_year_id);

    -- Convert attendance % to risk score (inverted: low attendance = high risk)
    IF v_att_pct IS NOT NULL THEN
        v_attendance_score := GREATEST(0, LEAST(100, 100 - v_att_pct));
        IF v_att_pct < 60 THEN
            v_flags := array_append(v_flags, 'critical_attendance');
            v_actions := v_actions || '["Immediate parent meeting about attendance"]'::JSONB;
        ELSIF v_att_pct < 75 THEN
            v_flags := array_append(v_flags, 'low_attendance');
            v_actions := v_actions || '["Monitor attendance closely"]'::JSONB;
        END IF;
    END IF;

    -- =========================================
    -- ACADEMIC FACTOR (35% weight)
    -- =========================================
    SELECT ROUND(AVG(percentage), 2)
    INTO v_exam_pct
    FROM mv_student_performance
    WHERE student_id = p_student_id
      AND academic_year_id = p_academic_year_id;

    IF v_exam_pct IS NOT NULL THEN
        v_academic_score := GREATEST(0, LEAST(100, 100 - v_exam_pct));
        IF v_exam_pct < 35 THEN
            v_flags := array_append(v_flags, 'failing_grades');
            v_actions := v_actions || '["Arrange remedial classes", "Consider peer tutoring"]'::JSONB;
        ELSIF v_exam_pct < 50 THEN
            v_flags := array_append(v_flags, 'below_average_grades');
            v_actions := v_actions || '["Schedule academic counseling"]'::JSONB;
        END IF;
    END IF;

    -- =========================================
    -- FEE FACTOR (15% weight)
    -- =========================================
    SELECT
        COALESCE(SUM(total_amount - discount_amount - paid_amount), 0),
        COALESCE(SUM(total_amount), 0)
    INTO v_fee_pending, v_fee_total
    FROM invoices
    WHERE student_id = p_student_id
      AND academic_year_id = p_academic_year_id
      AND status IN ('pending', 'overdue', 'partial');

    IF v_fee_total > 0 THEN
        v_fee_score := GREATEST(0, LEAST(100, ROUND((v_fee_pending / v_fee_total) * 100, 2)));
        IF v_fee_score > 75 THEN
            v_flags := array_append(v_flags, 'high_fee_pending');
            v_actions := v_actions || '["Send fee reminder to parents"]'::JSONB;
        END IF;
    END IF;

    -- =========================================
    -- ENGAGEMENT FACTOR (20% weight)
    -- =========================================
    SELECT ROUND(
        COUNT(*) FILTER (WHERE s.status IN ('submitted', 'graded'))::NUMERIC
        / NULLIF(COUNT(*), 0) * 100, 2
    )
    INTO v_assignment_rate
    FROM assignments a
    LEFT JOIN submissions s ON s.assignment_id = a.id AND s.student_id = p_student_id
    WHERE a.section_id IN (
        SELECT section_id FROM student_enrollments
        WHERE student_id = p_student_id AND academic_year_id = p_academic_year_id
    );

    IF v_assignment_rate IS NOT NULL THEN
        v_engagement_score := GREATEST(0, LEAST(100, 100 - v_assignment_rate));
        IF v_assignment_rate < 50 THEN
            v_flags := array_append(v_flags, 'low_engagement');
            v_actions := v_actions || '["Discuss engagement with student"]'::JSONB;
        END IF;
    END IF;

    -- =========================================
    -- COMPOSITE SCORE
    -- =========================================
    v_overall := ROUND(
        v_attendance_score * 0.30 +
        v_academic_score * 0.35 +
        v_fee_score * 0.15 +
        v_engagement_score * 0.20
    , 2);

    -- Determine risk level
    IF v_overall >= 70 THEN
        v_level := 'critical';
    ELSIF v_overall >= 50 THEN
        v_level := 'high';
    ELSIF v_overall >= 30 THEN
        v_level := 'medium';
    ELSE
        v_level := 'low';
    END IF;

    -- Get previous score for trend
    SELECT overall_risk_score INTO v_prev_score
    FROM student_risk_scores
    WHERE student_id = p_student_id AND academic_year_id = p_academic_year_id;

    IF v_prev_score IS NOT NULL THEN
        IF v_overall < v_prev_score - 5 THEN
            v_trend := 'improving';
        ELSIF v_overall > v_prev_score + 5 THEN
            v_trend := 'declining';
        ELSE
            v_trend := 'stable';
        END IF;
    ELSE
        v_trend := 'stable';
    END IF;

    -- =========================================
    -- UPSERT
    -- =========================================
    INSERT INTO student_risk_scores (
        tenant_id, student_id, academic_year_id,
        overall_risk_score, risk_level,
        attendance_score, academic_score, fee_score, engagement_score,
        previous_score, score_trend,
        flags, recommended_actions,
        computed_at, updated_at
    ) VALUES (
        v_tenant_id, p_student_id, p_academic_year_id,
        v_overall, v_level,
        v_attendance_score, v_academic_score, v_fee_score, v_engagement_score,
        v_prev_score, v_trend,
        v_flags, v_actions,
        NOW(), NOW()
    )
    ON CONFLICT (student_id, academic_year_id)
    DO UPDATE SET
        overall_risk_score = EXCLUDED.overall_risk_score,
        risk_level = EXCLUDED.risk_level,
        attendance_score = EXCLUDED.attendance_score,
        academic_score = EXCLUDED.academic_score,
        fee_score = EXCLUDED.fee_score,
        engagement_score = EXCLUDED.engagement_score,
        previous_score = student_risk_scores.overall_risk_score,
        score_trend = EXCLUDED.score_trend,
        flags = EXCLUDED.flags,
        recommended_actions = EXCLUDED.recommended_actions,
        computed_at = NOW(),
        updated_at = NOW()
    RETURNING id INTO v_id;

    RETURN v_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION compute_student_risk_score IS 'Computes composite risk score from attendance (30%), academics (35%), fees (15%), engagement (20%)';

-- =============================================
-- 7. GRANT PERMISSIONS
-- =============================================

GRANT SELECT ON student_risk_scores TO authenticated;
GRANT SELECT, INSERT, UPDATE ON student_risk_scores TO authenticated;
GRANT SELECT ON parent_digests TO authenticated;
GRANT SELECT, INSERT, UPDATE ON parent_digests TO authenticated;
GRANT SELECT ON trend_predictions TO authenticated;
GRANT SELECT, INSERT, UPDATE ON trend_predictions TO authenticated;
