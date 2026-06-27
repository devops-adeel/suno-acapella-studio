#!/usr/bin/env bash
# test-pipeline.sh — offline end-to-end self-test (0 credits).
# Drives credits -> scaffold -> gate-check (block/allow/instrumental) -> generate
# -> gate2 (PASS+FAIL) -> gate3 (PASS+FAIL) -> inject-brief, asserting each step.
#
# Run:  bash scripts/test-pipeline.sh         (auto-sets SUNO_DRYRUN=1)
set -uo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO"
export CLAUDE_PROJECT_DIR="$REPO"
export SUNO_DRYRUN=1
export PATH="$REPO/scripts:$PATH"   # so `suno` resolves to the dry-run shim

SLUG="_selftest_$$"
SONG="songs/$SLUG"
GEN="$SONG/generations/001"
PASS=0; FAIL=0
ok()   { PASS=$((PASS+1)); printf '  \033[32mok\033[0m   %s\n' "$1"; }
bad()  { FAIL=$((FAIL+1)); printf '  \033[31mFAIL\033[0m %s\n' "$1"; }
check(){ if eval "$2"; then ok "$1"; else bad "$1 -> [$2]"; fi; }

cleanup() { rm -rf "$SONG" "$REPO/tests/tmp"; [ -f "$REPO/.studio/active-song.bak" ] && mv "$REPO/.studio/active-song.bak" "$REPO/.studio/active-song" || true; }
trap cleanup EXIT

# preserve any existing active-song pointer
[ -f "$REPO/.studio/active-song" ] && cp "$REPO/.studio/active-song" "$REPO/.studio/active-song.bak" || true

echo "== Suno Acapella Studio :: offline self-test =="

# 1) credits via shim
creds="$(suno credits)"
check "credits returns JSON balance" '[ "$(printf "%s" "$creds" | jq -r .data.credits)" = "2347" ]'

# 2) scaffold a throwaway song
mkdir -p "$GEN/audio" "$SONG/sections"
printf '[Chorus]\nI forgave you quietly\n' > "$SONG/sections/chorus.md"
printf '# Test · Emotional Brief\n## Status\nselftest\n' > "$SONG/brief.md"
printf '%s\n' "$SLUG" > "$REPO/.studio/active-song"
check "song scaffolded" '[ -f "$SONG/brief.md" ]'

GEN_CMD="suno generate --title T --tags \"a cappella, female vocals\" --lyrics-file $SONG/sections/chorus.md --download $GEN/audio/ --json"

# 3) gate-check BLOCKS when gate1 missing
out="$(printf '{"tool_input":{"command":%s}}' "$(printf '%s' "$GEN_CMD" | jq -Rs .)" | bash .claude/hooks/gate-check.sh)"
check "gate-check DENY (no gate1)" '[ "$(printf "%s" "$out" | jq -r .hookSpecificOutput.permissionDecision)" = "deny" ]'

# 4) write gate1 PASS -> gate-check ALLOWS (silent, empty output)
printf '{"gate":1,"result":"PASS","style_chars":120,"exclude_items":40,"lyrics_chars":80,"arc_match":true}\n' > "$GEN/gate1.json"
out="$(printf '{"tool_input":{"command":%s}}' "$(printf '%s' "$GEN_CMD" | jq -Rs .)" | bash .claude/hooks/gate-check.sh)"
check "gate-check ALLOW (gate1 PASS)" '[ -z "$out" ]'

# 5) --instrumental is always denied
out="$(printf '{"tool_input":{"command":%s}}' "$(printf '%s' "$GEN_CMD --instrumental" | jq -Rs .)" | bash .claude/hooks/gate-check.sh)"
check "gate-check DENY (--instrumental)" '[ "$(printf "%s" "$out" | jq -r .hookSpecificOutput.permissionDecision)" = "deny" ]'

# 6) generate via shim writes an audio artifact
eval "$GEN_CMD" > "$GEN/chorus-a.json"
check "generate produced audio file" '[ -f "$GEN/audio/dryrun-clip.mp3" ]'
CLIP="$(jq -r '.data[0].id' "$GEN/chorus-a.json")"
check "generate JSON has clip id" '[ "$CLIP" = "clip_dryrun_a" ]'

# 7) Gate 2 PASS (silent instrumental stem)
SUNO_DRYRUN_STEM=silent SUNO_DRYRUN_STEMDIR="$REPO/tests/tmp/stems_pass" bash scripts/gate2.sh "$CLIP" "$GEN" >/dev/null
check "gate2 PASS on silent stem" '[ "$(jq -r .result "$GEN/gate2.json")" = "PASS" ]'

# 8) Gate 2 FAIL (loud/large instrumental stem)
SUNO_DRYRUN_STEM=noisy SUNO_DRYRUN_STEMDIR="$REPO/tests/tmp/stems_fail" bash scripts/gate2.sh "$CLIP" "$GEN" >/dev/null
check "gate2 FAIL on noisy stem" '[ "$(jq -r .result "$GEN/gate2.json")" = "FAIL" ]'

# 9) Gate 3 PASS (fixture coverage 18/20 = 0.90)
bash scripts/gate3.sh "$CLIP" "$GEN" >/dev/null
check "gate3 PASS (coverage>=0.85)" '[ "$(jq -r .result "$GEN/gate3.json")" = "PASS" ]'

# 10) Gate 3 FAIL (low-coverage input)
mkdir -p tests/tmp
jq -n '{data:[{word:"a",success:true},{word:"b",success:false},{word:"c",success:false},{word:"d",success:false}]}' > tests/tmp/low.json
bash scripts/gate3.sh "$CLIP" "$GEN" --from-file tests/tmp/low.json >/dev/null
check "gate3 FAIL (coverage<0.60)" '[ "$(jq -r .result "$GEN/gate3.json")" = "FAIL" ]'

# 11) inject-brief surfaces the active song
ctx="$(bash .claude/hooks/inject-brief.sh | jq -r .hookSpecificOutput.additionalContext)"
check "inject-brief names active song" 'printf "%s" "$ctx" | grep -q "$SLUG"'

echo "== done: $PASS passed, $FAIL failed =="
[ "$FAIL" -eq 0 ]
