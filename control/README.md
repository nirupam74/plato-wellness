# Loop Control Dashboard

A local web dashboard to drive the autonomous coding loop for the Wellness app:
feed it tasks, watch the activity log, inspect every fix's diff, see the
guardrails, and pause/resume — all from one page.

## Run it

```bash
node control/server.js
# then open http://127.0.0.1:4319
```

Zero dependencies (Node's built-ins only) — no `npm install`. To change the port:
`PORT=5000 node control/server.js`. Bound to `127.0.0.1` only — it is not exposed
to your network and has no login, so keep it local.

## What each part does

- **Feed it tasks** — type a task in plain English, optionally tag an area
  (nutrition, activity, restore, companion, profile, onboarding, healthkit,
  firebase, ios, bug-hunt, security) and priority, click *Add*. It goes into
  `control/tasks.json`. The loop reads the queue, works the top task,
  build-verifies with `xcodebuild`, commits, and marks it done with the commit
  hash + a one-line result shown back here.
- **Activity log** — every fix/feature the loop has shipped (parsed from
  `AUTONOMOUS_LOG.md`).
- **Changes** — the branch's commits; click one to expand its full diff.
- **Deploy** — inactive for now. The app has no backend wired yet (Firebase,
  HealthKit, Auth are stubbed), so there is nothing to deploy. Once a Firebase
  project exists, add its targets to `ALLOW` in `server.js` and the panel lights up.
- **Security & guardrails** — what the loop will and won't touch.
- **Pause / Resume** — stops the loop from picking up the next task (in-flight
  work finishes cleanly). The big switch when you want it to stop.

## How the autonomy actually works (important)

The dashboard is the **control surface**; it does **not** run Claude itself and
never pushes code. The actual coding is done by the Claude loop, which reads this
queue and writes its progress back. So "it keeps doing tasks while I'm away" holds
**as long as the Claude session and this Mac stay awake** (keep it plugged in;
consider `caffeinate -dimsu` to prevent sleep). Closing the session stops the loop;
your queue + logs persist and resume when you start it again.

## Files

| File | Role |
|---|---|
| `server.js` | the dashboard server + JSON API (reads repo state, reads/writes the two control files) |
| `public/index.html` | the dashboard UI |
| `progress.js` | called by the loop at each phase boundary to move the live progress bar |
| `tasks.json` | the task queue (gitignored, runtime) |
| `state.json` | loop state: `paused`, `current`, `heartbeat`, autonomy flags (gitignored, runtime) |
| `LESSONS.md` | what the loop learned from its own failures, read before each task |
| `../AUTONOMOUS_LOG.md` | the human-readable activity log the loop appends to |
| `../.claude/AUTONOMOUS_LOOP.md` | the worker protocol (incl. how the queue is consumed) |
