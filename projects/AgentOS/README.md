# AgentOS

A single dashboard page for the day: Google Calendar, TickTick tasks, completed work and habit streaks, WindowShopping extension analytics (installs, uninstalls, daily usage), a short agent-written brief of what needs attention, and the cost and health of the agent runs that keep it fresh.

## How it works

```text
Claude Code refresh run (scheduled)          Static page
  Google Calendar MCP  ─┐                     index.html
  TickTick MCP         ─┼─> data/snapshot.json ─> reads snapshot + store-stats
  Supabase MCP (SQL)   ─┘                     renders widgets and the brief
  agent brief          ─┘
```

There is no server. A scheduled Claude Code run executes `refresh.md`, which pulls the three sources through the MCP connectors already attached to Claude Code, writes `data/snapshot.json`, and adds a brief. The page is plain HTML and reads that file. This is the simplest end-to-end path; a hosted app with its own OAuth can come later if the page proves useful.

## Run it

```powershell
cd C:\Users\samgo\vault\projects\AgentOS
python -m http.server 8787
```

Open http://localhost:8787. The page must be served over HTTP (not opened as a file) so it can fetch the JSON.

## Refresh the data

Manual, from Claude Code in the vault:

```text
Run projects/AgentOS/refresh.md
```

Headless, which is what the schedule calls:

```powershell
projects\AgentOS\refresh.cmd
```

`refresh.cmd` runs `claude -p "Run projects/AgentOS/refresh.md" --output-format json` with only the read tools it needs plus Write for the snapshot. The JSON that Claude prints (duration, turns, tokens, cost, final reply) is handed to `scripts/record-run.py`, which appends one entry to `data/runs.json` (last 200 runs kept). Log lines go to `data/refresh.log`. Both data files are ignored by git. It is registered in Windows Task Scheduler as the task `AgentOS refresh`, hourly while logged on, starting at 07:00. Useful commands:

```powershell
schtasks /Run /TN "AgentOS refresh"      # refresh now
schtasks /Query /TN "AgentOS refresh" /V /FO LIST   # last run time and result
schtasks /Delete /TN "AgentOS refresh" /F   # remove the schedule
```

Alternatively, in an interactive Claude Code session, the `/loop` skill can rerun the refresh prompt at an interval for as long as the session is open.

## Data sources

| Widget | Source | Status |
|---|---|---|
| Calendar | Google Calendar MCP, calendars Main, Work, Family, next 8 days | Live |
| Tasks | TickTick MCP, undone tasks across Work, Personal, Inbox | Live |
| Done | TickTick MCP, tasks completed in the last 7 days and focus (pomodoro and stopwatch) minutes per day | Live |
| Habits | TickTick MCP, habit list and 30 days of check-ins: streak, done today, at risk, 30-day adherence | Live, shows a setup hint until habits exist in TickTick |
| Agent runs | `data/runs.json`, written locally by `refresh.cmd` after every scheduled run | Live |
| Daily usage | Supabase `public.extension_metric_counts`, plus `auth.users` and `public.products` activity | Live, proxy (see below) |
| Installs and uninstalls | `data/store-stats.csv`, copied from the Chrome Web Store developer dashboard | Manual until telemetry is extended |

### Why installs and uninstalls are manual today

The extension's telemetry is count-only and privacy-hardened: the edge function accepts a fixed list of product events (saves, removes, collections, price checks, onboarding milestones). Nothing fires on install or uninstall, and nothing fires once per active day. Those numbers exist only in the Chrome Web Store developer dashboard, which has no stats API.

`proposals/telemetry-install-uninstall-dau.md` describes the extension and migration change that would make Supabase the source of truth for all three numbers. Until it ships, paste the store numbers into `data/store-stats.csv`:

```csv
date,installs,uninstalls,daily_users
2026-09-05,3,1,12
```

The Chrome Web Store dashboard exports installs, uninstalls, and daily users per day under Stats. Firefox Add-ons and Safari can be added as extra rows with a `store` column later if needed.

### What "daily usage" means today

`snapshot.json` carries two usage views per day, both from Supabase:

- `user_actions`: product_saved, product_removed, product_page_viewed, collection_created, collection_deleted. These only happen when a person uses the extension.
- `price_checks`: price_check_completed and its successors. These are background checks and track installed, running devices rather than people.

Signed-in users active in the last 1 and 7 days come from `auth.users.last_sign_in_at`, and savers active in the last 1 and 7 days come from `public.products.updated_at`. Signed-out users are not counted anywhere, which is the gap the proposal closes.

### Agent run cost analytics

Every headless run records `durationSec`, `apiSec`, `turns`, `costUsd`, `inputTokens` (including cache reads and writes), `outputTokens`, `isError`, and the first 600 characters of the run's final reply. The Agent runs panel shows:

- Cost over the last 7 days and the projected 30-day cost at the same rate.
- Average cost, duration, and turns per successful run.
- Run count with failures called out, and a warning colour when the last run failed or is more than 90 minutes old.
- The last six runs with their one-line result, so a bad run is visible without opening the log.

A refresh costs roughly what a short Claude Code session costs; if the 7-day number climbs, lower the schedule frequency in Task Scheduler or trim `refresh.md`. Manual refreshes from an interactive session are not recorded.

## Layout

```text
AgentOS/
|-- README.md
|-- refresh.md                 Prompt the scheduled Claude Code run executes
|-- refresh.cmd                Headless wrapper the schedule runs
|-- index.html                 The dashboard
|-- scripts/
|   `-- record-run.py          Appends one run's stats to data/runs.json
|-- data/
|   |-- snapshot.json          Written by refresh.md
|   |-- runs.json              Per-run duration, turns, cost (ignored by git)
|   |-- refresh.log            Scheduler log (ignored by git)
|   `-- store-stats.csv        Hand-maintained store numbers
`-- proposals/
    `-- telemetry-install-uninstall-dau.md
```
