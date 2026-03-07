-- ============================================================
-- SEED FIX - Round 2 (fixing UUID formats, constraint syntax, FKs)
-- ============================================================

-- ============================================================
-- FIX SECTIONS: Class 12 sections (use valid hex UUIDs)
-- ============================================================
INSERT INTO sections (id, tenant_id, class_id, academic_year_id, name, capacity, class_teacher_id) VALUES
  ('dddddddd-dddd-dddd-dddd-ddddddddddc0', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'cccccccc-cccc-cccc-cccc-cccccccccc12', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'A', 40, NULL),
  ('dddddddd-dddd-dddd-dddd-ddddddddddc1', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'cccccccc-cccc-cccc-cccc-cccccccccc12', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'B', 40, NULL)
ON CONFLICT (id) DO NOTHING;

-- ============================================================
-- FIX CLASS_SUBJECTS: cast text to uuid
-- ============================================================
INSERT INTO class_subjects (tenant_id, class_id, subject_id, academic_year_id, is_mandatory)
SELECT
  'a1b2c3d4-e5f6-7890-abcd-ef1234567890'::uuid,
  c.class_id::uuid,
  s.subject_id::uuid,
  'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'::uuid,
  true
FROM (VALUES
  ('cccccccc-cccc-cccc-cccc-cccccccccc01'),
  ('cccccccc-cccc-cccc-cccc-cccccccccc05'),
  ('cccccccc-cccc-cccc-cccc-cccccccccc06'),
  ('cccccccc-cccc-cccc-cccc-cccccccccc07'),
  ('cccccccc-cccc-cccc-cccc-cccccccccc08'),
  ('cccccccc-cccc-cccc-cccc-cccccccccc09'),
  ('cccccccc-cccc-cccc-cccc-cccccccccc10'),
  ('cccccccc-cccc-cccc-cccc-cccccccccc11'),
  ('cccccccc-cccc-cccc-cccc-cccccccccc12')
) AS c(class_id)
CROSS JOIN (VALUES
  ('eeeeeeee-eeee-eeee-eeee-eeeeeeeeee01'),
  ('eeeeeeee-eeee-eeee-eeee-eeeeeeeeee02'),
  ('eeeeeeee-eeee-eeee-eeee-eeeeeeeeee03'),
  ('eeeeeeee-eeee-eeee-eeee-eeeeeeeeee04'),
  ('eeeeeeee-eeee-eeee-eeee-eeeeeeeeee05'),
  ('eeeeeeee-eeee-eeee-eeee-eeeeeeeeee06'),
  ('eeeeeeee-eeee-eeee-eeee-eeeeeeeeee07')
) AS s(subject_id)
ON CONFLICT (class_id, subject_id, academic_year_id) DO NOTHING;

-- ============================================================
-- FIX STUDENT ENROLLMENTS: make sections exist first, then enroll
-- ============================================================
-- Section 8-A and 9-A and 11-A already inserted, re-check then enroll
INSERT INTO student_enrollments (tenant_id, student_id, section_id, academic_year_id, roll_number, status) VALUES
  -- Class 8-A
  ('a1b2c3d4-e5f6-7890-abcd-ef1234567890', '55555555-5555-5555-5555-555555555563', 'dddddddd-dddd-dddd-dddd-dddddddddd80', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '1', 'active'),
  ('a1b2c3d4-e5f6-7890-abcd-ef1234567890', '55555555-5555-5555-5555-555555555564', 'dddddddd-dddd-dddd-dddd-dddddddddd80', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '2', 'active'),
  -- Class 9-A
  ('a1b2c3d4-e5f6-7890-abcd-ef1234567890', '55555555-5555-5555-5555-555555555565', 'dddddddd-dddd-dddd-dddd-dddddddddd90', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '1', 'active'),
  ('a1b2c3d4-e5f6-7890-abcd-ef1234567890', '55555555-5555-5555-5555-555555555566', 'dddddddd-dddd-dddd-dddd-dddddddddd90', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '2', 'active'),
  -- Class 11-A
  ('a1b2c3d4-e5f6-7890-abcd-ef1234567890', '55555555-5555-5555-5555-555555555567', 'dddddddd-dddd-dddd-dddd-dddddddddda0', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '1', 'active'),
  ('a1b2c3d4-e5f6-7890-abcd-ef1234567890', '55555555-5555-5555-5555-555555555568', 'dddddddd-dddd-dddd-dddd-dddddddddda0', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '2', 'active')
ON CONFLICT (student_id, academic_year_id) DO NOTHING;

-- ============================================================
-- FIX MARKS: the trigger needs section_id from student_enrollments
-- New exam subjects (unit test, final) for new students in 10-A
-- The trigger looks up section_id; students 55a-55d ARE in section 10-A
-- so the existing midterm subjects work. The new exam_subject_ids need marks too.
-- First insert marks for unit test exam subjects
-- ============================================================
DO $$
DECLARE
  student_ids uuid[] := ARRAY[
    '55555555-5555-5555-5555-555555555555'::uuid,
    '55555555-5555-5555-5555-555555555556'::uuid,
    '55555555-5555-5555-5555-555555555557'::uuid,
    '55555555-5555-5555-5555-555555555558'::uuid,
    '55555555-5555-5555-5555-555555555559'::uuid,
    '55555555-5555-5555-5555-55555555555a'::uuid,
    '55555555-5555-5555-5555-55555555555b'::uuid,
    '55555555-5555-5555-5555-55555555555c'::uuid,
    '55555555-5555-5555-5555-55555555555d'::uuid
  ];
  sid uuid;
  es_id uuid;
  unit_test_es uuid[];
  base_marks numeric;
  s_idx integer;
BEGIN
  -- Get exam subject IDs for unit test (exam 77777778)
  SELECT array_agg(id) INTO unit_test_es
  FROM exam_subjects
  WHERE exam_id = '77777777-7777-7777-7777-777777777778';

  IF unit_test_es IS NOT NULL THEN
    s_idx := 1;
    FOREACH sid IN ARRAY student_ids LOOP
      FOREACH es_id IN ARRAY unit_test_es LOOP
        base_marks := 25 + (s_idx * 2) + (floor(random() * 10))::integer;
        IF base_marks > 50 THEN base_marks := 50; END IF;
        INSERT INTO marks (tenant_id, exam_subject_id, student_id, marks_obtained, entered_by)
        VALUES (
          'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
          es_id, sid, base_marks,
          '22222222-2222-2222-2222-222222222222'
        ) ON CONFLICT (exam_subject_id, student_id) DO NOTHING;
      END LOOP;
      s_idx := s_idx + 1;
    END LOOP;
  END IF;
END $$;

-- ============================================================
-- FEE STRUCTURES (correct ON CONFLICT syntax)
-- ============================================================
INSERT INTO fee_structures (tenant_id, academic_year_id, class_id, fee_head_id, amount, due_date, is_mandatory) VALUES
  ('a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'cccccccc-cccc-cccc-cccc-cccccccccc10', '99999999-9999-9999-9999-999999999901', 15000.00, '2024-05-10', true),
  ('a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'cccccccc-cccc-cccc-cccc-cccccccccc10', '99999999-9999-9999-9999-999999999902',  3000.00, '2024-05-10', false),
  ('a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'cccccccc-cccc-cccc-cccc-cccccccccc10', '99999999-9999-9999-9999-999999999903',  2000.00, '2024-05-10', false),
  ('a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'cccccccc-cccc-cccc-cccc-cccccccccc05', '99999999-9999-9999-9999-999999999901', 12000.00, '2024-05-10', true),
  ('a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'cccccccc-cccc-cccc-cccc-cccccccccc05', '99999999-9999-9999-9999-999999999902',  2500.00, '2024-05-10', false)
ON CONFLICT (academic_year_id, class_id, fee_head_id, (COALESCE(term_id, '00000000-0000-0000-0000-000000000000'::uuid))) DO NOTHING;

-- ============================================================
-- INVOICES (use valid UUID format: all hex, proper length)
-- ============================================================
INSERT INTO invoices (id, tenant_id, invoice_number, student_id, academic_year_id, term_id, total_amount, discount_amount, paid_amount, due_date, status, generated_by) VALUES
  ('aa000001-0001-0001-0001-000000000001', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'INV-2024-001', '55555555-5555-5555-5555-555555555555', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbb01', 20000, 0,     20000, '2024-05-10', 'paid',    '11111111-1111-1111-1111-111111111111'),
  ('aa000001-0001-0001-0001-000000000002', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'INV-2024-002', '55555555-5555-5555-5555-555555555556', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbb01', 20000, 0,     20000, '2024-05-10', 'paid',    '11111111-1111-1111-1111-111111111111'),
  ('aa000001-0001-0001-0001-000000000003', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'INV-2024-003', '55555555-5555-5555-5555-555555555557', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbb01', 20000, 1000, 19000, '2024-05-10', 'paid',    '11111111-1111-1111-1111-111111111111'),
  ('aa000001-0001-0001-0001-000000000004', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'INV-2024-004', '55555555-5555-5555-5555-555555555558', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbb01', 20000, 0,         0, '2024-05-10', 'overdue', '11111111-1111-1111-1111-111111111111'),
  ('aa000001-0001-0001-0001-000000000005', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'INV-2024-005', '55555555-5555-5555-5555-555555555559', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbb01', 20000, 0,     10000, '2024-05-10', 'partial', '11111111-1111-1111-1111-111111111111'),
  ('aa000001-0001-0001-0001-000000000006', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'INV-2024-006', '55555555-5555-5555-5555-55555555555a', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbb01', 20000, 0,     20000, '2024-05-10', 'paid',    '11111111-1111-1111-1111-111111111111'),
  ('aa000001-0001-0001-0001-000000000007', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'INV-2024-007', '55555555-5555-5555-5555-55555555555b', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbb01', 20000, 0,         0, '2024-05-10', 'pending', '11111111-1111-1111-1111-111111111111'),
  ('aa000001-0001-0001-0001-000000000008', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'INV-2024-008', '55555555-5555-5555-5555-55555555555c', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbb01', 20000, 2000, 18000, '2024-05-10', 'paid',    '11111111-1111-1111-1111-111111111111'),
  ('aa000001-0001-0001-0001-000000000009', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'INV-2024-009', '55555555-5555-5555-5555-55555555555d', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbb01', 20000, 0,     20000, '2024-05-10', 'paid',    '11111111-1111-1111-1111-111111111111'),
  ('aa000001-0001-0001-0001-000000000010', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'INV-2024-010', '55555555-5555-5555-5555-55555555555e', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbb01', 20000, 0,         0, '2024-07-10', 'overdue', '11111111-1111-1111-1111-111111111111')
ON CONFLICT ON CONSTRAINT idx_invoices_number DO NOTHING;

-- ============================================================
-- LIBRARY BOOKS (valid UUIDs)
-- ============================================================
INSERT INTO library_books (id, tenant_id, isbn, title, author, publisher, category, edition, publication_year, total_copies, available_copies, shelf_location, description) VALUES
  ('bbbb0001-0001-0001-0001-000000000001', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', '978-0-13-468599-1', 'Introduction to Algorithms',           'Thomas H. Cormen',  'MIT Press',       'Computer Science', '4th',             2022, 3,  2, 'CS-A1',   'Comprehensive introduction to computer algorithms'),
  ('bbbb0001-0001-0001-0001-000000000002', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', '978-0-06-112008-4', 'To Kill a Mockingbird',                'Harper Lee',        'HarperCollins',   'Fiction',          '1st',             1960, 5,  5, 'FIC-B2',  'Classic American novel about racial injustice'),
  ('bbbb0001-0001-0001-0001-000000000003', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', '978-0-19-953592-3', 'Oxford Dictionary of Science',         'Oxford Univ Press', 'OUP',             'Reference',        '7th',             2017, 2,  2, 'REF-C1',  'Comprehensive science reference'),
  ('bbbb0001-0001-0001-0001-000000000004', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', '978-81-7387-073-3', 'NCERT Mathematics Class 10',           'NCERT',             'NCERT',           'Textbook',         'Latest',          2023, 10, 8, 'TB-D1',   'CBSE Mathematics textbook for Class 10'),
  ('bbbb0001-0001-0001-0001-000000000005', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', '978-81-7387-074-0', 'NCERT Science Class 10',               'NCERT',             'NCERT',           'Textbook',         'Latest',          2023, 10, 9, 'TB-D2',   'CBSE Science textbook for Class 10'),
  ('bbbb0001-0001-0001-0001-000000000006', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', '978-0-7432-7357-1', 'The Alchemist',                        'Paulo Coelho',      'HarperCollins',   'Fiction',          'Anniversary',     2014, 4,  3, 'FIC-E3',  'Philosophical novel about following ones dreams'),
  ('bbbb0001-0001-0001-0001-000000000007', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', '978-0-14-028329-7', 'Animal Farm',                          'George Orwell',     'Penguin Books',   'Fiction',          '1st',             1945, 3,  3, 'FIC-F4',  'Allegorical novella about totalitarianism'),
  ('bbbb0001-0001-0001-0001-000000000008', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', '978-0-306-40615-7', 'A Brief History of Time',              'Stephen Hawking',   'Bantam Books',    'Science',          '10th Anniversary',1998, 2,  2, 'SCI-G5',  'Cosmology for the general reader'),
  ('bbbb0001-0001-0001-0001-000000000009', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', '978-81-291-1947-3', 'Wings of Fire',                        'APJ Abdul Kalam',   'Universities Press','Biography',      '1st',             1999, 5,  4, 'BIO-H6',  'Autobiography of Dr. APJ Abdul Kalam'),
  ('bbbb0001-0001-0001-0001-000000000010', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', '978-0-525-55360-5', 'The Fault in Our Stars',               'John Green',        'Dutton Books',    'Fiction',          '1st',             2012, 3,  3, 'FIC-I7',  'Young adult novel about two teenage cancer patients'),
  ('bbbb0001-0001-0001-0001-000000000011', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', '978-0-316-76948-0', 'The Catcher in the Rye',               'J.D. Salinger',     'Little Brown',    'Fiction',          '1st',             1951, 2,  2, 'FIC-J8',  'Coming-of-age story of Holden Caulfield'),
  ('bbbb0001-0001-0001-0001-000000000012', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', '978-81-7387-100-6', 'NCERT History Class 10',               'NCERT',             'NCERT',           'Textbook',         'Latest',          2023, 8,  7, 'TB-K2',   'CBSE History textbook for Class 10'),
  ('bbbb0001-0001-0001-0001-000000000013', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', '978-0-439-02352-8', 'Harry Potter Sorcerers Stone',         'J.K. Rowling',      'Scholastic',      'Fiction',          '1st',             1998, 5,  5, 'FIC-L9',  'First book in the Harry Potter series'),
  ('bbbb0001-0001-0001-0001-000000000014', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', '978-0-14-028381-5', 'Nineteen Eighty-Four',                 'George Orwell',     'Penguin Books',   'Fiction',          '1st',             1949, 2,  2, 'FIC-M0',  'Dystopian novel about surveillance and totalitarianism'),
  ('bbbb0001-0001-0001-0001-000000000015', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', '978-0-679-72020-1', 'The Great Gatsby',                     'F. Scott Fitzgerald','Scribner',       'Fiction',          '1st',             1925, 3,  3, 'FIC-N1',  'Classic American novel set in the Jazz Age'),
  ('bbbb0001-0001-0001-0001-000000000016', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', '978-81-7387-200-3', 'NCERT Chemistry Class 12',             'NCERT',             'NCERT',           'Textbook',         'Latest',          2023, 6,  5, 'TB-O3',   'CBSE Chemistry textbook for Class 12'),
  ('bbbb0001-0001-0001-0001-000000000017', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', '978-0-7432-7356-4', 'The Secret',                           'Rhonda Byrne',      'Atria Books',     'Self-Help',        '1st',             2006, 3,  3, 'SH-P4',   'Inspirational book about the law of attraction'),
  ('bbbb0001-0001-0001-0001-000000000018', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', '978-0-674-02579-1', 'The Story of Mathematics',             'Anne Rooney',       'Arcturus',        'Mathematics',      '1st',             2008, 2,  2, 'MATH-Q5', 'History and development of mathematics'),
  ('bbbb0001-0001-0001-0001-000000000019', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', '978-81-222-0049-9', 'Malgudi Days',                         'R.K. Narayan',      'Penguin India',   'Fiction',          'Penguin Ed.',     2006, 4,  4, 'FIC-R6',  'Short stories set in fictional town of Malgudi'),
  ('bbbb0001-0001-0001-0001-000000000020', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', '978-0-521-63720-4', 'Physics for Scientists and Engineers',  'Serway and Jewett', 'Cengage',         'Physics',          '10th',            2018, 4,  3, 'SCI-S7',  'Comprehensive physics textbook for advanced students')
ON CONFLICT (id) DO NOTHING;

-- ============================================================
-- TRANSPORT ROUTES (valid UUIDs)
-- ============================================================
INSERT INTO transport_routes (id, tenant_id, name, code, vehicle_number, driver_name, driver_phone, capacity, fare_per_month, is_active) VALUES
  ('cc000001-0001-0001-0001-000000000001', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'Route A - Andheri West',   'RT-A', 'MH-01-AB-1234', 'Ramesh Yadav', '9988776655', 40, 2500.00, true),
  ('cc000001-0001-0001-0001-000000000002', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'Route B - Bandra East',    'RT-B', 'MH-01-CD-5678', 'Suresh Patil', '9977665544', 35, 2000.00, true),
  ('cc000001-0001-0001-0001-000000000003', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'Route C - Borivali North', 'RT-C', 'MH-01-EF-9012', 'Dinesh Gupta', '9966554433', 45, 3000.00, true)
ON CONFLICT (id) DO NOTHING;

-- ============================================================
-- HOSTELS (valid UUIDs)
-- ============================================================
INSERT INTO hostels (id, tenant_id, name, type, address, contact_number, total_rooms, total_capacity, fee_per_month, is_active) VALUES
  ('dd000001-0001-0001-0001-000000000001', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'Boys Hostel Block A',  'boys',  'School Campus, East Wing', '022-12345678', 6, 24, 8000.00, true),
  ('dd000001-0001-0001-0001-000000000002', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'Girls Hostel Block B', 'girls', 'School Campus, West Wing', '022-87654321', 4, 16, 8000.00, true)
ON CONFLICT (id) DO NOTHING;

-- ============================================================
-- HOSTEL ROOMS (valid UUIDs, using proper ON CONFLICT syntax)
-- ============================================================
INSERT INTO hostel_rooms (id, tenant_id, hostel_id, room_number, floor, room_type, capacity, occupied, amenities, is_available) VALUES
  ('ee000001-0001-0001-0001-000000000001', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'dd000001-0001-0001-0001-000000000001', '101', 1, 'double', 4, 3, '["WiFi","Attached Bathroom","Study Table"]',  true),
  ('ee000001-0001-0001-0001-000000000002', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'dd000001-0001-0001-0001-000000000001', '102', 1, 'double', 4, 4, '["WiFi","Shared Bathroom"]',                   false),
  ('ee000001-0001-0001-0001-000000000003', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'dd000001-0001-0001-0001-000000000001', '103', 1, 'single', 2, 1, '["WiFi","Attached Bathroom","AC"]',             true),
  ('ee000001-0001-0001-0001-000000000004', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'dd000001-0001-0001-0001-000000000001', '201', 2, 'double', 4, 2, '["WiFi","Shared Bathroom","Study Table"]',     true),
  ('ee000001-0001-0001-0001-000000000005', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'dd000001-0001-0001-0001-000000000001', '202', 2, 'double', 4, 4, '["WiFi","Attached Bathroom"]',                  false),
  ('ee000001-0001-0001-0001-000000000006', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'dd000001-0001-0001-0001-000000000001', '203', 2, 'triple', 6, 5, '["WiFi","Shared Bathroom"]',                    true),
  ('ee000001-0001-0001-0001-000000000007', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'dd000001-0001-0001-0001-000000000002', '101', 1, 'double', 4, 3, '["WiFi","Attached Bathroom","Wardrobe"]',      true),
  ('ee000001-0001-0001-0001-000000000008', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'dd000001-0001-0001-0001-000000000002', '102', 1, 'single', 2, 2, '["WiFi","Attached Bathroom","AC","Wardrobe"]', false),
  ('ee000001-0001-0001-0001-000000000009', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'dd000001-0001-0001-0001-000000000002', '103', 1, 'double', 4, 1, '["WiFi","Shared Bathroom"]',                    true),
  ('ee000001-0001-0001-0001-000000000010', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'dd000001-0001-0001-0001-000000000002', '201', 2, 'triple', 6, 4, '["WiFi","Attached Bathroom","Study Room"]',    true)
ON CONFLICT (hostel_id, room_number) DO NOTHING;

-- ============================================================
-- CANTEEN MENU (valid UUIDs)
-- ============================================================
INSERT INTO canteen_menu (id, tenant_id, name, description, price, category, is_available, available_days) VALUES
  ('ff000001-0001-0001-0001-000000000001', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'Idli Sambar',       'Steamed rice cakes with lentil soup and coconut chutney', 30.00, 'Breakfast', true, '{1,2,3,4,5}'),
  ('ff000001-0001-0001-0001-000000000002', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'Poha',              'Flattened rice with peas, onions and spices',             25.00, 'Breakfast', true, '{1,2,3,4,5}'),
  ('ff000001-0001-0001-0001-000000000003', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'Bread Butter',      'White/Brown bread with butter and jam',                   20.00, 'Breakfast', true, '{1,2,3,4,5}'),
  ('ff000001-0001-0001-0001-000000000004', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'Dal Rice',          'Yellow lentil soup with steamed rice',                    50.00, 'Lunch',     true, '{1,2,3,4,5}'),
  ('ff000001-0001-0001-0001-000000000005', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'Rajma Chawal',      'Kidney beans curry with steamed rice',                    60.00, 'Lunch',     true, '{1,3,5}'),
  ('ff000001-0001-0001-0001-000000000006', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'Chole Bhature',     'Chickpea curry with fried bread',                         70.00, 'Lunch',     true, '{2,4}'),
  ('ff000001-0001-0001-0001-000000000007', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'Veg Thali',         'Complete meal with roti, rice, dal, sabzi, and salad',    85.00, 'Lunch',     true, '{1,2,3,4,5}'),
  ('ff000001-0001-0001-0001-000000000008', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'Aloo Paratha',      'Potato stuffed flatbread with curd and butter',           40.00, 'Breakfast', true, '{1,3,5}'),
  ('ff000001-0001-0001-0001-000000000009', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'Masala Chai',       'Spiced Indian tea with milk',                             15.00, 'Beverages', true, '{1,2,3,4,5}'),
  ('ff000001-0001-0001-0001-000000000010', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'Fresh Fruit Juice', 'Seasonal fruit juice without sugar',                      35.00, 'Beverages', true, '{1,2,3,4,5}'),
  ('ff000001-0001-0001-0001-000000000011', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'Samosa',            'Crispy pastry filled with spiced potatoes and peas',      20.00, 'Snacks',    true, '{1,2,3,4,5}'),
  ('ff000001-0001-0001-0001-000000000012', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'Banana',            'Fresh ripe banana',                                       10.00, 'Fruits',    true, '{1,2,3,4,5}'),
  ('ff000001-0001-0001-0001-000000000013', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'Upma',              'Semolina cooked with vegetables and spices',              30.00, 'Breakfast', true, '{2,4}'),
  ('ff000001-0001-0001-0001-000000000014', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'Egg Sandwich',      'Boiled egg sandwich with vegetables',                     35.00, 'Snacks',    true, '{1,2,3,4,5}'),
  ('ff000001-0001-0001-0001-000000000015', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'Cold Milk',         'Chilled full-fat milk',                                   20.00, 'Beverages', true, '{1,2,3,4,5}')
ON CONFLICT (id) DO NOTHING;

-- ============================================================
-- TIMETABLE SLOTS (valid UUIDs)
-- ============================================================
INSERT INTO timetable_slots (id, tenant_id, name, start_time, end_time, slot_type, sequence_order) VALUES
  ('ab000001-0001-0001-0001-000000000001', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'Period 1',    '08:00', '08:45', 'class',  1),
  ('ab000001-0001-0001-0001-000000000002', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'Period 2',    '08:45', '09:30', 'class',  2),
  ('ab000001-0001-0001-0001-000000000003', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'Break',       '09:30', '09:45', 'break',  3),
  ('ab000001-0001-0001-0001-000000000004', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'Period 3',    '09:45', '10:30', 'class',  4),
  ('ab000001-0001-0001-0001-000000000005', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'Period 4',    '10:30', '11:15', 'class',  5),
  ('ab000001-0001-0001-0001-000000000006', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'Lunch Break', '11:15', '12:00', 'lunch',  6),
  ('ab000001-0001-0001-0001-000000000007', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'Period 5',    '12:00', '12:45', 'class',  7),
  ('ab000001-0001-0001-0001-000000000008', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'Period 6',    '12:45', '13:30', 'class',  8),
  ('ab000001-0001-0001-0001-000000000009', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'Period 7',    '13:30', '14:15', 'class',  9),
  ('ab000001-0001-0001-0001-000000000010', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'Period 8',    '14:15', '15:00', 'class', 10)
ON CONFLICT (id) DO NOTHING;

-- ============================================================
-- TIMETABLES for Class 10-A (using valid slot UUIDs)
-- ============================================================
INSERT INTO timetables (tenant_id, section_id, subject_id, teacher_id, slot_id, day_of_week, academic_year_id, room_number) VALUES
  -- Monday (1)
  ('a1b2c3d4-e5f6-7890-abcd-ef1234567890','dddddddd-dddd-dddd-dddd-dddddddddd01','eeeeeeee-eeee-eeee-eeee-eeeeeeeeee01','22222222-2222-2222-2222-222222222222','ab000001-0001-0001-0001-000000000001',1,'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa','10A'),
  ('a1b2c3d4-e5f6-7890-abcd-ef1234567890','dddddddd-dddd-dddd-dddd-dddddddddd01','eeeeeeee-eeee-eeee-eeee-eeeeeeeeee02','22222222-2222-2222-2222-222222222222','ab000001-0001-0001-0001-000000000002',1,'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa','10A'),
  ('a1b2c3d4-e5f6-7890-abcd-ef1234567890','dddddddd-dddd-dddd-dddd-dddddddddd01','eeeeeeee-eeee-eeee-eeee-eeeeeeeeee03','22222222-2222-2222-2222-222222222222','ab000001-0001-0001-0001-000000000004',1,'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa','10A'),
  ('a1b2c3d4-e5f6-7890-abcd-ef1234567890','dddddddd-dddd-dddd-dddd-dddddddddd01','eeeeeeee-eeee-eeee-eeee-eeeeeeeeee04','22222222-2222-2222-2222-222222222222','ab000001-0001-0001-0001-000000000005',1,'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa','10A'),
  ('a1b2c3d4-e5f6-7890-abcd-ef1234567890','dddddddd-dddd-dddd-dddd-dddddddddd01','eeeeeeee-eeee-eeee-eeee-eeeeeeeeee05','22222222-2222-2222-2222-222222222222','ab000001-0001-0001-0001-000000000007',1,'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa','10A'),
  ('a1b2c3d4-e5f6-7890-abcd-ef1234567890','dddddddd-dddd-dddd-dddd-dddddddddd01','eeeeeeee-eeee-eeee-eeee-eeeeeeeeee06','22222222-2222-2222-2222-222222222222','ab000001-0001-0001-0001-000000000008',1,'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa','Lab'),
  -- Tuesday (2)
  ('a1b2c3d4-e5f6-7890-abcd-ef1234567890','dddddddd-dddd-dddd-dddd-dddddddddd01','eeeeeeee-eeee-eeee-eeee-eeeeeeeeee03','22222222-2222-2222-2222-222222222222','ab000001-0001-0001-0001-000000000001',2,'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa','10A'),
  ('a1b2c3d4-e5f6-7890-abcd-ef1234567890','dddddddd-dddd-dddd-dddd-dddddddddd01','eeeeeeee-eeee-eeee-eeee-eeeeeeeeee01','22222222-2222-2222-2222-222222222222','ab000001-0001-0001-0001-000000000002',2,'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa','10A'),
  ('a1b2c3d4-e5f6-7890-abcd-ef1234567890','dddddddd-dddd-dddd-dddd-dddddddddd01','eeeeeeee-eeee-eeee-eeee-eeeeeeeeee05','22222222-2222-2222-2222-222222222222','ab000001-0001-0001-0001-000000000004',2,'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa','10A'),
  ('a1b2c3d4-e5f6-7890-abcd-ef1234567890','dddddddd-dddd-dddd-dddd-dddddddddd01','eeeeeeee-eeee-eeee-eeee-eeeeeeeeee02','22222222-2222-2222-2222-222222222222','ab000001-0001-0001-0001-000000000005',2,'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa','10A'),
  ('a1b2c3d4-e5f6-7890-abcd-ef1234567890','dddddddd-dddd-dddd-dddd-dddddddddd01','eeeeeeee-eeee-eeee-eeee-eeeeeeeeee04','22222222-2222-2222-2222-222222222222','ab000001-0001-0001-0001-000000000007',2,'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa','10A'),
  ('a1b2c3d4-e5f6-7890-abcd-ef1234567890','dddddddd-dddd-dddd-dddd-dddddddddd01','eeeeeeee-eeee-eeee-eeee-eeeeeeeeee07','22222222-2222-2222-2222-222222222222','ab000001-0001-0001-0001-000000000008',2,'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa','Playground'),
  -- Wednesday (3)
  ('a1b2c3d4-e5f6-7890-abcd-ef1234567890','dddddddd-dddd-dddd-dddd-dddddddddd01','eeeeeeee-eeee-eeee-eeee-eeeeeeeeee02','22222222-2222-2222-2222-222222222222','ab000001-0001-0001-0001-000000000001',3,'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa','10A'),
  ('a1b2c3d4-e5f6-7890-abcd-ef1234567890','dddddddd-dddd-dddd-dddd-dddddddddd01','eeeeeeee-eeee-eeee-eeee-eeeeeeeeee04','22222222-2222-2222-2222-222222222222','ab000001-0001-0001-0001-000000000002',3,'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa','10A'),
  ('a1b2c3d4-e5f6-7890-abcd-ef1234567890','dddddddd-dddd-dddd-dddd-dddddddddd01','eeeeeeee-eeee-eeee-eeee-eeeeeeeeee01','22222222-2222-2222-2222-222222222222','ab000001-0001-0001-0001-000000000004',3,'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa','10A'),
  ('a1b2c3d4-e5f6-7890-abcd-ef1234567890','dddddddd-dddd-dddd-dddd-dddddddddd01','eeeeeeee-eeee-eeee-eeee-eeeeeeeeee06','22222222-2222-2222-2222-222222222222','ab000001-0001-0001-0001-000000000005',3,'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa','Lab'),
  ('a1b2c3d4-e5f6-7890-abcd-ef1234567890','dddddddd-dddd-dddd-dddd-dddddddddd01','eeeeeeee-eeee-eeee-eeee-eeeeeeeeee03','22222222-2222-2222-2222-222222222222','ab000001-0001-0001-0001-000000000007',3,'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa','10A'),
  ('a1b2c3d4-e5f6-7890-abcd-ef1234567890','dddddddd-dddd-dddd-dddd-dddddddddd01','eeeeeeee-eeee-eeee-eeee-eeeeeeeeee05','22222222-2222-2222-2222-222222222222','ab000001-0001-0001-0001-000000000008',3,'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa','10A'),
  -- Thursday (4)
  ('a1b2c3d4-e5f6-7890-abcd-ef1234567890','dddddddd-dddd-dddd-dddd-dddddddddd01','eeeeeeee-eeee-eeee-eeee-eeeeeeeeee04','22222222-2222-2222-2222-222222222222','ab000001-0001-0001-0001-000000000001',4,'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa','10A'),
  ('a1b2c3d4-e5f6-7890-abcd-ef1234567890','dddddddd-dddd-dddd-dddd-dddddddddd01','eeeeeeee-eeee-eeee-eeee-eeeeeeeeee03','22222222-2222-2222-2222-222222222222','ab000001-0001-0001-0001-000000000002',4,'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa','10A'),
  ('a1b2c3d4-e5f6-7890-abcd-ef1234567890','dddddddd-dddd-dddd-dddd-dddddddddd01','eeeeeeee-eeee-eeee-eeee-eeeeeeeeee07','22222222-2222-2222-2222-222222222222','ab000001-0001-0001-0001-000000000004',4,'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa','Playground'),
  ('a1b2c3d4-e5f6-7890-abcd-ef1234567890','dddddddd-dddd-dddd-dddd-dddddddddd01','eeeeeeee-eeee-eeee-eeee-eeeeeeeeee01','22222222-2222-2222-2222-222222222222','ab000001-0001-0001-0001-000000000005',4,'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa','10A'),
  ('a1b2c3d4-e5f6-7890-abcd-ef1234567890','dddddddd-dddd-dddd-dddd-dddddddddd01','eeeeeeee-eeee-eeee-eeee-eeeeeeeeee02','22222222-2222-2222-2222-222222222222','ab000001-0001-0001-0001-000000000007',4,'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa','10A'),
  ('a1b2c3d4-e5f6-7890-abcd-ef1234567890','dddddddd-dddd-dddd-dddd-dddddddddd01','eeeeeeee-eeee-eeee-eeee-eeeeeeeeee05','22222222-2222-2222-2222-222222222222','ab000001-0001-0001-0001-000000000008',4,'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa','10A'),
  -- Friday (5)
  ('a1b2c3d4-e5f6-7890-abcd-ef1234567890','dddddddd-dddd-dddd-dddd-dddddddddd01','eeeeeeee-eeee-eeee-eeee-eeeeeeeeee05','22222222-2222-2222-2222-222222222222','ab000001-0001-0001-0001-000000000001',5,'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa','10A'),
  ('a1b2c3d4-e5f6-7890-abcd-ef1234567890','dddddddd-dddd-dddd-dddd-dddddddddd01','eeeeeeee-eeee-eeee-eeee-eeeeeeeeee06','22222222-2222-2222-2222-222222222222','ab000001-0001-0001-0001-000000000002',5,'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa','Lab'),
  ('a1b2c3d4-e5f6-7890-abcd-ef1234567890','dddddddd-dddd-dddd-dddd-dddddddddd01','eeeeeeee-eeee-eeee-eeee-eeeeeeeeee02','22222222-2222-2222-2222-222222222222','ab000001-0001-0001-0001-000000000004',5,'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa','10A'),
  ('a1b2c3d4-e5f6-7890-abcd-ef1234567890','dddddddd-dddd-dddd-dddd-dddddddddd01','eeeeeeee-eeee-eeee-eeee-eeeeeeeeee03','22222222-2222-2222-2222-222222222222','ab000001-0001-0001-0001-000000000005',5,'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa','10A'),
  ('a1b2c3d4-e5f6-7890-abcd-ef1234567890','dddddddd-dddd-dddd-dddd-dddddddddd01','eeeeeeee-eeee-eeee-eeee-eeeeeeeeee01','22222222-2222-2222-2222-222222222222','ab000001-0001-0001-0001-000000000007',5,'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa','10A'),
  ('a1b2c3d4-e5f6-7890-abcd-ef1234567890','dddddddd-dddd-dddd-dddd-dddddddddd01','eeeeeeee-eeee-eeee-eeee-eeeeeeeeee04','22222222-2222-2222-2222-222222222222','ab000001-0001-0001-0001-000000000008',5,'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa','10A')
ON CONFLICT ON CONSTRAINT timetables_section_id_slot_id_day_of_week_academic_year_id_key DO NOTHING;

-- ============================================================
-- ANNOUNCEMENTS (valid UUIDs)
-- ============================================================
INSERT INTO announcements (id, tenant_id, title, content, priority, publish_at, created_by, is_published) VALUES
  ('ac000001-0001-0001-0001-000000000001', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
   'Annual Sports Day - March 15, 2026',
   'We are delighted to announce our Annual Sports Day on March 15, 2026. All students are encouraged to participate in various sports events. Parents are cordially invited to attend. Events include athletics, team sports, and cultural performances. Please report by 8:00 AM.',
   'high', NOW() - INTERVAL '5 days', '11111111-1111-1111-1111-111111111111', true),
  ('ac000001-0001-0001-0001-000000000002', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
   'Parent-Teacher Meeting - March 20, 2026',
   'Parent-Teacher Meeting (PTM) for Classes 9-12 is scheduled for March 20, 2026 from 9:00 AM to 2:00 PM. Parents are requested to meet the class teachers to discuss ward academic progress. Prior appointment booking through the school app is mandatory.',
   'high', NOW() - INTERVAL '3 days', '11111111-1111-1111-1111-111111111111', true),
  ('ac000001-0001-0001-0001-000000000003', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
   'Fee Payment Reminder - Term 3',
   'This is a reminder to all parents that the due date for Term 3 fee payment is March 31, 2026. Please ensure timely payment to avoid late fees. Online payment options are available through the school portal. Contact the accounts office for any queries.',
   'normal', NOW() - INTERVAL '1 day', '11111111-1111-1111-1111-111111111111', true),
  ('ac000001-0001-0001-0001-000000000004', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
   'Summer Vacation Notice 2026',
   'Summer vacation for the academic year 2024-25 will commence from April 5, 2026. School will reopen for the new academic year 2025-26 on June 16, 2026. Result cards will be distributed on the last working day April 4, 2026.',
   'normal', NOW(), '11111111-1111-1111-1111-111111111111', true),
  ('ac000001-0001-0001-0001-000000000005', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
   'New Library Books Available',
   'The school library has received a fresh batch of 50 new books across various genres including fiction, science, history, and reference materials. Students can borrow up to 2 books at a time for 14 days. Visit the library during break or after school hours.',
   'low', NOW() - INTERVAL '2 days', '11111111-1111-1111-1111-111111111111', true)
ON CONFLICT (id) DO NOTHING;

-- ============================================================
-- PAYMENTS (valid UUIDs)
-- ============================================================
INSERT INTO payments (tenant_id, invoice_id, payment_number, amount, payment_method, status, transaction_id, paid_at, received_by, remarks) VALUES
  ('a1b2c3d4-e5f6-7890-abcd-ef1234567890','aa000001-0001-0001-0001-000000000001','PAY-2024-001',20000,'online', 'completed','TXN2024001','2024-05-08 10:00:00+00','11111111-1111-1111-1111-111111111111','Full payment'),
  ('a1b2c3d4-e5f6-7890-abcd-ef1234567890','aa000001-0001-0001-0001-000000000002','PAY-2024-002',20000,'online', 'completed','TXN2024002','2024-05-09 10:00:00+00','11111111-1111-1111-1111-111111111111','Full payment'),
  ('a1b2c3d4-e5f6-7890-abcd-ef1234567890','aa000001-0001-0001-0001-000000000003','PAY-2024-003',19000,'cheque', 'completed','CHQ2024001','2024-05-07 10:00:00+00','11111111-1111-1111-1111-111111111111','After sibling discount'),
  ('a1b2c3d4-e5f6-7890-abcd-ef1234567890','aa000001-0001-0001-0001-000000000005','PAY-2024-005',10000,'cash',   'completed','CASH2024001','2024-05-10 10:00:00+00','11111111-1111-1111-1111-111111111111','Partial payment'),
  ('a1b2c3d4-e5f6-7890-abcd-ef1234567890','aa000001-0001-0001-0001-000000000006','PAY-2024-006',20000,'upi',    'completed','UPI2024006', '2024-05-08 10:00:00+00','11111111-1111-1111-1111-111111111111','Full payment'),
  ('a1b2c3d4-e5f6-7890-abcd-ef1234567890','aa000001-0001-0001-0001-000000000008','PAY-2024-008',18000,'upi',    'completed','UPI2024008', '2024-05-09 10:00:00+00','11111111-1111-1111-1111-111111111111','After merit concession'),
  ('a1b2c3d4-e5f6-7890-abcd-ef1234567890','aa000001-0001-0001-0001-000000000009','PAY-2024-009',20000,'online', 'completed','TXN2024009','2024-05-08 10:00:00+00','11111111-1111-1111-1111-111111111111','Full payment')
ON CONFLICT ON CONSTRAINT idx_payments_number DO NOTHING;

-- ============================================================
-- FINAL VERIFICATION
-- ============================================================
SELECT table_name, row_count FROM (
  SELECT 'academic_years'    AS table_name, count(*) AS row_count FROM academic_years    WHERE tenant_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890' UNION ALL
  SELECT 'terms',                           count(*)              FROM terms              WHERE tenant_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890' UNION ALL
  SELECT 'classes',                         count(*)              FROM classes             WHERE tenant_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890' UNION ALL
  SELECT 'sections',                        count(*)              FROM sections            WHERE tenant_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890' UNION ALL
  SELECT 'subjects',                        count(*)              FROM subjects            WHERE tenant_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890' UNION ALL
  SELECT 'class_subjects',                  count(*)              FROM class_subjects      WHERE tenant_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890' UNION ALL
  SELECT 'staff',                           count(*)              FROM staff               WHERE tenant_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890' UNION ALL
  SELECT 'teacher_assignments',             count(*)              FROM teacher_assignments WHERE tenant_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890' UNION ALL
  SELECT 'students',                        count(*)              FROM students            WHERE tenant_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890' UNION ALL
  SELECT 'student_enrollments',             count(*)              FROM student_enrollments WHERE tenant_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890' UNION ALL
  SELECT 'parents',                         count(*)              FROM parents             WHERE tenant_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890' UNION ALL
  SELECT 'student_parents',                 count(*)              FROM student_parents     UNION ALL
  SELECT 'attendance',                      count(*)              FROM attendance          WHERE tenant_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890' UNION ALL
  SELECT 'exams',                           count(*)              FROM exams               WHERE tenant_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890' UNION ALL
  SELECT 'exam_subjects',                   count(*)              FROM exam_subjects       WHERE tenant_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890' UNION ALL
  SELECT 'marks',                           count(*)              FROM marks               WHERE tenant_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890' UNION ALL
  SELECT 'fee_heads',                       count(*)              FROM fee_heads           WHERE tenant_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890' UNION ALL
  SELECT 'fee_structures',                  count(*)              FROM fee_structures      WHERE tenant_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890' UNION ALL
  SELECT 'invoices',                        count(*)              FROM invoices            WHERE tenant_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890' UNION ALL
  SELECT 'payments',                        count(*)              FROM payments            WHERE tenant_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890' UNION ALL
  SELECT 'library_books',                   count(*)              FROM library_books       WHERE tenant_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890' UNION ALL
  SELECT 'transport_routes',                count(*)              FROM transport_routes    WHERE tenant_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890' UNION ALL
  SELECT 'hostels',                         count(*)              FROM hostels             WHERE tenant_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890' UNION ALL
  SELECT 'hostel_rooms',                    count(*)              FROM hostel_rooms        WHERE tenant_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890' UNION ALL
  SELECT 'canteen_menu',                    count(*)              FROM canteen_menu        WHERE tenant_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890' UNION ALL
  SELECT 'timetable_slots',                 count(*)              FROM timetable_slots     WHERE tenant_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890' UNION ALL
  SELECT 'timetables',                      count(*)              FROM timetables          WHERE tenant_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890' UNION ALL
  SELECT 'announcements',                   count(*)              FROM announcements       WHERE tenant_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'
) t ORDER BY table_name;
