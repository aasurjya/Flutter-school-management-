---
project: school-management-flutter
type: index
last_updated: 2026-05-16
---

# School-Management-Flutter Wiki

**Project:** Multi-tenant K-12 school SaaS — Flutter + Riverpod + Supabase + Isar + GoRouter + Razorpay
**Status:** Sprint 1 security closure in progress, Phase β (user management) in flight
**Stack:** 32 feature modules · 88 screens · 12 roles · ~104 DB tables · 75+ routes

> This wiki uses [Obsidian](https://obsidian.md)-style `[[wikilinks]]`. Open the folder as an Obsidian vault for the full graph view. Plain Markdown viewers ignore the wikilink syntax gracefully.

---

## Quick Nav

- [[pending]] — kanban: backlog, in progress, done, needs human
- [[features/]] — per-feature audit pages (one Markdown file per feature)
- [[panels/]] — multi-agent panel discussions and decisions
- [[decisions/]] — daily decision log (YYYY-MM-DD.md)

---

## How this wiki gets updated

| Agent | Writes to |
|---|---|
| `product-tester` | `features/<name>.md` and `panels/feature-audit-<date>.md` |
| `panel-moderator` | `panels/<topic>-decision-<date>.md` and `pending.md` |
| `architect` | `decisions/<date>.md` for architectural calls |
| `critic` | appends Verdict sections to `features/*.md` |
| Any agent | `pending.md` under appropriate kanban column |

When the user invokes `jarvis`, the meta-orchestrator auto-spawns the right agents and they all write here.

---

## Active Sprints

### Sprint 1 — Security closure (2026-05-16)
3 CRITICAL + 9 HIGH bugs found in audit. 5 parallel agents shipped fixes. See [[panels/sprint-1-closure-2026-05-16]].

### Phase β — User management (2026-05-16)
Admin-initiated password reset, member self-change-password, edit profile, account settings. 4 parallel agents.

---

## Out of scope (deferred)

- Sprint 2 — `BaseRepository.scoped()` tenant-isolation hardening
- Sprint 3 — Fees module dead snackbars, PTM create form, AI remarks hardcoded IDs
- Isar offline-first decision (commit or rip)

---

## Feature audits (2026-05-16 pass)

- [[_feature_inventory_2026-05-16]] — full inventory + verdict map
- [[panels/feature-audit-2026-05-16]] — panel-prep with 3 contentious findings

### Per-feature pages
- [[features/dashboard]] — IMPROVE (5 mock-data sites on the most-viewed screen)
- [[features/fees]] — IMPROVE (6 dead "coming soon" snackbars on the revenue screen)
- [[features/attendance]] — IMPROVE (fake weekly calendar, inert filters)
- [[features/exams]] — SHIP
- [[features/homework]] — SHIP
- [[features/bus_tracking]] — IMPROVE (aspirational; merge with `transport`)
- [[features/communication]] — IMPROVE (router leak, info-arch bloat)
- [[features/admission]] — SHIP
- [[features/students]] — IMPROVE (dead Add Student + dead filter sheet)
- [[features/profile]] — SHIP (Phase β; canonical pattern)
- [[features/ptm]] — IMPROVE (Create-PTM snackbar)
- [[features/ai_insights]] — IMPROVE (mock IDs in `generate_remarks_screen`)
- [[features/timetable]] — IMPROVE (folder empty; screens live elsewhere)
- [[features/ai_tutor]] — **KILL candidate** (no entry, bad unit economics)

## Backlinks

- [[pending]]
- Sprint Plan: `/Users/ihub-devs/.claude/plans/composed-bouncing-lecun.md`
