# MURDERCRAB!
## PILOT MANUAL

> **8-bit shell. 16-bit attitude. Arcade doctrine.**

---

## CONTENTS

1. Warning to New Pilots
2. What *MurderCrab* Is
3. How the Cabinet Works
4. Basic Controls
5. HUD Readout
6. Core Combat Systems
7. Resources
8. Enemy Field Guide
9. Stage Guide
10. Boss Doctrine
11. Score Attack
12. Credits and Continues
13. High Scores
14. Technical Reference
15. Cart Budget

---

# 1. WARNING TO NEW PILOTS

This is an arcade shooter.

Your first objective is simple: **stay alive long enough to understand the stage.**

Your second objective is more important: **learn why the stage is built the way it is.**

Your third objective is where the good stuff starts: **turn survival into authority.**

Clearing proves you can live. A route proves you can drive.

---

# 2. WHAT *MURDERCRAB* IS

**MurderCrab!** is a vertically scrolling arcade shooter built for PICO-8. Five stages of escalating swarm density, two bosses per level, a true last boss gated behind skilled play, and a new game plus loop for pilots who want to push further. The **feel** is quarter-muncher: credits, continues, a top-3 board, and no campaign unlocks -- even though you pick options from a menu between the title and play.

The game runs at 128x128 resolution with 16 colors, 8x8 base sprites, and a single combined cartridge. Built within PICO-8's 8,192-token and 32KB cart constraints.

> Humanity did not find peace in the void.
> It found armored claws, chitin cathedrals, and wave after wave of shell-born murder.
> Launch. Learn the lanes. Burn through the swarm.

---

# 3. HOW THE CABINET WORKS

This is an arcade shooter. Think in quarters.

## What you actually see (current build)

**Title screen.** Logo, scrolling starfield, a big crab boss tease, and "press any button." Credits reset to **3** every time you land here.

**Main menu.** Four options: start game, enter initials, instructions, high scores. Your remaining credits show at the bottom. **Start game** costs 1 credit and launches the warp into level 1.

**During play.** When you die, **game over** appears with **Z to continue** (if you have credits) or **X for menu**. A **10-second** countdown runs; if it hits zero, you go to the menu. Continuing costs 1 credit, gives you **3 HP**, and **resets your multiplier and streak**. Any continue **locks out** the true last boss for that run.

**High scores.** Your score (including the end-of-run bonus) is checked **as soon as game over begins**. If you rank in the **top 3**, the board updates using whatever **3-character initials** you have saved (defaults start as **ACE** until you change them under **enter initials** on the menu). There is **no** separate "you made the board, type your name now" moment after death -- set your tag **before** the run if you care.

**After a run.** You return to the **menu** (not straight back to the title). From there you can start again, read instructions, or quit to the title with **X**.

**Victory / NG+.** After the true last boss, **Z** starts the next loop on the same "life" of the run; **X** exits to the menu.

## The mental model (one sentence)

You get **3 credits** per visit to the title screen: **1** to start, up to **2** more if you want harsh continues. No real-money quarters -- but the rhythm is "short runs, cheap retries, chase the board."

---

# 4. BASIC CONTROLS

| Input | Action |
|-------|--------|
| Arrow keys / D-pad | Move ship |
| Z (button 4) | Shoot |
| X (button 5) | Bomb |

**Movement** is digital at 2 pixels per frame in all four directions. No inertia, no acceleration. Diagonals move at full speed on both axes.

**Shoot** fires twin bullets from either side of the ship. Each press fires one volley. There is no auto-fire -- you tap for each shot. Bullets travel upward at 6 pixels per frame.

**Bomb** is your panic button and your tactical tool. Details in section 6.

There is no focus mode, no secondary fire, and no charge mechanic. Three inputs. That's the whole cockpit.

---

# 5. HUD READOUT

The HUD displays during gameplay along the top and left edges of the screen:

```
SCORE: 1,240          HI: 5,680
HEALTH: 97
BOMBS: 3
LEVEL: 2
x3 (7/10)
```

| Element | Location | Details |
|---------|----------|---------|
| **Score** | Top left | Current score, comma-formatted for large values |
| **Hi-Score** | Top right | Best score from the high score table. Flashes gold/orange when your current score beats it |
| **Health** | Below score | Current HP. Flashes red when at 2 or below |
| **Bombs** | Below health | Remaining bomb stock |
| **Level** | Below bombs | Current level number. Shows "3-2" format in NG+ (level 3, loop 2) |
| **Multiplier** | Below level | Current multiplier and streak progress toward next increase (e.g. "x3 (7/10)") |

### Boss warning

When a boss is about to spawn, **"! WARNING !"** flashes at center screen for 3 seconds (90 frames), alternating red and yellow.

### Game over overlay

When health reaches zero, **game over** appears mid-screen. After a short grace period: **Z** continues (costs 1 credit, only if credits remain), **X** sends you to the **menu**. The overlay shows **credits** left and a **countdown in seconds** so you are not guessing. **Z: continue** only appears when you have at least one credit. A **10-second** countdown runs in the background; if it expires, you go to the menu automatically.

---

# 6. CORE COMBAT SYSTEMS

## 6.1 Movement

The ship moves at a fixed 2 pixels per frame. The player hitbox for enemy bullet collisions is a tight 2x2 pixel box centered on the ship sprite -- much smaller than the visual 8x8 sprite. This means you can thread through gaps that look impossible.

For kamikaze enemy collisions, the check uses the full ship sprite bounding box.

The ship tilts left or right while strafing and displays a small exhaust thrust animation while moving in any direction.

## 6.2 Shot

Each press of Z fires two bullets simultaneously, offset to the left and right of the ship's center. Bullets are 8x8 sprites with a 5-frame looping animation. They travel straight up at 6 pixels per frame and despawn when they leave the top of the screen.

There is no weapon power system. Your gun is the same from the first second to the last.

## 6.3 Bomb

Press X to detonate a bomb. Requirements: at least 1 bomb in stock, and no bomb currently active.

**What the bomb does:**
- Clears **all enemy bullets** from the screen instantly
- Clears **all player bullets** from the screen
- Deals **30 damage** to every boss-type enemy on screen
- Instantly kills all normal enemies on screen (they have 1 HP on loop 1)
- Grants a brief period of screen control with visual flash and expanding shockwave
- Creates 3 expanding explosion rings centered on the player
- Triggers heavy screen shake (20 frames)

**Bomb duration:** 30 frames (1 second at 30fps). During this time, the bomb is "active" and you cannot fire another.

**Bomb effect:** An additional 30-frame visual effect follows -- a white screen flash, contracting circle, and secondary shake pulses.

Bombs are not an apology. They are a conversion mechanic. Use them before death, not after regret.

## 6.4 Invincibility

When hit, the player becomes invincible for 30 frames (1 second). The ship flickers during this window. Use it to reposition.

---

# 7. RESOURCES

## Health

- **Starting HP:** 100
- **Damage per hit:** 1 (from enemy bullets or enemy contact)
- **Health pickup:** restores 1 HP
- **No maximum cap** -- health can exceed 100 through pickups

100 HP is generous. You can absorb many hits before dying. But multiplier resets on every hit, so taking damage is expensive even when it isn't lethal.

## Bombs

- **Starting stock:** 3
- **Bomb pickup:** adds 1 bomb
- **No maximum cap**

## Credits

- **Starting credits:** 3
- **Cost to start:** 1 credit
- **Continue cost:** 1 credit
- **Continue restores:** 3 HP

Continuing is harsh by design. You get 3 more hits, not a fresh start. It's enough to see what's ahead, not enough to coast.

**Important:** using any continues locks you out of the true last boss. A no-continue clear is required to reach level 6.

## Powerups

Defeated normal enemies have a **90% chance** to spawn a powerup burst: 2-4 cherry (score) pickups that scatter outward, plus a **5% chance** of an additional bomb or health pickup.

| Powerup | Sprite | Effect |
|---------|--------|--------|
| Cherry | 7 | +100 points (x multiplier), +1 streak progress |
| Health | 6 | +1 HP |
| Bomb | 5 | +1 bomb |

Cherries have a **30-frame lifespan** and will expire with a small flash if not collected. They blink when about to expire (last 15 frames).

All powerups are attracted toward the player when within 48 pixels. They drift toward you -- you don't have to fly directly over them.

---

# 8. ENEMY FIELD GUIDE

## Normal enemies

One core enemy type with two weapon variants and three behavior states.

### Behavior states

**State 0 -- Entry:** Enemy spawns above the screen and descends toward a randomized hover point (y = 20-35). Drifts slightly left or right during descent. Already firing during this state.

**State 1 -- Hover:** Enemy patrols horizontally, bouncing off screen edges. Fires at the player. After a 45-frame timer expires, transitions to kamikaze.

**State 2 -- Kamikaze:** Enemy locks onto the player's position and dives at double speed. Sprite changes to the dive sprite. If it misses, it flies off-screen and despawns.

### Weapon variants (50/50 chance)

**Shotgun:** Fires 3 bullets in a spread pattern aimed at the player. Bullet speed 4.5 px/frame, spread angle 10 degrees.

**Burst:** Fires 3 rapid aimed shots in sequence with a 3-frame delay between each. Bullet speed 5 px/frame.

### Scaling

| Property | Base (Level 1) | Per level | Per NG+ loop |
|----------|----------------|-----------|--------------|
| Speed | 2.0 | +0.4 | +0.3 |
| Max speed | 3.5 | -- | +0.5 |
| Shoot interval | 60 frames | -4 | -6 to -8 |
| Min shoot interval | 40 frames | -- | decreases further |
| HP | 1 | -- | +1 per loop |
| Spawn count | 1 | 2 at level 4+ | -- |
| Spawn delay | 75 frames | -6 | -5 |

## Bosses

See section 10 for full boss doctrine.

---

# 9. STAGE GUIDE

## Progression structure

Each of the 5 levels follows the same structure:

1. **Normal phase (pre-mini-boss):** Kill enemies to reach the mini-boss threshold
2. **Boss warning:** 3-second flashing warning
3. **Mini-boss fight**
4. **Normal phase (post-mini-boss):** Kill more enemies to reach the final boss threshold
5. **Boss warning**
6. **Final boss fight**
7. **Level complete:** Cinematic explosion sequence, then warp to next level

### Kill thresholds

| Level | Mini-boss threshold | Final boss threshold |
|-------|-------------------|---------------------|
| 1 | 8 kills | 12 kills |
| 2 | 12 kills | 15 kills |
| 3 | 16 kills | 18 kills |
| 4 | 20 kills | 21 kills |
| 5 | 24 kills | 24 kills |

Kill count resets after each boss defeat.

### Boss count per level

| Level | Mini-bosses | Final bosses |
|-------|-------------|-------------|
| 1 | 1 | 1 |
| 2-5 | 2 | 2 |

## Stage aesthetics

Each level has a distinct starfield that communicates depth and escalation:

| Level | Background | Star colors | Density | Feel |
|-------|-----------|-------------|---------|------|
| 1 | Black | White | 90 stars | Clean void. Training ground. |
| 2 | Dark blue | White, light blue, blue-grey | 100 stars | Deeper space. Colder. |
| 3 | Dark green | White, green, dark green | 110 stars | Biological territory. Something alive out here. |
| 4 | Dark purple | White, blue-grey, pink, dark blue | 120 stars | Approaching the hive. Colors shifting. |
| 5 | Dark red | White, yellow, blue-grey, light blue | 130 stars | The core. Everything is wrong. |
| 6 (TLB) | Shifting | All colors | 150 stars | Hyperspace. Reality breaking. |

Star scroll speed increases with level. Stars twinkle more aggressively in later levels.

## Warp transition

Between levels, a 6-second warp sequence plays: stars streak into lines, the screen flashes, and the level number displays mid-transition. During warp, the player's position resets to center and all bullets are cleared.

---

# 10. BOSS DOCTRINE

Bosses in *MurderCrab* are exams, not spectacles.

## Mini-boss

- **Sprite:** 2x2 tile (16x16 pixels)
- **Base HP:** 60 (+5 per level, x1.5 per NG+ loop)
- **Phases:** 2 (transition at 50% HP)
- **Shoot interval:** 30 frames (decreases per phase)
- **Score:** 50 points
- **Movement:** Enters from top, strafes horizontally within a 60-pixel range centered on screen

### Level 1 HP reference

| Loop | Mini-boss HP |
|------|-------------|
| 1 | 60 |
| 2 | 90 |
| 3 | 120 |

## Final boss

- **Sprite:** 2x2 tile (16x16 pixels), palette-shifted to distinguish from mini-boss
- **Base HP:** 100 (+5 per level, x1.5 per NG+ loop)
- **Phases:** 3 (transitions at 66% and 33% HP)
- **Shoot interval:** 12 frames (decreases per phase)
- **Score:** 100 points
- **Movement:** Enters from top, strafes horizontally (slower than mini-boss, dx=0.3 vs 0.5)

### Level 1 HP reference

| Loop | Final boss HP |
|------|--------------|
| 1 | 100 |
| 2 | 150 |
| 3 | 200 |

## True last boss

- **Sprite:** 4x4 tile (32x32 pixels)
- **Condition:** Beat all 5 levels without using any continues
- **Base HP:** 450 (x1.5 per NG+ loop)
- **Phases:** 3 (transitions at 66% and 33% HP)
- **Rage mode:** Activates at phase 3. Visual aura appears, +10 bullets added to every pattern
- **Shoot interval:** 10 frames (decreases per phase, minimum 3)
- **Score:** 50 points
- **Movement:** Strafes horizontally

## Boss attack patterns

All bosses share the same pattern system, cycling between three attack types:

**Spiral:** Bullets spawn in a rotating spiral. Count scales with level and boss damage. Wobbles slightly with a sine offset for unpredictability.

**Radial burst:** Bullets fire in an even radial spread from the boss center. Clean geometric pattern that demands positioning.

**Aimed burst:** 3-shot aimed burst directly at the player. Fast and precise. Tests streaming ability.

Pattern selection rotates based on game time and boss phase. Higher phases cycle faster and unlock all three pattern types (phase 1 only uses spiral and radial).

Bullet speed scales with level (+0.15 per level) and boss damage state (+0.3 at low HP). More damaged bosses shoot faster bullets in denser patterns.

## Boss defeat

When the last boss of a type is destroyed:
- All enemy bullets convert to small explosions (visual reward + safety)
- Cinematic explosion chain at the boss position
- Heavy screen shake
- Music fades out

For the final boss, a 90-frame (3 second) explosion celebration plays with periodic secondary detonations before the level warp begins.

---

# 11. SCORE ATTACK

## Point values

| Source | Base value | Notes |
|--------|-----------|-------|
| Normal enemy kill | 10 | Multiplied by current multiplier |
| Cherry pickup | 100 | Multiplied by current multiplier |
| Mini-boss kill | 50 | Multiplied by current multiplier |
| Final boss kill | 100 | Multiplied by current multiplier |
| TLB kill | 50 | Multiplied by current multiplier |

## Multiplier system

The multiplier starts at x1 and increases through cherry collection:

1. Kill enemies. They drop 2-4 cherries on death (90% chance).
2. Collect cherries to build streak. Each cherry = +1 streak.
3. Every **10 cherries** collected increases the multiplier by 1.
4. **Getting hit resets both multiplier and streak to zero.**

The multiplier applies to all point sources: kills, pickups, and boss defeats.

### Multiplier strategy

The multiplier is the entire scoring game. A x5 multiplier means every kill is worth 50 instead of 10. Every cherry is worth 500 instead of 100.

**The cost of getting hit is not the 1 HP you lose. It's the multiplier you drop.**

Playing for score means playing for streaks. That means positioning to collect cherries efficiently, avoiding damage above all else, and using bombs proactively to protect the multiplier rather than reactively to survive.

## End-of-game bonus

When the game ends (victory or game over), a bonus is calculated:

```
bonus = (remaining bombs x 25) + (remaining health x 25)
```

On a clean loop 1 clear with 100 HP and 3 bombs remaining, that's a 2,575 point bonus. Every bomb you don't use and every hit you don't take pays off at the end.

## High score persistence

The game stores the top 3 high scores with 3-character initials using PICO-8's cartdata system. Scores are stored in component form (millions / thousands / units) across 6 cartdata slots per entry to handle large values. Your initials are also persisted between sessions.

---

# 12. CREDITS AND CONTINUES

## Credits

You get 3 credits per session. Think of them as quarters.

Choosing **start game** from the menu costs 1 credit. Credits reset to **3** every time you return to the **title** screen (from the menu).

## Continuing

When you die:
- A 10-second timer (300 frames) begins counting down
- After a brief grace period, press Z to continue (costs 1 credit) or X to end the run
- Continuing restores 3 HP and resets your multiplier and streak
- If the timer expires, the run ends automatically

Continuing is harsh by design. You get 3 more hits, not a fresh start. Enough to see what's ahead, not enough to coast.

## True ending condition

The true last boss only appears if you used zero continues. Any continue disqualifies you. After beating level 5's final boss without continuing, you warp to level 6 for the TLB encounter.

If you used continues, level 5's final boss defeat goes directly to the game complete screen.

## New Game Plus

After defeating the TLB, press Z to enter the next loop. This is not a new game -- it's the game continuing on the same credit. Score carries over. HP and bombs carry over. Enemies get harder.

NG+ scaling per loop:
- Enemy HP: +1 per loop
- Enemy speed: +0.3 base, +0.5 max
- Enemy shoot interval: reduced by 6-8 frames
- Spawn delay: reduced by 5 frames
- Boss HP: x1.5 per loop
- Boss bullet clusters: +1 per level (additive with base scaling)

During an NG+ chain you keep playing until you die or exit from the victory screen. When you are out of credits on game over, the timer eventually returns you to the menu.

---

# 13. HIGH SCORES

## The board

The high score table holds **3** entries. View them anytime from **high scores** on the main menu.

## Entering initials

From the menu, choose **enter initials** to set your **3-character** tag. Up/down changes the character (printable ASCII, codes 33-126), left/right moves between positions, **Z** confirms, **X** cancels.

Your initials are **saved** and used automatically whenever your run qualifies for the board. They persist between sessions. If you never change them, defaults apply until you do.

**Tip for first-timers:** Set your initials **before** a serious run so the leaderboard shows *you*, not the default.

## When scores are recorded

The game computes **final score** (current score + end bonus) and updates the table at:
- **Game over** -- checked on the first frame of the countdown
- **True last boss defeat** (victory path)

If you qualify for top 3, your **saved** initials are written with that score. You then continue from **menu** or **title** as usual -- there is no mandatory name-entry screen after death in the current build.

---

# 14. TECHNICAL REFERENCE

## Frame rate

The game runs at PICO-8's default 30fps using `_update()` (not `_update60()`).

## Hitboxes

| Entity | Hitbox size | Notes |
|--------|------------|-------|
| Player (vs bullets) | 2x2 px | Centered on 8x8 sprite. Tight. |
| Player (vs kamikazes) | 8x8 px | Full sprite bounding box |
| Player bullets | 8x8 px | Full sprite |
| Enemy bullets | 8x8 px | Full sprite |
| Normal enemies | 8x8 px | Full sprite |
| Mini/final boss | 16x16 px | 2x2 tile sprite |
| True last boss | 32x32 px | 4x4 tile sprite |
| Powerups | 8x8 px | Full sprite |

## Object pools

Player bullets and enemy bullets use object pooling for memory efficiency. Killed bullets return to the pool for reuse rather than being garbage collected.

## Music layout

| Patterns | Usage |
|----------|-------|
| 0-5 | Title / menu |
| 6-9 | Gameplay |
| 10-13 | Boss |
| 14-17 | Additional tracks |

## Cartdata slots

| Slots | Usage |
|-------|-------|
| 0-17 | High score table (6 slots per entry x 3 entries) |
| 18-20 | Saved initials (ASCII codes) |
| 21-63 | Free |

---

# 15. CART BUDGET

How MurderCrab fits on the PICO-8 cartridge.

## Platform limits

| Resource | Limit |
|----------|-------|
| Code | 8,192 tokens |
| Compressed code | 15,360 bytes (for .p8.png export) |
| Total cart | 32 KB |
| Sprites | 256 (128 + 128 shared with map) |
| Map | 128x32 tiles (+ 128x32 shared with sprites) |
| SFX | 64 slots |
| Music | 64 patterns |
| Persistent storage | 64 numbers (256 bytes) |
| Display | 128x128, 16 fixed colors |
| CPU | 4M VM instructions/sec |
| Frame rate | 30fps (using `_update`) |

## Current usage

| Resource | Used | Headroom |
|----------|------|----------|
| Lua code | ~1,951 lines, 86 functions | Moderate (within 8,192 token limit) |
| Sprites | 6 of 16 rows populated (~37%) | Significant |
| SFX | 27 of 64 | 37 free |
| Music | 18 of 64 patterns | 46 free |
| Cartdata | 21 of 64 slots | 43 free |
| Map | Unused | Fully available |

## Cartdata allocation

| Slots | Usage |
|-------|-------|
| 0-17 | High scores (6 per entry x 3 entries) |
| 18-20 | Saved initials (3 ASCII codes) |
| 21-63 | Free (43 slots) |

## Sprite allocation

| Sprite(s) | Usage |
|-----------|-------|
| 1, 17, 33 | Player ship (center, left-tilt, right-tilt) |
| 2, 18, 34, 50 | Player bullet (4-frame animation) |
| 3, 19 | Enemy (normal, animated) |
| 35 | Enemy (kamikaze) |
| 4 | Enemy bullet |
| 5, 6, 7 | Powerups (bomb, health, cherry) |
| 8 (2x2) | Mini-boss / Final boss |
| 10 (4x4) | True last boss |
| 48+ | Explosions |

---

> **THE SWARM IS LEARNING. SO ARE YOU.**
> Route five stages of shell-born violence. Cash power. Spend bombs before regret.
> Push for the clear, then come back for the score.
