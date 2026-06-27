#!/usr/bin/env node
// album-batch.mjs — OPTIONAL dynamic-workflow template (advanced / album-scale).
//
// The single-song core flow NEVER uses this. It exists only because batch work is the one place a
// dynamic workflow is genuinely the right primitive: many independent songs, fanned out in parallel,
// with the plan living in code rather than a context window.
//
// What it does (template): for each song brief under songs/<slug>/brief.md, it would fan out a
// prompt-architect + Gate-1 critic per song in parallel, then print a consolidated report. The actual
// subagent-spawn call depends on your Claude Code workflow runtime; the orchestration shape is what
// matters here. Run `node --check workflows/album-batch.mjs` to validate syntax.
//
// Usage (illustrative dry plan, no subagents):  node workflows/album-batch.mjs songs/*/brief.md

import { readFileSync, existsSync } from 'node:fs';
import { basename, dirname } from 'node:path';

const briefs = process.argv.slice(2).filter((p) => existsSync(p));
if (briefs.length === 0) {
  console.error('usage: node workflows/album-batch.mjs <songs/*/brief.md ...>');
  process.exit(2);
}

// In a real dynamic workflow, replace this stub with the runtime's parallel subagent spawns, e.g.:
//   const results = await Promise.all(jobs.map((j) => spawnSubagent('prompt-architect', j)));
// then gate each candidate with a `adversarial-critic` subagent and collect gate1.json verdicts.
async function planSong(briefPath) {
  const slug = basename(dirname(briefPath));
  const text = readFileSync(briefPath, 'utf8');
  const titleLine = text.split('\n').find((l) => l.startsWith('#')) ?? `# ${slug}`;
  return { slug, title: titleLine.replace(/^#+\s*/, ''), steps: ['prompt-architect', 'gate1-critic'] };
}

const plan = await Promise.all(briefs.map(planSong));
console.log('Album batch plan (parallel fan-out per song):');
for (const p of plan) {
  console.log(`  • ${p.slug} — "${p.title}"  →  ${p.steps.join(' → ')}`);
}
console.log(`\n${plan.length} song(s). Wire spawnSubagent() into planSong() to execute for real.`);
