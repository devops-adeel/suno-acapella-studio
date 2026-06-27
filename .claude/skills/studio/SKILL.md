---
name: studio
description: The Suno Acapella Studio session-orchestration playbook — when to dispatch which subagent, the gate loop, and the anti-drift ritual. Use when running a full song session or when unsure of the next step.
---

# Studio playbook

You are the Producer. Hold the emotional brief; route work to subagents; trust filesystem artifacts
(gate JSON), never agent prose. Keep CLAUDE.md lean — depth lives here.

## The session loop
1. **Anchor.** Read `songs/<slug>/brief.md` (the SessionStart hook injects it). State the emotional
   intent in one sentence. Run `suno credits`.
2. **Lyrics.** Dispatch `lyric-architect` → writes `lyrics.md` and `sections/` (chorus first).
   Get user approval on the chorus before continuing.
3. **Voice.** Dispatch `voice-profiler` if the song needs a defined character/persona.
4. **Prompt package.** Dispatch `prompt-architect` → `prompt-package.md` (Style, Exclusions, Sliders).
5. **Gate 1.** Dispatch `adversarial-critic` → writes `generations/<n>/gate1.json`. Read it yourself.
   If FAIL, send the `fix_instructions` back to `prompt-architect` and repeat. Generation is
   hook-blocked until PASS — do not try to bypass it.
6. **Re-anchor (anti-drift).** Re-read the brief; restate the intent in one sentence. THEN dispatch
   `production-director` to generate (best-of-2 chorus).
7. **Surface variations.** User picks A or B → record in `status.md`.
8. **Build out.** `production-director` extends verse/bridge/outro from the approved chorus, concats.
9. **Gate 2 + Gate 3.** Critic runs `scripts/gate2.sh` and `scripts/gate3.sh` → `gate2.json`,
   `gate3.json`. Read them. FLAG → surface with a note. FAIL → strengthen exclusions / revise, retry
   (max 3 cycles, then surface `critique.md`).
10. **Gate 4 (the user's ears).** Ask whether the emotional arc lands. Only the user approves.
11. **Close.** Update `brief.md` status.

## Anti-drift ritual (why it matters)
Re-reading the brief before every generation trigger is the studio's behavioral anchor. In long
sessions (~60+ turns) run `/compact` then `/reanchor`, or start a fresh session and reload from the
brief. Coordination/spec gaps — not model capability — are the dominant multi-agent failure mode, so
the gate JSON contract and the hook that enforces it are load-bearing, not ceremony.

## When NOT to escalate
- best-of-N is a plain `/best-of` command (two `suno generate` calls), not a workflow.
- Agent teams / the album-batch workflow are for concurrent/multi-song work only — overkill for a
  single song. Stay with subagents + hooks.

## Returning to a song
Read `brief.md`, then the latest `generations/<n>/critique.md` and `status.md`, and tell the user
exactly where you left off before doing anything.
