---
description: Surface the latest generation's variations and gate results for approval.
---

Present the active song's latest generation for the user's decision (Gate 4 — their ears):

```bash
slug="$(cat .studio/active-song 2>/dev/null)"
gen="$(ls -d songs/$slug/generations/*/ 2>/dev/null | sort | tail -1)"
echo "Active: $slug   Gen: $gen"
ls -1 "${gen}audio/" 2>/dev/null
for g in gate1 gate2 gate3; do echo "--- $g ---"; jq -r '.result' "${gen}${g}.json" 2>/dev/null || echo "(none)"; done
```

Then: list the audio variations, give the three gate results, and ask the user which variation lands
emotionally. Do NOT declare a song done — only the user approves the feeling.
