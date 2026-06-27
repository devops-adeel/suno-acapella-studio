---
description: Show the gate JSON status for the active song's latest generation.
---

Resolve the active song and print its latest generation's gate files (the source of truth):

```bash
slug="$(cat .studio/active-song 2>/dev/null)"
gen="$(ls -d songs/$slug/generations/*/ 2>/dev/null | sort | tail -1)"
echo "Active: $slug   Latest gen: $gen"
for g in gate1 gate2 gate3; do
  echo "--- $g ---"; cat "${gen}${g}.json" 2>/dev/null || echo "(none)"
done
```

Summarise PASS/FLAG/FAIL across the three gates and state what the next action is.
