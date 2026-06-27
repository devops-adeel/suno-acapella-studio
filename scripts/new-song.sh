#!/usr/bin/env bash
# new-song.sh — scaffold a new song directory and mark it active.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

SLUG="${1:-}"
[ -z "$SLUG" ] && { echo "Usage: ./scripts/new-song.sh <song-slug>"; exit 1; }

SONG_DIR="$REPO_DIR/songs/$SLUG"
[ -d "$SONG_DIR" ] && { echo "Already exists: songs/$SLUG"; exit 1; }

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

# Mark active (machine-readable pointer used by the SessionStart brief-injection hook).
mkdir -p "$REPO_DIR/.studio"
printf '%s\n' "$SLUG" > "$REPO_DIR/.studio/active-song"

echo "✓ Scaffolded: songs/$SLUG  (active song set)"
echo "Open Claude Code and say: \"Let's start a new song. I've scaffolded songs/$SLUG/\""
