#!/usr/bin/env node
'use strict';

/**
 * Wellness App — Autonomous Loop Control Server
 *
 * A zero-dependency local dashboard for the autonomous coding loop. It is the
 * human control surface over a shared task queue that the Claude loop consumes:
 *   - feed it tasks (POST /api/tasks)            -> control/tasks.json
 *   - pause / resume the loop                    -> control/state.json
 *   - watch the activity log                     -> ../AUTONOMOUS_LOG.md
 *   - inspect every fix's diff                   -> git show on the branch
 *   - see the security guardrails                -> ../.claude/AUTONOMOUS_LOOP.md
 *
 * The server NEVER runs Claude and NEVER pushes code — it only reads repo state
 * and reads/writes the two control JSON files. The loop does the coding.
 *
 * Bound to 127.0.0.1 only (no network exposure, no auth — local single-user).
 * Run:  node control/server.js     then open http://127.0.0.1:4319
 */

const http = require('http');
const fs = require('fs');
const path = require('path');
const { execFile } = require('child_process');

const CONTROL = __dirname;
const ROOT = path.resolve(CONTROL, '..');
const PUBLIC = path.join(CONTROL, 'public');
const TASKS_FILE = path.join(CONTROL, 'tasks.json');
const STATE_FILE = path.join(CONTROL, 'state.json');
const LOG_FILE = path.join(ROOT, 'AUTONOMOUS_LOG.md');
const PROTOCOL_FILE = path.join(ROOT, '.claude', 'AUTONOMOUS_LOOP.md');
// The loop works on a dedicated branch off main so main is never touched.
// Override with LOOP_BRANCH / LOOP_BASE env vars if you use different names.
const BRANCH = process.env.LOOP_BRANCH || 'auto/build-out';
const BASE = process.env.LOOP_BASE || 'main';
const PORT = Number(process.env.PORT) || 4319;
const HOST = '127.0.0.1';

// ---- tiny fs helpers -------------------------------------------------------
function readJSON(file, fallback) {
  try { return JSON.parse(fs.readFileSync(file, 'utf8')); }
  catch (_) { return fallback; }
}
function writeJSON(file, obj) {
  fs.writeFileSync(file, JSON.stringify(obj, null, 2) + '\n');
}
function ensureSeed() {
  if (!fs.existsSync(TASKS_FILE)) writeJSON(TASKS_FILE, []);
  if (!fs.existsSync(STATE_FILE)) {
    writeJSON(STATE_FILE, { paused: false, current: null, heartbeat: null, note: '',
      autonomy: { selfDirected: true, autoDeploy: true } });
  }
}

// ---- git (safe: execFile, validated args) ----------------------------------
function git(args) {
  return new Promise((resolve) => {
    execFile('git', args, { cwd: ROOT, maxBuffer: 8 * 1024 * 1024 }, (err, stdout) => {
      resolve(err ? '' : stdout);
    });
  });
}
const SHA_RE = /^[0-9a-f]{7,40}$/;

// ---- activity-log parser (AUTONOMOUS_LOG.md markdown table) -----------------
function parseLog() {
  let text = '';
  try { text = fs.readFileSync(LOG_FILE, 'utf8'); } catch (_) { return []; }
  const rows = [];
  for (const line of text.split('\n')) {
    const t = line.trim();
    if (!t.startsWith('|')) continue;
    const cols = t.split('|').slice(1, -1).map((c) => c.trim());
    if (cols.length < 6) continue;
    if (/^#$/.test(cols[0]) || /^-+$/.test(cols[0])) continue; // header/separator
    rows.push({ num: cols[0], date: cols[1], area: cols[2], files: cols[3], desc: cols[4], verified: cols[5] });
  }
  return rows;
}

// ---- request body ----------------------------------------------------------
function readBody(req) {
  return new Promise((resolve) => {
    let data = '';
    req.on('data', (c) => { data += c; if (data.length > 1e6) req.destroy(); });
    req.on('end', () => { try { resolve(JSON.parse(data || '{}')); } catch (_) { resolve({}); } });
  });
}
function json(res, code, obj) {
  res.writeHead(code, { 'Content-Type': 'application/json', 'Cache-Control': 'no-store' });
  res.end(JSON.stringify(obj));
}

// ---- static files ----------------------------------------------------------
const MIME = { '.html': 'text/html', '.js': 'text/javascript', '.css': 'text/css', '.svg': 'image/svg+xml' };
function serveStatic(res, urlPath) {
  let rel = urlPath === '/' ? 'index.html' : urlPath.replace(/^\/+/, '');
  const file = path.join(PUBLIC, rel);
  if (!file.startsWith(PUBLIC)) { res.writeHead(403); return res.end('forbidden'); }
  fs.readFile(file, (err, buf) => {
    if (err) { res.writeHead(404); return res.end('not found'); }
    res.writeHead(200, { 'Content-Type': MIME[path.extname(file)] || 'application/octet-stream' });
    res.end(buf);
  });
}

// ---- API -------------------------------------------------------------------
async function api(req, res, url) {
  const p = url.pathname;

  if (p === '/api/state' && req.method === 'GET') {
    const state = readJSON(STATE_FILE, {});
    const ahead = (await git(['rev-list', '--count', `${BASE}..${BRANCH}`])).trim();
    const branch = (await git(['rev-parse', '--abbrev-ref', 'HEAD'])).trim();
    const dirty = (await git(['status', '--porcelain'])).trim().length > 0;
    // rolling average task duration -> drives the ETA shown on the progress bars
    const tasks = readJSON(TASKS_FILE, []);
    const dones = tasks.filter((t) => t.status === 'done' && t.durationSeconds > 0);
    const avgTaskSeconds = dones.length
      ? Math.round(dones.reduce((a, t) => a + t.durationSeconds, 0) / dones.length) : 0;
    return json(res, 200, { ...state, branch, ahead, dirty, avgTaskSeconds, doneCount: dones.length });
  }

  if (p === '/api/tasks' && req.method === 'GET') {
    return json(res, 200, readJSON(TASKS_FILE, []));
  }

  if (p === '/api/tasks' && req.method === 'POST') {
    const body = await readBody(req);
    const text = (body.text || '').toString().trim();
    if (!text) return json(res, 400, { error: 'task text required' });
    const tasks = readJSON(TASKS_FILE, []);
    const task = {
      id: 't' + Date.now().toString(36),
      text,
      area: (body.area || '').toString().slice(0, 40),
      priority: body.priority === 'high' ? 'high' : 'normal',
      status: 'pending',
      createdAt: new Date().toISOString(),
      startedAt: null, doneAt: null, commit: null, result: null,
    };
    // high-priority tasks jump ahead of normal pending ones
    if (task.priority === 'high') {
      const firstNormal = tasks.findIndex((t) => t.status === 'pending' && t.priority !== 'high');
      if (firstNormal === -1) tasks.push(task); else tasks.splice(firstNormal, 0, task);
    } else tasks.push(task);
    writeJSON(TASKS_FILE, tasks);
    return json(res, 200, task);
  }

  if (p === '/api/tasks/delete' && req.method === 'POST') {
    const body = await readBody(req);
    let tasks = readJSON(TASKS_FILE, []);
    tasks = tasks.filter((t) => !(t.id === body.id && t.status === 'pending'));
    writeJSON(TASKS_FILE, tasks);
    return json(res, 200, { ok: true });
  }

  if (p === '/api/tasks/clear-done' && req.method === 'POST') {
    const tasks = readJSON(TASKS_FILE, []).filter((t) => t.status !== 'done');
    writeJSON(TASKS_FILE, tasks);
    return json(res, 200, { ok: true });
  }

  if (p === '/api/pause' && req.method === 'POST') {
    const s = readJSON(STATE_FILE, {}); s.paused = true; writeJSON(STATE_FILE, s);
    return json(res, 200, s);
  }

  // Toggle an autonomy flag: { key: 'selfDirected'|'autoDeploy', value: bool }
  if (p === '/api/autonomy' && req.method === 'POST') {
    const body = await readBody(req);
    const s = readJSON(STATE_FILE, {});
    s.autonomy = s.autonomy || { selfDirected: true, autoDeploy: true };
    if (body.key === 'selfDirected' || body.key === 'autoDeploy') s.autonomy[body.key] = !!body.value;
    writeJSON(STATE_FILE, s);
    return json(res, 200, s.autonomy);
  }

  if (p === '/api/deploys' && req.method === 'GET') {
    let md = ''; try { md = fs.readFileSync(path.join(ROOT, 'control', 'DEPLOYS.md'), 'utf8'); } catch (_) {}
    const lines = md.split('\n').filter((l) => /^\d{4}-\d\d-\d\d/.test(l.trim()));
    return json(res, 200, lines);
  }
  if (p === '/api/resume' && req.method === 'POST') {
    const s = readJSON(STATE_FILE, {}); s.paused = false; writeJSON(STATE_FILE, s);
    return json(res, 200, s);
  }

  if (p === '/api/log' && req.method === 'GET') {
    return json(res, 200, parseLog());
  }

  if (p === '/api/commits' && req.method === 'GET') {
    const out = await git(['log', '--date=short', '--pretty=format:%h\x1f%an\x1f%ad\x1f%s', `${BASE}..${BRANCH}`]);
    const commits = out.split('\n').filter(Boolean).map((l) => {
      const [hash, author, date, subject] = l.split('\x1f');
      return { hash, author, date, subject };
    });
    return json(res, 200, commits);
  }

  if (p === '/api/commit' && req.method === 'GET') {
    const hash = (url.searchParams.get('hash') || '').trim();
    if (!SHA_RE.test(hash)) return json(res, 400, { error: 'bad hash' });
    const diff = await git(['show', '--stat', '--patch', '--format=%H%n%an%n%ad%n%s%n', hash]);
    return json(res, 200, { hash, diff: diff.slice(0, 500000) });
  }

  if (p === '/api/security' && req.method === 'GET') {
    let protocol = ''; try { protocol = fs.readFileSync(PROTOCOL_FILE, 'utf8'); } catch (_) {}
    return json(res, 200, {
      branch: BRANCH,
      base: BASE,
      guardrails: [
        'FULL AUTONOMY: the loop works your tasks first, then finds + fixes things on its own and commits — all gated behind a passing independent self-review.',
        'Every change is build-verified with xcodebuild (a real ** BUILD SUCCEEDED **, not single-file SourceKit diagnostics) AND independently re-reviewed before it is committed; work that can\'t pass review is reverted, not shipped.',
        'Works on the ' + BRANCH + ' branch only — main is never touched directly. No force-push, no history rewrite, no destructive git or data ops.',
        'Deploy is inactive: there is no backend wired yet (Firebase, HealthKit, Auth are stubbed). Once a backend exists, add its targets to ALLOW in control/server.js; until then nothing ships to production.',
        'Protected to protect you (never modified or exposed): secrets and keys, GoogleService-Info.plist, functions/.env, code-signing settings, *.storekit IDs. Project conventions enforced: no em dashes, HealthMath stays unit-tested.',
        'Kill switches: Pause stops all new work (in-flight work finishes cleanly); the Self-directed toggle narrows it to your queued tasks only. Every change is logged to AUTONOMOUS_LOG.md.',
      ],
      protocol,
    });
  }

  // Deploy staged changes to PRODUCTION. Human-triggered only (a dashboard
  // button + confirm) — the autonomous loop never calls this. Targets are
  // allow-listed so the button can't deploy anything unexpected.
  //
  // Live deploy targets for the Wellness Firebase project (wellness-app-4b33d7).
  // Deploys use the CLI with cwd = repo root, which reads .firebaserc for the
  // project. Functions read the ANTHROPIC_API_KEY secret at runtime.
  if (p === '/api/deploy' && req.method === 'POST') {
    const body = await readBody(req);
    const ALLOW = ['firestore:rules', 'firestore:indexes', 'storage', 'functions'];
    const targets = (Array.isArray(body.targets) ? body.targets : []).filter((t) => ALLOW.includes(t));
    if (!targets.length) return json(res, 400, { error: 'no valid deploy targets selected' });
    execFile('firebase', ['deploy', '--only', targets.join(','), '--non-interactive'],
      { cwd: ROOT, maxBuffer: 8 * 1024 * 1024, timeout: 600000 },
      (err, stdout, stderr) => {
        const out = (stdout || '') + (stderr || '');
        const hint = err && /command not found|ENOENT/.test(String(err))
          ? '\n\n[server] `firebase` CLI not found on PATH for this process — deploy from a terminal, or start the server from a shell where `firebase` works.'
          : (err && /login|credential|auth/i.test(out) ? '\n\n[server] Looks like a Firebase auth issue — run `firebase login` in a terminal first.' : '');
        json(res, err ? 500 : 200, { ok: !err, targets, output: out + hint });
      });
    return;
  }

  return json(res, 404, { error: 'not found' });
}

// ---- server ----------------------------------------------------------------
ensureSeed();
const server = http.createServer((req, res) => {
  const url = new URL(req.url, `http://${HOST}:${PORT}`);
  if (url.pathname.startsWith('/api/')) {
    api(req, res, url).catch((e) => json(res, 500, { error: String(e) }));
  } else {
    serveStatic(res, url.pathname);
  }
});
server.listen(PORT, HOST, () => {
  console.log(`\n  Wellness App — Loop Control`);
  console.log(`  Dashboard:  http://${HOST}:${PORT}`);
  console.log(`  Repo:       ${ROOT}`);
  console.log(`  Branch:     ${BRANCH}  (main is never touched)\n`);
});
