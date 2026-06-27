#!/usr/bin/env bash
# inject-brief.sh — SessionStart hook. Surfaces the active song's brief.md into context
# as the studio's anti-drift anchor (Adaptive Behavioral Anchoring). SessionStart hooks
# CANNOT block, so this is fail-safe by construction: any error → no context, never a
# broken session.
set -uo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
. "$DIR/lib.sh" 2>/dev/null || exit 0

repo="$(studio_repo_dir)"
slug="$(studio_active_song 2>/dev/null || true)"

emit() { # emit <context-string>
  if command -v jq >/dev/null 2>&1; then
    jq -n --arg c "$1" '{hookSpecificOutput:{hookEventName:"SessionStart",additionalContext:$c}}'
  else
    # Minimal hand-rolled JSON (newlines escaped).
    local esc; esc="$(printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g' | awk '{printf "%s\\n",$0}')"
    printf '{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"%s"}}\n' "$esc"
  fi
}

if [ -z "$slug" ] || [ ! -f "$repo/songs/$slug/brief.md" ]; then
  emit "Suno Acapella Studio: no active song detected. Ask which song to work on, or scaffold one with ./scripts/new-song.sh <slug>. Reminder: every output is pure vocals — no instruments, ever."
  exit 0
fi

brief="$(cat "$repo/songs/$slug/brief.md" 2>/dev/null || true)"
ctx="ACTIVE SONG: $slug
This is the emotional anchor for the session. Re-read it before every generation trigger and
state the emotional intent in one sentence before dispatching to production-director.
Reminder: pure vocals only — no instruments, ever. Never generate without gate1.json == PASS.

--- songs/$slug/brief.md ---
$brief"

emit "$ctx"
exit 0
