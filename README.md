# Suno Acapella Studio

A personal **acapella** music-production studio that runs inside Claude Code and drives
[`suno-cli`](https://github.com/paperfoot/suno-cli). You arrive with a concept and an emotional
state; the studio co-writes lyrics, engineers a Suno prompt package, generates **pure-vocal** output
(lead voice, backing harmonies, beatboxing), runs three automated quality gates, and surfaces results
for your approval.

> **No instruments. Ever.** The Style + Exclusions fields enforce it, and a hook blocks any
> `--instrumental` generation outright.

## What's in here

| Layer | Where | Purpose |
|---|---|---|
| Producer context | `CLAUDE.md` | Identity, routing, non-negotiable rules (loaded every session) |
| Subagents | `.claude/agents/` | lyric-architect, prompt-architect, voice-profiler, adversarial-critic, production-director |
| Skills (vendored) | `.claude/skills/` | `suno` (CLI reference, self-contained), `studio` (orchestration playbook) |
| Hooks | `.claude/hooks/` | `gate-check` (blocks generation without a Gate-1 PASS), `inject-brief` (anti-drift anchor) |
| Commands | `.claude/commands/` | `/new-song`, `/switch`, `/credits`, `/gate-status`, `/surface`, `/reanchor`, `/best-of` |
| Gate scripts | `scripts/gate2.sh`, `gate3.sh` | Automated Gate 2 (stem loudness) and Gate 3 (lyric-alignment coverage) |
| Dry-run shim | `scripts/suno` | Fixture-backed `suno` for offline testing (0 credits) |
| References | `references/` | Exclusions bank, acapella formulas, vocal-tag bank, metatag-arc library |
| Optional | `.claude/teams/`, `workflows/` | Agent team + album-batch workflow — advanced, not used for one song |

The full design rationale (and the research it's grounded in) is in
[`suno-acapella-studio-guide-v2.md`](./suno-acapella-studio-guide-v2.md).

## The quality gates

1. **Gate 1 — prompt review.** The critic writes `gate1.json`. Generation is **hook-blocked** until
   it shows `"result":"PASS"` — the rule "never generate without a PASS" is enforced by code, not
   discipline.
2. **Gate 2 — instrumental leakage.** `scripts/gate2.sh` runs `suno stems` and measures the
   *instrumental* stem's **loudness** with ffmpeg (mean dB). (File size is meaningless for WAV; if
   ffmpeg is missing it falls back to a byte-size proxy and says so.)
3. **Gate 3 — lyric-fidelity proxy.** `scripts/gate3.sh` runs `suno timed-lyrics` and computes
   **alignment coverage** — the fraction of your words Suno could place in the audio. (This is a
   coverage check, not a transcription diff; true ASR on sung audio is noisy and intentionally not
   used.)
4. **Gate 4 — your ears.** Emotional quality is yours alone, by design.

## Quickstart

```bash
# 1. Prereqs: Claude Code, suno-cli (brew tap paperfoot/tap && brew install suno), ffmpeg, jq.
bash scripts/setup.sh

# 2. Authenticate Suno (live use). Log in to suno.com in your browser first, then:
suno auth --login && suno credits

# 3. Start a song and open the studio.
./scripts/new-song.sh forgiveness-grief
claude .
# then: "Let's start a new song. I've scaffolded songs/forgiveness-grief/"
```

## Try it offline first (0 credits)

Everything is testable without a Suno account using the dry-run shim:

```bash
bash scripts/test-pipeline.sh      # 12 assertions across the whole pipeline
```

This exercises the gate-check hook (block/allow/instrumental), a dry-run generation, Gate 2 (PASS +
FAIL), Gate 3 (PASS + FAIL), and brief-injection — all from fixtures, spending nothing.

`SUNO_DRYRUN=1` plus `scripts/` on `PATH` makes `suno` a fixture-backed shim. The **same code** hits
the real CLI when `SUNO_DRYRUN` is unset.

## Self-contained skill

The `suno` capability reference is **vendored** at `.claude/skills/suno/SKILL.md` and committed, so
anyone who clones this repo gets full CLI awareness without running `suno install-skill` (which would
write to `~/.claude/`). Refresh it from a live install with `suno agent-info`.

## Calibrate before you trust the gates

The shipped Gate 2 dB threshold (`mean ≲ −50 dB`) and Gate 3 coverage threshold (`≥ 0.85`) are
**starting points**, not validated cutoffs. After your first real generation, check `gate2.json` /
`gate3.json` against what you hear and tune via env vars:
`SUNO_GATE2_PASS_DB`, `SUNO_GATE2_FLAG_DB`, `SUNO_GATE3_PASS`, `SUNO_GATE3_FLAG`.

## Caveats

- `suno-cli` is unofficial and can break when Suno changes their API — `suno update`, then
  `suno auth --refresh`.
- Voice persona creation is a manual web step (suno.com → Voices); the CLI can't automate it.
- Agent teams and the album-batch workflow are experimental/optional and never part of the
  single-song flow.
