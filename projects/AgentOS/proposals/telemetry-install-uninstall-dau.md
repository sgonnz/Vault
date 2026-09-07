# Proposal: install, uninstall, and daily-active telemetry

Status: implemented and live in Supabase as of 2026-09-06 (migration `20260906120000_telemetry_install_uninstall_active_day.sql` pushed, `telemetry` and `uninstall` edge functions deployed). Not yet shipped in a store release, so no rows arrive until the next extension update reaches users. Code lives in `projects/WindowShopping/WindowShoppingsExtensions`.

One consequence of the consent design: all three counters describe the opted-in population only. An install is counted the first time consent is turned on after a fresh install, an active day only while consent is on, and the uninstall page is registered only while consent is on. The Chrome Web Store dashboard stays the census for total installs; `data/store-stats.csv` remains useful for that.

## Goal

Make Supabase the source of truth for the three numbers the AgentOS dashboard shows: installs, uninstalls, and daily active devices. Keep the existing privacy posture: count-only rows, no identifiers, one row per UTC day per event.

## Events

| Event | When it fires | Guard |
|---|---|---|
| `extension_installed` | `runtime.onInstalled` with `reason === "install"` | none needed, fires once per install by definition |
| `extension_active_day` | first user-visible action or first alarm tick of a UTC day | local `lastActiveDay` flag in storage; send at most once per device per day |
| `extension_uninstalled` | browser opens the uninstall URL set by `runtime.setUninstallURL` | browser-driven; fires once |

`extension_active_day` counts devices, not people, and includes signed-out users, which is exactly what the current data lacks. It should fire on an alarm tick as well as on user actions so an installed-but-idle device still counts as retained; if you want "used it today" instead, drop the alarm path.

Note that telemetry is consent-gated in `background.js` (`ensureTelemetryDefault`, `TELEMETRY_CONSENT_VERSION`). Install and active-day events must respect the same consent flag. The uninstall URL cannot carry a POST body or respect consent after the fact, so set it only when consent is on and clear it when consent is turned off.

## Extension changes

1. Add the three names to `TELEMETRY_EVENTS` in `background.js`.
2. In the `onInstalled` listener, when `details.reason === "install"`, call `enqueueMilestone("extension_installed")`.
3. Add `markActiveDay()` that compares today's UTC date with a stored `telemetryLastActiveDay`, enqueues `extension_active_day` when different, and stores the new day. Call it from the check alarm handler and from the save and remove code paths.
4. After consent is confirmed on, call `browser.runtime.setUninstallURL("<uninstall endpoint>")`. Firefox and Chrome both support it; Safari ignores it, so Safari uninstalls stay unmeasured.

## Backend changes

1. New migration in `supabase/migrations`: extend the check constraint on `public.extension_metric_counts` and the allow list inside `increment_extension_metrics` with the three event names. Same `create or replace` style as `20260905170918_telemetry_privacy_endpoint_hardening.sql`.
2. Add the three names to `allowedEvents` in `supabase/functions/telemetry/index.ts`.
3. New edge function `uninstall` that accepts GET, applies the same abuse quota as `telemetry`, calls `increment_extension_metrics` with `[{ "event_name": "extension_uninstalled" }]`, and returns a tiny goodbye page. GET is required because the browser navigates to the uninstall URL; it does not POST.

## Dashboard changes

None. `refresh.md` already copies `extension_installed`, `extension_uninstalled`, and `extension_active_day` into `installs`, `uninstalls`, and `daily_users` when present, and `index.html` prefers those over `store-stats.csv`.

## Rollout order

1. Push pending migrations 15 and 16. Done 2026-09-06.
2. Apply the new migration and deploy both edge functions. Done 2026-09-06.
3. Ship the extension update. Installs will only be counted from the version that carries the event, so keep the CSV for history before that date.
