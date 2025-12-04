-- =============================================
-- Row Level Security (RLS) Policies
-- =============================================

-- =============================================
-- HELPER FUNCTIONS
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
  
  -- If we got a valid UUID, return it
  IF tenant_uuid IS NOT NULL THEN
    RETURN tenant_uuid;
  END IF;
  
  -- Fallback: return zero UUID
  RETURN '00000000-0000-0000-0000-000000000000'::UUID;
EXCEPTION
  WHEN OTHERS THEN
    -- If anything fails, return zero UUID
    RETURN '00000000-0000-0000-0000-000000000000'::UUID;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Check if user has a specific role
CREATE OR REPLACE FUNCTION public.has_role(required_role user_role)
RETURNS BOOLEAN AS $$
DECLARE
  roles JSONB;
BEGIN
  roles := (current_setting('request.jwt.claims', true)::json->'app_metadata'->'roles')::JSONB;
  RETURN roles ? required_role::TEXT;
EXCEPTION
  WHEN OTHERS THEN
    RETURN false;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Check if user is admin (tenant_admin or principal)
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN AS $$
BEGIN
  RETURN public.has_role('tenant_admin') OR public.has_role('principal') OR public.has_role('super_admin');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =============================================
-- ENABLE RLS ON ALL TABLES
-- =============================================

ALTER TABLE tenants ENABLE ROW LEVEL SECURITY;
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE academic_years ENABLE ROW LEVEL SECURITY;
ALTER TABLE terms ENABLE ROW LEVEL SECURITY;
ALTER TABLE classes ENABLE ROW LEVEL SECURITY;
ALTER TABLE sections ENABLE ROW LEVEL SECURITY;
ALTER TABLE subjects ENABLE ROW LEVEL SECURITY;
ALTER TABLE class_subjects ENABLE ROW LEVEL SECURITY;
ALTER TABLE teacher_assignments ENABLE ROW LEVEL SECURITY;
ALTER TABLE students ENABLE ROW LEVEL SECURITY;
ALTER TABLE student_enrollments ENABLE ROW LEVEL SECURITY;
ALTER TABLE parents ENABLE ROW LEVEL SECURITY;
ALTER TABLE student_parents ENABLE ROW LEVEL SECURITY;
ALTER TABLE staff ENABLE ROW LEVEL SECURITY;
ALTER TABLE timetable_slots ENABLE ROW LEVEL SECURITY;
ALTER TABLE timetables ENABLE ROW LEVEL SECURITY;
ALTER TABLE attendance ENABLE ROW LEVEL SECURITY;
ALTER TABLE period_attendance ENABLE ROW LEVEL SECURITY;
ALTER TABLE exams ENABLE ROW LEVEL SECURITY;
ALTER TABLE exam_subjects ENABLE ROW LEVEL SECURITY;
ALTER TABLE marks ENABLE ROW LEVEL SECURITY;
ALTER TABLE grade_scales ENABLE ROW LEVEL SECURITY;
ALTER TABLE grade_scale_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE exam_statistics ENABLE ROW LEVEL SECURITY;
ALTER TABLE assignments ENABLE ROW LEVEL SECURITY;
ALTER TABLE submissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE threads ENABLE ROW LEVEL SECURITY;
ALTER TABLE thread_participants ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE announcements ENABLE ROW LEVEL SECURITY;
ALTER TABLE fee_heads ENABLE ROW LEVEL SECURITY;
ALTER TABLE fee_structures ENABLE ROW LEVEL SECURITY;
ALTER TABLE invoices ENABLE ROW LEVEL SECURITY;
ALTER TABLE invoice_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE canteen_menu ENABLE ROW LEVEL SECURITY;
ALTER TABLE wallets ENABLE ROW LEVEL SECURITY;
ALTER TABLE wallet_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE canteen_orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE canteen_order_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE library_books ENABLE ROW LEVEL SECURITY;
ALTER TABLE book_issues ENABLE ROW LEVEL SECURITY;
ALTER TABLE transport_routes ENABLE ROW LEVEL SECURITY;
ALTER TABLE transport_stops ENABLE ROW LEVEL SECURITY;
ALTER TABLE student_transport ENABLE ROW LEVEL SECURITY;
ALTER TABLE hostels ENABLE ROW LEVEL SECURITY;
ALTER TABLE hostel_rooms ENABLE ROW LEVEL SECURITY;
ALTER TABLE room_allocations ENABLE ROW LEVEL SECURITY;
ALTER TABLE calendar_events ENABLE ROW LEVEL SECURITY;

-- =============================================
-- TENANT POLICIES
-- =============================================

-- Super admins can see all tenants
CREATE POLICY "Super admins view all tenants"
ON tenants FOR SELECT
USING (public.has_role('super_admin'));

-- Users can view their own tenant
CREATE POLICY "Users view own tenant"
ON tenants FOR SELECT
USING (id = public.tenant_id());

-- Super admins can manage tenants
CREATE POLICY "Super admins manage tenants"
ON tenants FOR ALL
USING (public.has_role('super_admin'));

-- =============================================
-- USER POLICIES
-- =============================================

CREATE POLICY "Users view users in tenant"
ON users FOR SELECT
USING (tenant_id = public.tenant_id() OR id = auth.uid());

CREATE POLICY "Users update own profile"
ON users FOR UPDATE
USING (id = auth.uid());

CREATE POLICY "Admins manage users"
ON users FOR ALL
USING (tenant_id = public.tenant_id() AND public.is_admin());

-- =============================================
-- ACADEMIC STRUCTURE POLICIES
-- =============================================

-- Read access for all authenticated users in tenant
CREATE POLICY "View academic years"
ON academic_years FOR SELECT
USING (tenant_id = public.tenant_id());

CREATE POLICY "Admins manage academic years"
ON academic_years FOR ALL
USING (tenant_id = public.tenant_id() AND public.is_admin());

CREATE POLICY "View terms"
ON terms FOR SELECT
USING (tenant_id = public.tenant_id());

CREATE POLICY "Admins manage terms"
ON terms FOR ALL
USING (tenant_id = public.tenant_id() AND public.is_admin());

CREATE POLICY "View classes"
ON classes FOR SELECT
USING (tenant_id = public.tenant_id());

CREATE POLICY "Admins manage classes"
ON classes FOR ALL
USING (tenant_id = public.tenant_id() AND public.is_admin());

CREATE POLICY "View sections"
ON sections FOR SELECT
USING (tenant_id = public.tenant_id());

CREATE POLICY "Admins manage sections"
ON sections FOR ALL
USING (tenant_id = public.tenant_id() AND public.is_admin());

CREATE POLICY "View subjects"
ON subjects FOR SELECT
USING (tenant_id = public.tenant_id());

CREATE POLICY "Admins manage subjects"
ON subjects FOR ALL
USING (tenant_id = public.tenant_id() AND public.is_admin());

-- =============================================
-- STUDENT POLICIES
-- =============================================

-- Admins and teachers can view students
CREATE POLICY "Staff view students"
ON students FOR SELECT
USING (
  tenant_id = public.tenant_id() AND (
    public.is_admin() OR 
    public.has_role('teacher') OR
    -- Students see themselves
    user_id = auth.uid() OR
    -- Parents see their children
    id IN (
      SELECT sp.student_id FROM student_parents sp
      JOIN parents p ON sp.parent_id = p.id
      WHERE p.user_id = auth.uid()
    )
  )
);

CREATE POLICY "Admins manage students"
ON students FOR ALL
USING (tenant_id = public.tenant_id() AND public.is_admin());

-- =============================================
-- ATTENDANCE POLICIES
-- =============================================

CREATE POLICY "View attendance"
ON attendance FOR SELECT
USING (
  tenant_id = public.tenant_id() AND (
    public.is_admin() OR
    public.has_role('teacher') OR
    -- Students see own
    student_id IN (SELECT id FROM students WHERE user_id = auth.uid()) OR
    -- Parents see children
    student_id IN (
      SELECT sp.student_id FROM student_parents sp
      JOIN parents p ON sp.parent_id = p.id
      WHERE p.user_id = auth.uid()
    )
  )
);

CREATE POLICY "Teachers mark attendance"
ON attendance FOR INSERT
WITH CHECK (
  tenant_id = public.tenant_id() AND (
    public.is_admin() OR public.has_role('teacher')
  )
);

CREATE POLICY "Teachers update attendance"
ON attendance FOR UPDATE
USING (
  tenant_id = public.tenant_id() AND (
    public.is_admin() OR public.has_role('teacher')
  )
);

-- =============================================
-- MARKS POLICIES
-- =============================================

CREATE POLICY "View marks"
ON marks FOR SELECT
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

CREATE POLICY "Teachers manage marks"
ON marks FOR ALL
USING (
  tenant_id = public.tenant_id() AND (
    public.is_admin() OR public.has_role('teacher')
  )
);

-- =============================================
-- FEES POLICIES
-- =============================================

CREATE POLICY "View invoices"
ON invoices FOR SELECT
USING (
  tenant_id = public.tenant_id() AND (
    public.is_admin() OR
    public.has_role('accountant') OR
    student_id IN (SELECT id FROM students WHERE user_id = auth.uid()) OR
    student_id IN (
      SELECT sp.student_id FROM student_parents sp
      JOIN parents p ON sp.parent_id = p.id
      WHERE p.user_id = auth.uid()
    )
  )
);

CREATE POLICY "Accountants manage invoices"
ON invoices FOR ALL
USING (
  tenant_id = public.tenant_id() AND (
    public.is_admin() OR public.has_role('accountant')
  )
);

-- =============================================
-- MESSAGING POLICIES
-- =============================================

CREATE POLICY "View own threads"
ON threads FOR SELECT
USING (
  tenant_id = public.tenant_id() AND (
    created_by = auth.uid() OR
    id IN (SELECT thread_id FROM thread_participants WHERE user_id = auth.uid())
  )
);

CREATE POLICY "Create threads"
ON threads FOR INSERT
WITH CHECK (
  tenant_id = public.tenant_id() AND created_by = auth.uid()
);

CREATE POLICY "View messages in threads"
ON messages FOR SELECT
USING (
  tenant_id = public.tenant_id() AND
  thread_id IN (SELECT thread_id FROM thread_participants WHERE user_id = auth.uid())
);

CREATE POLICY "Send messages"
ON messages FOR INSERT
WITH CHECK (
  tenant_id = public.tenant_id() AND
  sender_id = auth.uid() AND
  thread_id IN (SELECT thread_id FROM thread_participants WHERE user_id = auth.uid())
);

-- =============================================
-- CANTEEN POLICIES
-- =============================================

CREATE POLICY "View menu"
ON canteen_menu FOR SELECT
USING (tenant_id = public.tenant_id());

CREATE POLICY "Staff manage menu"
ON canteen_menu FOR ALL
USING (
  tenant_id = public.tenant_id() AND (
    public.is_admin() OR public.has_role('canteen_staff')
  )
);

CREATE POLICY "View own wallet"
ON wallets FOR SELECT
USING (
  tenant_id = public.tenant_id() AND (
    user_id = auth.uid() OR
    student_id IN (SELECT id FROM students WHERE user_id = auth.uid()) OR
    student_id IN (
      SELECT sp.student_id FROM student_parents sp
      JOIN parents p ON sp.parent_id = p.id
      WHERE p.user_id = auth.uid()
    )
  )
);

-- =============================================
-- ANNOUNCEMENTS POLICIES  
-- =============================================

CREATE POLICY "View announcements"
ON announcements FOR SELECT
USING (
  tenant_id = public.tenant_id() AND
  is_published = true AND
  (publish_at IS NULL OR publish_at <= NOW()) AND
  (expires_at IS NULL OR expires_at > NOW())
);

CREATE POLICY "Admins manage announcements"
ON announcements FOR ALL
USING (tenant_id = public.tenant_id() AND public.is_admin());
