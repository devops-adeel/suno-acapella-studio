---
description: Generate N variations of a section (best-of-N) for the active generation.
argument-hint: <section-file> [N=2]
---

Best-of-N is a plain batch of `suno generate` calls — NOT a workflow. Before running, confirm the
active generation's `gate1.json` is PASS (the hook will block otherwise).

Generate `${2:-2}` variations of the section `$1`, naming outputs `<section>-a.json`, `-b.json`, …:

```bash
slug="$(cat .studio/active-song 2>/dev/null)"
gen="$(ls -d songs/$slug/generations/*/ 2>/dev/null | sort | tail -1)"
sec="$1"; n="${2:-2}"; base="$(basename "$sec" .md)"
for i in $(seq 1 "$n"); do
  letter="$(printf "\\$(printf '%03o' $((96+i)))")"   # 1->a, 2->b, ...
  suno generate \
    --tags "$(jq -r .style "${gen}prompt-package.yaml" 2>/dev/null)" \
    --lyrics-file "songs/$slug/sections/$sec" \
    --model v5.5 --wait --download "${gen}audio/" --json > "${gen}${base}-${letter}.json"
done
```

(Reserve best-of-2 for chorus/hook; best-of-1 elsewhere — credits are finite.) Then surface the
variations with `/surface`.
