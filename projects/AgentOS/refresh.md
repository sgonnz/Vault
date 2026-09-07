# AgentOS refresh

Collect the dashboard data and write `projects/AgentOS/data/snapshot.json`. Read only from the sources; never create, update, complete, or delete anything in Calendar, TickTick, or Supabase. Do not delegate to subagents; do the calls directly.

"Today" and "yesterday" are America/Chicago calendar days.

## 1. Calendar

Call `list_events` for each calendar below with `startTime` = today 00:00 America/Chicago, `endTime` = today + 8 days, `orderBy` = `startTime`, `pageSize` = 50.

| Name | calendarId |
|---|---|
| Main | `samgonz021@gmail.com` |
| Work | `6d52eb765c141b048fb5281737a95f9c56ac82185757d6e41dfe1fe08136dff9@group.calendar.google.com` |
| Family | `family18266020078026691213@group.calendar.google.com` |

Map each event to `{ "calendar", "title", "start", "end", "allDay", "location" }` with ISO timestamps. Skip declined events.

## 2. Open tasks

Call `get_project_with_undone_tasks` for `5e0053957bba11054ab6fbba` (Work), `5e0053957ba911054ab6fbbb` (Personal) and `inbox`. `inbox` returns `"project": null` with an empty task list when the inbox is empty; that is normal, not an error. If Work or Personal returns `"project": null`, call `list_projects`, use the id whose name matches, and add a line to `errors` saying the id in this file is stale. Map each task to `{ "project", "title", "due", "priority", "overdue" }`. `overdue` is true when `due` is before today. Sort overdue first, then by due date, then undated.

## 3. Done and focus

Call `list_completed_tasks_by_date` with `startDate` = today minus 7 days 00:00 and `endDate` = tomorrow 00:00 (America/Chicago, ISO 8601 with offset), no `projectIds`. Then call `get_focuses_by_time` with the same range and `type` = 0, and again with `type` = 1 (pomodoro and stopwatch records).

Produce:

- `done.yesterday`: tasks whose `completedTime` falls on yesterday, as `{ "project", "title", "completedAt" }`, newest first. Project names: Work, Personal, Inbox.
- `done.today`: same for today.
- `done.perDay`: object keyed by local day `YYYY-MM-DD` for each of the last 7 days including today, value = number of tasks completed that day (0 when none).
- `done.focusMinutesPerDay`: same keys, total focus minutes that day summed across both types (0 when none).

## 4. Habits

Call `list_habits`. If the list is empty, set `habits.items` to `[]` and `habits.configured` to false. Otherwise set `configured` to true and call `get_habit_checkins` with all habit ids and `from_stamp` = today minus 30 days, `to_stamp` = today, as `yyyyMMdd` integers. For each habit produce `{ "name", "streak", "doneToday", "atRisk", "last30" }` where `streak` counts consecutive days ending today or yesterday with a check-in, `doneToday` is whether today has a check-in, `atRisk` is `streak > 0 and not doneToday`, and `last30` is the number of days with a check-in in the window.

## 5. WindowShopping analytics

Project id `twyycvdvsfigbzzskhyw`. Run with `execute_sql`:

```sql
select metric_day, jsonb_object_agg(event_name, count) as events
from public.extension_metric_counts
where metric_day >= current_date - 29
group by metric_day order by metric_day;
```

```sql
select
  (select count(*) from auth.users) as users_total,
  (select count(*) from auth.users where created_at >= now() - interval '7 days') as users_new_7d,
  (select count(*) from auth.users where last_sign_in_at >= now() - interval '1 day') as signed_in_1d,
  (select count(*) from auth.users where last_sign_in_at >= now() - interval '7 days') as signed_in_7d,
  (select count(distinct user_id) from public.products where updated_at >= now() - interval '1 day') as active_savers_1d,
  (select count(distinct user_id) from public.products where updated_at >= now() - interval '7 days') as active_savers_7d,
  (select count(*) from public.products where not deleted) as live_products;
```

If the events table ever contains `extension_installed`, `extension_uninstalled`, or `extension_active_day`, copy those into `installs`, `uninstalls`, and `daily_users` per day so the page can prefer them over the CSV.

For each day produce `{ "day", "user_actions", "price_checks", "events" }` where `user_actions` sums product_saved, product_removed, product_page_viewed, collection_created, collection_deleted and `price_checks` sums every event whose name starts with `price_check_`.

## 6. Brief

Write three to six one-line bullets a person would want at a glance. Only state things the data supports. Examples of what qualifies: overdue tasks, the first meeting today, a day with no calendar events, nothing completed yesterday when the 7-day average is above zero, a habit at risk, a usage day that is zero or a clear outlier versus the prior 7 days, a store-stats file that has not been updated in more than 3 days (compare its last date with today). Do not mention agent run cost or duration; the page reads those from `data/runs.json` on its own.

## 7. Write the file

Write `projects/AgentOS/data/snapshot.json` using this shape. Keep every key even when the list is empty.

```json
{
  "generatedAt": "2026-09-06T12:00:00-05:00",
  "timeZone": "America/Chicago",
  "calendar": { "rangeDays": 8, "events": [] },
  "tasks": { "items": [] },
  "done": {
    "yesterday": [ { "project": "Work", "title": "Example", "completedAt": "2026-09-05T16:41:00-05:00" } ],
    "today": [],
    "perDay": { "2026-08-31": 3, "2026-09-01": 2 },
    "focusMinutesPerDay": { "2026-08-31": 0, "2026-09-01": 25 }
  },
  "habits": { "configured": false, "items": [ { "name": "Example", "streak": 4, "doneToday": false, "atRisk": true, "last30": 20 } ] },
  "windowshopping": {
    "totals": { "users_total": 0, "users_new_7d": 0, "signed_in_1d": 0, "signed_in_7d": 0, "active_savers_1d": 0, "active_savers_7d": 0, "live_products": 0 },
    "days": [ { "day": "2026-09-06", "user_actions": 0, "price_checks": 0, "installs": null, "uninstalls": null, "daily_users": null, "events": {} } ]
  },
  "brief": [],
  "errors": []
}
```

If a source fails, keep its previous content from the existing snapshot when there is one, add a line to `errors`, and still write the file. Finish with a reply of at most three lines saying what changed; it is stored as the run's result.
