# AgentOS

A single dashboard page for the day: Google Calendar, TickTick tasks, and WindowShopping extension analytics (installs, uninstalls, daily usage), plus a short agent-written brief of what needs attention.

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

Headless, which is what a schedule should call:

```powershell
claude -p "Run projects/AgentOS/refresh.md" --allowedTools "Read,Write,Bash,mcp__claude_ai_Google_Calendar__*,mcp__claude_ai_TickTick__*,mcp__claude_ai_Supabase__execute_sql"
```

To schedule it, register that command in Windows Task Scheduler (start in `C:\Users\samgo\vault`, every 30 minutes while logged on). Alternatively, in an interactive Claude Code session, the `/loop` skill can rerun the refresh prompt at an interval for as long as the session is open.

## Data sources

| Widget | Source | Status |
|---|---|---|
| Calendar | Google Calendar MCP, calendars Main, Work, Family, next 7 days | Live |
| Tasks | TickTick MCP, undone tasks across Work, Personal, Inbox | Live |
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

## Layout

```text
AgentOS/
|-- README.md
|-- refresh.md                 Prompt the scheduled Claude Code run executes
|-- index.html                 The dashboard
|-- data/
|   |-- snapshot.json          Written by refresh.md
|   `-- store-stats.csv        Hand-maintained store numbers
`-- proposals/
    `-- telemetry-install-uninstall-dau.md
```
