---
panel: sprint-1-closure
date: 2026-05-16
moderator: panel-moderator
status: PENDING_TESTER
audit_agents: [explore, product-intel, code-reviewer, security-reviewer, architect, critic]
---

# Panel: Sprint 1 Security Closure — Findings

## The Question
Are the security fixes from Sprint 1 + Phase β sufficient to deploy to a paying tenant, or do we have remaining systemic risks before that gate?

## Audit Evidence

### From 6 parallel audit agents (2026-05-16):

**🔴 CRITICAL (3 → closed)**
- Plaintext passwords in `user_credentials.initial_password` — security-reviewer
- Exception leakage to clients in `create-user/index.ts:244-249` — security-reviewer
- Auth bypass `isLoggedIn = session != null \|\| currentUser != null` — code-reviewer

**🟠 HIGH (9 → 8 closed; 1 deferred to Sprint 2)**
- `has_role()` not tenant-scoped — security
- 47 repos manually filter `tenant_id` — architect (deferred to Sprint 2)
- 17 screens bypass repos and call SupabaseClient directly — architect (deferred to Sprint 2)
- Avatars bucket — XSS via SVG upload — security
- CORS `*` on privileged endpoint — security
- StateProvider stale auth reads — code-reviewer
- Client-side super_admin email-match promotion — code-reviewer
- Unguarded `developer.log` in production redirect path — code-reviewer

**🟡 PRODUCT (deferred to Sprint 3)**
- 4 dead snackbars in fees module (the #1 conversion trigger for Indian K-12) — product-intel
- AI remarks broken with hardcoded section/exam IDs — product-intel
- PTM Create FAB is a snackbar — product-intel

**🟢 STRATEGIC (critic's verdict)**
- "48 feature folders, 632 .dart files — the team ships screens before jobs-to-be-done."
- Recommends FREEZE on new feature folders until fees + attendance + messaging close E2E.

## Notes for the panel
After product-tester runs (Phase 12), this panel needs to convene on:
1. Is the deferral of 47 manual-tenant-filter repos to Sprint 2 acceptable, or is one missed `.eq()` a deploy-blocker today?
2. Should Sprint 3's fees fixes be promoted to "blocker for first tenant" given product-intel's "Indian schools buy fee collection that works"?
3. Critic's FREEZE call vs. the new user-management feature shipping anyway — was Phase β a mistake?

Convene: critic, security-reviewer, product-intel, architect, head-of-product (5 panelists max).

## Backlinks
- [[00 Index]]
- [[pending]]
