---
description: Re-anchor to the emotional brief (drift mitigation).
---

Re-read the active song's brief and re-ground the session:

```bash
slug="$(cat .studio/active-song 2>/dev/null)"; echo "Active: $slug"; cat "songs/$slug/brief.md" 2>/dev/null
```

Then state the song's emotional intent in ONE sentence, list which decisions in the brief are still
open, and confirm we're still optimizing for that feeling — not whatever the last few turns drifted
toward. If this session is past ~60 turns, suggest `/compact` or a fresh session reloaded from the
brief.
