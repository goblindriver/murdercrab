# Playtest 2026-05-02 21:06 — Run 1 (12:45)

## Real commentary (filtered from whisper hallucinations)

| Time | Quote | Note |
|---|---|---|
| 00:00 | "Check one." | mic test |
| 02:00 | "Entering stage 2 right now in the cherries reset top" | progress callout |
| 03:00 | "Going to level 3" | progress |
| 04:00 | "Level 4" | progress |
| 04:29 | "This is where the high rank…" (cuts) | rank-system observation |
| 05:19 | "All five, no bombs" / "Level 5, no bombs" | reached level 5 with bombs unused |
| 05:59 | "Oh, we got a high score, we're blinking yellow on the right" | **positive UX feedback** |
| 06:15 | "Level 6, true last boss, this is my first time here" | first TLB encounter |
| 07:46 | "Oh, the bombs have not been…" (cuts) | bomb behavior flag — needs follow-up |
| 11:14 | "Now it's asking me for my input even though it said ACE when I beat the TLB without putting [it in]" | **bug: initial-entry runs after no-input ace finish** |
| 11:47 | "After I beat the game, the backdrop is replaced with whatever level I was on" | **bug: level backdrop persists into post-game UI** |
| 11:58 | "I think you'll find that when I start a new game, on the screen it will say level 5" | **suspected bug: current_level not reset before display** |

## Actionable issues — mapped to cart code

### 1. "PILOT: ACE" on victory screen, then prompted for initials anyway
- Origin: [murdercrab.p8:1723](pico8/murdercrab.p8:1723) — `center_text("pilot: " .. get_initials(), 48, 9)` shows the default initials ("ACE") even when the user never entered them. Then [murdercrab.p8:1788-1792](pico8/murdercrab.p8:1788) sends them to `enter_initials` on `btnp(5)`.
- This is a UX inconsistency, not a strict bug. **Design choice needed** — pick one:
  - A: Drop "PILOT: ___" from the victory screen until after initials entered
  - B: Treat the victory screen "ACE" as the saved name (skip enter_initials if user pressed X)
  - C: Always go to enter_initials with the field pre-filled to "ACE" so the act of entering is unambiguous

### 2. Level backdrop bleeds into title / instructions / enter_initials / victory
- Origin: [murdercrab.p8:322-325](pico8/murdercrab.p8:322) — `draw_starfield()` uses `current_level` unconditionally, but never gets reset before non-game UI is drawn. Frame 145 shows red instructions on red bg (level 5 backdrop).
- One-line fix:
  ```lua
  local cl = (game_state == "game" or game_state == "starting") and min(current_level, max_level) or 1
  ```
  Replaces the existing `local cl = min(current_level, max_level)`.

### 3. Warp animation on new game would show "level 5"
- Origin: [murdercrab.p8:446-454](pico8/murdercrab.p8:446) — `start_game()` sets `game_state = "starting"` but doesn't reset `current_level`. The warp draw at [murdercrab.p8:312](pico8/murdercrab.p8:312) shows `"level " .. current_level` while warping. `init_game()` only resets `current_level = 1` after `warp_time <= 0.3 * warp_duration`, which is mid-warp.
- Fix: add `current_level = 1` to `start_game()` before setting game_state.

## Open questions for next pass

- 07:46 "Oh, the bombs have not been…" — cut off. Did the bomb fail? Did you forget you had bombs? You also said "All 5, no bombs" at 05:19.
- 04:29 "This is where the high rank…" — cut off. Is rank ramping right?

