# Suno Acapella Studio

**End-to-End Implementation Guide**

![Platform](https://img.shields.io/badge/platform-Claude%20Code-6B52F6)
![Model](https://img.shields.io/badge/model-Suno%20v5.5-FF9500)
![Plan](https://img.shields.io/badge/plan-Pro%20·%202%2C500%20cr%2Fmo-4FD490)
![Agents](https://img.shields.io/badge/agents-5%20specialised-7EC8E3)
![CLI](https://img.shields.io/badge/cli-suno--cli%20Rust-CE422B)

A personal acapella music production studio running in Claude Code, backed by a GitHub repository. You arrive with a concept and an emotional state. The system co-writes lyrics, engineers a Suno prompt package, generates pure vocal output — lead voice, backing harmonies, beatboxing — runs technical quality checks silently, and surfaces results for your approval.

> [!IMPORTANT]
> **No instruments. Ever.** Every generation from this system is pure vocals: lead voice, backing harmonies, beatboxing. The Exclusions field and Style field enforce this on every run.

---

## Table of Contents

- [Architecture](#architecture)
- [Part 1 — Prerequisites](#part-1--prerequisites)
- [Part 2 — Repository Structure](#part-2--repository-structure)
- [Part 3 — Installation](#part-3--installation)
- [Part 4 — Configuration Files](#part-4--configuration-files)
- [Part 5 — Reference Files](#part-5--reference-files)
- [Part 6 — Session Workflow](#part-6--session-workflow)
- [Part 7 — Credit Management](#part-7--credit-management)
- [Part 8 — Troubleshooting](#part-8--troubleshooting)
- [Part 9 — Known Limitations](#part-9--known-limitations)
- [Part 10 — Upgrade Path](#part-10--upgrade-path)

---

## Architecture

Six specialised agents. All coordination routes through the Producer — agents never talk to each other directly. Trust flows from filesystem artifacts (JSON gate files), not agent prose.

```
YOU ──── natural language ──▶ PRODUCER (Sonnet 4.6 · main session)
                                   │
              ┌──────────────┬─────┴────────┬───────────────┐
              ▼              ▼              ▼               ▼
       LYRIC         PROMPT         VOICE            ADVERSARIAL
       ARCHITECT     ARCHITECT      PROFILER         CRITIC
       (Opus 4.8)    (Opus 4.8)     (Sonnet 4.6)     (Sonnet 4.6)

              └──────────────┴──────────────┴───────────────┘
                                   │
                                   ▼
                         PRODUCTION DIRECTOR
                         (Haiku 4.5 · bash execution)
                         generate → extend → concat → stems
                         Reads gate1.json before firing.
                         Verifies gate2.json after.
```

| Agent | Model | Role | Tier |
|---|---|---|---|
| Producer | Sonnet 4.6 | Orchestrates session, holds emotional brief, routes all agents | Reasoning |
| Lyric Architect | Opus 4.8 | Co-writes lyrics section-by-section from brief | Creative |
| Prompt Architect | Opus 4.8 | Builds complete Suno prompt package: Style, Exclusions, Sliders | Creative |
| Voice Profiler | Sonnet 4.6 | Manages Suno Voices personas, defines vocal character | Reasoning |
| Adversarial Critic | Sonnet 4.6 | Three-gate technical quality check; writes gate JSON files | Reasoning |
| Production Director | Haiku 4.5 | Executes suno-cli pipeline; reads gate files before acting | Mechanical |

**Why Opus for creative agents:** Output from these agents directly defines music quality. Errors in prompt engineering or lyric structure cascade into failed generations. The cost difference is justified by the quality floor it sets.

**Why the two-level hierarchy matters:** Independent research on multi-agent LLM systems (Rath, 2026) found that two-level hierarchies — orchestrator plus specialists — demonstrate significantly greater long-term stability than flat (peer-to-peer) or deep (three-plus levels) architectures. A 5× increase in inter-agent conflicts was observed in drifting flat systems after ~300 interactions. The Producer-plus-specialists structure is not stylistic preference; it's structurally more stable.

> [!IMPORTANT]
> **The critical design rule:** The Production Director reads `gate1.json` and verifies `"result": "PASS"` before executing any generation. It never trusts an agent's prose claim that a gate passed. Filesystem artifacts are the source of truth — not summaries.

---

## Part 1 — Prerequisites

Required on your machine before setup:

- **macOS or Linux** — suno-cli supports Windows binaries but this guide uses bash
- **Homebrew** — `https://brew.sh`
- **Git** — `brew install git`
- **Claude Code** — `npm install -g @anthropic-ai/claude-code`
- **Active Suno Pro subscription** at suno.com, logged in via Chrome / Arc / Brave / Firefox / Edge
- **GitHub account** for the repository

---

## Part 2 — Repository Structure

```
suno-acapella-studio/
│
├── CLAUDE.md                         ← Studio context · loaded every session
├── .gitignore
├── README.md
│
├── .claude/
│   ├── settings.json                 ← Tool permissions
│   └── agents/
│       ├── lyric-architect.md        ← Opus · co-writes lyrics
│       ├── prompt-architect.md       ← Opus · builds Suno prompt package
│       ├── voice-profiler.md         ← Sonnet · manages voice personas
│       ├── adversarial-critic.md     ← Sonnet · technical quality gate
│       └── production-director.md    ← Haiku · suno-cli execution
│
├── songs/
│   └── <song-slug>/
│       ├── brief.md                  ← THE ANCHOR · read first every session
│       ├── lyrics.md                 ← full song with metatags
│       ├── prompt-package.md         ← Style, Exclusions, Sliders, Persona
│       ├── voice-profile.md
│       ├── sections/                 ← per-section lyric files
│       │   └── chorus.md · verse1.md · bridge.md · outro.md
│       ├── generations/
│       │   └── 001/
│       │       ├── gate1.json        ← Critic Gate 1 result (machine-readable)
│       │       ├── gate2.json        ← Critic Gate 2 result (machine-readable)
│       │       ├── critique.md       ← human-readable log
│       │       ├── status.md         ← PENDING | FAILED | SURFACED
│       │       ├── chorus-a.json · chorus-b.json
│       │       └── audio/            ← .gitignored
│       └── approved/
│           ├── final.wav             ← .gitignored
│           └── notes.md
│
├── personas/
│   ├── registry.md
│   └── <persona-name>/
│       ├── profile.md
│       └── suno-id.txt               ← UUID from Suno web UI
│
├── references/                       ← shared knowledge base · populate before first session
│   ├── exclusions-bank.md
│   ├── acapella-formulas.md
│   ├── vocal-tag-bank.md
│   └── metatag-arc-library.md
│
└── scripts/
    ├── setup.sh
    └── new-song.sh
```

> [!WARNING]
> **Populate `references/` before your first session.** Agents are instructed to read all four files in `references/`. Empty files cause agents to hallucinate the content they were told to find. Full starter content for all four files is in Part 5.

---

## Part 3 — Installation

### 3.1 Clone and initialise

```bash
git clone https://github.com/YOUR-USERNAME/suno-acapella-studio
cd suno-acapella-studio
```

### 3.2 Install suno-cli (Rust binary)

> [!CAUTION]
> **Naming trap — two tools share the name `suno-cli`.**
> `pip install suno-cli` installs AceDataCloud's tool — it uses their Suno account pools, **not yours**. The correct tool is the Rust binary installed via Homebrew with the command `suno`. These are entirely different products.

```bash
# Install via Homebrew (recommended)
brew tap paperfoot/tap
brew install suno

# Alternative: via cargo (requires Rust toolchain)
# cargo install suno-cli

# Verify — latest release is v0.5.7
suno --version
```

### 3.3 Authenticate with your Suno account

```bash
# Log in to suno.com in Chrome/Arc/Brave/Firefox/Edge first, then:
suno auth --login
# Reads your Clerk session cookie automatically
# Stores refreshable session in a 0600 local auth file
# One Keychain dialog on first run, then silent

# Verify authentication and check credit balance
suno credits
```

### 3.4 Install the agent skill into Claude Code

```bash
suno install-skill
# Writes ~/.claude/skills/suno/SKILL.md
# Claude Code gains native awareness of all suno-cli capabilities
```

### 3.5 Open in Claude Code

```bash
claude .
# Claude Code reads CLAUDE.md on start
# All .claude/agents/ definitions load automatically
```

### 3.6 Handling suno-cli breakage

Suno updates their internal API without notice. suno-cli has broken twice in its first two months. When generation fails unexpectedly:

```bash
suno update              # pull latest binary — fixes schema_drift errors
suno auth --refresh      # force-refresh JWT from stored Clerk session
suno auth --login        # full re-auth from browser (if refresh fails)
```

### 3.7 Setup script — `scripts/setup.sh`

```bash
#!/usr/bin/env bash
set -euo pipefail

echo "════════════════════════════════════"
echo "  Suno Acapella Studio — Setup"
echo "════════════════════════════════════"

# Check prerequisites
command -v git     >/dev/null 2>&1 || { echo "ERROR: git not found"; exit 1; }
command -v brew    >/dev/null 2>&1 || { echo "ERROR: Homebrew required → https://brew.sh"; exit 1; }
command -v claude  >/dev/null 2>&1 || { echo "ERROR: Claude Code → npm install -g @anthropic-ai/claude-code"; exit 1; }

# Install suno-cli (Rust) — NOT pip install suno-cli (that's AceDataCloud)
if command -v suno >/dev/null 2>&1; then
  echo "✓ suno-cli: $(suno --version 2>/dev/null || echo 'installed')"
  suno update --check 2>/dev/null || true
else
  brew tap paperfoot/tap && brew install suno
fi

# Authenticate
echo "Authenticate with your Suno account..."
suno auth --login
suno credits

# Install skill
suno install-skill
echo "✓ Skill installed at ~/.claude/skills/suno/SKILL.md"

# Verify reference files
MISSING=()
for f in exclusions-bank.md acapella-formulas.md vocal-tag-bank.md metatag-arc-library.md; do
  [ ! -s "references/$f" ] && MISSING+=("references/$f")
done

if [ ${#MISSING[@]} -gt 0 ]; then
  echo ""
  echo "⚠ Populate these files before your first session:"
  for f in "${MISSING[@]}"; do echo "  - $f"; done
fi

mkdir -p songs personas
echo ""
echo "✓ Setup complete. Run: claude ."
```

### 3.8 New song scaffold — `scripts/new-song.sh`

```bash
#!/usr/bin/env bash
set -euo pipefail

SLUG="${1:-}"
[ -z "$SLUG" ] && { echo "Usage: ./scripts/new-song.sh <song-slug>"; exit 1; }

SONG_DIR="songs/$SLUG"
[ -d "$SONG_DIR" ] && { echo "Already exists: $SONG_DIR"; exit 1; }

mkdir -p "$SONG_DIR"/{sections,generations,approved}

cat > "$SONG_DIR/brief.md" << BRIEF
# [Song Title] · Emotional Brief

## Status
In progress · No generations yet · Created: $(date +%Y-%m-%d)

## Emotional State


## Concept / Theme


## Sonic Intent


## Emotional Arc
Intro:       Verse:       Pre-Chorus:
Chorus:      Bridge:      Outro:

## Voice Profile
Using persona: TBD · See personas/registry.md

## Decisions Made
- [ ] Lyrics approved       - [ ] Prompt package finalised
- [ ] Voice persona set     - [ ] Chorus approved
- [ ] Full song approved
BRIEF

touch "$SONG_DIR/lyrics.md" "$SONG_DIR/prompt-package.md" "$SONG_DIR/voice-profile.md"

echo "✓ Scaffolded: $SONG_DIR"
echo "Open Claude Code and say: 'Let's start a new song. I've scaffolded songs/$SLUG/'"
```

---

## Part 4 — Configuration Files

### 4.1 `CLAUDE.md`

Keep this under 200 lines. Procedures belong in agents. CLAUDE.md holds facts Claude needs at all times: identity, routing, non-negotiable constraints.

> [!NOTE]
> **Behavioral anchoring:** Re-reading `brief.md` before every generation trigger is this system's implementation of Adaptive Behavioral Anchoring — a technique shown to reduce agent goal drift by 70.4% in multi-agent LLM systems (Rath, 2026). The emotional brief is not documentation; it is the anti-drift anchor.

```markdown
# Suno Acapella Studio

## Identity
Personal acapella music production studio. Every output is pure vocals:
lead voice, backing harmonies, beatboxing. No instruments. No exceptions.
Model: Suno v5.5 (chirp-fenix). Plan: Pro · 2,500 credits/month.

## Session Start
1. Ask which song to work on, or scan `songs/` for work in progress
2. Read `songs/<slug>/brief.md` — load before anything else
3. Read `songs/<slug>/lyrics.md` if it exists
4. Check `songs/<slug>/generations/` for what was tried and why
5. **Before every generation trigger: re-read the brief and state the emotional
   intent in one sentence before dispatching to production-director**
6. Run `suno credits` at session start

## Active Song
Currently working on: ← update this each session

## Agent Routing
- Lyric co-writing   → dispatch to `lyric-architect` subagent
- Prompt engineering → dispatch to `prompt-architect` subagent
- Voice persona work → dispatch to `voice-profiler` subagent
- Quality review     → dispatch to `adversarial-critic` subagent
- Suno generation    → dispatch to `production-director` subagent

## Studio Rules (non-negotiable)
- Style field: always open with acapella tags in positions 1–3
- Exclusions: always use the full set from references/exclusions-bank.md
- Never generate without gate1.json showing `"result": "PASS"`
- Verify gate1.json exists — never trust agent prose summary of gate status
- Max 3 retry cycles before surfacing to user with critique.md
- `suno credits` before every generation batch
- Best-of-2 for chorus/hook; best-of-1 for outros/verse 2

## Pro Plan Notes
- Stems: Auto Split (50cr/run) and Split from Mix (20cr total)
- No Suno Studio — use Song Editor instead
- No Advanced Split — Split from Mix is sufficient for Gate 2
- No Remove FX — use "dry vocal, close-mic, no reverb" in Style field

## End of Session
Update `songs/<slug>/brief.md` status field.
```

---

### 4.2 `.claude/agents/lyric-architect.md`

```markdown
---
name: lyric-architect
description: Co-writes acapella song lyrics section by section from an emotional brief.
model: opus
tools: Read, Write
---

You are the Lyric Architect for an acapella-only Suno production studio.

## Read first
1. songs/<slug>/brief.md (the emotional anchor — always first)
2. songs/<slug>/lyrics.md (existing draft if any)
3. references/metatag-arc-library.md
4. references/vocal-tag-bank.md

## Section tags
[Intro] [Verse 1] [Pre-Chorus] [Chorus] [Bridge] [Outro]
One tag per line, before the lyrics for that section.

## Stacking delivery modifiers
[Chorus]
[Belted]
(lines here are belted)

Parameterised: [Verse: whispered, single voice, close-mic]
               [Chorus: full harmony, voices swell, open vowels]

## Beatbox notation
[Beatbox]
boom-tss-boom-tss

## Harmony direction
(harmonies enter) — before the line where they begin
(unison)          — to drop back to one voice

## Energy signals
CAPITALISED LINES = higher intensity signal to Suno
(softly) (building) (sudden break) = within-section dynamics

## Hard limits
- Total lyrics: never exceed 5,000 characters
- No section longer than 8 lines
- Avoid end-rhymes on closed consonants at phrase ends (sounds clipped)

## Output
Write to songs/<slug>/lyrics.md (full song)
Write per-section files to songs/<slug>/sections/:
chorus.md first — section-by-section generation builds outward from this
Then: verse1.md, verse2.md, bridge.md, outro.md

Do not write style prompts, select personas, or evaluate generations.
```

---

### 4.3 `.claude/agents/prompt-architect.md`

```markdown
---
name: prompt-architect
description: Builds the complete Suno prompt package from lyrics and emotional brief.
model: opus
tools: Read, Write
---

You are the Prompt Architect for an acapella-only Suno production studio.

## Read first
1. songs/<slug>/brief.md
2. songs/<slug>/lyrics.md
3. references/acapella-formulas.md
4. references/vocal-tag-bank.md
5. references/exclusions-bank.md

## Style field (max 1,000 characters)
Position rule: Suno weights position 1 at ~30% influence.
Positions 1–3 must be acapella-specific. Never lead with a genre name.

Proven openers (use one):
- `a cappella, unaccompanied vocals, vocal harmony,`
- `a cappella harmonic, human voices only, vocal ensemble,`
- `a cappella, beatbox percussion, lead vocal, human voices only,`

Always add:
- Gender: `female vocals` OR `male vocals` (always explicit)
- Character: from references/vocal-tag-bank.md Tier 1
- Dry workaround: `dry vocal, close-mic, no reverb`
- Light inline negation (2 max): `no instruments, no accompaniment`

## Exclusions field (--exclude flag)
Always use the complete set from references/exclusions-bank.md. Never abbreviate.
This field is more reliable than inline negation in the Style field.

## Sliders
- vocal: `female` | `male`
- weirdness: 20–40 (higher = more experimental, riskier for acapella)
- style-influence: 65–75

## Metatag arc check
Before finalising, cross-check lyrics.md against brief.md arc:
- Does [Build] appear before the energy peak?
- Does [Breakdown] create the space the brief describes?
- Does [Belted] appear at the break-open moment?

## Output format — songs/<slug>/prompt-package.md

```yaml
---
title: [Song Title]
style: >
  a cappella, vocal harmony, female vocals, [character], [energy],
  dry vocal, close-mic, no reverb, no instruments, no accompaniment
exclude: >
  guitar, piano, drums, bass, synthesizer, strings, ...
vocal: female
weirdness: 30
style-influence: 70
persona-id: [UUID or omit]
---
[Notes on prompting decisions]
```
```

---

### 4.4 `.claude/agents/adversarial-critic.md`

```markdown
---
name: adversarial-critic
description: Technical quality gate. Runs Gate 1 before generation. Gate 2 after. Writes machine-readable JSON files. Never evaluates emotional quality.
model: sonnet
tools: Read, Write, Bash
---

You are the Adversarial Critic. Quality engineer, not creative judge.

CRITICAL: Write JSON gate files. The Production Director reads these files,
not your text output. Never let generation proceed on prose claims alone.

## Gate 1 — Pre-generation prompt review

FAIL if any of these are true:
- Style field does NOT open with acapella tags in positions 1–3
- Style field exceeds 1,000 characters
- Exclusions field is missing, empty, or less comprehensive than references/exclusions-bank.md
- Lyrics exceed 5,000 characters
- Any section exceeds 8 lines
- Metatag structure contradicts brief.md's emotional arc
- Style contains genre tags that imply instruments (e.g., "pop ballad" → implies piano)
- Missing explicit vocal gender tag

GATE 1 PASS → write songs/<slug>/generations/<n>/gate1.json:
```json
{
  "gate": 1,
  "result": "PASS",
  "checked_at": "[timestamp]",
  "style_chars": N,
  "exclude_items": N,
  "lyrics_chars": N,
  "arc_match": true
}
```

GATE 1 FAIL → write gate1.json with result "FAIL":
```json
{
  "gate": 1,
  "result": "FAIL",
  "failures": ["[specific item]"],
  "fix_instructions": "[exact instructions for Prompt Architect]"
}
```
Return to Producer. Do NOT allow generation to proceed.

## Gate 2 — Instrumental leakage check (v1: manual step)

After generation, instruct the user:
"Please run Split from Mix → Vocals in suno.com.
Download both stems to songs/<slug>/generations/<n>/audio/stems/"

When stems are placed, run:
```bash
# macOS
stat -f%z songs/$SLUG/generations/$N/audio/stems/complement.wav
# Linux
stat -c%s songs/$SLUG/generations/$N/audio/stems/complement.wav
```

Interpret complement.wav size:
- < 500,000 bytes     → **PASS**
- 500,000–2,000,000   → **FLAG** (surface with note to user)
- > 2,000,000 bytes   → **FAIL** (strengthen exclusions, retry)

Write gate2.json with result and complement_bytes.

## Retry budget
Max 3 retry cycles. After 3 failures: surface to user with full critique.md.

`retry_type: "execution"` — network/auth errors → retry same prompt
`retry_type: "strategy"` — prompt failures → escalate to Prompt Architect

2 strategy escalations → surface to user immediately.

## Never evaluate
Emotional quality · artistic merit · whether the song is good · voice character match.
Those belong to the user.
```

---

### 4.5 `.claude/agents/production-director.md`

```markdown
---
name: production-director
description: Executes suno-cli pipeline. Use after Adversarial Critic Gate 1 passes. Handles generate, extend, concat, file management.
model: haiku
tools: Read, Write, Bash
---

You are the Production Director. You execute and verify. No creative judgment.

CRITICAL: Before any generation, verify gate1.json contains "result": "PASS".
If gate1.json is absent or shows FAIL: stop, report to Producer immediately.

## Pre-flight

```bash
# Check credits — minimum 50 before starting
suno credits

# Verify Gate 1
cat songs/$SLUG/generations/$N/gate1.json | python3 -c \
  "import json,sys; d=json.load(sys.stdin); assert d['result']=='PASS', d; print('Gate 1: PASS')"
```

## Generate chorus (best-of-2)

```bash
# Variation A
suno generate \
  --title "[from prompt-package.md]" \
  --tags "[style field]" \
  --exclude "[exclusions field]" \
  --lyrics-file songs/$SLUG/sections/chorus.md \
  --model v5.5 \
  --vocal female \
  --weirdness 30 \
  --style-influence 70 \
  --wait \
  --download songs/$SLUG/generations/$N/audio/ \
  --json > songs/$SLUG/generations/$N/chorus-a.json
```

Run a second time → `chorus-b.json`.
Surface both to user. Write approved choice to `status.md`.

## Extend sections from approved chorus

```bash
suno extend [APPROVED_CHORUS_ID] \
  --lyrics-file songs/$SLUG/sections/verse1.md \
  --wait --download ... --json > verse1.json

# Repeat for bridge.md → bridge.json
# Repeat for outro.md → outro.json
```

## Concat

```bash
suno concat [VERSE1_ID] [CHORUS_ID] [VERSE2_ID] [CHORUS_ID] [BRIDGE_ID] [OUTRO_ID] \
  --wait --download songs/$SLUG/generations/$N/audio/ --json > full.json
```

## After generation
Report to Adversarial Critic: "Generation complete. Dispatching for Gate 2."
Do NOT surface audio to user until gate2.json exists.

## Error handling

| Error | Fix |
|---|---|
| `schema_drift` | Run `suno update`, retry |
| `auth_expired` | Run `suno auth --refresh`, retry |
| `GenerationFailed` | Check `suno credits`, retry once |
| Persistent (2+ attempts) | Stop, report full error to Producer |

Never fabricate a clip_id. If a command fails, report the actual error.
```

---

### 4.6 `.claude/agents/voice-profiler.md`

```markdown
---
name: voice-profiler
description: Manages Suno v5.5 voice personas. Use when setting up a new song's vocal character.
model: sonnet
tools: Read, Write
---

You are the Voice Profiler. Define and maintain vocal character for each song.

## Read first
1. songs/<slug>/brief.md — sonic intent
2. personas/registry.md — existing personas

## If existing persona fits
Reference it in songs/<slug>/voice-profile.md. Explain the match.

## If no persona fits
Define the voice character (timbre · delivery · range · texture).
Write to personas/<name>/profile.md and add to personas/registry.md.
Leave personas/<name>/suno-id.txt with note: "Create at suno.com → Voices"

## IMPORTANT: persona creation is manual
suno-cli cannot create Voices personas (endpoint not yet implemented).
Steps: suno.com → account → Voices → Create Voice → upload audio → train
→ copy UUID from URL → paste into personas/<name>/suno-id.txt

Your role: define the character, track the registry, surface the UUID to
Prompt Architect. You do not create it in Suno.

## Vocal tags (no persona)
Supply to Prompt Architect for the Style field:
`breathy` · `intimate` · `close-mic` · `warm` · `full chest voice` · `raspy` · `silky` · `wide range`

## voice-profile.md format

```yaml
---
persona-id: [UUID or "PENDING — see setup note"]
vocal-tags: [comma-separated for Style field]
character: [prose description]
---
```
```

---

### 4.7 `.claude/settings.json`

```json
{
  "permissions": {
    "allow": [
      "Bash(suno *)",
      "Bash(cat songs/**)",
      "Bash(ls songs/**)",
      "Bash(ls -la songs/**)",
      "Bash(stat *)",
      "Bash(python3 *)",
      "WriteFile(songs/**)",
      "WriteFile(personas/**)",
      "WriteFile(.claude/**)"
    ]
  }
}
```

---

### 4.8 `.gitignore`

```gitignore
# Audio — large binaries
songs/**/audio/
songs/**/approved/*.wav
songs/**/approved/*.mp3

# Auth
.env
*.env.local
.suno-auth

# Python / Node
__pycache__/
*.pyc
.venv/
node_modules/

# OS
.DS_Store
Thumbs.db
```

---

## Part 5 — Reference Files

Copy this content directly into the four files in `references/`. Agents read these on every invocation — quality here directly affects generation quality.

### 5.1 `references/exclusions-bank.md`

```markdown
# Exclusions Bank — Acapella Generation

The dedicated Exclude field (--exclude flag in suno-cli) is more reliable
than inline "no [element]" in the Style field. Always use the full list below.
Never abbreviate. The belt-and-braces approach: put "no instruments" in Style
AND the full list in Exclude.

## Standard set (copy verbatim)
guitar, piano, drums, bass, synthesizer, strings, brass, woodwinds,
keyboard, organ, violin, cello, viola, trumpet, trombone, saxophone,
flute, clarinet, oboe, harp, banjo, mandolin, ukulele,
electric guitar, acoustic guitar, bass guitar, rhythm guitar,
808, hi-hat, snare, kick, cymbal, percussion, melody,
chord progression, backing track, accompaniment, instruments, music,
harmonica, accordion, orchestral, band, live band

## For stubborn leakage (add if standard set fails)
no chord structure, no musical arrangement, no audio bed,
no pads, no ambient music, no underscore, no musical backdrop

## Intro-specific (stops wordless opening hum)
ooh vocals, ahh vocals, la la vocals, ambient intro, cinematic intro,
wordless intro, humming, vocalise

## Combined approach
Also add "no instruments, no accompaniment" in the Style field inline.
Positive reinforcement: "human voice only" is as powerful as negation.
If a specific instrument keeps appearing: name it explicitly in both fields.
```

---

### 5.2 `references/acapella-formulas.md`

```markdown
# Acapella Formulas — Suno v5.5

Position rule: Suno weights Style position 1 at ~30% influence.
Positions 1–3 must be acapella-specific. Never lead with a genre name.

## Formula 1 — Harmonic ensemble (Pentatonix-style)
a cappella, unaccompanied vocals, vocal harmony, [gender], [character],
[energy], dry vocal, close-mic, no reverb, no instruments, no accompaniment

## Formula 2 — Lead + beatbox
a cappella, beatbox percussion, lead vocal, human voices only, [gender],
[character], [energy], intimate, dry vocal, no instruments, no accompaniment

## Formula 3 — Choral ensemble
a cappella, choral harmony, vocal ensemble, unaccompanied choir,
[gender], [character], [energy], no instruments

## Formula 4 — Spoken word / intimacy
a cappella, spoken word, vocal performance, close-mic,
intimate delivery, breathy, dry, no reverb, no instruments

## Dry vocal modifier (Remove FX workaround — Pro plan)
"dry vocal, close-mic recording, no reverb, no room sound, no hall echo"

## What never works as an opener
- Genre names (pop, jazz, R&B) — these imply instruments
- BPM numbers — attract rhythmic instrumentation
- Production terms (808, trap, drop) — imply non-vocal elements
- "Only vocals" — too vague; describe WHAT vocals specifically
```

---

### 5.3 `references/vocal-tag-bank.md`

```markdown
# Vocal Tag Bank — Suno v5.5

## Tier 1 — >80% compliance, use freely
female vocals, male vocals, breathy, raspy, intimate, close-mic,
falsetto, chest voice, head voice, warm, clear, smooth

Section delivery tags (stack on section line):
[Belted]  [Whispered]  [Spoken Word]  [Rap]  [Falsetto]  [Choir]

## Tier 2 — ~60% compliance, anchor with a Tier 1
ethereal, haunting, melismatic, nasal, bright, dark, full-bodied,
velvet, gritty, soulful, airy, powerful, tender

## Tier 3 — ~40% compliance, use sparingly
operatic, theatrical, conversational, deadpan, emotive, vulnerable,
restrained, explosive, whimsical

## Parameterised section modifiers (v5.5)
[Verse: whispered, single voice, close-mic]
[Chorus: full harmony, voices swell, belted, open vowels]
[Bridge: breakdown, bare, breath only]
[Pre-Chorus: building, harmonies layer in, growing urgency]
[Outro: fading, voices dropping away one by one]

## Voice + Persona note
With Suno Voices active, Style controls DELIVERY, not timbre.
Timbre is locked by the persona. Still specify delivery:
"breathy and intimate" vs "powerful and belted" still matters.
```

---

### 5.4 `references/metatag-arc-library.md`

```markdown
# Metatag Arc Library — Emotional Arc → Tag Patterns

## Arc 1: Controlled Tension → Release
[Intro: sparse, one voice, intimate]
[Verse 1: controlled, close-mic, single voice]
[Pre-Chorus: harmonies enter, building]
[Chorus]
[Belted]
[Post-Chorus: voices pull back, breath]
[Verse 2: slightly more open than verse 1]
[Pre-Chorus: fuller harmonies, higher urgency]
[Chorus]
[Belted]
[Bridge: breakdown, bare, one voice]
[Final Chorus]
[Belted]
[Big]
[Outro: voices fade, back to single]

## Arc 2: Grief / Stays Close
[Intro: whispered]
[Verse 1]
[Whispered]
[Chorus]
[Intimate]
[Bridge: breakdown, silence, breath]
[Final Chorus]
[Intimate]
[Outro: fading]

## Arc 3: Joy / Builds and Stays Up
[Intro: light, harmonies, playful]
[Verse 1: medium energy, conversational]
[Chorus: joyful, full harmonies, open]
[Bridge: beatbox featured, rhythmic breakdown]
[Final Chorus]
[Euphoric]
[Big]
[Outro: natural fadeout]

## Per-section energy modifiers
Low:        [Whispered]  (softly)  (breath)  (barely audible)
Rising:     [Building]   (harmonies enter)  (voices layer in)
Peak:       [Belted]     [Big]     [Euphoric]  [Full Harmony]
Drop:       [Breakdown]  (silence)  (breath only)  (bare)
Resolution: [Intimate]   [Whispered]  (fading)

## CAPITALISATION for intensity
CAPITALISED LINES = higher energy signal to Suno.
Use sparingly — caps everywhere cancels the signal.
```

---

## Part 6 — Session Workflow

### Starting a new song

```
You:     "Let's start a new song."

Claude:  "What's the concept? Tell me the feeling you're trying to make."

You:     "The moment you realise you've forgiven someone
          but the grief hasn't left yet."

Claude:  "How should the voice feel — close and fragile,
          or do we build to something?"

You:     "Starts alone. Harmonies enter like a memory."

Claude:  [brief.md complete → dispatches to lyric-architect]

Lyric:   [writes chorus first, proposes it]
         "Here's the chorus. Does this arc feel right?"

You:     [approve or adjust → lyrics complete]

Claude:  [dispatches to prompt-architect]

Prompt:  [builds prompt-package.md, explains decisions]

Claude:  [dispatches to adversarial-critic → Gate 1]

Critic:  [writes gate1.json → PASS]

Claude:  [reads gate1.json, confirms PASS]
         "Gate 1 passed. Dispatching to production-director."

Prod:    [suno credits: 2,347 remaining]
         [generates chorus ×2 → downloads to audio/]
         "Two chorus variations ready. Which do you prefer?"

You:     [listen, pick A]

Prod:    [extends verse 1, bridge, outro from chorus A]
         [concats full song → full.json]

Critic:  "Please run Split from Mix → Vocals in suno.com,
          download both stems to songs/.../audio/stems/"

You:     "Done."

Critic:  [stat complement.wav: 284,000 bytes → PASS]
         [writes gate2.json → PASS]

Claude:  "Both gates passed. Does the emotional arc land?"

You:     "Yes. Approved."
```

### Returning to a song in progress

```
You:     "Let's get back to the forgiveness song."

Claude:  [reads CLAUDE.md active song pointer]
         [reads songs/forgiveness-grief/brief.md]
         [reads songs/forgiveness-grief/generations/001/critique.md]

Claude:  "We're on generation 001. The verse 2 felt flat —
          that's where we stopped. Want to revise the verse 2
          lyrics or adjust the prompt first?"
```

### When Gate 1 fails

```json
{
  "gate": 1,
  "result": "FAIL",
  "failures": ["Style field leads with 'emotional pop ballad' — implies piano and strings"],
  "fix_instructions": "Remove 'pop ballad'. Replace with 'intimate vocal' at position 3."
}
```

The Producer reads this file, dispatches back to Prompt Architect with the fix instructions. Gate 1 runs again on the revised package. Generation only fires after a PASS.

---

## Part 7 — Credit Management

> [!WARNING]
> **Pro Plan: 2,500 credits/month — use-it-or-lose-it.** Subscription credits expire at your billing date each month. They do not roll over. Add-on credits (purchased separately) do not expire while your subscription is active and are the correct safety valve for overflow months.

### Credit costs per operation

| Operation | Credits | Notes |
|---|---|---|
| `suno generate` (v5.5) | ~5 | Per ~30–60s clip |
| `suno extend` | ~5 | Per section continuation |
| `suno concat` | ~2 | Minimal |
| Split from Mix (Gate 2) | 20 | Both stems total. Use this, not Auto Split. |
| Auto Split (12 stems) | 50 | Diagnostic only — not for routine Gate 2. |

### Per-song budget (section-by-section workflow)

| Phase | Operations | Credits |
|---|---|---|
| Chorus ×2 variations | 2 × 5 | 10 |
| Verse 1 extend | 1 × 5 | 5 |
| Verse 2 extend | 1 × 5 | 5 |
| Bridge extend | 1 × 5 | 5 |
| Outro extend | 1 × 5 | 5 |
| Concat | 1 × 2 | 2 |
| Gate 2 stem check | Split from Mix × 1 | 20 |
| Section replacement (occasional) | 1 × 5 | 5 |
| **Total per complete song** | | **~57 credits** |

**Monthly capacity (Pro: 2,500 credits):** ~43 complete songs at this workflow. Realistic for a personal studio: 20–30 songs/month with natural iteration and revision.

> [!TIP]
> Generate **best-of-2** for chorus and hook sections (the emotional peak), and **best-of-1** for outros and secondary verses. The Premier-era recommendation of "generate 5–10 variations" isn't budget-appropriate at 2,500 credits/month. Add-on credits are the right path for intensive months — they don't expire.

---

## Part 8 — Troubleshooting

### suno-cli errors

| Error | Cause | Fix |
|---|---|---|
| `schema_drift` | Suno changed their internal API | `suno update` then retry |
| `auth_expired` | JWT expired | `suno auth --refresh` |
| `Token validation failed` | Stale Clerk session | `suno auth --login` |
| `GenerationFailed` | Credit exhaustion or API issue | `suno credits`, retry once |
| hCaptcha rejection | Captcha enforcement | Keep browser open at suno.com; suno-cli uses browser-backed hCaptcha |

### Suno generation issues

| Problem | Fix |
|---|---|
| Instruments keep appearing | Strengthen `--exclude` list; add specific instrument names; add "human voice only" to Style |
| Wordless humming intro | Add to exclude: `ooh vocals, ahh vocals, ambient intro, vocalise` |
| Structure collapses by outro | Use section-by-section workflow — never full-song single-shot generation |
| Voice inconsistent across sections | Set up a Suno Voices persona and add `--persona [UUID]` |
| Harmonies don't appear | Add harmony direction: `[Chorus: full harmony, voices swell]` |
| Beatbox too quiet | Add `beatbox featured` to bridge modifier; raise weirdness to 40–50 |

### Claude Code subagent issues

| Problem | Fix |
|---|---|
| Agent returns result without acting | Check gate1.json/status.md contain actual content (not prose). Retry with explicit "write the JSON file" instruction |
| Orchestrator treats failed subagent as success | Read `gate1.json` directly — never trust Producer's prose summary |
| Session loses emotional brief context | Run `/compact` at ~50% context usage; brief.md is re-read on every generation trigger |

---

## Part 9 — Known Limitations

**Gate 2 stem check is manual in v1**

The `suno stems` command exists but does not yet expose type-specific extraction (Split from Mix vs Auto Split). Gate 2 requires opening suno.com, running Split from Mix manually, and downloading stems. This is the primary friction in v1. Target for v2: automate when suno-cli adds a `--stem-type` flag.

**The Critic cannot hear audio**

Gate 1 catches bad prompt architecture. Gate 2 catches significant instrumental leakage via complement stem file size. Gate 3 is your ears. Subtle leakage (very quiet background texture) passes Gate 2 and is caught only when you listen. Emotional quality judgement belongs to you by design.

**suno-cli is unofficial and can break**

Suno has no public API. This CLI reverse-engineers Suno's internal endpoints. It has broken twice in its first two months (v0.5.2: endpoint migration; v0.5.3: hCaptcha enforcement). Latest stable release: v0.5.7 (May 4, 2026). Run `suno update` when generation fails unexpectedly.

**Voice persona creation is a manual web UI step**

The Voice Profiler defines and manages voice characters, but creating the Suno Voices persona requires uploading audio at suno.com → Voices → Create Voice. The CLI cannot automate this yet. Voice personas on v5.5 can also be unstable — test across 5–10 generations before committing one to a project.

**Agent drift in long sessions**

Independent research (Rath, 2026) found that detectable behavioral drift in multi-agent LLM systems emerges at a median of 73 interactions. In long creative sessions, agents may subtly deviate from the emotional brief without explicit failures. Mitigations already in this design: re-reading `brief.md` before every generation trigger (Adaptive Behavioral Anchoring), running `/compact` at ~50% context usage, and the session-end brief update. For sessions exceeding ~60 interactions, consider starting a new Claude Code session and reloading from `brief.md`.

**Pro plan: no Advanced Split, no Suno Studio**

Advanced Split (generative stem reconstruction, more precise leakage detection) is Premier only. Split from Mix is sufficient for the proxy check. Suno Studio (multitrack DAW, MIDI export, Remove FX) is Premier only and not required for acapella generation. The `dry vocal, close-mic, no reverb` Style field workaround replaces Remove FX.

**Subagent fabrication risk**

Claude Code subagents occasionally return confident results without making the tool calls required to produce them. The gate JSON file pattern mitigates this: the Production Director reads and verifies `gate1.json` before acting. Run `/compact` at ~50% context usage to reduce risk.

---

## Part 10 — Upgrade Path

v1 is deliberately conservative — built for reliability over automation. Logical v2 additions, in priority order:

1. **Automated Gate 2** — when `suno stems --type split-from-mix` is available in the CLI, replace the manual step with automated complement file size analysis
2. **Whisper STT for Gate 3** — pipe generated audio through `whisper` CLI for automated lyric fidelity check; compare against `lyrics.md`
3. **Persona auto-selection** — Voice Profiler scores candidates in the persona registry against `brief.md` using semantic similarity
4. **Session memory formalisation** — explicitly write to `~/.claude/projects/<hash>/memory/MEMORY.md` at session end so the Producer auto-loads the last few session notes alongside `brief.md`
5. **Best-of-3 for key projects** — when credit budget allows (add-on credits or an intensive month with remaining balance), run best-of-3 on chorus sections for important tracks

---

## Pro Plan vs Premier

Stay on **Pro** if:
- Monthly song output stays below ~40 songs
- Split from Mix stem detection accuracy is sufficient
- You don't need Suno Studio's multitrack DAW or MIDI export

Consider **Premier** ($24/month annual) if:
- You consistently exhaust 2,500 credits before month end
- The complement stem check is missing subtle leakage you care about (Advanced Split gives significantly more precise separation)
- You want Remove FX post-processing for cleaner, drier vocal output
- 2–4 week early access to major features matters to you

---

*Built through Socratic dialogue. Every architectural decision was drawn out, validated against research, and corrected against evidence — not imposed.*

*Architecture validated by: Rath (2026) on multi-agent drift and hierarchy stability; HAIM benchmark (Go & Kim, 2026) on AI music production role decomposition; independent production data from bitwize-music-studio.*
