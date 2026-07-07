---
name: ffmpeg
description: Reference for using ffmpeg volumedetect in Gate 2 — how to measure instrumental leakage dBFS, interpret readings, run calibration, and set SUNO_GATE2_PASS_DB / SUNO_GATE2_FLAG_DB thresholds. Read by adversarial-critic when running or interpreting Gate 2.
---

# ffmpeg Gate 2 Reference (vendored)

Gate 2 uses ffmpeg's `volumedetect` filter to measure energy in the instrumental stem
produced by `suno stems`. This file is the authority on what the readings mean and how to
act on them. Updated when calibration is run.

> Version installed: 8.1.2 (Homebrew, arm64). Confirmed working 2026-06-27.

---

## The volumedetect command

`gate2.sh` runs this internally — you do not call ffmpeg directly:

```bash
ffmpeg -i <instrumental_stem.wav> -af volumedetect -f null - 2>&1
```

Parse `mean_volume` from stderr output:
```
[Parsed_volumedetect_0 @ ...] mean_volume: -52.3 dB
[Parsed_volumedetect_0 @ ...] max_volume: -18.1 dB
```

**Use `mean_volume` only.** `max_volume` reflects brief transients; mean reflects sustained
energy, which is what matters for detecting continuous instrument leakage.

---

## What dBFS means

- **0 dBFS** = digital full scale (clipping). Louder = closer to 0.
- **More negative** = quieter = less energy = less leakage.
- **-inf** = true digital silence (not physically achievable in a stem).

Gate 2 measures the instrumental stem, not the vocal stem. A low reading on the instrumental
stem means Suno's separator cleanly isolated the voice and left little instrument signal
behind — which is what you want for an acapella production.

---

## Expected reading ranges

| Scenario | Approximate mean_volume range |
|---|---|
| Clean acapella, Suno's own separator | -40 to -60 dBFS |
| Minimal instrument leakage | -30 to -40 dBFS |
| Audible instrument leakage | -20 to -30 dBFS |
| Heavy instrument presence | above -20 dBFS |
| Digital silence (test fixture) | around -73 dBFS |

> These are estimates. Suno's separator model and the specific song content both affect the
> reading. Calibration on throwaway clips (the gate2-calibration song) anchors the thresholds
> empirically for this studio's typical output.

---

## Current thresholds (defaults — not yet calibrated)

| Variable | Default | Meaning |
|---|---|---|
| `SUNO_GATE2_PASS_DB` | `-50` | Below this → PASS (clean) |
| `SUNO_GATE2_FLAG_DB` | `-30` | Above this → FAIL; between → FLAG |

Set in `.claude/settings.json` under `"env"`. Default values are conservative placeholders.
**Do not treat defaults as calibrated.** They will be replaced after calibration (see below).

---

## Gate 2 status: PENDING CALIBRATION

`suno stems` is broken in suno-cli v0.5.7 — the CLI cannot parse the stem API response
(array of stem objects deserialized as a single `Clip` struct; required `model_name` field
missing). Issue filed: https://github.com/paperfoot/suno-cli/issues/5

**Calibration clips are saved and ready** — no new credits needed once the bug is fixed:
- `b8759abd-6a12-4538-8c45-d0dc78f26753` → `songs/gate2-calibration/generations/001/audio/`
- `40c54f63-a66b-456d-a1fa-c042cc710820` → `songs/gate2-calibration/generations/002/audio/`

Run `/calibrate-gate2` after `suno update` confirms the stems bug is fixed.

---

## Calibration decision tree

After running gate2.sh on both calibration clips and reading `mean_volume` from each
`gate2.json`:

```
worst_case = max(reading_001, reading_002)   # loudest = most leakage = worst case

PASS_DB  = worst_case - 10   # headroom below the clean baseline
FLAG_DB  = worst_case + 10   # early warning for real productions
```

Example: if worst-case reading is -48 dBFS:
- PASS_DB = -58
- FLAG_DB = -38

Update `.claude/settings.json`:
```json
{
  "env": {
    "SUNO_GATE2_PASS_DB": "-58",
    "SUNO_GATE2_FLAG_DB": "-38"
  }
}
```

---

## MANUAL fallback procedure

When `gate2.sh` returns `"result":"MANUAL"` (stems unavailable):

1. Open the clip on suno.com.
2. Use **Split from Mix** (Pro plan feature — appears in the clip's actions).
3. Download the instrumental stem.
4. Save it to `songs/<slug>/generations/<n>/audio/stems/instrumental.wav`.
5. Re-run: `bash scripts/gate2.sh <clip_id> songs/<slug>/generations/<n>`.

The script will detect the local file, run volumedetect, and write `gate2.json` properly.
