---
description: Scaffold a new song directory and set it active.
argument-hint: <song-slug>
---

Run the scaffold script for the slug `$1`, then confirm what was created:

```bash
./scripts/new-song.sh "$1"
```

After it runs, read `songs/$1/brief.md` and begin the brief interview from the `studio` playbook:
ask for the concept and the feeling first, then the voice direction. Do not write lyrics yet.
