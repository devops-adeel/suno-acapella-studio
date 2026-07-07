# Changelog

All notable changes to the Suno Acapella Studio are documented here.

---

## [Unreleased] — 2026-06-27

### Infrastructure hardening (post-calibration session)

#### Fixed

- **gate-check hook false positives** — `studio_gen_dir_from_cmd` in `lib.sh` previously
  extracted `songs/*/generations/*` from anywhere in the command string, causing the hook to
  fire on commands like `gh issue create --body "...suno generate..."`. The function now
  extracts the generation path exclusively from the `--download` flag, matching only actual
  studio generation invocations. The empty-gen-dir branch in `gate-check.sh` now allows when
  `--download` is absent (text mention, not a real invocation) and denies with a clear message
  when `--download` is present but the path is malformed.

- **prompt-architect CLI flag errors** — The agent previously invented incorrect flag names
  (`--style`, `--vocal-gender`, `--model chirp-fenix`). Root cause: the suno skill containing
  the authoritative flag table was not in the agent's read list. Fixed by:
  - Adding `.claude/skills/suno/SKILL.md` as the first item in prompt-architect's "Read first" list.
  - Adding an explicit YAML→CLI flag mapping table to the agent constitution.
  - Adding an "Authoritative generate command" section to the `prompt-package.md` output format,
    making the generate command a canonical execution artifact rather than an informal reference.

- **production-director silent retry loop** — The agent previously retried on network/rate-limit
  failures autonomously, burning ~80 credits instead of ~20 in the calibration session. Replaced
  the error-handling table with an explicit confirm-before-retry policy: any non-zero exit code
  causes the agent to stop, record exit code + error + credit balance before and after, and
  surface to the Producer. No retry without explicit instruction.

#### Added

- **`adversarial-critic` Gate 1 CLI flag check** — Gate 1 now fails if `prompt-package.md`
  uses wrong flag names (`--style`, `--vocal-gender`, `--model chirp-fenix`) or if the
  authoritative generate command section is absent entirely. Provides a second validation layer
  on top of prompt-architect's improved knowledge.

- **`adversarial-critic` Gate 2 ffmpeg skill read** — Gate 2 instructions now direct the
  critic to read `.claude/skills/ffmpeg/SKILL.md` before interpreting any Gate 2 result.

- **`/ffmpeg` skill** (`.claude/skills/ffmpeg/SKILL.md`) — Vendored reference for the ffmpeg
  `volumedetect` filter used in Gate 2. Documents: the exact command gate2.sh runs, what
  `mean_volume` dBFS means (RMS-based energy, not peak), expected reading ranges for clean
  acapella vs. leaky stems, current default thresholds with calibration-pending status, the
  calibration decision tree (worst-case - 10 dB / + 10 dB), and the MANUAL fallback procedure
  (Split from Mix on suno.com). Analogous to the suno skill — a tool agents depend on through
  scripts, now in the knowledge graph.

- **`/calibrate-gate2` skill** (`.claude/skills/calibrate-gate2/SKILL.md`) — One-command Gate 2
  calibration runbook. Runs `gate2.sh` on both saved throwaway calibration clips, applies the
  decision tree, and updates `.claude/settings.json` with calibrated `SUNO_GATE2_PASS_DB` /
  `SUNO_GATE2_FLAG_DB` values. Blocked until suno-cli v0.5.7 stems bug is fixed
  (paperfoot/suno-cli#5). Calibration clips are saved — no new credits needed.

- **`/status` skill** (`.claude/skills/status/SKILL.md`) — Pipeline summary at a glance.
  Reads the active song's brief status, all gate JSON files for the latest generation, and
  current credit balance. Outputs a scannable summary with an inferred "next step". Falls back
  to a table of all songs and their brief status when no active song is set.

#### Changed

- **`production-director` pre-flight** — Now reads the authoritative generate command from
  `prompt-package.md` verbatim, rather than re-deriving flag names from the YAML frontmatter.
  Removes the duplicate inline generate command template (flags are now authoritative in one
  place only — the prompt-package, informed by the suno skill).

- **`studio/SKILL.md` step 6** — Updated to note the confirm-before-retry expectation: the
  Producer should wait for production-director's failure report before authorising a retry.

- **`CLAUDE.md` honest caveats** — Gate 3 coverage threshold (0.85) confirmed calibrated
  2026-06-27: 100% coverage on both throwaway calibration clips, no adjustment needed. Gate 2
  calibration status updated: defaults are in place, pending suno-cli stems bug fix
  (paperfoot/suno-cli#5), with `/calibrate-gate2` as the path forward.

#### Studio sessions

- **Gate 2 calibration** — Generated 8 calibration clips (~80 credits) for the throwaway
  "Open Morning" gratitude meditation song. Gate 3 confirmed PASS (1.000 coverage) on both
  calibration variations. Gate 2 blocked by suno-cli v0.5.7 stems bug. Two clips saved for
  future calibration: `b8759abd-6a12-4538-8c45-d0dc78f26753` (48.6s) and
  `40c54f63-a66b-456d-a1fa-c042cc710820` (43.1s).

- **ffmpeg installed** — v8.1.2 (Homebrew, arm64_tahoe). All 12 fixture-backed pipeline tests
  pass. Silent test fixture reads -73.4 dBFS (confirms volumedetect filter works correctly).

- **suno-cli stems bug reported** — Filed paperfoot/suno-cli#5 documenting the v0.5.7 type
  mismatch: `stems()` attempts to deserialize the API response as a single `Clip` struct but
  the endpoint returns stem-specific objects; required `model_name` field is absent in stem
  responses. Also notes `--wait` flag is silently unimplemented.

---

## [1.0.0] — 2026-06-20

Initial implementation of the Suno Acapella Studio.

- Multi-agent pipeline: lyric-architect, prompt-architect, voice-profiler, adversarial-critic,
  production-director
- Three automated quality gates: Gate 1 (prompt review), Gate 2 (instrumental leakage via
  ffmpeg volumedetect), Gate 3 (lyric-fidelity proxy via suno timed-lyrics)
- Hook-enforced generation safety: gate-check PreToolUse hook blocks generation unless
  gate1.json PASS; blocks `--instrumental` unconditionally
- Offline dry-run mode: SUNO_DRYRUN=1 with fixture-backed shim scripts
- Self-test suite: `bash scripts/test-pipeline.sh` (12 assertions)
- Skills: `/suno` (CLI reference), `/studio` (session playbook)
- Session management: active-song pointer, SessionStart brief injection, `/new-song`, `/switch`
