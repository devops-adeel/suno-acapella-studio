---
description: Switch the active song.
argument-hint: <song-slug>
---

Set `$1` as the active song so the SessionStart brief-injection and gate paths target it:

```bash
test -d "songs/$1" && printf '%s\n' "$1" > .studio/active-song && echo "Active song: $1" || echo "No such song: songs/$1"
```

Then read `songs/$1/brief.md`, the latest `songs/$1/generations/*/critique.md`, and `status.md`, and
tell me exactly where we left off before doing anything else.
