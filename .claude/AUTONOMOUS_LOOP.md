# Autonomous Loop — Worker Protocol (Wellness App)

You are the worker for the Wellness app autonomous loop. The control dashboard
(`control/server.js`) is the human's control surface; you are the hands. This
file is the contract. Read it, and `control/LESSONS.md`, at the start of every
unit of work.

Repo root: `/Volumes/X9 Pro/Wellness and Health` (note the spaces — always quote paths).

## The loop

1. **Check the kill switch.** Read `control/state.json`. If `paused` is true, stop
   picking up new work (finish anything already in flight, then idle).
2. **Read lessons.** Read `control/LESSONS.md` so you don't repeat past mistakes.
3. **Pick the next task** from `control/tasks.json`:
   - If a task is already `in_progress`, resume it.
   - Otherwise take the top `pending` task (high priority first, then FIFO).
   - If there are no pending tasks and `autonomy.selfDirected` is true, find
     something worth doing yourself (see Self-directed below). If `selfDirected`
     is false, idle.
4. **Start it.** Set the task `status: "in_progress"`, `startedAt: <ISO now>`, and
   call `node control/progress.js <taskId> 5 "starting"` to move the bar + refresh
   the heartbeat.
5. **Do the work** on the working branch (see Branch). Call
   `node control/progress.js <taskId> <0-100> "<phase>"` at each phase boundary
   (e.g. "reading", "editing", "building", "reviewing") so the dashboard shows
   live progress.
6. **Build-verify** (mandatory, see Build). No `** BUILD SUCCEEDED **`, no commit.
7. **Self-review** (mandatory, see Review). Independently re-check that the task
   was actually done and nothing regressed. If it fails, revert and fix — do not
   commit failing work.
8. **Commit** to the working branch with a clear message. Never commit to `main`.
9. **Mark done.** Update the task: `status: "done"`, `doneAt`, `commit: "<short
   hash>"`, `durationSeconds`, `result: "<one line>"`, and
   `review: { status: "passed", notes: "" }`. Append a row to `AUTONOMOUS_LOG.md`.
10. **On any failure** (build, review), append a line to `control/LESSONS.md`
    describing what went wrong and the rule to follow next time.

Write `tasks.json` / `state.json` by reading, mutating a real object, and writing
it back — never `node -e` with prose-heavy literals (it corrupts JSON). Prefer a
small script file in scratchpad for non-trivial mutations.

## Branch

Work on `auto/build-out` (create it off `main` if it does not exist). `main` is
never touched directly. No force-push, no history rewrite, no destructive git ops.
The dashboard shows commits on this branch ahead of `main`.

## Build (verify command)

```bash
cd "/Volumes/X9 Pro/Wellness and Health"
xcodebuild -project "Wellness App.xcodeproj" -scheme "Wellness App" \
  -destination 'generic/platform=iOS Simulator' build CODE_SIGNING_ALLOWED=NO
```

Trust only a real `** BUILD SUCCEEDED **`. Ignore single-file SourceKit
diagnostics — they are phantom without the full module graph. For UI-affecting
work, also boot a simulator, install, and launch to confirm no runtime crash
(pin a booted sim id; remember app env vars need the `SIMCTL_CHILD_` prefix).

## Review (independent self-check)

After the build passes, re-read the diff with fresh eyes against the task text:
was every part done? Any regression, dead code, or convention break? Confirm the
project conventions hold: no em dashes anywhere, `HealthMath` stays unit-tested,
stores keep their `// SYNC:` seams, shared components are reused not duplicated.
Only a task that passes this review may be committed.

## Self-directed work (when the queue is empty)

If `selfDirected` is on and nothing is queued, pick high-value work: wiring a
stubbed seam (Firebase, HealthKit, Auth) behind its `// SYNC:` marker, adding
`HealthMath` unit tests, fixing a real bug, or improving a rough screen. Same
rules: build-verify, review, commit, log.

## Guardrails (never cross these)

- Never modify or expose secrets/keys, `GoogleService-Info.plist`, `functions/.env`,
  code-signing settings, or `*.storekit` IDs.
- Never touch `main` directly; no force-push or history rewrite; no destructive
  data ops.
- Deploy is inactive (no backend wired). Never attempt a production deploy until
  targets exist in `control/server.js`'s `ALLOW` list; deploys stay human-triggered.
- Auth/login-critical and billing/IAP changes (when they exist) are staged and
  flagged for the human, not auto-shipped.

## Heartbeat

`progress.js` refreshes `state.heartbeat` and `state.current` each time you call
it, so the dashboard shows the loop is alive and what it is working on. Call it
regularly during long tasks.
