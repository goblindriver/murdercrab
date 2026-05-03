# Playtest report — Run 3 (2026-05-03 07:09, 10:37, no commentary)

Pure-visual analysis. Pipeline ran clean (Track 2 mic isolation handled the empty audio fine — transcript is just hallucinations, ignored).

## Run shape (read off the overview grid)

| Time | What happened |
|---|---|
| 0:00–0:30 | Console boot, title cycle showing INSERT COIN |
| 0:30–1:00 | Inserted coin (credits → 1), pressed start |
| 1:00–2:00 | Level 1 (black bg) |
| 2:30 | Level 2 (dark blue) — quick |
| 3:00–4:00 | Level 3 (green) |
| **4:00** | **Peak: x28 cherry chain, 608k score, boss-clear explosion cluster** |
| 4:30 | Level 4 warp (purple/magenta) |
| 5:00 | Level 4 mid |
| 5:30 | **GAME OVER on level 5 brown bg, score 882k, big countdown digit "7" visible** |
| ~6:00 | Used continue, pushed through, died at TLB |
| 6:30 | **ENTER INITIALS on clean BLACK bg ✓** (backdrop fix confirmed) |
| 7:00 | New game starts, **warp text says "LEVEL 1" ✓** (state-leak fix confirmed) |
| 7:30–10:00 | Run 2: levels 1, 2, 3, then died at level 4 |
| 10:30 | High score table cycle, run ends |

Two complete attempts in 10:37. Run 1 cleared 4 levels and reached TLB. Run 2 stalled at level 4.

---

## What I can confirm from the frames alone

### Bugs we fixed are actually fixed
- **Frame 781 (6:30) ENTER INITIALS** is on a clean black bg, not the level-5 brown bleed we saw in run 1
- **Frame 841 (7:00) warp animation** literally says `LEVEL 1` on the new game start, not `LEVEL 5`
- **Frame 661 (5:30) GAME OVER** shows the big white countdown digit `7` mid-screen — the new bigprint working at 3x scale
- **Bottom strip** shows `CREDITS 2` shadow_text style — arcade UI active across all states
- The level-3 high-score (`1,518,448`) renders with two commas. Comma fix landed.

### Bomb behavior changed between runs
This is the interesting visual signal:
- **Run 1**: bomb count visible in bottom-right stays at 3 the whole time. **No bombs used.**
- **Run 2**: between frame 1021 (8:30, 3 bombs) and frame 1141 (9:30, 1 bomb), **two bombs got used**. Both during level 3.

So the player used bombs in their second run after not using any in the first. Could be a learned behavior, or a level-3 bullet pattern that demanded it. Worth a follow-up: was the level-3 challenge what unlocked bomb usage, or did continues just lower the stakes for spending them?

### Player skill / pace
- **x28 cherry peak** at frame 481 (4:00). Sustained chain through level 1-3 before resetting on level 4 warp.
- **x16 second peak** at frame 1141 (9:30) on the second run, level 3.
- Level 1 takes ~1 minute. Level 2 finished in ~25 seconds (very quick — possibly just a transition level or the player blew through it). Levels 3–5 are ~1 minute each.
- TLB is the wall. Both attempts to push past level 5 ended in death.

### Difficulty signal
- **Level 4 is becoming the second wall.** Run 2 died there without reaching 5. If a third run also stalls at level 4, that's a real friction point worth investigating — what's the level 4 enemy pattern that catches them out?
- Level 5 / TLB is consistent across runs — first encounter dies fast (16 sec in run 1, similar pattern likely here).

---

## What I notice purely from looking

### Starfield + bullet density
Several frames (especially around bosses and level 5) have the screen densely populated with both white starfield pixels and red player bullets / yellow enemy fire. **Frame 481** is a particular case where the explosion cluster makes the player ship invisible — which means in that moment, the player can't see themselves. That might be normal for a boss-clear celebration, but it's a readability point.

### HUD positioning seems clean across all states
The top row (score / hi-score), middle-left cherry/multiplier, bottom-left lives, bottom-right bombs, bottom-center credits — they don't visually compete with the gameplay area. Credits text at y=120 sits below the active field even in busy frames.

### Level 2 feels rushed
At ~25 seconds, level 2 is half the duration of every other level. Either the player chained through it on the cherry x14 multiplier, or the level itself is short by design. Worth noting because a uniform level pace would feel different.

### Game-over countdown is now legible
The "7" in frame 661 is unmistakeably a 7, not a "5s" you have to squint at. The 3x scale paid off. I can read it from the overview thumbnail at 1/4 size.

---

## What I can't tell without your commentary

- Whether any death felt cheap / unfair
- If bullet patterns at level 4-5 feel readable in real time
- Whether the bomb usage in run 2 was deliberate or panic
- If the new GAME OVER screen layout reads well in the moment
- Sound design / music feedback (no audio analysis here)

---

## Resolution check (your question)

**2 fps was enough for everything I just wrote.** Frame rate caught:
- Level transition warp text (visible for ~1.5 sec, hits 3 frames at 2 fps) ✓
- Big countdown digits (visible 1 sec each, hits 2 frames per digit) ✓
- Bomb count changes (visible across many frames) ✓
- Score milestones, multiplier peaks ✓
- Backdrop / bg verification ✓

What 2 fps misses:
- Individual bullet patterns frame-by-frame (would need ~10-30 fps)
- Exact moment of player hit / death (lossy ±0.25 sec)
- Quick UI flashes shorter than 0.5 sec

For playtest analysis, **2 fps is the right resolution**. Going to 30 fps would 15x the frames for marginal extra signal. Going down to 1 fps would start missing level transitions.

---

## One concrete observation that's actionable

If a third no-commentary run also dies on level 4, that's a strong signal that level 4 needs a tuning pass. From the overview:
- Run 1: died at level 5 (TLB) — appropriate (TLB is the boss)
- Run 2: died at level 4 — earlier than expected

Worth recording one focused level-4 pass with commentary on what's killing you there.
