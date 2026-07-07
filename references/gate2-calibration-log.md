# Gate 2 Calibration Log

## Session: 2026-06-27

### Song: gate2-calibration (throwaway)
Lyrics: 10-line acapella, emotionally neutral morning-gratitude meditation.
Purpose: Empirically anchor Gate 2 dB thresholds for the instrumental leakage check.

---

## Generations Produced

| Clip ID (full UUID) | Duration | File |
|---|---|---|
| `b8759abd-6a12-4538-8c45-d0dc78f26753` | 48.6s | gate-2-calibration--open-morning-b8759abd.mp3 |
| `40c54f63-a66b-456d-a1fa-c042cc710820` | 43.1s | gate-2-calibration--open-morning-40c54f63.mp3 |
| `2d848894-5329-4856-9f62-61b8ad28efda` | 131.9s | (not used for calibration) |
| `66032a6f-9792-4eda-845e-a69c77b1f806` | 479.4s | (not used for calibration) |

Total clips generated: 8 (suno-cli retried due to timeout/rate-limit; ~80 credits consumed).

---

## Gate 2 Status: BLOCKED (suno-cli v0.5.7 bug)

### What happened
`suno stems <clip_id> --json` returns HTTP 200 but exits with error:
```
{"code":"http_error","message":"error decoding response body"}
```
All clip IDs tested. Auth refresh did not resolve. CLI is up-to-date (v0.5.7).

### Root cause
suno-cli v0.5.7's `stems` command cannot parse the current Suno API response format —
the `stems` endpoint response schema has changed since the CLI was last updated. This is
a known risk documented in CLAUDE.md ("suno-cli is unofficial and can break when Suno changes
their API").

### Confirmed working
- `suno info <clip_id>` returns `"has_stem": true` — stems exist on Suno's servers.
- The clips were successfully generated and downloaded as MP3.
- gate2.sh wrote `"result": "MANUAL"` with the correct fallback note.

### Demucs experiment (NOT usable for calibration)
Local stem separation via demucs 4.0.1 / htdemucs model was attempted.
For a pure-acapella source, demucs leaks substantial vocal energy into its "no_vocals" stem:

| Stem | Mean dB | Max dB |
|---|---|---|
| Full mix (original acapella) | -16.5 dB | -0.8 dB |
| Demucs vocals | -16.9 dB | -0.9 dB |
| Demucs no_vocals (instrumental) | **-27.5 dB** | -3.3 dB |

The -27.5 dB reading is almost entirely vocal bleed from demucs's separation model
(which was trained on mixed music, not pure-vocal sources). This reading CANNOT be used
to set Gate 2 thresholds — it would produce a far too permissive PASS_DB that would accept
actual instrument leakage in real productions.

**The calibration procedure requires Suno's own stem separator, not a third-party model.**

### Action required
1. Track fix at: https://github.com/paperfoot/suno-cli/issues/5
2. When fixed: run `suno update` or reinstall from brew, then re-run calibration:
   ```bash
   bash scripts/gate2.sh b8759abd-6a12-4538-8c45-d0dc78f26753 songs/gate2-calibration/generations/001
   bash scripts/gate2.sh 40c54f63-a66b-456d-a1fa-c042cc710820 songs/gate2-calibration/generations/002
   ```
   The calibration clips are saved and ready. No new generation credits needed.
3. Apply the decision tree from the plan to set NEW_PASS_DB and NEW_FLAG_DB.
4. Persist in `.claude/settings.json` under `"env"`.

---

## Gate 3 Results: PASS (both variations)

| Variation | Clip | Coverage | Result |
|---|---|---|---|
| 001 | b8759abd | **1.000 (100%)** | PASS |
| 002 | 40c54f63 | **1.000 (100%)** | PASS |

**Finding:** 100% lyric placement on both variations. The Gate 3 default PASS threshold
of 0.85 (85%) is confirmed as conservative for clean, simple, rhythmically clear lyrics
with close-mic dry vocal delivery. No adjustment needed.

---

## Current Threshold Status

| Gate | Parameter | Current Value | Calibrated? |
|---|---|---|---|
| Gate 2 | SUNO_GATE2_PASS_DB | -50 dB (default) | **Pending — awaiting suno-cli fix** |
| Gate 2 | SUNO_GATE2_FLAG_DB | -30 dB (default) | **Pending — awaiting suno-cli fix** |
| Gate 3 | SUNO_GATE3_PASS | 0.85 (default) | Confirmed appropriate (100% observed) |
| Gate 3 | SUNO_GATE3_FLAG | 0.60 (default) | Not tested with low-fidelity case |

---

## ffmpeg Installation Confirmed

- Version: 8.1.2 (Homebrew, arm64_tahoe)
- Fixture silent WAV reads: -73.4 dBFS mean (confirms filter works; fixture has low-level content)
- All 12 fixture-backed tests: **PASS**
- Gate 2 will use `ffmpeg-volumedetect` method (not byte-size fallback) once stems are available.
