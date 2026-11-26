---
title: Scheduler
description: Cron-like tasks defined in Crystal.
---
# Scheduler

```crystal
# src/app.cr
Silth.schedule do |s|
  s.job(PruneTokensJob.new).daily_at("03:00")
  s.call("refresh-stats") { Stats.refresh }.every(10.minutes).without_overlapping
  s.command("cache:clear").weekly_on(:monday, "08:00").timezone("Europe/Paris")
  s.call("business-hours") { Ping.run }.hourly.weekdays.between("09:00", "18:00")
  s.call("reports") { Reports.send }.cron("0 7 1 * *").on_one_server
end
```

Frequencies: `every_minute`, `every(span)`, `hourly`, `hourly_at(17)`, `daily`, `daily_at("13:00")`, `twice_daily`, `weekly`, `weekly_on(:friday, "17:00")`, `monthly`, `monthly_on(1, "00:00")`, `cron("*/5 * * * *")`. Constraints: `weekdays`, `weekends`, `between`, `when { … }`, `skip { … }`, `timezone`, `without_overlapping`, `on_one_server`.

Run it either with a single system cron entry or a long-running process:

```bash
* * * * * cd /app && bin/cli schedule:run
silth schedule:work
silth schedule:list
```

The profiler's *Schedule* tab shows next and last runs.
