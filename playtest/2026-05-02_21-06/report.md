# Playtest report — Run 1 (2026-05-02 21:06, 12:45)

## Headline

You played from cold to TLB in 6:30, died first try, used a continue, beat TLB, looped to game_loop=2, died on level 3 of loop 2, eventually game-overed and dropped to the post-game UI. **You never used a bomb the entire run.** You spotted three bugs in real time — all three are visually confirmed in the frames.

Final state at end of recording: a fresh new run started, died after ~25 sec, score 6,520. The "LEVEL 5" warp text on that new run start is on tape (frame 1451) — confirmed bug.

---

## What's working

**Score readability.** You explicitly called out the high-score crossover at 6:11 ("we got a high score… we're blinking yellow on the right"). That visual feedback landed. You noticed it without having to think about it.

**Cherry chain pacing.** You hit x27 cherries during the level-3→level-4 warp at 4:30. That's a strong feedback loop — staying alive long enough to chain 27 cherries means the multiplier system is rewarding sustained play, which is what you want from a shmup.

**TLB feels like a real boss.** First-time encounter, you died in ~16 seconds. That's the right shape: TLB earns the "true last" name, not a victory lap.

**Loop 2 difficulty curve.** You made it through the first half of loop 2 (level 1→3) but died on level 3 of the loop. Loop 2 being noticeably harder than loop 1 is correct.

---

## Confirmed bugs

All three are visible in the recording. Code locations from earlier mapping.

### 1. New game starts with "LEVEL N" instead of "LEVEL 1" — CONFIRMED ON TAPE
- **Frame 1451 (12:05)** literally shows `LEVEL 5` in white text mid-warp on a brown bg
- Predicted by you at 12:05; bug visible 0 seconds later
- Cause: [murdercrab.p8:446](pico8/murdercrab.p8:446) — `start_game()` sets `game_state = "starting"` but doesn't reset `current_level`. The warp draw at [murdercrab.p8:312](pico8/murdercrab.p8:312) reads `current_level` directly. `init_game()` only resets `current_level = 1` mid-warp, after the level text has already been drawn for several frames.
- **Fix**: add `current_level = 1` to `start_game()` before setting game_state.

### 2. Level backdrop bleeds into title / instructions / enter_initials — CONFIRMED
- Frame 1385 (11:32) ENTER INITIALS on brown bg
- Frame 1417 (11:48) INSTRUCTIONS in red text on brown bg — terrible contrast as side effect
- Frame 1437 (11:58) title cycle, brown bg still
- Cause: [murdercrab.p8:322-325](pico8/murdercrab.p8:322) — `draw_starfield()` uses `current_level` unconditionally
- **Fix** (one line): `local cl = (game_state == "game" or game_state == "starting") and min(current_level, max_level) or 1`

### 3. "PILOT: ACE" on victory screen, then prompted to enter initials anyway
- Cause: [murdercrab.p8:1723](pico8/murdercrab.p8:1723) shows `get_initials()` (default = "ACE") on the victory screen, but the score isn't actually saved until the user presses X and goes through enter_initials at [murdercrab.p8:1788-1792](pico8/murdercrab.p8:1788)
- This is a UX inconsistency, not a strict bug. Three options:
  - A. Drop "PILOT: …" from the victory screen until initials are confirmed
  - B. Treat the displayed default as accepted; skip enter_initials if user pressed X
  - C. Always go to enter_initials, with field pre-filled to the default — making the act of entering unambiguous
- C is probably the cleanest: it preserves the high-score-name ritual without contradicting itself.

---

## Friction signals (you flagged but didn't finish the thought)

### Bombs go unused for entire 12-minute run
- 5:18 you noted "level five, no bombs"
- Earlier transcript run picked up "Oh, the bombs have not been…" (cut)
- You died at TLB at 6:30 with 3 bombs in inventory
- This is data, not opinion: **a player on their first TLB encounter does not reach for the bomb**. That's worth investigating. Options:
  - Bombs aren't discoverable enough — instructions screen says "BOMB: X BUTTON" but if it's the first time you've ever needed a bomb, the muscle memory isn't there
  - Bombs feel too valuable to spend ("save it for when I really need it" → never)
  - Bomb cost/benefit isn't clear — does it clear bullets? do damage? both? for how long?
- I can't tell which from one run. Worth a follow-up recording where you deliberately try to use bombs and narrate.

### Rank ramp at level 4 — cut off
- 4:28 "This is where the high rank and…" *(trail off)*
- Frame 541 confirms the level 4 warp is happening
- Pin this for next pass — what does rank do at level 4 that's notable?

### "Cherries reset to…" at level transitions — cut off
- 2:21 "we're entering stage 2 right now and the cherries reset to…"
- The cherry counter on screen at frame 261 (2:10, end of level 1) shows x10. After warp into level 2, frame 305 (2:32) shows x3.
- So cherries reset to ~3 (or some lower value) on level transition. You didn't say if that feels right or wrong — open question.

---

## Visual observations (mine, not yours)

### Starfield density
You didn't comment on this, but I noticed early — the starfield is dense and bullets/enemy projectiles include white. In some frames (e.g. frame 109 around 9:00) the screen is so cluttered with mixed-color streaks that distinguishing player bullets from enemy bullets from stars is hard. You either implicitly handled it or it's genuinely not a problem during play. Worth a deliberate "is this readable" pass on a future run.

### Warp white flash is mistakeable for a bomb
Frame 541 (level 4 warp) and frame 1451 (level 5 wrong-warp) both pass through near-white during the transition. Visually similar to the bomb effect (frame 55 in the original sparser sample). If the bomb's "screen flash" and the warp's "screen flash" share too much vocabulary, it can blunt the bomb's feel. A future readability pass could check whether the bomb has a distinctive enough payoff vs. just a warp.

### High-score yellow blink works
Frame 728 (6:04) shows the score numbers on the right turning yellow as you cross the threshold. That's the moment you called out at 6:11. Visual cue is doing its job.

---

## Difficulty curve evidence

| Marker | Time | Score | Notes |
|---|---|---|---|
| Game start | 0:55 | 0 | |
| Level 2 entry | 2:20 | 128k | |
| Level 3 entry | 3:00 | 210k | |
| Level 4 entry | 4:28 | 565k | x27 cherries — peak |
| Level 5 entry | 5:18 | 858k | x5 cherries (chain reset) |
| TLB entry (loop 1) | 6:14 | 966k | 1st time, x7 |
| Death @ TLB | 6:30 | 970k | 16 sec into TLB |
| TLB cleared (continue) | ~7:00 | — | inferred from credits-3 reset |
| Death @ loop 2 L3 | 9:30 | 1.13M | |
| Final game over | ~11:25 | — | |

Pacing reads as: ~1 minute per level on first run, TLB is a real wall, looping is meaningfully harder. That's a healthy curve. If you want a polish pass on difficulty, the question to record next is "did level X feel cheap or fair when I died?"

---

## Suggested polish order

1. **Fix the three bugs** (small, mechanical, low risk):
   - One-line fix to `draw_starfield` for backdrop bleed
   - One-line fix to `start_game` for level-1 reset
   - Pick A/B/C for the PILOT/initials inconsistency
2. **Bomb discoverability** — record a focused playtest where you try to use bombs deliberately. Or: redesign so the first level practically requires a bomb (forcing the muscle memory).
3. **Starfield/bullet readability** — mostly mine. Worth checking with a deliberate-attention pass.

Don't fix anything else from this run yet. One run is one data point.

---

## Process notes

- Audio capture worked: voice was at 0.0 dB peak throughout, demucs cleanly isolated
- Whisper still hallucinated in silent stretches — filtered with a "all-same-words" check in the script
- The 1530-frame dense extract gives sub-second pairing; this report cites specific frames you can pull up
- The pipeline script ([playtest/process.sh](playtest/process.sh)) reproduces all of this in one command for the next recording
- OBS now records mic on Track 2 — future runs skip demucs entirely (~10 min saved per run)
