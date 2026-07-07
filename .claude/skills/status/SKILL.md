---
name: status
description: Quick pipeline status for the active (or named) song — gate results, credits remaining, next step. Use at session start or when re-orienting after a break.
tools: Read, Bash
---

# /status

Surfaces a one-glance pipeline summary. Run at session start or any time you need to
re-orient.

## Steps

1. **Find the active song:**
```bash
cat .studio/active-song 2>/dev/null || ls -t songs/*/brief.md | head -1
```

2. **Read the brief:**
```bash
cat songs/<slug>/brief.md
```
Extract the `Status:` line.

3. **Check credits:**
```bash
suno credits --json 2>/dev/null || suno credits
```

4. **Find the latest generation directory:**
```bash
ls -d songs/<slug>/generations/*/ 2>/dev/null | sort -V | tail -1
```

5. **Read gate JSON files** from the latest generation dir:
```bash
cat songs/<slug>/generations/<n>/gate1.json 2>/dev/null
cat songs/<slug>/generations/<n>/gate2.json 2>/dev/null
cat songs/<slug>/generations/<n>/gate3.json 2>/dev/null
```

6. **Output the summary** in this format:

```
Song: <slug>   Status: <Status field from brief.md>
Credits: <balance> (<plan>)

Generation <n>:
  Gate 1: PASS / FAIL (<failures>) / MISSING
  Gate 2: PASS (mean -XX.X dB) / FLAG (mean -XX.X dB) / FAIL / MANUAL / MISSING
  Gate 3: PASS (coverage X.XXX) / FAIL (coverage X.XXX) / MISSING

Next step: <inferred from gate states — see logic below>
```

**Next step inference:**
- All three MISSING → "Run Gate 1 (dispatch adversarial-critic)"
- Gate 1 MISSING → "Run Gate 1 (dispatch adversarial-critic)"
- Gate 1 FAIL → "Fix prompt package per gate1.json fix_instructions, then re-run Gate 1"
- Gate 1 PASS, Gate 2+3 MISSING → "Dispatch production-director (gate1 PASS — generation ready)"
- Gate 2 MANUAL → "Download instrumental stem from suno.com Split from Mix — see ffmpeg skill"
- Gate 2 FLAG or Gate 3 FLAG → "Review flagged output; may proceed to Gate 4 (your ears)"
- Gate 2 FAIL or Gate 3 FAIL → "Retry cycle: strengthen exclusions, re-run Gate 1"
- All three PASS → "Gate 4: listen and evaluate emotional quality"

## If no active song

List all songs and their status:

```bash
for f in songs/*/brief.md; do
  slug=$(basename $(dirname $f))
  status=$(grep '^Status' "$f" | head -1)
  printf "%-25s %s\n" "$slug" "$status"
done
```
