-- =============================================
-- Security Fixes Migration
-- 1. Fix tenant_id() fallback from zero UUID to NULL
-- 2. Add RLS + policies for 21 tables from 00008_new_features
-- =============================================

-- =============================================
-- 1. REDEFINE tenant_id() — return NULL instead of zero UUID
-- =============================================

CREATE OR REPLACE FUNCTION public.tenant_id()
RETURNS UUID AS $$
DECLARE
  jwt_claims JSONB;
  tenant_uuid UUID;
BEGIN
  -- Get the JWT claims from the current request
  jwt_claims := current_setting('request.jwt.claims', true)::jsonb;

  -- Try to extract tenant_id from app_metadata
  tenant_uuid := (jwt_claims->'app_metadata'->>'tenant_id')::UUID;

  -- Return the tenant UUID (NULL if not present)
  RETURN tenant_uuid;
EXCEPTION
  WHEN OTHERS THEN
    -- If anything fails, return NULL (deny access by default)
    RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =============================================
-- 2. ENABLE RLS ON ALL 21 TABLES FROM 00008
-- =============================================

ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE student_health_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE health_incidents ENABLE ROW LEVEL SECURITY;
ALTER TABLE achievements ENABLE ROW LEVEL SECURITY;
ALTER TABLE student_achievements ENABLE ROW LEVEL SECURITY;
ALTER TABLE student_points ENABLE ROW LEVEL SECURITY;
ALTER TABLE point_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE quizzes ENABLE ROW LEVEL SECURITY;
ALTER TABLE question_bank ENABLE ROW LEVEL SECURITY;
ALTER TABLE quiz_questions ENABLE ROW LEVEL SECURITY;
ALTER TABLE quiz_attempts ENABLE ROW LEVEL SECURITY;
ALTER TABLE ptm_schedules ENABLE ROW LEVEL SECURITY;
ALTER TABLE ptm_teacher_availability ENABLE ROW LEVEL SECURITY;
ALTER TABLE ptm_appointments ENABLE ROW LEVEL SECURITY;
ALTER TABLE emergency_alerts ENABLE ROW LEVEL SECURITY;
ALTER TABLE emergency_responses ENABLE ROW LEVEL SECURITY;
ALTER TABLE emergency_contacts ENABLE ROW LEVEL SECURITY;
ALTER TABLE leave_applications ENABLE ROW LEVEL SECURITY;
ALTER TABLE leave_balance ENABLE ROW LEVEL SECURITY;
ALTER TABLE study_resources ENABLE ROW LEVEL SECURITY;
ALTER TABLE resource_access ENABLE ROW LEVEL SECURITY;

-- =============================================
-- 3. RLS POLICIES FOR EACH TABLE
-- =============================================

-- ----- notifications -----
CREATE POLICY "View own notifications"
ON notifications FOR SELECT
USING (tenant_id = public.tenant_id() AND user_id = auth.uid());

CREATE POLICY "Admins manage notifications"
ON notifications FOR ALL
USING (tenant_id = public.tenant_id() AND public.is_admin());

-- ----- student_health_records -----
CREATE POLICY "View health records"
ON student_health_records FOR SELECT
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

CREATE POLICY "Admins manage health records"
ON student_health_records FOR ALL
USING (tenant_id = public.tenant_id() AND public.is_admin());

-- ----- health_incidents -----
CREATE POLICY "View health incidents"
ON health_incidents FOR SELECT
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

CREATE POLICY "Staff manage health incidents"
ON health_incidents FOR ALL
USING (tenant_id = public.tenant_id() AND (public.is_admin() OR public.has_role('teacher')));

-- ----- achievements -----
CREATE POLICY "View achievements"
ON achievements FOR SELECT
USING (tenant_id = public.tenant_id());

CREATE POLICY "Admins manage achievements"
ON achievements FOR ALL
USING (tenant_id = public.tenant_id() AND public.is_admin());

-- ----- student_achievements -----
CREATE POLICY "View student achievements"
ON student_achievements FOR SELECT
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

CREATE POLICY "Admins manage student achievements"
ON student_achievements FOR ALL
USING (tenant_id = public.tenant_id() AND public.is_admin());

-- ----- student_points -----
CREATE POLICY "View student points"
ON student_points FOR SELECT
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

CREATE POLICY "Staff manage student points"
ON student_points FOR ALL
USING (tenant_id = public.tenant_id() AND (public.is_admin() OR public.has_role('teacher')));

-- ----- point_transactions -----
CREATE POLICY "View point transactions"
ON point_transactions FOR SELECT
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

CREATE POLICY "Staff manage point transactions"
ON point_transactions FOR ALL
USING (tenant_id = public.tenant_id() AND (public.is_admin() OR public.has_role('teacher')));

-- ----- quizzes -----
CREATE POLICY "View quizzes"
ON quizzes FOR SELECT
USING (tenant_id = public.tenant_id());

CREATE POLICY "Teachers manage quizzes"
ON quizzes FOR ALL
USING (tenant_id = public.tenant_id() AND (public.is_admin() OR public.has_role('teacher')));

-- ----- question_bank -----
CREATE POLICY "View questions"
ON question_bank FOR SELECT
USING (tenant_id = public.tenant_id() AND (public.is_admin() OR public.has_role('teacher')));

CREATE POLICY "Teachers manage questions"
ON question_bank FOR ALL
USING (tenant_id = public.tenant_id() AND (public.is_admin() OR public.has_role('teacher')));

-- ----- quiz_questions -----
CREATE POLICY "View quiz questions"
ON quiz_questions FOR SELECT
USING (tenant_id = public.tenant_id());

CREATE POLICY "Teachers manage quiz questions"
ON quiz_questions FOR ALL
USING (tenant_id = public.tenant_id() AND (public.is_admin() OR public.has_role('teacher')));

-- ----- quiz_attempts -----
CREATE POLICY "View own quiz attempts"
ON quiz_attempts FOR SELECT
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

CREATE POLICY "Students create quiz attempts"
ON quiz_attempts FOR INSERT
WITH CHECK (
  tenant_id = public.tenant_id() AND
  student_id IN (SELECT id FROM students WHERE user_id = auth.uid())
);

CREATE POLICY "Students update own quiz attempts"
ON quiz_attempts FOR UPDATE
USING (
  tenant_id = public.tenant_id() AND
  student_id IN (SELECT id FROM students WHERE user_id = auth.uid())
);

CREATE POLICY "Admins manage quiz attempts"
ON quiz_attempts FOR ALL
USING (tenant_id = public.tenant_id() AND public.is_admin());

-- ----- ptm_schedules -----
CREATE POLICY "View PTM schedules"
ON ptm_schedules FOR SELECT
USING (tenant_id = public.tenant_id());

CREATE POLICY "Admins manage PTM schedules"
ON ptm_schedules FOR ALL
USING (tenant_id = public.tenant_id() AND public.is_admin());

-- ----- ptm_teacher_availability -----
CREATE POLICY "View PTM teacher availability"
ON ptm_teacher_availability FOR SELECT
USING (tenant_id = public.tenant_id());

CREATE POLICY "Teachers manage own availability"
ON ptm_teacher_availability FOR ALL
USING (tenant_id = public.tenant_id() AND (public.is_admin() OR public.has_role('teacher')));

-- ----- ptm_appointments -----
CREATE POLICY "View own PTM appointments"
ON ptm_appointments FOR SELECT
USING (
  tenant_id = public.tenant_id() AND (
    public.is_admin() OR
    public.has_role('teacher') OR
    parent_id IN (SELECT id FROM parents WHERE user_id = auth.uid())
  )
);

CREATE POLICY "Parents book PTM appointments"
ON ptm_appointments FOR INSERT
WITH CHECK (
  tenant_id = public.tenant_id() AND
  parent_id IN (SELECT id FROM parents WHERE user_id = auth.uid())
);

CREATE POLICY "Admins manage PTM appointments"
ON ptm_appointments FOR ALL
USING (tenant_id = public.tenant_id() AND public.is_admin());

-- ----- emergency_alerts -----
CREATE POLICY "View emergency alerts"
ON emergency_alerts FOR SELECT
USING (tenant_id = public.tenant_id());

CREATE POLICY "Admins manage emergency alerts"
ON emergency_alerts FOR ALL
USING (tenant_id = public.tenant_id() AND public.is_admin());

-- ----- emergency_responses -----
CREATE POLICY "View emergency responses"
ON emergency_responses FOR SELECT
USING (tenant_id = public.tenant_id() AND (public.is_admin() OR responder_id = auth.uid()));

CREATE POLICY "Create emergency responses"
ON emergency_responses FOR INSERT
WITH CHECK (tenant_id = public.tenant_id() AND responder_id = auth.uid());

CREATE POLICY "Admins manage emergency responses"
ON emergency_responses FOR ALL
USING (tenant_id = public.tenant_id() AND public.is_admin());

-- ----- emergency_contacts -----
CREATE POLICY "View emergency contacts"
ON emergency_contacts FOR SELECT
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

CREATE POLICY "Parents manage own emergency contacts"
ON emergency_contacts FOR ALL
USING (
  tenant_id = public.tenant_id() AND (
    public.is_admin() OR
    student_id IN (
      SELECT sp.student_id FROM student_parents sp
      JOIN parents p ON sp.parent_id = p.id
      WHERE p.user_id = auth.uid()
    )
  )
);

-- ----- leave_applications -----
CREATE POLICY "View leave applications"
ON leave_applications FOR SELECT
USING (
  tenant_id = public.tenant_id() AND (
    public.is_admin() OR
    applicant_id = auth.uid() OR
    student_id IN (
      SELECT sp.student_id FROM student_parents sp
      JOIN parents p ON sp.parent_id = p.id
      WHERE p.user_id = auth.uid()
    )
  )
);

CREATE POLICY "Create own leave applications"
ON leave_applications FOR INSERT
WITH CHECK (tenant_id = public.tenant_id() AND applicant_id = auth.uid());

CREATE POLICY "Admins manage leave applications"
ON leave_applications FOR ALL
USING (tenant_id = public.tenant_id() AND public.is_admin());

-- ----- leave_balance -----
CREATE POLICY "View own leave balance"
ON leave_balance FOR SELECT
USING (tenant_id = public.tenant_id() AND (public.is_admin() OR user_id = auth.uid()));

CREATE POLICY "Admins manage leave balance"
ON leave_balance FOR ALL
USING (tenant_id = public.tenant_id() AND public.is_admin());

-- ----- study_resources -----
CREATE POLICY "View study resources"
ON study_resources FOR SELECT
USING (tenant_id = public.tenant_id());

CREATE POLICY "Teachers manage study resources"
ON study_resources FOR ALL
USING (tenant_id = public.tenant_id() AND (public.is_admin() OR public.has_role('teacher')));

-- ----- resource_access -----
CREATE POLICY "View resource access"
ON resource_access FOR SELECT
USING (tenant_id = public.tenant_id() AND (public.is_admin() OR public.has_role('teacher') OR user_id = auth.uid()));

CREATE POLICY "Log own resource access"
ON resource_access FOR INSERT
WITH CHECK (tenant_id = public.tenant_id() AND user_id = auth.uid());

CREATE POLICY "Admins manage resource access"
ON resource_access FOR ALL
USING (tenant_id = public.tenant_id() AND public.is_admin());
