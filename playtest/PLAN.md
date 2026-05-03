# Polish plan — based on Run 1 + Run 2 playtest assessment

Token-aware, no code changes here. Each item below has the exact line(s) and the proposed change. Sized so we can land them in order, in small commits, when ready.

---

## P0 — Two one-line bug fixes (do these together)

### 1. Reset `current_level` on new game start
**File**: [pico8/murdercrab.p8:446-454](pico8/murdercrab.p8:446)
```lua
function start_game()
  if credits > 0 then
    credits -= 1
    warp_time = warp_duration
    sfx(19, 3)
    update_music("silent")
    game_state = "starting"
  end
end
```
**Add one line**: `current_level = 1` between `credits -= 1` and `warp_time = warp_duration`.

Why this and not `init_game()`: `init_game()` only runs partway through the warp animation (when `warp_time <= warp_duration * 0.3` at line 1757-1758), but the warp text "level X" is drawn during 0.3 < ratio < 0.7 of the warp — i.e. before init_game. So the reset has to happen at the trigger point.

Confirmed visual evidence: 3 instances across runs (LEVEL 5, LEVEL 2, LEVEL 3 warp text on fresh games).

### 2. Gate `draw_starfield` background on game state
**File**: [pico8/murdercrab.p8:322-325](pico8/murdercrab.p8:322)
```lua
local bg_colors = {0, 1, 3, 2, 4}
local cl = min(current_level, max_level)
local bg = bg_colors[cl] or 0
if bg > 0 then rectfill(0, 0, 127, 127, bg) end
```
**Replace** the `local cl = ...` line with:
```lua
local cl = (game_state == "game" or game_state == "starting") and min(current_level, max_level) or 1
```

This makes title / instructions / enter_initials / game_complete always render on the level-1 (black) bg. Gameplay and warp transitions are unaffected.

Confirmed: backdrop bleed in 4+ frames between runs (level 5 brown, level 2 dark blue, level 3 green all observed under non-game UI).

---

## P0 — One design call

### 3. PILOT/initials inconsistency
The mechanic is already partly correct: `update_enter_initials` at [pico8/murdercrab.p8:395-401](pico8/murdercrab.p8:395) pre-fills with `last_entered_initials` (default "ACE"). So the enter-initials screen is already "Option C" (pre-filled, user just confirms or edits).

The friction is that the **victory screen** at [pico8/murdercrab.p8:1723](pico8/murdercrab.p8:1723) prematurely shows `pilot: ACE` before initials are confirmed, which sets the user up to expect the score is already attributed. Then the prompt feels redundant.

**Recommendation**: Option A — drop the line.
```lua
center_text("pilot: " .. get_initials(), 48, 9)  -- remove this line
```
Then shift the lines below up by 10px (score 58 → 48, bonus 68 → 58, final 78 → 68). The enter-initials prompt that follows is the moment of identity; victory screen is the moment of accomplishment. Don't conflate.

Lower-effort alternative if we want to keep the line: change `"pilot: " .. get_initials()` to `"pilot: ???"` so the prompt-to-enter feels like a payoff, not a contradiction. But this is a half-measure.

---

## P1 — Three explicit asks from the user

### 4. Comma formatting on 6+ digit scores (it's actually a `sc()` bug)
**File**: [pico8/murdercrab.p8:213-216](pico8/murdercrab.p8:213)
```lua
function sc(b)
  b = score + (b or 0)
  return {m=0, k=score_hi + flr(b / 1000), u=b % 1000}
end
```

`m=0` is hardcoded, so when `k` overflows past 999 (i.e. score > 999,999), `score_fmt` formats as `"1518,945"` instead of `"1,518,945"`. **Fix**:
```lua
function sc(b)
  b = score + (b or 0)
  local total_k = score_hi + flr(b / 1000)
  return {m = flr(total_k / 1000), k = total_k % 1000, u = b % 1000}
end
```

Single fix, covers in-game HUD ([1674-1675](pico8/murdercrab.p8:1674)), high-score table ([375](pico8/murdercrab.p8:375)), victory screen ([1724, 1726](pico8/murdercrab.p8:1724)), all in one shot. `score_fmt` itself is correct.

### 5. Continue-countdown visibility
**File**: [pico8/murdercrab.p8:1688](pico8/murdercrab.p8:1688)
```lua
center_text(flr(game_over_timer / 60) .. "s", 96, 5)
```

Three problems compounding: small font, dark gray (color 5), no urgency cue. Proposed replacement:
```lua
local secs = flr(game_over_timer / 60)
local col = secs <= 3 and (time() * 4 % 1 < 0.5 and 8 or 10) or 7  -- red/yellow flash <=3s, white otherwise
local s = secs .. "s"
-- 2x scale via spr-style print, or just use big_text helper
local x = 64 - #s * 4  -- 2x of #s * 4 (default char width = 4)
print(s, x, 95, col)
print(s, x+1, 95, col)
print(s, x, 96, col)
print(s, x+1, 96, col)
-- (cheap "bold" — burns 3 extra prints. PICO-8 has no native scale; can also do sspr from a sprite if we want true 2x)
```

Cleaner alternative if the budget allows: add a `big_text(str, x, y, col)` helper that uses `sspr` to draw scaled text. Reusable for other moments.

Token-aware version (just fix color + bold): only do the 4-print bold + flash color. Keeps it 5 lines.

### 6. Sprite padding on instructions screen
**File**: [pico8/murdercrab.p8:384-387](pico8/murdercrab.p8:384)
```lua
local hx = 64 - (#"extra health" * 4) / 2
shadow_text("extra health", 70, 8) spr(6, hx - 12, 68)
shadow_text("extra bomb", 80, 8) spr(5, hx - 12, 78)
shadow_text("increase score", 90, 8) spr(7, hx - 12, 88)
```

Sprite is 8px wide, currently at `hx - 12` (4px gap before text starts at `hx`). User wants more breathing room. **Change `hx - 12` to `hx - 14`** in all three lines (replace_all in the file). Adds 2px of padding.

If we want the icons more prominent and still aligned, could go `hx - 16` (4px gap → 6px gap). 14 is conservative.

---

## P2/P3 — defer

- **Bomb discoverability** — needs another playtest where you intentionally try to bomb. Run 2 didn't add new data here. Hold.
- **Starfield/bullet readability** — my flag, low confidence. Hold until you confirm or notice it.
- **Arcade-mode framing** — design discussion, not in scope for polish. Separate epic.

---

## Suggested commit order

If you want to land in slices:

1. **P0 commit**: warp text reset + backdrop gate + remove pilot line. ~5 line diff total. Kills 3 confirmed bugs at once.
2. **P1a commit**: `sc()` fix for commas. 3-line function rewrite. Easy to review.
3. **P1b commit**: countdown bold/color. Self-contained.
4. **P1c commit**: sprite padding. 3-line replace.

Each commit is independently verifiable — record a fresh run between each and the pipeline will tell us whether the issue is gone.

---

## What we don't have yet

- Did you use bombs in run 2? I didn't watch the gameplay frames densely enough to verify.
- Whether the warp-color-flash visual is too similar to a bomb's visual — needs a frame-by-frame comparison once a bomb is actually used.
- Whether the rank ramp at level 4 was the source of your trail-off "this is where the high rank and…" comment in run 1.

These need either targeted re-records or denser visual review. Not worth burning tokens on now.
