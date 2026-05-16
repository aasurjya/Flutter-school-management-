---
feature: communication
last_tested: 2026-05-16
tester: product-tester
verdict: IMPROVE
persona: Principal Mrs. Banerjee broadcasting "school closed tomorrow for heavy rain"
---

# Communication Hub

## At a Glance
- **Verdict:** IMPROVE — feature is wired, but it's a 13-screen sub-app inside the app. Information architecture buries the one action users care about.
- **Entry screen:** [[../../lib/features/communication/presentation/screens/communication_dashboard_screen.dart]]
- **Roles with access:** admin, principal, tenant_admin

## Axis 1 — Works?

**Pass:**
- `communicationDashboardStatsProvider` + `campaignsNotifierProvider` powering everything — `communication_dashboard_screen.dart:33-34`.
- All 4 quick actions route to real screens — `:301-327`.
- AppBar history + settings menu items route correctly — `:42-50, 425-477`.
- FAB → "New Campaign" routes to `/communication/campaigns/create` — `:111-118`.
- Per-campaign card has live delivery progress bar — `:558-595`.
- Channel breakdown shows real per-channel split with linear progress — `:171-230`.
- Empty state with icon + copy — `:377-400`.

**Inconsistency / smell:**
- The screen mixes `Navigator.pushNamed(context, '/communication/...')` (lines 43, 91, 113, 343, etc.) with `context.push` from go_router everywhere else in the app. **This is a routing-architecture leak** — go_router is the spine; calling `Navigator.pushNamed` may go through unnamed `MaterialPageRoute`s that don't get the same redirect / RLS guards.

## Axis 2 — Good?

- **Taps to send an emergency broadcast:** 4-5 (open Communication → New Campaign → choose template → audience → schedule → send). For the persona's actual use case ("send 'school closed tomorrow' to all parents"), this is way too many steps. The product needs a "Quick Announcement" mode that's 2 taps.
- **Labels:** "Communication Hub" is corporate. The persona thinks "Announcement" or "Message Parents". Rename consideration.
- **Channel breakdown** widget is genuinely excellent — `:175-230`. Shows the operator how SMS vs WhatsApp vs email split, which is a real CFO question in India where SMS costs ₹0.15/msg.

Nitpicks:
- Mini-stats row (Active / Scheduled / Auto Rules) at the bottom — `:236-267`. "Auto Rules" is dev-speak; users will not know what an auto-rule is. Rename "Smart Triggers" or "Automations".
- 13 screens under one feature is a lot. There's no breadcrumb / hierarchy indicator.

## Axis 3 — Necessary?

YES — broadcast communication is a top-3 reason a principal uses a school SaaS. SMS templates + WhatsApp + email + auto-rules are differentiators against MyClassboard / Edsys.

**BUT** the surface area is bloated for the actual job-to-be-done. The principal's actual need is "send a message to all parents in Class 5 right now" — a 2-tap flow. The 13-screen hub is for the rare admin doing campaigns / settings / auto-rules / SMS gateway config.

Split decision: keep the hub, but add a **"Quick Notice"** action on the admin dashboard that bypasses the hub and goes straight to compose-and-send.

## Axis 4 — Improvable?

- [ ] Replace `Navigator.pushNamed` calls with `context.push(AppRoutes.xxx)` — 8 sites flagged at `:43, 91, 113, 343, 443, 451, 459, 467, 507`.
- [ ] Add a **"Quick Notice"** flow (2 taps to send) accessible from the admin dashboard, not from this hub.
- [ ] Rename "Auto Rules" → "Smart Triggers". Rename "Communication Hub" → "Announcements" (consider).
- [ ] Add cost-per-message preview before send (SMS in INR; WhatsApp in INR). This is the *one* feature that beats Tally + manual SMS.
- [ ] Merge with `notifications/notification_center_screen.dart` — they overlap functionally for the admin.

## Notes for the panel

- **Architect:** the `Navigator.pushNamed` leak is a regression of go_router as the canonical router. Decide enforce-via-lint vs case-by-case fix.
- **Product-intel:** what does Teachmint charge for "AI smart triggers"? If >₹500/month, our auto-rules story is the wedge.
- **UX-expert:** is the FAB "New Campaign" the right primary action for the principal's persona? Likely not — the 2-tap quick-notice is what the persona actually does daily.

## Backlinks

- [[../00 Index]]
- [[../_feature_inventory_2026-05-16]]
