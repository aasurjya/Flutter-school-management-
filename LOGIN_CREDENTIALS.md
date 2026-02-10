# 🔐 Login Credentials - Demo School
**EduMaster Pro - Test User Accounts**

---

## 🚀 Quick Start Guide

### Step 1: Start Docker & Supabase
```bash
# Open Docker Desktop (manually)
# Wait for Docker to fully start

# Then run:
cd /Users/ihub-devs/cascade-projects/School-Management-Flutter
supabase start
```

### Step 2: Reset Database & Load Test Data
```bash
# Apply all migrations and seed data
supabase db reset

# Load test users
psql -h localhost -p 54322 -U postgres -d postgres -f supabase/seed_test_users_with_auth.sql
```

### Step 3: Create Auth Users via Supabase Dashboard
```bash
# Open Supabase Studio
open http://localhost:54323

# Go to Authentication > Users
# Click "Add User" for each user below
# Use Email + Password, disable email confirmation
```

---

## 👥 All Test User Accounts

**Default Password for ALL users:** `Demo@2026`

### 🔴 **SUPER ADMIN** - Full System Access

| Field | Value |
|-------|-------|
| **Role** | Super Admin |
| **Email** | superadmin@demoschool.edu |
| **Password** | Demo@2026 |
| **User ID** | 20000000-0000-0000-0000-000000000001 |
| **Access Level** | Complete system access |
| **Use Case** | System configuration, all data access |

**Permissions:**
- ✅ All tenant data
- ✅ User management
- ✅ System settings
- ✅ Audit logs
- ✅ ML models
- ✅ All reports

---

### 🟠 **TENANT ADMIN** - School Administrator

| Field | Value |
|-------|-------|
| **Role** | Tenant Admin |
| **Email** | admin@demoschool.edu |
| **Password** | Demo@2026 |
| **User ID** | 20000000-0000-0000-0000-000000000002 |
| **Access Level** | Full school access |
| **Use Case** | School administration, all features |

**Permissions:**
- ✅ All school data
- ✅ User management (within tenant)
- ✅ Reports & analytics
- ✅ Settings
- ✅ Fee management
- ✅ Student management

---

### 🟡 **PRINCIPAL** - Academic Head

| Field | Value |
|-------|-------|
| **Role** | Principal |
| **Email** | principal@demoschool.edu |
| **Password** | Demo@2026 |
| **User ID** | 20000000-0000-0000-0000-000000000003 |
| **Name** | Dr. Principal Smith |
| **Access Level** | Academic management |
| **Use Case** | Academic oversight, reports |

**Permissions:**
- ✅ Student academic data
- ✅ Teacher management
- ✅ Attendance oversight
- ✅ Performance reports
- ✅ Behavior tracking
- ✅ Academic planning

---

### 🟢 **TEACHERS** - Teaching Staff (3 accounts)

#### Teacher 1 - Math Teacher
| Field | Value |
|-------|-------|
| **Role** | Teacher |
| **Email** | teacher1@demoschool.edu |
| **Password** | Demo@2026 |
| **User ID** | 20000000-0000-0000-0000-000000000010 |
| **Name** | John Teacher |
| **Employee ID** | EMP001 |
| **Subject** | Mathematics |
| **Use Case** | Grade entry, attendance marking |

#### Teacher 2 - English Teacher
| Field | Value |
|-------|-------|
| **Role** | Teacher |
| **Email** | teacher2@demoschool.edu |
| **Password** | Demo@2026 |
| **User ID** | 20000000-0000-0000-0000-000000000011 |
| **Name** | Mary Teacher |
| **Employee ID** | EMP002 |
| **Subject** | English |

#### Teacher 3 - Science Teacher
| Field | Value |
|-------|-------|
| **Role** | Teacher |
| **Email** | teacher3@demoschool.edu |
| **Password** | Demo@2026 |
| **User ID** | 20000000-0000-0000-0000-000000000012 |
| **Name** | Bob Teacher |
| **Employee ID** | EMP003 |
| **Subject** | Science |

**Teacher Permissions:**
- ✅ View assigned class students
- ✅ Mark attendance
- ✅ Enter grades
- ✅ Create assignments
- ✅ Record behavior incidents
- ✅ View student reports

---

### 💰 **ACCOUNTANT** - Finance Manager

| Field | Value |
|-------|-------|
| **Role** | Accountant |
| **Email** | accountant@demoschool.edu |
| **Password** | Demo@2026 |
| **User ID** | 20000000-0000-0000-0000-000000000020 |
| **Name** | Alice Accountant |
| **Employee ID** | EMP010 |
| **Department** | Finance |
| **Use Case** | Fee management, payment tracking |

**Permissions:**
- ✅ All fee data
- ✅ Invoice generation
- ✅ Payment tracking
- ✅ Payment plans
- ✅ Concessions management
- ✅ Financial reports
- ❌ Academic data (restricted)
- ❌ Student personal info (restricted)

---

### 🎓 **STUDENTS** - Student Accounts (5 accounts)

#### Student 1 - Grade 1
| Field | Value |
|-------|-------|
| **Role** | Student |
| **Email** | student1@demoschool.edu |
| **Password** | Demo@2026 |
| **User ID** | 20000000-0000-0000-0000-000000000100 |
| **Name** | Emma Student |
| **Admission Number** | ADM2025001 |
| **Grade** | Grade 1, Section A |
| **Roll Number** | 001 |

#### Student 2 - Grade 1
| Field | Value |
|-------|-------|
| **Email** | student2@demoschool.edu |
| **Password** | Demo@2026 |
| **Name** | Liam Student |
| **Admission Number** | ADM2025002 |
| **Grade** | Grade 1, Section A |
| **Roll Number** | 002 |

#### Student 3 - Grade 2
| Field | Value |
|-------|-------|
| **Email** | student3@demoschool.edu |
| **Password** | Demo@2026 |
| **Name** | Olivia Student |
| **Admission Number** | ADM2025003 |
| **Grade** | Grade 2, Section A |
| **Roll Number** | 003 |

#### Student 4 - Grade 10 (At-Risk Student)
| Field | Value |
|-------|-------|
| **Email** | student4@demoschool.edu |
| **Password** | Demo@2026 |
| **Name** | Noah Student |
| **Admission Number** | ADM2025004 |
| **Grade** | Grade 10, Section A |
| **Roll Number** | 004 |
| **Special Notes** | Has AI prediction showing high dropout risk |

#### Student 5 - Grade 10
| Field | Value |
|-------|-------|
| **Email** | student5@demoschool.edu |
| **Password** | Demo@2026 |
| **Name** | Ava Student |
| **Admission Number** | ADM2025005 |
| **Grade** | Grade 10, Section A |
| **Roll Number** | 005 |

**Student Permissions:**
- ✅ View own grades
- ✅ View own attendance
- ✅ View assignments
- ✅ Submit assignments
- ✅ View fee invoices
- ✅ View own predictions (AI)
- ❌ Other students' data

---

### 👨‍👩‍👧 **PARENTS** - Parent Accounts (3 accounts)

#### Parent 1 - Father of Emma & Liam
| Field | Value |
|-------|-------|
| **Role** | Parent |
| **Email** | parent1@demoschool.edu |
| **Password** | Demo@2026 |
| **User ID** | 20000000-0000-0000-0000-000000000200 |
| **Name** | Robert Parent |
| **Occupation** | Engineer |
| **Children** | Emma Student (ADM2025001), Liam Student (ADM2025002) |

#### Parent 2 - Mother of Olivia
| Field | Value |
|-------|-------|
| **Email** | parent2@demoschool.edu |
| **Password** | Demo@2026 |
| **Name** | Sarah Parent |
| **Occupation** | Doctor |
| **Children** | Olivia Student (ADM2025003) |

#### Parent 3 - Father of Noah & Ava
| Field | Value |
|-------|-------|
| **Email** | parent3@demoschool.edu |
| **Password** | Demo@2026 |
| **Name** | Michael Parent |
| **Occupation** | Lawyer |
| **Children** | Noah Student (ADM2025004), Ava Student (ADM2025005) |

**Parent Permissions:**
- ✅ View children's grades
- ✅ View children's attendance
- ✅ View fee invoices
- ✅ View payment plans
- ✅ View AI predictions for children
- ✅ View behavior incidents (children only)
- ✅ Communication with teachers
- ❌ Other students' data

---

## 📊 Account Summary

| Role | Count | Purpose |
|------|-------|---------|
| **Super Admin** | 1 | System administration |
| **Tenant Admin** | 1 | School administration |
| **Principal** | 1 | Academic leadership |
| **Teachers** | 3 | Teaching staff |
| **Accountant** | 1 | Finance management |
| **Students** | 5 | Student accounts |
| **Parents** | 3 | Parent/guardian accounts |
| **TOTAL** | **15** | Complete stakeholder coverage |

---

## 🔧 Setting Up Auth Users in Supabase

### Method 1: Via Supabase Dashboard (Recommended for Testing)

1. **Start Supabase Studio:**
   ```bash
   open http://localhost:54323
   ```

2. **Navigate to Authentication:**
   - Click "Authentication" in left sidebar
   - Click "Users" tab
   - Click "Add User" button

3. **For Each User Above, Add:**
   - Email: (use email from table above)
   - Password: `Demo@2026`
   - User ID: (use UUID from table above) **IMPORTANT!**
   - Auto Confirm User: ✅ Check this box
   - Click "Create User"

4. **Set User Metadata:**
   After creating user, click on the user and add metadata:
   ```json
   {
     "app_metadata": {
       "tenant_id": "00000000-0000-0000-0000-000000000001",
       "roles": ["super_admin"]
     }
   }
   ```
   Replace "super_admin" with appropriate role for each user.

### Method 2: Via SQL (Automated - Advanced)

⚠️ **Note:** Direct auth.users insertion is not recommended. Use Dashboard or signUp API.

---

## 🧪 Testing Different User Roles

### Test Scenario 1: Admin Dashboard
```
Login as: admin@demoschool.edu
Password: Demo@2026

Expected Access:
- ✅ All students visible
- ✅ All financial data
- ✅ All reports
- ✅ User management
- ✅ Settings
```

### Test Scenario 2: Teacher View
```
Login as: teacher1@demoschool.edu
Password: Demo@2026

Expected Access:
- ✅ Assigned class students only
- ✅ Attendance marking
- ✅ Grade entry
- ❌ Financial data (restricted)
- ❌ Other teachers' classes
```

### Test Scenario 3: Student Portal
```
Login as: student4@demoschool.edu
Password: Demo@2026

Expected Access:
- ✅ Own grades & attendance
- ✅ Own AI predictions (showing high risk)
- ✅ Own fee invoices
- ❌ Other students' data
- ❌ Teacher functions
```

### Test Scenario 4: Parent Portal
```
Login as: parent3@demoschool.edu
Password: Demo@2026

Expected Access:
- ✅ Noah's grades & attendance
- ✅ Ava's grades & attendance
- ✅ AI predictions for both children
- ✅ Fee invoices for both
- ❌ Other students' data
```

### Test Scenario 5: Accountant Dashboard
```
Login as: accountant@demoschool.edu
Password: Demo@2026

Expected Access:
- ✅ All fee invoices
- ✅ Payment plans
- ✅ Payment tracking
- ✅ Financial reports
- ❌ Student grades (restricted)
- ❌ Teacher functions
```

---

## 🔐 Security Notes

### Important Security Considerations:

1. **Change Default Password:**
   - `Demo@2026` is for TESTING ONLY
   - Change all passwords in production
   - Enforce strong password policy

2. **Row-Level Security (RLS):**
   - All tables have RLS enabled
   - Users can only access data based on role
   - Tenant isolation enforced

3. **Multi-Factor Authentication:**
   - Consider enabling MFA for admins in production
   - Available in Supabase Auth settings

4. **Session Management:**
   - Sessions expire after inactivity
   - Refresh tokens handled automatically

5. **Audit Logging:**
   - All login attempts logged
   - Data access logged for compliance
   - Check `login_audit` table

---

## 📱 Mobile App Login

### Flutter App Login Flow:

```dart
// Example login code
final response = await supabase.auth.signInWithPassword(
  email: 'admin@demoschool.edu',
  password: 'Demo@2026',
);

// Get user role
final userId = response.user!.id;
final roles = await supabase
  .from('user_roles')
  .select('role')
  .eq('user_id', userId)
  .single();
```

---

## 🆘 Troubleshooting

### Issue: "User not found"
**Solution:** Make sure you created auth users in Supabase Dashboard with exact UUIDs listed above.

### Issue: "Access Denied"
**Solution:** Check that user metadata contains correct tenant_id and roles array.

### Issue: "RLS Policy Error"
**Solution:** Verify tenant_id in user metadata matches tenant in database.

### Issue: "Invalid Password"
**Solution:** Password is `Demo@2026` (case-sensitive, includes @).

---

## 📞 Quick Reference

### Login URL (Local):
```
http://localhost:54323
```

### Database Connection (Local):
```
Host: localhost
Port: 54322
Database: postgres
Username: postgres
Password: postgres
```

### Supabase Studio:
```
http://localhost:54323
```

### API URL (Local):
```
http://localhost:54321
```

---

## ✅ Verification Checklist

After setup, verify each user can login:

- [ ] Super Admin (`superadmin@demoschool.edu`)
- [ ] Tenant Admin (`admin@demoschool.edu`)
- [ ] Principal (`principal@demoschool.edu`)
- [ ] Teacher 1 (`teacher1@demoschool.edu`)
- [ ] Teacher 2 (`teacher2@demoschool.edu`)
- [ ] Teacher 3 (`teacher3@demoschool.edu`)
- [ ] Accountant (`accountant@demoschool.edu`)
- [ ] Student 1 (`student1@demoschool.edu`)
- [ ] Student 2 (`student2@demoschool.edu`)
- [ ] Student 3 (`student3@demoschool.edu`)
- [ ] Student 4 (`student4@demoschool.edu`)
- [ ] Student 5 (`student5@demoschool.edu`)
- [ ] Parent 1 (`parent1@demoschool.edu`)
- [ ] Parent 2 (`parent2@demoschool.edu`)
- [ ] Parent 3 (`parent3@demoschool.edu`)

---

## 🎯 Next Steps

1. **Start Docker Desktop** ⬅️ **DO THIS FIRST**
2. Run `supabase start`
3. Run `supabase db reset`
4. Run seed file: `psql -h localhost -p 54322 -U postgres -d postgres -f supabase/seed_test_users_with_auth.sql`
5. Open Supabase Studio: `http://localhost:54323`
6. Create auth users for each email above
7. Test login with each role
8. Verify RLS policies working correctly

---

**🎉 Happy Testing!**

*All credentials are for development/testing only. Never use these in production.*
