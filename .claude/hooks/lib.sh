#!/usr/bin/env bash
# lib.sh — shared helpers for Suno Acapella Studio hooks & gate scripts.
# Source this; do not execute. All functions avoid `set -e` surprises in callers.

# Resolve the repo root regardless of where we're sourced from.
studio_repo_dir() {
  if [ -n "${CLAUDE_PROJECT_DIR:-}" ]; then echo "$CLAUDE_PROJECT_DIR"; return; fi
  local d; d="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
  echo "$d"
}

# Extract `songs/<slug>/generations/<n>` from a shell command string.
# Works whether the path came from --download, --lyrics-file, or an output redirect.
studio_gen_dir_from_cmd() {
  local cmd="$1"
  printf '%s' "$cmd" | grep -oE 'songs/[^/ "'"'"']+/generations/[0-9]+' | head -1
}

# Read the "result" field from a gate JSON file. Echoes PASS|FAIL|MISSING.
studio_gate_result() {
  local f="$1"
  [ -f "$f" ] || { echo "MISSING"; return; }
  if command -v jq >/dev/null 2>&1; then
    jq -r '.result // "MISSING"' "$f" 2>/dev/null || echo "MISSING"
  else
    grep -oE '"result"[[:space:]]*:[[:space:]]*"[A-Z]+"' "$f" | grep -oE '[A-Z]+$' | head -1 || echo "MISSING"
  fi
}

# Resolve the active song slug: explicit pointer first, else most-recently-modified brief.md.
studio_active_song() {
  local repo; repo="$(studio_repo_dir)"
  local ptr="$repo/.studio/active-song"
  if [ -s "$ptr" ]; then
    head -1 "$ptr" | tr -d '[:space:]'
    return
  fi
  # Fallback: newest brief.md under songs/.
  local newest=""
  if [ -d "$repo/songs" ]; then
    newest="$(ls -t "$repo"/songs/*/brief.md 2>/dev/null | head -1 || true)"
  fi
  if [ -n "$newest" ]; then
    basename "$(dirname "$newest")"
  fi
}
