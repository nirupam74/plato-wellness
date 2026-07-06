#!/usr/bin/env node
'use strict';
/**
 * Update a task's live progress + phase. Workers/verifiers call this at each
 * phase boundary so the dashboard's progress bar moves in real time.
 *
 *   node control/progress.js <taskId> <progress 0-100> [phase label]
 *
 * Also refreshes the loop heartbeat + state.current so the dashboard shows the
 * loop is alive and what it's working on.
 */
const fs = require('fs');
const path = require('path');
const TASKS = path.join(__dirname, 'tasks.json');
const STATE = path.join(__dirname, 'state.json');

const [, , id, prog, ...phaseParts] = process.argv;
const phase = phaseParts.join(' ');
if (!id) { console.error('usage: progress.js <taskId> <0-100> [phase]'); process.exit(1); }

const tasks = JSON.parse(fs.readFileSync(TASKS, 'utf8'));
const t = tasks.find((x) => x.id === id);
if (!t) { console.error('no such task', id); process.exit(1); }
if (prog !== undefined && prog !== '') t.progress = Math.max(0, Math.min(100, Number(prog)));
if (phase) t.phase = phase;
fs.writeFileSync(TASKS, JSON.stringify(tasks, null, 2) + '\n');

try {
  const s = JSON.parse(fs.readFileSync(STATE, 'utf8'));
  s.heartbeat = new Date().toISOString();
  s.current = (t.text || '').slice(0, 80) + (t.text && t.text.length > 80 ? '…' : '');
  s.note = (t.phase || 'working') + ' — ' + (t.progress || 0) + '%';
  fs.writeFileSync(STATE, JSON.stringify(s, null, 2) + '\n');
} catch (_) {}
console.log('progress', id, '->', t.progress, t.phase || '');
