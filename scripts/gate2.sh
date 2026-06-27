#!/usr/bin/env bash
# gate2.sh — automated Gate 2 (instrumental-leakage check).
#
# Usage: gate2.sh <clip_id> <gen_dir>
#   <gen_dir> is relative to repo root, e.g. songs/forgiveness/generations/001
#
# Method: `suno stems` splits the clip into vocals + instrumental. For a clean acapella,
# the INSTRUMENTAL stem should be ~silent. We measure its LOUDNESS with ffmpeg
# (mean_volume dB) — NOT file size, which is meaningless for uncompressed WAV.
# Thresholds (dB mean_volume, tune live):
#   <= SUNO_GATE2_PASS_DB (-50)  -> PASS
#   <= SUNO_GATE2_FLAG_DB (-30)  -> FLAG (surface to user)
#   else                          -> FAIL (strengthen exclusions, retry)
# Fallback when ffmpeg is absent: byte-size proxy (UNRELIABLE for WAV; warns).
set -uo pipefail

CLIP="${1:?usage: gate2.sh <clip_id> <gen_dir>}"
GEN_DIR_REL="${2:?usage: gate2.sh <clip_id> <gen_dir>}"
REPO="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
GEN_DIR="$REPO/$GEN_DIR_REL"
OUT="$GEN_DIR/gate2.json"
mkdir -p "$GEN_DIR/audio/stems"

PASS_DB="${SUNO_GATE2_PASS_DB:--50}"
FLAG_DB="${SUNO_GATE2_FLAG_DB:--30}"

write_json() { # write_json <result> <method> <detail-json>
  cat > "$OUT" <<EOF
{
  "gate": 2,
  "result": "$1",
  "method": "$2",
  "checked_at": "$(date -u +%FT%TZ)",
  "clip_id": "$CLIP",
  $3
}
EOF
  echo "Gate 2: $1 ($2) -> $OUT"
}

# 1) Ask the CLI to split stems. `suno` resolves via PATH (real binary live, shim in dry-run).
stems_json="$(suno stems "$CLIP" --json --wait 2>/dev/null || suno stems "$CLIP" --json 2>/dev/null || true)"

inst=""
if [ -n "$stems_json" ] && command -v jq >/dev/null 2>&1; then
  inst="$(printf '%s' "$stems_json" | jq -r '.data.instrumental_path // empty' 2>/dev/null || true)"
  if [ -z "$inst" ]; then
    url="$(printf '%s' "$stems_json" | jq -r '.data.instrumental_url // empty' 2>/dev/null || true)"
    if [ -n "$url" ] && command -v curl >/dev/null 2>&1; then
      inst="$GEN_DIR/audio/stems/instrumental.wav"
      curl -fsSL "$url" -o "$inst" 2>/dev/null || inst=""
    fi
  fi
fi

if [ -z "$inst" ] || [ ! -f "$inst" ]; then
  write_json "MANUAL" "fallback-manual" \
    "\"note\": \"Could not obtain an instrumental stem from 'suno stems'. Fall back: run Split from Mix on suno.com, save the instrumental to $GEN_DIR_REL/audio/stems/instrumental.wav, then re-run gate2.sh.\""
  exit 0
fi

# 2) Preferred: ffmpeg loudness.
if command -v ffmpeg >/dev/null 2>&1; then
  mean="$(ffmpeg -hide_banner -nostats -i "$inst" -af volumedetect -f null - 2>&1 \
            | grep -oE 'mean_volume: -?[0-9.]+ dB' | grep -oE '\-?[0-9.]+' | head -1 || true)"
  if [ -z "$mean" ]; then mean="0"; fi
  # Compare floats via awk.
  res="$(awk -v m="$mean" -v p="$PASS_DB" -v f="$FLAG_DB" 'BEGIN{ if (m<=p) print "PASS"; else if (m<=f) print "FLAG"; else print "FAIL" }')"
  write_json "$res" "ffmpeg-volumedetect" \
    "\"instrumental_mean_db\": $mean, \"pass_db\": $PASS_DB, \"flag_db\": $FLAG_DB, \"instrumental_path\": \"$inst\""
  exit 0
fi

# 3) Fallback: byte size (unreliable for WAV — warn).
bytes="$(wc -c < "$inst" | tr -d ' ')"
res="$(awk -v b="$bytes" 'BEGIN{ if (b<500000) print "PASS"; else if (b<=2000000) print "FLAG"; else print "FAIL" }')"
write_json "$res" "bytesize-fallback" \
  "\"instrumental_bytes\": $bytes, \"warning\": \"ffmpeg missing; byte-size is UNRELIABLE for WAV. Install ffmpeg and re-run for a valid loudness check.\""
exit 0
