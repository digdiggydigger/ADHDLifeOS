# `F-CTACelebrations-7` — the chime E picked by ear

**Environment:** candidates produced 2026-09-13 on this machine; three synthesised locally, two
generated with ElevenLabs `eleven_text_to_sound_v2`. Sent to E as `.wav` with `SendUserFile` and
chosen by listening — the only way this decision could have been made.

**This folder is audio, not screenshots, and it belongs here for the same reason the images do:
what it records is a decision E settled by SENSE rather than by assertion.** No test can hear a
chime. `screenshots/` is the app's one home for "why does it look — or sound — like this?", so the
candidates live here rather than being deleted once the winner shipped.

## The pick

**E chose `04-generated-a`** (2026-09-13): *"'el-a.mp3' is a good Sound effect."* That exact file —
the trimmed, normalised 1.20 s version E heard, not the 3 s original — is now
`ADHD LifeOS/Assets.xcassets/CelebrationChime.dataset/CelebrationChime.caf`.

**E also reserved `05-generated-b`**, verbatim: *"Could you also keep a hold of the sound 'el-b' For
laser use as there is likely other locations that The sound 'el-b' Could be used."* It is kept here
as both `.wav` and a ready-to-ship `.caf`. **It is deliberately NOT in the asset catalog**: an asset
with no call site is dead weight the app would carry in every build, and this repo already has a
name for shipping things nothing reaches. When a second sound gets a real site, the `.caf` is ready
and no regeneration is needed.

## The candidates

All five were peak-normalised to **the same −3.0 dBFS** so E was comparing timbre rather than
loudness — RMS landed within 1.7 dB across the set, so the levels were genuinely close by ear too.

| file | what it is | duration | RMS |
|---|---|---|---|
| `01-single-note.wav` | One struck note, four inharmonic partials, upper ones decaying fastest — the most restrained thing that still reads as "landed". | 0.90 s | −20.6 dBFS |
| `02-rising-fifth.wav` | Two notes, C6→G6, same timbre — the classic "done", with the interval doing the work. | 0.95 s | −19.7 dBFS |
| `03-rising-arpeggio.wav` | C6→E6→G6 with a shimmer partial on the last — the most celebratory of the three. | 1.00 s | −21.0 dBFS |
| **`04-generated-a.wav`** | **E'S PICK.** ElevenLabs, from a brief asking for a warm bell-like sparkle with a gentle attack, never shrill or alarm-like. | 1.20 s | −21.4 dBFS |
| `05-generated-b.wav` | Second ElevenLabs generation, same prompt. **Reserved by E for future use elsewhere**, kept as `.caf` too. | 1.20 s | −20.5 dBFS |

`synth.py` is the generator for 01–03, kept so the three can be re-derived or re-tuned without
guessing at the partial structure. It is pure stdlib — `sox` is not installed on this machine and
installing it is E's call, not Claude Code's.

**Both ElevenLabs generations came back LONGER than the brief** — 1.4 s and 2.0 s of audio against a
request for ~1 s — so each was trimmed to a 1.20 s cap with a 120 ms raised-cosine fade, then
peak-matched to the others. E heard and approved the trimmed files, which is what shipped.

## What producing these caught that no test could

- **A chime cannot be auditioned by the thing that makes it.** Claude Code cannot hear, so the
  candidates could only be measured (duration, peak, RMS) and had to be chosen by E. That is the
  whole reason this block was specified as "E picks by ear" rather than as a build task, and it is
  why five candidates were sent rather than one recommendation.
- **A peak-normalised set is not automatically a loudness-matched set.** Peak was identical by
  construction; RMS varied by 1.7 dB across the five, and a wider spread would have had E comparing
  volume instead of character. Worth measuring rather than assuming, and worth widening the brief
  if a future set drifts further.

## Verified paths

The chime has no `#available` gate: `AVAudioSession` and `AVAudioPlayer` are available at the
app's 16.0 floor, so there is one path and no floor branch is owed.

> `Run on sim + E's phone (music playing, and on silent). No tiered API, so no per-tier line.`

**"Run on sim" is earned rather than assumed, and it nearly wasn't.** Every unit test injects
`loadAsset`, so none of them touches the catalog — `assetutil` showing the bytes inside
`Assets.car` proves they are in the bundle and nothing more, since a dataset can be present and
still unreadable by name, or hold something `AVAudioPlayer` refuses.
`testTheRealCatalogAssetLoadsAndIsPlayable` builds the player through its DEFAULT loader against
the real catalog and is what closes that gap.

**Reduce Motion is not involved** — §7.2 is explicit that haptics are unaffected because they are
not motion, and sound is the same shape. The chime plays identically with Reduce Motion on or off,
so **this block owes no RM-on device pass**; the setting that governs it is E's own "Celebration
sounds" switch, plus the phone's silent switch via `.ambient`.

## Nothing owed — the device verdict PASSED on both checks

**2026-09-13, on `wishwashwacky15`.** E, verbatim: ***"both work correctly"***, answering an ask
that named the two checks separately:

1. **With music playing** — the chime sounds UNDER the track without pausing it. That is
   `.mixWithOthers`, and it is the difference between a chime and the first celebration of the day
   stopping whatever the user is listening to.
2. **With the ring switch on silent** — no chime at all. That is `.ambient` rather than
   `.playback`, and it is E's own wish from the design record.

Neither could be proved on the simulator, which is exactly why the block was written to close on a
device verdict rather than on a green suite.
