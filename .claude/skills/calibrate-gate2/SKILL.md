---
name: calibrate-gate2
description: Run Gate 2 calibration on the saved throwaway clips and set SUNO_GATE2_PASS_DB / SUNO_GATE2_FLAG_DB in .claude/settings.json. Only run after suno update confirms the stems bug (paperfoot/suno-cli#5) is fixed.
tools: Read, Write, Bash
---

# /calibrate-gate2

Runs Gate 2 calibration end-to-end using the saved throwaway clips from the gate2-calibration
song. Sets calibrated thresholds in `.claude/settings.json`. No new credits needed — clips
are already saved.

**Prerequisite:** `suno stems` must be working. Run `suno update` first, then verify with:
```bash
suno stems b8759abd-6a12-4538-8c45-d0dc78f26753 --json
```
If it exits 0 and returns stem URLs, proceed. If it still fails with "error decoding response
body", the suno-cli stems bug is not yet fixed — stop and check the issue:
https://github.com/paperfoot/suno-cli/issues/5

---

## Steps

1. **Run gate2.sh on both calibration clips:**
```bash
bash scripts/gate2.sh b8759abd-6a12-4538-8c45-d0dc78f26753 songs/gate2-calibration/generations/001
bash scripts/gate2.sh 40c54f63-a66b-456d-a1fa-c042cc710820 songs/gate2-calibration/generations/002
```

2. **Read the results:**
```bash
cat songs/gate2-calibration/generations/001/gate2.json
cat songs/gate2-calibration/generations/002/gate2.json
```
Extract `mean_db` from each. If either returns `"result":"MANUAL"`, the stems bug is still
present — stop and re-check.

3. **Apply the decision tree** (from `.claude/skills/ffmpeg/SKILL.md`):
```
worst_case = max(reading_001, reading_002)
PASS_DB    = worst_case - 10
FLAG_DB    = worst_case + 10
```

4. **Update `.claude/settings.json`:** Read the file first, then add/update the `"env"`
section with the calibrated values:
```json
{
  "env": {
    "SUNO_GATE2_PASS_DB": "<PASS_DB>",
    "SUNO_GATE2_FLAG_DB": "<FLAG_DB>"
  }
}
```

5. **Update `references/gate2-calibration-log.md`:** Record the readings, the calibrated
thresholds, and the date under a new calibration section.

6. **Report to the user:** State both raw readings, the worst-case, the thresholds set, and
confirm the settings.json update.

---

## Reference

- Calibration clip IDs: `b8759abd-6a12-4538-8c45-d0dc78f26753`, `40c54f63-a66b-456d-a1fa-c042cc710820`
- Audio saved at: `songs/gate2-calibration/generations/001/audio/` and `.../002/audio/`
- gate3.json already confirmed PASS (1.000 coverage) on both clips — no need to re-run Gate 3
- ffmpeg reference: `.claude/skills/ffmpeg/SKILL.md`
- suno-cli stems bug: https://github.com/paperfoot/suno-cli/issues/5
