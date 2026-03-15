# Security Review Rubric — Flutter/School Management

**Used By**: Security Reviewer Agent
**Purpose**: Identify security vulnerabilities before code reaches production
**Version**: 1.0

---

## Severity Levels

| Level | Description | Action |
| --- | --- | --- |
| **CRITICAL** | Exploitable vulnerability, data breach, crash risk | MUST fix immediately, blocks PR |
| **HIGH** | Security weakness, significant risk | MUST fix before merge |
| **MEDIUM** | Hardening opportunity, best practice violation | SHOULD fix |
| **LOW** | Minor improvement | OPTIONAL |

---

## Project-Critical Security Checks

### 1. Demo Credentials (CRITICAL)

**Known issue**: Demo credentials are hardcoded in `LoginScreen`. This MUST be removed before production.

```bash
# Grep for known hardcoded credentials
grep -r "admin@school.com\|admin123\|password123\|demo@" lib/
```

| Check | Severity | What to Look For |
| --- | --- | --- |
| No hardcoded email credentials | CRITICAL | `admin@school.com` or similar in any Dart file |
| No hardcoded passwords | CRITICAL | `admin123`, `password123` or similar |
| No demo login buttons | HIGH | Buttons that auto-fill credentials |

---

### 2. Multi-Tenant Data Isolation (CRITICAL)

| Check | Severity | What to Look For |
| --- | --- | --- |
| tenant_id on all queries | CRITICAL | Supabase queries without `.eq('tenant_id', tenantId)` |
| tenantId null safety | CRITICAL | `tenantId!` crash for super_admin users |
| RLS policies active | CRITICAL | New tables without row-level security |
| No cross-tenant reads | CRITICAL | Super_admin queries that can expose other tenants' data |

**Code Patterns to Flag:**

```dart
// CRITICAL — fetches ALL tenants' data
final students = await supabase.from('students').select();

// CRITICAL — crashes for super_admin
final tid = authState.tenantId!; // null for super_admin

// GOOD
final tid = authState.tenantId;
if (tid == null) return; // super_admin handling
final students = await supabase.from('students').select()
    .eq('tenant_id', tid);
```

---

### 3. Authentication & Authorization (CRITICAL)

| Check | Severity | What to Look For |
| --- | --- | --- |
| Role-based route guards | CRITICAL | Routes accessible by wrong roles |
| JWT claims verified | CRITICAL | Role from JWT, not from a client-side field |
| No client-side role bypass | CRITICAL | `if (user.role == 'admin')` based on mutable state |
| Session cleanup on logout | HIGH | Supabase session cleared, Isar local data cleared |

---

### 4. Cryptographic Failures (CRITICAL/HIGH)

| Check | Severity | What to Look For |
| --- | --- | --- |
| Secrets in source code | CRITICAL | API keys, Supabase service role keys in Dart files |
| Secrets in logs | HIGH | `print()` or `debugPrint()` with tokens/passwords |
| No cleartext passwords | CRITICAL | Passwords stored locally without hashing |
| Secure storage for tokens | HIGH | Tokens in `SharedPreferences` vs `flutter_secure_storage` |

---

### 5. Input Validation (HIGH)

| Check | Severity | What to Look For |
| --- | --- | --- |
| Form validation before Supabase calls | HIGH | `null` or empty strings reaching `.insert()` |
| Grade bounds enforced | HIGH | No `maxLength` / `max` on grade/score fields |
| Date pickers used | HIGH | Free-text dates instead of `showDatePicker()` |
| No command injection | CRITICAL | User input in system calls (rare in Flutter but possible with `Process.run`) |

---

### 6. Real-Time Channel Safety (MEDIUM/HIGH)

| Check | Severity | What to Look For |
| --- | --- | --- |
| Channels disposed on screen exit | HIGH | Missing `_subscription?.cancel()` in `dispose()` |
| Channel scope verified | HIGH | Subscriptions not scoped to correct tenant |
| No channel accumulation | HIGH | Multiple subscriptions without cleanup |

---

### 7. Payment & Financial Data (HIGH)

| Check | Severity | What to Look For |
| --- | --- | --- |
| No amount manipulation | HIGH | Payment amounts computed client-side only |
| Wallet race conditions | CRITICAL | Multi-step wallet debit without server-side atomicity |
| Invoice duplicate protection | HIGH | `generate_class_invoices()` RPC — no duplicate check (KNOWN ISSUE) |
| No card data stored | CRITICAL | Never store full card numbers locally |

---

### 8. Quiz / Assessment Security (HIGH)

| Check | Severity | What to Look For |
| --- | --- | --- |
| Timer server-side | HIGH | Client-side quiz timer is exploitable (KNOWN ISSUE) |
| Answers not pre-loaded | HIGH | Quiz answers fetched before submission |
| Score computed server-side | HIGH | Not trusted from client payload |

---

## Mobile-Specific Security Checks

| Check | Severity | What to Look For |
| --- | --- | --- |
| No secrets in `pubspec.yaml` | HIGH | No hardcoded API keys in build configs |
| Debug logs removed | MEDIUM | `kDebugMode` check before sensitive logs |
| Deep link validation | HIGH | GoRouter handles malformed deep links safely |
| Screenshot prevention | LOW | Sensitive screens (fees, grades) can disable screenshots |

---

## Review Output Format

```markdown
## Security Audit: <files or description>

### Verdict: APPROVED | BLOCKED

### Summary

<Brief security assessment>

---

### Critical Findings (Blocks PR)

#### 1. Demo Credentials in LoginScreen

**File**: `lib/features/auth/presentation/screens/login_screen.dart:45`
**Issue**: Hardcoded `admin@school.com` / `admin123` visible in source
**Impact**: Credentials exposed in version control and app binary
**Fix**: Remove hardcoded credentials, use placeholder text only

---

### High Priority Findings

#### 2. Missing tenant_id in Student Query

**File**: `lib/features/students/data/repositories/student_repository.dart:67`
**OWASP**: A01 Broken Access Control
**Issue**: `.from('students').select()` without tenant_id filter
**Fix**: Add `.eq('tenant_id', tenantId)` to query

---

### Security Checklist

- [ ] No hardcoded credentials (admin@school.com, admin123)
- [ ] All Supabase queries have tenant_id filter
- [ ] tenantId! not force-unwrapped
- [ ] No secrets in source code or logs
- [ ] Role-based route guards enforced
- [ ] Real-time subscriptions disposed
- [ ] Payment operations server-side atomic
```

---

## Approval Criteria

**APPROVED** when:
- Zero CRITICAL findings
- Zero HIGH findings (or accepted with documented justification)
- All project-critical checks verified

**BLOCKED** when:
- Any CRITICAL finding (especially: demo creds, missing tenant_id, tenantId! crash)
- Multiple HIGH findings without mitigation plan
