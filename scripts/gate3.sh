#!/usr/bin/env bash
# gate3.sh — automated Gate 3 (lyric-fidelity proxy via alignment coverage).
#
# Usage: gate3.sh <clip_id> <gen_dir> [--from-file <timed-lyrics.json>]
#
# IMPORTANT: `suno timed-lyrics` returns FORCED ALIGNMENT of the lyrics you submitted
# (endpoint aligned_lyrics/v2), each word carrying a per-word `success` flag — it is NOT
# an independent transcription. So we do NOT diff text (that would be circular). Instead we
# compute alignment COVERAGE = (#words success:true) / (#words total). Low coverage means
# Suno could not place your words in the audio (skipped/mumbled lyrics, or instrumental
# drift). Thresholds (tune live):
#   >= SUNO_GATE3_PASS (0.85) -> PASS
#   >= SUNO_GATE3_FLAG (0.60) -> FLAG
#   else                       -> FAIL
# Note: true semantic transcription (did it sing the RIGHT words) needs ASR (Whisper) and is
# NOISY on sung audio (high ALT WER) — left as an optional, off-by-default extra.
set -uo pipefail

CLIP="${1:?usage: gate3.sh <clip_id> <gen_dir> [--from-file f.json]}"
GEN_DIR_REL="${2:?usage: gate3.sh <clip_id> <gen_dir> [--from-file f.json]}"
FROM_FILE=""
if [ "${3:-}" = "--from-file" ]; then FROM_FILE="${4:-}"; fi

REPO="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
GEN_DIR="$REPO/$GEN_DIR_REL"
OUT="$GEN_DIR/gate3.json"
mkdir -p "$GEN_DIR"

PASS="${SUNO_GATE3_PASS:-0.85}"
FLAG="${SUNO_GATE3_FLAG:-0.60}"

if [ -n "$FROM_FILE" ] && [ -f "$FROM_FILE" ]; then
  tl_json="$(cat "$FROM_FILE")"
else
  tl_json="$(suno timed-lyrics "$CLIP" --json 2>/dev/null || true)"
fi

if [ -z "$tl_json" ] || ! command -v jq >/dev/null 2>&1; then
  cat > "$OUT" <<EOF
{
  "gate": 3,
  "result": "MANUAL",
  "method": "fallback-manual",
  "checked_at": "$(date -u +%FT%TZ)",
  "clip_id": "$CLIP",
  "note": "Could not obtain/parse timed-lyrics (need the CLI output and jq). Fall back: listen and judge lyric fidelity yourself, then set result manually."
}
EOF
  echo "Gate 3: MANUAL (fallback) -> $OUT"
  exit 0
fi

total="$(printf '%s' "$tl_json" | jq '[.data[]] | length' 2>/dev/null || echo 0)"
ok="$(printf '%s' "$tl_json" | jq '[.data[] | select(.success==true)] | length' 2>/dev/null || echo 0)"
if [ "${total:-0}" -eq 0 ]; then
  cat > "$OUT" <<EOF
{ "gate": 3, "result": "MANUAL", "method": "no-words", "checked_at": "$(date -u +%FT%TZ)", "clip_id": "$CLIP",
  "note": "timed-lyrics returned no words (instrumental clip?). Verify by ear." }
EOF
  echo "Gate 3: MANUAL (no words) -> $OUT"
  exit 0
fi

coverage="$(awk -v o="$ok" -v t="$total" 'BEGIN{ printf "%.3f", (t>0)? o/t : 0 }')"
res="$(awk -v c="$coverage" -v p="$PASS" -v f="$FLAG" 'BEGIN{ if (c>=p) print "PASS"; else if (c>=f) print "FLAG"; else print "FAIL" }')"

cat > "$OUT" <<EOF
{
  "gate": 3,
  "result": "$res",
  "method": "alignment-coverage",
  "checked_at": "$(date -u +%FT%TZ)",
  "clip_id": "$CLIP",
  "aligned_words": $ok,
  "total_words": $total,
  "coverage": $coverage,
  "pass_threshold": $PASS,
  "flag_threshold": $FLAG
}
EOF
echo "Gate 3: $res (coverage $coverage) -> $OUT"
exit 0
