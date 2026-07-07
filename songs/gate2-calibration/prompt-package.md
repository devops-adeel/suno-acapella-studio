---
title: Gate 2 Calibration — Open Morning
style: >
  a cappella, unaccompanied vocals, solo voice, female vocals, clear,
  warm, intimate, single voice, no harmony, no backing vocals,
  dry vocal, close-mic, no reverb, no room sound, no instruments,
  no accompaniment
exclude: >
  guitar, piano, drums, bass, synthesizer, strings, brass, woodwinds,
  keyboard, organ, violin, cello, viola, trumpet, trombone, saxophone,
  flute, clarinet, oboe, harp, banjo, mandolin, ukulele,
  electric guitar, acoustic guitar, bass guitar, rhythm guitar,
  808, hi-hat, snare, kick, cymbal, percussion, melody,
  chord progression, backing track, accompaniment, instruments, music,
  harmonica, accordion, orchestral, band, live band,
  no chord structure, no musical arrangement, no audio bed,
  no pads, no ambient music, no underscore, no musical backdrop,
  ooh vocals, ahh vocals, la la vocals, ambient intro, cinematic intro,
  wordless intro, humming, vocalise,
  beatbox, mouth percussion, vocal percussion, harmony, backing vocals
vocal: female
weirdness: 20
style-influence: 75
persona-id: omit
---

# Prompting Decisions — Gate 2 Calibration

## Goal
This is a throwaway calibration generation. The single objective is the **cleanest
possible pure-vocal output** so the *instrumental* stem reads as close to silence as
possible, anchoring the Gate 2 dB threshold empirically. Artistic merit is irrelevant
here; stem separation cleanliness is everything.

## Style field decisions
- **Positions 1–3 are acapella-specific** per the mandatory studio rule:
  `a cappella, unaccompanied vocals, solo voice`. No genre name leads (genres imply
  instruments and would risk leakage into the instrumental stem).
- **Solo / no harmony.** The brief explicitly forbids harmonies and backing vocals —
  layered voices can bleed into the instrumental stem during separation and corrupt the
  dB reading. `solo voice, single voice, no harmony, no backing vocals` enforce this.
- **Dry / close-mic (Remove-FX workaround).** Pro plan has no Remove FX, so
  `dry vocal, close-mic, no reverb, no room sound` are in the Style field per CLAUDE.md.
  Reverb tails are exactly the kind of artifact a separator can dump into the
  instrumental stem, so suppressing them at the source matters for a clean measurement.
- **Tier-1 character only.** `clear, warm, intimate` are all Tier-1 (>80% compliance) —
  no Tier-2/3 tags, to keep the render predictable and low-risk. No beatbox, no mouth
  percussion (brief forbids them; they also confuse Gate 2's "instrumental" detection).
- **Inline negation kept light** (`no instruments, no accompaniment`) — the heavy lifting
  is done by the Exclude field per the exclusions-bank guidance.

## Exclude field decisions
- Uses the **complete standard set, never abbreviated** (calibration wants maximum
  exclusion coverage).
- Adds the **stubborn-leakage** block (`no chord structure, no musical arrangement, ...`).
- Adds the **intro-specific** block to stop a wordless opening hum/vocalise — important
  here because the lyrics open mid-phrase ("Morning light is slow") and any ambient
  wordless intro would muddy stem separation at the very start of the file.
- Adds explicit `beatbox, mouth percussion, vocal percussion, harmony, backing vocals`
  to lock in the solo-voice intent from both directions.

## Slider decisions
- `vocal: female` — neutral simple lead, matches the brief's "simple neutral female or
  male" guidance.
- `weirdness: 20` — lowest end of the 20–40 range. Calibration wants zero risk and the
  most literal, conventional vocal delivery possible.
- `style-influence: 75` — top of the 65–75 range, to maximise adherence to the acapella /
  dry / solo instructions and minimise the chance of instrumental leakage.

## Metatag arc check
The brief's arc is deliberately minimal (no bridge, fade to silence). The lyrics match:
Verse (gentle gratitude) -> Chorus (single affirmation) -> Outro (fading). There is no
energy peak or break-open moment to land a `[Belted]`, by design — this is a calm,
grounded calibration piece. Each section header already carries
single-voice/close-mic/fading delivery tags, consistent with the solo-clean goal. Arc is
coherent with the brief.

## Ready-to-use generate command
The `--download` path includes the literal
`songs/gate2-calibration/generations/001/audio/` required by the gate-check hook.
Run `suno credits` first (studio rule), and ensure
`songs/gate2-calibration/generations/001/gate1.json` shows `"result":"PASS"` (the
PreToolUse hook blocks generation otherwise).

```bash
suno generate \
  --title "Gate 2 Calibration — Open Morning" \
  --tags "a cappella, unaccompanied vocals, solo voice, female vocals, clear, warm, intimate, single voice, no harmony, no backing vocals, dry vocal, close-mic, no reverb, no room sound, no instruments, no accompaniment" \
  --lyrics-file "songs/gate2-calibration/lyrics.md" \
  --exclude "guitar, piano, drums, bass, synthesizer, strings, brass, woodwinds, keyboard, organ, violin, cello, viola, trumpet, trombone, saxophone, flute, clarinet, oboe, harp, banjo, mandolin, ukulele, electric guitar, acoustic guitar, bass guitar, rhythm guitar, 808, hi-hat, snare, kick, cymbal, percussion, melody, chord progression, backing track, accompaniment, instruments, music, harmonica, accordion, orchestral, band, live band, no chord structure, no musical arrangement, no audio bed, no pads, no ambient music, no underscore, no musical backdrop, ooh vocals, ahh vocals, la la vocals, ambient intro, cinematic intro, wordless intro, humming, vocalise, beatbox, mouth percussion, vocal percussion, harmony, backing vocals" \
  --vocal female \
  --weirdness 20 \
  --style-influence 75 \
  --model v5.5 \
  --download "songs/gate2-calibration/generations/001/audio/"
```

> Note: `--instrumental` is deliberately absent and is hook-blocked anyway. Do not add it.
