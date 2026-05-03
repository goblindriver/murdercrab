# Playtest 2026-05-02 21:06 — Run 1 (12:45)

Voice isolated with demucs (htdemucs), transcribed with whisper-large-v3-turbo. Frames sampled every 5s; the table below pairs commentary timestamps with what was on screen at that moment.

## Timeline

| Time | What's on screen | What you said |
|---|---|---|
| 0:00–0:55 | PICO-8 console: typed `LOAD MURDERCRAB`, then `RUN MURDERC` | (silent — boot) |
| 1:00 | Level 1 begins. Score 11,250, x5 cherries, "WARNING" text up. | (silent — playing) |
| 1:30 | Score 0?? Likely a screen-clear / restart artifact, level 1 still | — |
| 2:00 | Level 1 still, score 40,640, x10 | — |
| 2:20 | Mid-warp into next level, bg flashing green | "We're entering stage 2 right now and the cherries reset to…" *(cut)* |
| 2:30 | Level 2 (dark blue), score 131,410, x3 | — |
| 3:00 | Level 2 mid, x2 | — |
| 3:22 | Level 3 (dark green), score 247,420 | "I love three." (probably "level three") |
| 4:00 | Level 3, x16 multiplier — peak cherry chain | — |
| 4:28 | Level 4 (dark purple), score ~720k, x15 | "Alright, level four. This is where the high rank and…" *(cut)* |
| 4:30 | **Bomb activated** — full screen white flash, all bullets canceling | — |
| 5:00 | Level 4 still, x15 | — |
| 5:18 | Level 5 (brown), score 858,220, x5 | "Alright, here we are, level five, no bombs." |
| 5:30 | Level 5 enemies, mini-boss approaching | — |
| 6:00 | Level 5 boss with circular attack pattern | — |
| 6:11 | Score crossed high-score threshold | "We got a high score." |
| 6:13 | High-score indicator flashing yellow | "We're blinking yellow on the right." |
| 6:14 | TLB warp-in / level 6 transition | "Level 6, true last boss. This is my first time here. No bomb." |
| 6:30 | **GAME OVER**, "Z: CONTINUE / X: QUIT", credits 2 | "Oh!" "Oh no!" "Good." |
| 6:44–7:02 | Continue chosen — back into level | "I don't know what to speak." "I didn't have to find me. That's a problem." "Now move two." |
| 7:30–8:00 | Looped — back at level 1 (black), pushing through | "What it looks like once you get over it." |
| 8:30–9:00 | Level 2 again, score crossing 1M | "Come on." |
| 9:00 | Heavy bullet pattern, possible hit / bomb / explosion, gray/white bg | — |
| 9:30 | **GAME OVER**, level 3, credits 3 (so loop 2 fresh credits) | — |
| 10:00 | Level 3 reentry after continue, x13 | — |
| 10:30–11:25 | Level 4, slogging through | — |
| 11:12 | (unclear short noise) | "We'll pipe." (probably noise) |
| 11:30 | **ENTER INITIALS** screen on level-5 (brown) backdrop — bug visible | "Now it's asking me for my input even though it said ACE when I beat the TLB without putting my input in. So there's some things I need to disambiguate about that." |
| 11:48 | Initials confirmed; instructions screen with same brown backdrop bug | "You see now the front plate of the game after I beat the game, the backdrop is replaced with whatever level I was on, that backdrop." |
| 11:58 | Title cycle begins, backdrop still brown | "And I think you'll find that when I start a new game after that, on the screen, it will say level 5." |
| 12:30 | New run started, died fast — score 6,520, GAME OVER | (silent) |

## Outstanding cuts (you talked, whisper missed the rest)

- **2:21** "…cherries reset to…" — finish that thought next time. (Counter behavior at level transitions?)
- **4:28** "This is where the high rank and…" — rank ramp behavior on level 4?
- **5:18** "no bombs" — by choice, or bombs not feeling worth it?
- **7:57** "What it looks like once you get over it." — over what?

## Concrete bugs/issues observed (visual + audio confirmed)

1. **Initials prompt despite "ACE" already shown on victory screen** — confirmed by your 11:32 commentary + frame 76-79 showing TLB victory then GAME OVER flow.
2. **Backdrop persistence** — frames 139, 145, 151 (11:30, 12:00, 12:30) all show level-5 brown bg behind menu/initials/instructions UI.
3. **(Predicted) "Level 5" on next run start** — you predicted this at 12:05; would need to look at the warp text on a 12:30+ frame to confirm. Frame 151 shows the post-game state but the warp text isn't visible in the 5-second sample.

## Process artifacts

- `audio.mp3` — original audio extract
- `voice.wav` — demucs vocal stem (clean)
- `voice.json` — whisper raw output with word timestamps
- `frame_NNNN.jpg` — 153 frames, one per 5s
- `overview.jpg` — full-run montage (10×16)
- `timeline_grid.jpg` — 30s-sample montage (5×6)
- `notes.md` — first-pass cart-code mapping (earlier)
- `log.md` — this file
