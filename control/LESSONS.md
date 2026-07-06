# Loop Lessons — what the loop learned from itself

The loop reads this at the start of every unit of work and appends a line
whenever a build, self-review, or commit fails, so it stops repeating mistakes.
One lesson per line: `YYYY-MM-DD — <what went wrong> → <the rule to follow>`.

- 2026-07-05 — SourceKit reports phantom "Cannot find type X in scope" errors across files because it indexes file-by-file without the whole module graph → trust a full `xcodebuild ** BUILD SUCCEEDED **`, never single-file diagnostics.
- 2026-07-05 — the Xcode project uses filesystem-synchronized groups, so any `.swift` file created under `Wellness App/` auto-joins the target → never hand-edit `project.pbxproj` to add files; just write the file.
- 2026-07-05 — the repo lives at `/Volumes/X9 Pro/Wellness App` (spaces in the path) → always quote paths in shell commands.
- 2026-07-05 — a shared `SectionHeaderRow` had a positional init only for the no-accessory (EmptyView) case, so `SectionHeaderRow("Title") { accessory }` failed with "missing argument label 'title:'" → when a shared component is used two ways, give it both inits rather than fixing every call site.
- 2026-07-05 — `Color(.secondarySystemBackground)` sometimes fails to resolve; `Color(uiColor: .secondarySystemBackground)` is unambiguous → prefer the explicit `uiColor:` initializer.
- 2026-07-05 — build verify runs against the iOS Simulator; use `xcodebuild -project "Wellness App.xcodeproj" -scheme "Wellness App" -destination 'generic/platform=iOS Simulator' build CODE_SIGNING_ALLOWED=NO`, or pin a booted sim id for install+launch smoke tests.
- 2026-07-05 — `simctl launch ... KEY=value` passes KEY=value as an argv arg, not an env var; app env vars must be prefixed `SIMCTL_CHILD_` in the caller's environment → `SIMCTL_CHILD_START_TAB=activity xcrun simctl launch ...`.
- 2026-07-05 — project convention: NO em dashes anywhere in code, comments, or copy; HealthMath must stay unit-tested; stores mark backend seams with `// SYNC:` → preserve these when editing.
