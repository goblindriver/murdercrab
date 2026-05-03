# Playtest report — Run 2 (2026-05-02 23:48, 8:53)

Pipeline ran clean — Track-2 mic isolation worked, demucs skipped, transcript is high-signal with almost zero hallucinations.

## What you flagged (in order)

| Time | Frame | Issue | Status |
|---|---|---|---|
| 0:15 | 31 | Cherry sprite needs more padding on instructions screen | **NEW** — visible in frame: cherry icon flush against "INCREASE SCORE" text, same for heart and bolt icons against their labels |
| 0:15–0:28 | — | Score numbers over 6 figures need commas | **NEW** — design call, applies to in-game HUD and high-score table |
| 1:08 | 137 | "Just entered top rank, my bullets are red" | **CONFIRMED** — frame 145 shows player firing red vertical streaks. This is the rank-tinted bullets feature working. You called it out as observation, not complaint. |
| 2:25 | 295 | Backdrop bleed after death — title screen on dark blue (level 2) bg | **CONFIRMED AGAIN** — same bug as run 1 |
| 2:38 | — | Cherry padding issue (mentioned again on instructions screen) | duplicate of 0:15 |
| 2:52 | — | Need commas on high-score screens | duplicate of 0:15 |
| 3:02 | 365 | "Text is wrong, said level 2" on fresh game | **CONFIRMED ON TAPE** — frame 365 shows `LEVEL 2` warp text on the new-game start (your previous game ended on level 2) |
| 6:05 | 731 | "Countdown should be pretty big" — got sent back, didn't notice continue countdown in time | **CONFIRMED** — frame 731 shows `55` in tiny dark-gray text under "CREDITS 2". At [murdercrab.p8:1688](pico8/murdercrab.p8:1688) — `center_text(flr(game_over_timer / 60) .. "s", 96, 5)` — small font, color 5 (dark gray), no scaling |
| 6:21 | — | Need to show inserted credits — for arcade context, "how many credits you put in" | **NEW** — design discussion, you noted "we currently don't have a credit system" |
| 6:44 | 811 | "Says level 3, restarting and it's actually level 1, same bug" | **CONFIRMED** — frame 811 shows `LEVEL 3` warp text on a new-game start |

That's **3 confirmed instances of the level-text bug** now (run 1: LEVEL 5; run 2: LEVEL 2 + LEVEL 3). Same root cause, three observations.

## New issues this run

### 1. Cherry/heart/bolt sprite padding on instructions screen
Frame 31 (0:15) — sprites are flush against their labels. Looking at [murdercrab.p8:385-387](pico8/murdercrab.p8:385):

```lua
shadow_text("extra health", 70, 8) spr(6, hx - 12, 68)
shadow_text("extra bomb", 80, 8) spr(5, hx - 12, 78)
shadow_text("increase score", 90, 8) spr(7, hx - 12, 88)
```

The sprite x position is `hx - 12` where `hx = 64 - (#"extra health" * 4) / 2`. Hardcoded `hx - 12` for all three rows means the gap is fixed and tight. Easy fix: `hx - 14` or `hx - 16` for more breathing room.

### 2. Number formatting — commas at 6+ digits
You mentioned this for both in-game score and high-score table. The cart has a `score_fmt()` function. Quick search:

```
375: shadow_text(i .. ". " .. e.initials .. " " .. score_fmt(e.score), y, 8)
1724: center_text("score: " .. score_fmt(sc()), 58, 7)
```

`score_fmt()` is the chokepoint — adding comma separators there fixes both surfaces at once. (Score is stored as `{m=, k=, u=}` triple — million/thousand/unit — so the function already knows the magnitude.)

### 3. Continue-countdown visibility
At [murdercrab.p8:1688](pico8/murdercrab.p8:1688):

```lua
center_text(flr(game_over_timer / 60) .. "s", 96, 5)
```

Three problems all at once:
- Color 5 (dark gray) on a level-tinted bg = low contrast
- Default 4×6 font is tiny relative to "GAME OVER" text above it
- Just "5s" / "4s" / "3s" — no visual urgency cue

The countdown is the "you're about to lose your run" warning and it currently looks like an afterthought. Suggest: bigger font (PICO-8 has a 2x text trick: `print(s, x, y, c)` then redraw bigger via `pset` loop, or just use larger sprite-based digits), warmer color (8 = red, especially in last 3 sec), maybe a shake/pulse.

### 4. Arcade-mode framing (design discussion)
You said: "if this is going to be an actual arcade game, it's going to need to say how many credits you put in. We currently don't have a credit system. So if this was to be an actual arcade, that would be difficult."

This is a scope question, not a bug. The cart already has `credits` and `credits_used` semantics; what's missing is the arcade UX wrapper around them — title screen "INSERT COIN", credit count visible at all times, etc. Worth a separate design pass if arcade is a real target.

## Recurring confirmed issues (carrying over from run 1)

- **Backdrop bleed** — confirmed on level-2 bg this time (frame 295)
- **Level-text bug on new game** — confirmed twice (LEVEL 2 at frame 365, LEVEL 3 at frame 811)

These two are the same root cause: state not reset before non-game UI is drawn. The two one-line fixes from run 1 still apply and now have **5 visual instances** between the two runs.

## What's working (unchanged from run 1)

- Score readability — yellow blink on high-score crossover still landed (you didn't have to call it out this run, which means it just works)
- Cherry chain — x10 reached at 1:12, still satisfying
- Top-rank bullet color — you noticed it neutrally, the visual rank communication is doing its job

## Run shape

- 0:00–0:35 — title cycle, called out instructions polish
- 0:35–2:25 — first game, died fast (score plateau ~50k from frame data)
- 2:25–3:00 — quit to title, called out backdrop bleed; restarted
- 3:00–6:00 — second game, made it through level 2 to level 3 (score 478k)
- 6:00–6:30 — game over on level 3, missed the continue countdown
- 6:30–6:50 — restarted, called out the "level 3" bug
- 6:50–8:30 — third game, died again (transcript: "got wrecked again")
- 8:30 — quit to title

## Suggested polish queue (from runs 1+2 combined)

| Priority | Item | Effort | Confidence |
|---|---|---|---|
| P0 | Reset `current_level` in `start_game()` (kills LEVEL N warp text bug) | 1 line | high — 3 confirmed |
| P0 | Gate `draw_starfield` bg on game_state (kills backdrop bleed) | 1 line | high — multiple confirmed |
| P0 | Resolve PILOT/initials inconsistency (pick A/B/C from run 1 report) | small | medium |
| P1 | Bigger / warmer countdown text on GAME OVER | small | high — explicit ask |
| P1 | Add commas to `score_fmt()` for 6+ digit numbers | small | high — explicit ask |
| P1 | Add padding to instructions sprite layout | small | high — explicit ask |
| P2 | Bomb discoverability (run 1 finding — still 0 bombs used in run 2 too?) | medium | medium |
| P2 | Starfield/bullet readability (my flag) | medium | low |
| P3 | Arcade-mode framing (credits display) | larger | scope question |

## Pipeline performance

- Run 1 (single track + demucs): ~13 min total processing
- Run 2 (Track 2 mic-only): ~2 min total processing
- The script ([playtest/process.sh](playtest/process.sh)) is now the right shape for fast iteration. Drop the next .mp4 in and run it.
