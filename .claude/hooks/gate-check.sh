#!/usr/bin/env bash
# gate-check.sh — PreToolUse hook. Blocks `suno generate` unless that generation's
# gate1.json shows "result":"PASS". Also blocks generation carrying --instrumental
# (which would defeat the acapella-only purpose of this studio).
#
# Reads the PreToolUse JSON payload on stdin; the Bash command is at .tool_input.command.
# Emits a permissionDecision JSON on stdout. Designed to FAIL CLOSED for generation:
# if it can't prove a PASS, it denies. Emergency bypass: SUNO_FORCE=1 (logged loudly).
set -uo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
. "$DIR/lib.sh"

deny() {
  local reason="$1"
  printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":%s}}\n' \
    "$(printf '%s' "$reason" | { command -v jq >/dev/null 2>&1 && jq -Rs . || printf '"%s"' "$(printf '%s' "$reason" | tr -d '"')"; })"
  exit 0
}
allow() { exit 0; }  # silent → normal permission flow applies

payload="$(cat)"
cmd=""
if command -v jq >/dev/null 2>&1; then
  cmd="$(printf '%s' "$payload" | jq -r '.tool_input.command // empty' 2>/dev/null || true)"
fi
[ -z "$cmd" ] && cmd="$payload"   # fallback: treat raw stdin as the command (test mode)

# Only intercept actual suno CLI invocations — not commands that merely mention
# "suno generate" in text (e.g. gh pr create --body "...", git commit -m "...").
studio_is_suno_cmd "$cmd" || allow

# Within a suno invocation, only gate on generate/describe subcommands.
case "$cmd" in
  *generate*|*describe*) : ;;
  *) allow ;;
esac

# Hard rule: never allow an instrumental generation in an acapella studio.
case "$cmd" in
  *--instrumental*) deny "Blocked: --instrumental defeats the acapella-only purpose of this studio. Remove the flag." ;;
esac

repo="$(studio_repo_dir)"
log="$repo/.studio/gate-check.log"
mkdir -p "$repo/.studio" 2>/dev/null || true

# Emergency bypass — allowed, but never silent.
if [ "${SUNO_FORCE:-0}" = "1" ]; then
  printf '%s  WARNING: SUNO_FORCE=1 bypassed gate-check for: %s\n' "$(date -u +%FT%TZ)" "$cmd" >> "$log" 2>/dev/null || true
  echo "WARNING: SUNO_FORCE=1 — gate-check bypassed. Generation is NOT verified against gate1.json." >&2
  allow
fi

gen_dir="$(studio_gen_dir_from_cmd "$cmd")"
if [ -z "$gen_dir" ]; then
  # No gen_dir found in the --download flag.
  # Only deny if --download is followed by a songs/ path (a real but malformed generation).
  # This prevents false positives when "suno generate" and "--download" both appear in
  # quoted text (e.g. git commit -m "...suno generate...--download only...").
  if printf '%s' "$cmd" | grep -qE -- '--download[[:space:]]+songs/'; then
    deny "Blocked: --download flag present but no songs/<slug>/generations/<n> path found in its value. Fix the download path to songs/<slug>/generations/<n>/audio/."
  else
    allow
  fi
fi

gate1="$repo/$gen_dir/gate1.json"
result="$(studio_gate_result "$gate1")"
case "$result" in
  PASS) allow ;;
  FAIL) deny "Blocked: $gen_dir/gate1.json is FAIL. Fix the prompt package per fix_instructions and re-run Gate 1 before generating." ;;
  *)    deny "Blocked: $gen_dir/gate1.json is missing. Adversarial Critic must run Gate 1 and write a PASS before generation." ;;
esac
