---
feature: bus_tracking
last_tested: 2026-05-16
tester: product-tester
verdict: IMPROVE
persona: Mr. Iyer, transport manager at a 1,500-student school with 12 buses
---

# Bus Tracking

## At a Glance
- **Verdict:** IMPROVE — appears wired, but premium-tier feature is gated by hardware/operations the typical Indian K-12 customer doesn't have.
- **Entry screen:** [[../../lib/features/bus_tracking/presentation/screens/bus_tracking_dashboard_screen.dart]]
- **Roles with access:** transport_manager, admin, parent (read-only via `my_transport_screen.dart`)

## Axis 1 — Works?

**Pass:**
- `busTrackingStatsProvider`, `busVehiclesProvider`, `liveLocationProvider` all wired — `bus_tracking_dashboard_screen.dart:16-18`.
- 3 Quick Actions (Live Map / Start Trip / Add Bus) route to real screens — `:90-119`.
- AppBar actions for Geofences + popup menu (Trips / Alerts) — `:30-65`.
- Empty state has CTA "Add Bus" with icon and copy — `:244-292`.
- Per-vehicle BusStatusCard + onTap to detail screen with vehicleId param — `:159-172`.
- Refresh invalidates 3 providers + refreshes live locations — `:67-72`. Correct.

**Risk (not a true fail, but practically broken):**
- The feature is heavily dependent on `liveLocationProvider` working. In a typical Indian K-12 school, this requires GPS devices on buses **plus** an MQTT/Supabase Realtime backplane **plus** SIM cards with data. The dashboard doesn't warn the user "you haven't configured a tracking device yet" — `live_map_screen.dart` will just show empty markers. **Surface that as a setup state before showing the dashboard.**

## Axis 2 — Good?

- **Taps to Live Map:** 2 (open Bus Tracking → tap Live Map quick action OR tap map-icon in app bar). Good.
- **Labels:** "FLEET STATUS" header is enterprise-y. Fine.
- **Mobile pattern:** all-caps labels on quick action cards (`LIVE MAP / START TRIP / ADD BUS`) — `:96, 105, 113`. Bold; works for a fleet-ops persona.
- 3-action row on a phone width is tight. On 360dp width, "LIVE MAP" is ~120dp wide — the labels truncate cleanly with `letterSpacing: 1.0` but pile attention.

Nitpicks:
- No empty/loading distinction for `liveLocationProvider` separately — a fleet of 10 buses with 0 live data looks identical to a fleet with 10 live buses except for the missing marker dot.
- "Driver Panel" lives behind the "START TRIP" quick action — that label is hugely ambiguous if you're not a driver.

## Axis 3 — Necessary?

CONDITIONAL — yes for **premium-tier schools that have invested in GPS trackers** (typically large city schools, $30+/month tier). For most Tier-2 / Tier-3 Indian K-12, this is aspiration, not utility. The product-positioning question is: do we ship this prominently and let the field be empty, or do we gate it behind a "Transport add-on" feature flag?

Today, `lib/features/transport/` and `lib/features/bus_tracking/` both exist. `transport/` looks like the parent-facing read-only route/schedule view; `bus_tracking/` is the operator dashboard. They should be siblings under one transport hub.

## Axis 4 — Improvable?

- [ ] Add a setup-required state: "No tracking devices configured. Add a device →" before showing the empty fleet card.
- [ ] **Merge `features/transport` and `features/bus_tracking` into a single `features/transport` hub** with operator + parent role variants. Today they're two separate codepaths solving overlapping problems.
- [ ] Rename "START TRIP" → "Driver Panel" or "Today's Routes" — the current label only makes sense if you're already a driver.
- [ ] Surface a "Battery / GPS signal" status badge per vehicle on the card — the #1 ops question.

## Notes for the panel

- **Product-intel:** what % of Indian K-12 schools currently buy bus-GPS modules separately? If it's <20%, this should be a paid add-on, not a base feature. Free tier should show transport routes only, not live tracking.
- **Architect:** confirm transport + bus_tracking merge plan before Sprint 2 RLS hardening (cleaner to refactor first).
- **Critic:** this looks polished but is functionally aspirational. For a product-tester audit, that's the canonical "filler in the 48-feature sprawl" case.

## Backlinks

- [[../00 Index]]
- [[../_feature_inventory_2026-05-16]]
