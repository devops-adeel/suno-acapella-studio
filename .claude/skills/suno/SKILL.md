---
name: suno
description: Capability reference for the suno-cli (paperfoot/suno-cli, Rust) — how to generate, extend, concat, split stems, get timed lyrics, and read JSON output for acapella production. Use whenever invoking the `suno` command. Vendored in-repo so the studio is self-contained (no `suno install-skill` needed).
---

# suno-cli reference (vendored)

A single Rust binary that talks to Suno's API. Every command supports `--json` for machine-readable
output. This file is committed to the repo so anyone who clones it has full CLI awareness without
running `suno install-skill`. To refresh from a live install: `suno agent-info` (machine-readable
capabilities) — paste relevant fields here.

> Offline: with `SUNO_DRYRUN=1` and `scripts/` on PATH, `suno` is a fixture-backed shim (0 credits).

## Auth & housekeeping
- `suno auth --login` — extract session from your browser (Chrome/Arc/Brave/Firefox/Edge).
- `suno auth --refresh` — force a fresh JWT. `suno auth --login` — full re-auth if refresh fails.
- `suno credits` — balance + plan. `suno models` — model list. `suno update` — self-update (run
  first when the API drifts: fixes `schema_drift`).

## Create
- `suno generate` — custom mode: lyrics + tags + title + sliders + persona.
- `suno describe --prompt "..."` — Suno writes the lyrics.
- `suno lyrics` — lyrics only (free, no credits).
- `suno extend <id> --lyrics-file f` — continue a clip (used to build sections off the chorus).
- `suno concat <id1> <id2> ...` — stitch clips into a full song.
- `suno cover <id>` / `suno remaster <id>` — restyle / re-model an existing clip.

### generate flags (key ones)
| Flag | Meaning | Notes |
|---|---|---|
| `--title` | song title | ≤100 chars |
| `--tags` | Style field | ≤1000 chars; positions 1–3 must be acapella-specific |
| `--exclude` | Exclusions field | ≤1000 chars; use the FULL exclusions-bank set |
| `--lyrics-file` / `--lyrics` | lyrics with `[Section]` tags | ≤5000 chars |
| `--model` | `v5.5` (chirp-fenix, default) | |
| `--vocal` | `male` \| `female` | always set explicitly |
| `--persona` | voice persona UUID | from suno.com → Voices |
| `--weirdness` | 0–100 | 20–40 for acapella |
| `--style-influence` | 0–100 | 65–75 |
| `--variation` | high \| normal \| subtle | |
| `--instrumental` | **NO VOCALS — FORBIDDEN here** | the gate-check hook blocks it |
| `--wait` | block until done | |
| `--download <dir>` | auto-download after generation | put under the gen's `audio/` |

## Quality-gate commands
- `suno stems <id> --json --wait` → vocals + instrumental split (`/api/edit/stems/`). Gate 2 measures
  the **instrumental** stem's loudness. (`--instrumental` on *generate* is unrelated and forbidden.)
- `suno timed-lyrics <id> --json` → word-level **aligned** lyrics (`aligned_lyrics/v2`), each word
  with a `success` flag. This is forced alignment of the SUBMITTED lyrics, not a transcription. Gate
  3 uses the fraction of `success:true` words as a coverage/fidelity proxy. `--lrc` for LRC output.
- `suno info <id> --json` → full clip detail (`audio_url`, status, etc.).

## JSON & exit codes (agent-friendly)
- Pipe-detected `--json`; progress/errors → stderr.
- Exit codes are semantic: `0` success · `1` runtime/network (retry) · `2` config (don't retry) ·
  `3` auth (`suno auth --refresh`) · `4` rate-limit (wait, retry).

## Acapella idioms (this studio)
- Never lead the Style field with a genre name or BPM — they pull in instruments.
- Belt-and-braces: `no instruments, no accompaniment` inline in Style AND the full `--exclude` set.
- Remove-FX workaround (Pro plan): `dry vocal, close-mic, no reverb` in Style.
- Build section-by-section from the chorus (`extend` → `concat`); never single-shot a whole song.
