#!/usr/bin/env bash
# setup.sh — Suno Acapella Studio setup. Self-contained: the suno skill is VENDORED
# in this repo (.claude/skills/suno/), so there is no `suno install-skill` step.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_DIR"

echo "════════════════════════════════════"
echo "  Suno Acapella Studio — Setup"
echo "════════════════════════════════════"

# Prerequisites
command -v git    >/dev/null 2>&1 || { echo "ERROR: git not found"; exit 1; }
command -v claude >/dev/null 2>&1 || echo "WARN: Claude Code not found → npm install -g @anthropic-ai/claude-code"

# suno-cli (Rust) — NOT `pip install suno-cli` (that's a different/AceDataCloud tool).
if command -v suno >/dev/null 2>&1; then
  echo "✓ suno-cli: $(suno --version 2>/dev/null || echo 'installed')"
else
  echo "WARN: suno-cli not found. Install: brew tap paperfoot/tap && brew install suno"
  echo "      (You can still run everything offline with SUNO_DRYRUN=1.)"
fi

# ffmpeg — required for the automated Gate 2 loudness check.
if command -v ffmpeg >/dev/null 2>&1; then
  echo "✓ ffmpeg: present (Gate 2 loudness check enabled)"
else
  echo "WARN: ffmpeg not found → Gate 2 degrades to an unreliable byte-size proxy."
  echo "      Install: brew install ffmpeg"
fi

# Vendored skill check (self-contained; no home-profile install).
if [ -s ".claude/skills/suno/SKILL.md" ]; then
  echo "✓ Vendored suno skill: .claude/skills/suno/SKILL.md"
else
  echo "WARN: .claude/skills/suno/SKILL.md missing or empty."
fi

# Reference files must be populated (agents read them every run).
MISSING=()
for f in exclusions-bank.md acapella-formulas.md vocal-tag-bank.md metatag-arc-library.md; do
  [ ! -s "references/$f" ] && MISSING+=("references/$f")
done
if [ ${#MISSING[@]} -gt 0 ]; then
  echo ""
  echo "⚠ Populate these reference files before your first session:"
  for f in "${MISSING[@]}"; do echo "  - $f"; done
fi

mkdir -p songs personas .studio
echo ""
echo "✓ Setup complete."
echo "  Offline self-test:  SUNO_DRYRUN=1 bash scripts/test-pipeline.sh"
echo "  Start a song:       ./scripts/new-song.sh <slug>  then  claude ."
