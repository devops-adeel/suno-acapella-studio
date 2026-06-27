# Suno Acapella Studio

A personal acapella production studio. You arrive with a concept and an emotional state;
the system co-writes lyrics, engineers a Suno prompt package, generates pure-vocal output,
runs technical quality gates, and surfaces results for your approval.

## Identity
Every output is pure vocals: lead voice, backing harmonies, beatboxing. **No instruments. Ever.**
Model: Suno v5.5 (chirp-fenix). Plan: Pro · 2,500 credits/month. CLI: `suno` (paperfoot/suno-cli).

## Session Start
1. The SessionStart hook injects the active song's `brief.md`. If none, ask which song to work on,
   or scan `songs/` for work in progress (`./scripts/new-song.sh <slug>` to scaffold).
2. Read `songs/<slug>/brief.md` first — it is the emotional anchor for the whole session.
3. Read `songs/<slug>/lyrics.md` if it exists; check `songs/<slug>/generations/` for prior attempts.
4. **Before every generation trigger: re-read the brief and state the emotional intent in one
   sentence before dispatching to `production-director`.** (This is the studio's anti-drift ritual.)
5. Run `suno credits` at session start.

## Active Song
The machine-readable pointer is `.studio/active-song`. `/new-song` and `/switch` keep it current.

## Agent Routing (dispatch to subagents — never do their work inline)
- Lyric co-writing    → `lyric-architect`     (Opus)
- Prompt engineering  → `prompt-architect`    (Opus)
- Voice persona work  → `voice-profiler`      (Sonnet)
- Quality gates       → `adversarial-critic`  (Sonnet)
- Suno generation     → `production-director` (Haiku)

Coordination routes through you (the Producer). Agents never talk to each other. **Trust flows from
filesystem artifacts (the gate JSON files), not from any agent's prose summary.**

## Studio Rules (non-negotiable — some are hook-enforced)
- **Hook-enforced:** generation is blocked unless that generation's `gate1.json` shows
  `"result":"PASS"` (PreToolUse `gate-check.sh`). Don't try to route around it; fix the gate.
- **Hook-enforced:** `--instrumental` is always blocked (it would defeat the studio's purpose).
- Style field: always open with acapella tags in positions 1–3; never lead with a genre name.
- Exclusions: always use the full set from `references/exclusions-bank.md`; never abbreviate.
- Verify gate JSON files exist and read them directly — never trust a prose claim that a gate passed.
- Max 3 retry cycles before surfacing to the user with `critique.md`.
- `suno credits` before every generation batch.
- Best-of-2 for chorus/hook; best-of-1 for outros/verse 2. (`/best-of` runs a batch.)

## Quality Gates (all three are automated; each has a manual fallback)
- **Gate 1 — pre-generation prompt review.** Critic writes `gate1.json` (PASS/FAIL). Generation is
  hook-blocked until PASS.
- **Gate 2 — instrumental leakage.** `scripts/gate2.sh` runs `suno stems`, measures the
  *instrumental* stem's loudness with ffmpeg (mean dB) — NOT file size. Writes `gate2.json`.
- **Gate 3 — lyric-fidelity proxy.** `scripts/gate3.sh` runs `suno timed-lyrics` and computes
  alignment **coverage** (fraction of words Suno could place in the audio). Writes `gate3.json`.
- **Gate 4 — your ears.** Emotional quality and artistic merit are yours alone, by design.

## Pro Plan Notes
- Stems: `suno stems` = vocals + instrumental (used for Gate 2). `--instrumental` is forbidden here.
- No Suno Studio, no Advanced Split, no Remove FX on Pro — use `dry vocal, close-mic, no reverb` in
  the Style field as the Remove-FX workaround.

## Offline / dry-run
`SUNO_DRYRUN=1` + `scripts/` on PATH makes `suno` a fixture-backed shim (0 credits). The whole
pipeline is self-testable: `bash scripts/test-pipeline.sh`.

## End of Session
Update `songs/<slug>/brief.md` status. For sessions past ~60 turns, run `/compact` and `/reanchor`,
or start fresh and reload from the brief (drift mitigation).

## Honest caveats
- Gate 2 dB thresholds and Gate 3 coverage thresholds are starting points; calibrate them on one real
  generation before trusting them (see the plan / README).
- `suno-cli` is unofficial and can break when Suno changes their API — `suno update`, then
  `suno auth --refresh`.
