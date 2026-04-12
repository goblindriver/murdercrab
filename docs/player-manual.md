# MURDERCRAB!

## Player's Manual

> **8-bit shell. 16-bit attitude. Arcade doctrine.**

---

## Contents

1. Warning to New Pilots
2. What MurderCrab Is
3. Mission Brief
4. How the Cabinet Works
5. Basic Controls
6. HUD Readout
7. Core Combat Systems
8. Resources
9. The Rank System
10. Enemy Field Guide
11. Stage Guide
12. Boss Doctrine
13. Score Attack
14. Credits and Continues
15. High Scores
16. Glossary

---

# 1. WARNING TO NEW PILOTS

This is an arcade shooter.

Your first objective is simple: **stay alive long enough to understand the stage.**

Your second objective is more important: **learn why the stage is built the way it is.**

Your third objective is where the good stuff starts: **turn survival into authority.**

Clearing proves you can live. A route proves you can drive.

---

# 2. WHAT MURDERCRAB IS

**MurderCrab!** is a vertically scrolling arcade shooter built for PICO-8. Five stages of escalating swarm density, two bosses per level, a true last boss gated behind skilled play, and a new game plus loop for pilots who want to push further.

The feel is quarter-muncher: credits, continues, a top-3 board, and no campaign unlocks. You walk up, press a button, and play until you die.

The game runs at 128x128 resolution, 16 colors, 60 frames per second, with 8x8 base sprites on a single combined cartridge.

---

# 3. MISSION BRIEF

**The outer shells have opened.** At the edge of charted space, broken stations became nesting ground for a mechanized crab-host: waves, cruel geometries, strongholds that molt and harden. One compact craft answers -- **MURDERCRAB** -- enough output and a pilot mad enough to fly it into the choke.

**Field note.** The enemy does not advance like an army. It spreads like a bad idea.

---

# 4. HOW THE CABINET WORKS

Think in quarters.

**Title screen.** The attract mode cycles three phases every 6 seconds: the logo with a big crab boss tease, the high score table, and a controls/powerup instructions page. A starfield scrolls behind everything. Credits reset to **3** every time you land here.

**Starting the game.** Press any button. This costs 1 credit and launches a warp sequence into level 1. There is no menu -- you press start, you play.

**During play.** When you die, **GAME OVER** appears with a **10-second** countdown. After a brief grace period: **Z to continue** (costs 1 credit, if you have any) or **X to quit**. Continuing gives you **3 HP** and resets your multiplier and streak. Any continue **locks you out** of the true last boss for that run. If the timer expires, the run ends automatically.

**After a run.** If your final score places in the **top 3**, you are taken to the **enter initials** screen. Otherwise you return to the title. There is no menu between death and the next attract cycle.

**Victory / NG+.** After the true last boss, a results screen shows your score, bonus, and final total. **Z** starts the next loop on the same credit. **X** exits to enter initials (if you qualify) or the title.

**The mental model.** You get **3 credits** per visit to the title screen: **1** to start, up to **2** more as harsh continues. No real-money quarters -- but the rhythm is short runs, cheap retries, chase the board.

---

# 5. BASIC CONTROLS

| Input              | Action    |
| ------------------ | --------- |
| Arrow keys / D-pad | Move ship |
| Z (button 4)       | Shoot     |
| X (button 5)       | Bomb      |

**Movement** is digital at 1 pixel per frame (60 pixels per second) in all four directions. No inertia, no acceleration. Diagonals move at full speed on both axes.

**Shoot** fires twin bullets from either side of the ship. **Hold Z for rapid fire** -- the game fires approximately 7.5 volleys per second while held. You can also tap for single bursts.

**Bomb** is your panic button and your tactical tool. Details in section 7.

There is no focus mode, no secondary fire, and no charge mechanic. Three inputs. That's the whole cockpit.

---

# 6. HUD READOUT

```
1,240              5,680
[cherry]x3
[heart][heart][heart]          [bomb][bomb][bomb]
```

| Element        | Location      | Details                                                                                       |
| -------------- | ------------- | --------------------------------------------------------------------------------------------- |
| **Score**      | Top left      | Current score, comma-formatted                                                                |
| **Hi-Score**   | Top right     | Best score from the high score table. Flashes gold/orange when your current score beats it    |
| **Multiplier** | Below score   | Cherry icon + current multiplier (e.g. "x3")                                                  |
| **Health**     | Bottom left   | Ship icons, one per HP (shows up to 10)                                                       |
| **Bombs**      | Bottom right  | Bomb icons, one per bomb in stock                                                             |

### Boss warning

When a boss is about to spawn, **"! WARNING !"** flashes at center screen for 3 seconds, alternating red and yellow.

### Game over overlay

When health reaches zero, **GAME OVER** appears mid-screen with a bobbing sine wave. After a 1-second grace period: **Z: continue** (only if credits remain), **X: quit**. The overlay shows remaining **credits** and a **countdown in seconds**.

---

# 7. CORE COMBAT SYSTEMS

## 7.1 Movement

The ship moves at a fixed 1 pixel per frame. The player hitbox for enemy bullet collisions is a tight **2x2 pixel box** centered on the 8x8 ship sprite -- much smaller than the visual sprite. This means you can thread through gaps that look impossible.

For **kamikaze** (dive) collisions, the game uses **full 8x8 ship bounds vs full enemy body** -- rams are not the same puzzle as bullet threading.

The ship tilts left or right while strafing and shows a small exhaust thrust animation while moving.

## 7.2 Shot

Each volley spawns two bullets simultaneously, offset left and right of the ship's center. Bullets are 8x8 sprites with a 4-frame looping animation. They travel straight up at 3 pixels per frame and despawn off the top of the screen. Fire rate is approximately 7.5 volleys per second.

**At higher rank, your shots deal more damage.** See section 9 for details.

## 7.3 Bomb

Press X to detonate a bomb. Requirements: at least 1 bomb in stock, no bomb currently active.

**What the bomb does:**

- Clears **all enemy bullets** from the screen instantly
- Clears **all player bullets** from the screen
- Deals **30 damage** to every boss-type enemy on screen
- Kills all normal enemies on screen
- Creates expanding explosion rings centered on the player
- Triggers heavy screen shake

**Bomb duration:** 1 second. During this time, no other bomb can be fired.

**Bomb visual effect:** An additional 1-second effect follows -- contracting circle and secondary shake pulses.

Bombs are not an apology. They are a conversion mechanic. Use them before death, not after regret.

## 7.4 Invincibility

When hit, the player becomes invincible for 1 second. The ship flickers during this window. Use it to reposition.

---

# 8. RESOURCES

## Health

- **Starting HP:** 3
- **Damage per hit:** 1 (from enemy bullets or enemy contact)
- **Health pickup:** restores 1 HP
- **No maximum cap** -- health can exceed 3 through pickups

3 HP is tight. Every hit matters. But multiplier also resets on every hit, so taking damage is expensive even when it isn't lethal.

## Bombs

- **Starting stock:** 3
- **Bomb pickup:** adds 1 bomb
- **No maximum cap**

## Powerups

Defeated normal enemies have a **90% chance** to spawn a powerup burst: 4-8 cherry (score) pickups that scatter outward in a ring. There is an additional **5% chance** of a bomb or health pickup in the burst.

At **rank 2 and above**, kills have a bonus chance to drop an extra cherry. Higher rank means more bonus drops. See section 9.

| Powerup | Effect                                          |
| ------- | ----------------------------------------------- |
| Cherry  | +100 points (x multiplier), +1 streak progress |
| Health  | +1 HP                                           |
| Bomb    | +1 bomb                                         |

Cherries have a **1.5-second lifespan** and blink when about to expire (last 0.5 seconds). All powerups are attracted toward the player when within **48 pixels**. They drift toward you -- you don't have to fly directly over them.

---

# 9. THE RANK SYSTEM

Rank is MurderCrab's core risk/reward system. It makes you stronger and the game harder at the same time. Rank runs from **0 to 10**.

## How rank works

**Rank rises** by tracking your score multiplier. As your multiplier climbs through cherry collection, rank follows -- but rank is **sticky**. It only goes up to match your multiplier, never down from multiplier changes.

**Rank falls** only when you get hit: **-1 rank per hit**, minimum 0.

**Rank resets** to 0 at the start of each new game. It **persists between levels** and through continues.

## What rank does to you (rewards)

| Rank tier | Weapon damage | Visual                                      |
| --------- | ------------- | ------------------------------------------- |
| 0-2       | 1 per hit     | Normal ship                                 |
| 3-5       | 2 per hit     | Ship tints yellow-green, bullet trails      |
| 6+        | 3 per hit     | Ship tints red-orange, longer bullet trails  |

- **Bonus cherry drops** start at rank 2. The higher your rank, the more bonus cherries enemies drop on death.
- **Weapon damage** scales from 1 to 3 as rank rises. At max rank, your shots shred through enemies three times faster.
- **Visual feedback** tells you your rank without looking at a number. Your ship and bullets progressively shift from green to yellow to red.

## What rank does to the game (risk)

- **Enemy bullet speed** increases: up to **+40%** faster at rank 10.
- **Enemy spawn rate** increases: spawns come up to **30%** faster at rank 10, with a floor so it never gets truly unfair.

## The deal

High rank means you kill faster, earn more cherries, and score higher -- but enemy bullets are faster and waves come quicker. Getting hit drops rank by 1 and resets your multiplier, which slows rank growth. The player who can hold high rank the longest scores the most.

---

# 10. ENEMY FIELD GUIDE

## Normal enemies

One core enemy type with two weapon variants and three behavior states.

### Behavior states

**State 0 -- Entry:** Spawns above the screen and descends toward a randomized hover point (y = 20-35). Drifts slightly left or right during descent. Already firing during this state.

**State 1 -- Hover:** Patrols horizontally, bouncing off screen edges. Fires at the player. After 1.5 seconds, transitions to kamikaze.

**State 2 -- Kamikaze:** Locks onto the player's current position and dives at double speed. Sprite changes to the dive sprite. If it misses, it flies off-screen and despawns.

### Weapon variants (50/50 chance)

**Shotgun:** 3 bullets in a spread pattern aimed at the player. Spread angle of 10 degrees.

**Burst:** 3 rapid aimed shots in sequence with a short delay between each.

### Scaling

| Property       | Level 1 | Level 5 | Per NG+ loop |
| -------------- | ------- | ------- | ------------ |
| HP             | 1       | 3 (cap) | +1           |
| Speed          | 1.0     | 1.8     | +0.15        |
| Shoot interval | 2 sec   | ~1.5 sec | Faster       |
| Spawn count    | 1       | 2       | --           |

Normal enemies take **knockback** when hit but not killed -- they get pushed back slightly, giving you visual feedback that the shot connected.

**Field note.** Most "reflex deaths" are positioning errors from one or two seconds earlier.

## Bosses

See section 11 for full boss doctrine.

---

# 11. STAGE GUIDE

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
| ----- | ------------------- | -------------------- |
| 1     | 8 kills             | 12 kills             |
| 2     | 12 kills            | 15 kills             |
| 3     | 16 kills            | 18 kills             |
| 4     | 20 kills            | 21 kills             |
| 5     | 24 kills            | 24 kills             |

Kill count resets after each boss defeat.

### Boss count per level

| Level | Mini-bosses | Final bosses |
| ----- | ----------- | ------------ |
| 1     | 1           | 1            |
| 2-5   | 2           | 2            |

## Stage aesthetics

Each level has a distinct starfield that communicates depth and escalation:

| Level   | Background  | Star colors                    | Feel                                            |
| ------- | ----------- | ------------------------------ | ----------------------------------------------- |
| 1       | Black       | White                          | Clean void. Training ground.                    |
| 2       | Dark blue   | White, light blue, blue-grey   | Deeper space. Colder.                           |
| 3       | Dark green  | White, green, dark green       | Biological territory. Something alive out here. |
| 4       | Dark purple | White, blue-grey, pink         | Approaching the hive. Colors shifting.          |
| 5       | Dark brown  | White, yellow, blue-grey, cyan | The core. Everything is wrong.                  |
| 6 (TLB) | All colors  | Full spectrum                  | Hyperspace. Reality breaking.                   |

Star density increases per level (90 to 150). Stars twinkle more aggressively in later levels. Scroll speed increases with level.

## Warp transition

Between levels, a 6-second warp sequence plays: stars streak into lines, the background cycles through colors, the level number displays mid-transition, and the screen brightens to white at peak. During warp, the player's position resets to center and all bullets are cleared.

---

# 12. BOSS DOCTRINE

Bosses in MurderCrab are exams, not spectacles.

## Mini-boss

- **Sprite:** 16x16 pixels (2x2 tiles)
- **Base HP:** 60 (+5 per level, x1.5 per NG+ loop)
- **Phases:** 2 (transition at 50% HP)
- **Score:** 50 points (x multiplier)
- **Movement:** Enters from top, strafes horizontally within a 60-pixel range

Phase transitions are marked by screen shake and small explosions on the boss body.

## Final boss

- **Sprite:** 16x16 pixels (2x2 tiles), palette-shifted to distinguish from mini-boss
- **Base HP:** 100 (+5 per level, x1.5 per NG+ loop)
- **Phases:** 3 (transitions at 66% and 33% HP)
- **Score:** 100 points (x multiplier)
- **Movement:** Enters from top, strafes horizontally (slower than mini-boss)

At phase 3, the final boss palette shifts again -- a visual warning that the fight has entered its hardest stage.

## True last boss

- **Sprite:** 32x32 pixels (4x4 tiles)
- **Condition:** Beat all 5 levels without using any continues
- **Base HP:** 450 (x1.5 per NG+ loop)
- **Phases:** 3 (transitions at 66% and 33% HP)
- **Rage mode:** Phase 3. Pulsing red aura appears, +10 bullets added to every pattern
- **Score:** 50 points (x multiplier)

## Boss attack patterns

All bosses share three attack types that cycle based on game time and phase:

**Spiral:** Bullets spawn in a rotating spiral stream. Wobbles slightly with a sine offset for unpredictability. Count scales with level and boss damage state.

**Radial burst:** Bullets fire in an even circular spread from the boss center. Clean geometric pattern that demands positioning.

**Aimed burst:** 3-shot burst aimed directly at the player. Fast and precise. Tests streaming ability.

Higher phases cycle faster and unlock all three pattern types (phase 1 only uses spiral and radial). Bullet speed scales with level and boss damage state -- more damaged bosses shoot faster bullets in denser patterns.

**Rank effect:** Boss bullets are affected by rank speed scaling, just like normal enemy bullets. At high rank, boss patterns are measurably faster.

## Boss defeat

When the last boss of a type is destroyed:

- All enemy bullets on screen convert to small explosions (visual reward + safety)
- Cinematic explosion chain at the boss position
- Heavy screen shake
- Music fades out

For the final boss, a 3-second explosion celebration plays with periodic secondary detonations before the level warp begins.

---

# 13. SCORE ATTACK

## Point values

| Source            | Base value | Notes                            |
| ----------------- | ---------- | -------------------------------- |
| Normal enemy kill | 10         | Multiplied by current multiplier |
| Cherry pickup     | 100        | Multiplied by current multiplier |
| Mini-boss kill    | 50         | Multiplied by current multiplier |
| Final boss kill   | 100        | Multiplied by current multiplier |
| TLB kill          | 50         | Multiplied by current multiplier |

## Multiplier system

The multiplier starts at x1 and increases through cherry collection:

1. Kill enemies. They drop 4-8 cherries on death (90% chance).
2. Collect cherries to build streak. Each cherry = +1 streak.
3. Every **10 cherries** collected increases the multiplier by 1.
4. **Getting hit resets both multiplier and streak to 1.**

The multiplier applies to all point sources.

### Multiplier strategy

The multiplier is the entire scoring game. A x5 multiplier means every kill is worth 50 instead of 10. Every cherry is worth 500 instead of 100.

**The cost of getting hit is not the 1 HP you lose. It's the multiplier you drop and the rank you lose.**

Playing for score means playing for streaks. That means positioning to collect cherries efficiently, avoiding damage above all else, and using bombs proactively to protect the multiplier rather than reactively to survive.

## End-of-game bonus

When the game ends (victory or game over), a bonus is calculated:

```
bonus = (remaining bombs x 25) + (remaining HP x 25)
```

Every bomb you don't use and every hit you don't take pays off at the end.

---

# 14. CREDITS AND CONTINUES

## Credits

You get 3 credits per session. Think of them as quarters. Pressing any button on the title screen costs 1 credit. Credits reset to **3** every time you return to the title screen.

## Continuing

When you die:

- A 10-second countdown begins
- After a 1-second grace period, press Z to continue (costs 1 credit) or X to end the run
- Continuing restores 3 HP and resets your multiplier and streak to 1
- Rank is preserved through continues
- If the timer expires, the run ends automatically

Continuing is harsh by design. You get 3 more hits, not a fresh start.

## True ending condition

The true last boss only appears if you used **zero continues**. Any continue disqualifies you. After beating level 5's final boss without continuing, you warp to level 6 for the TLB encounter.

If you used continues, level 5's final boss defeat goes directly to the game complete screen.

## New Game Plus

After defeating the TLB, press Z to enter the next loop. This is not a new game -- it's the game continuing on the same credit. Score carries over. HP and bombs carry over. Rank carries over. Credits reset to 3. Enemies get harder.

NG+ scaling per loop:

- Normal enemy HP: +1 per loop (on top of level scaling, still capped at 3 in loop 1)
- Enemy speed: increases
- Enemy shoot interval: decreases
- Spawn delay: decreases
- Boss HP: x1.5 per loop (60 → 90 → 120 for mini-boss base)
- Boss bullet clusters: scale with level

During an NG+ chain you keep playing until you die or exit from the victory screen.

---

# 15. HIGH SCORES

## The board

The high score table holds **3** entries. It displays during the attract mode cycle on the title screen.

## Entering initials

When your run ends and your score qualifies for the **top 3**, the game takes you to the enter initials screen. Up/down cycles through characters (full printable ASCII), left/right moves between the 3 positions, and **Z or X confirms**.

Your initials are saved between sessions and used as the default starting point next time.

## When scores are recorded

The game computes **final score** (current score + end bonus) and checks against the board when:

- **Game over** begins (first frame of the countdown)
- **TLB defeat** (victory path)

If you qualify, you enter initials after the run ends. If you don't qualify, you go straight back to the title.

---

# 16. GLOSSARY

| Term             | Meaning                                                        |
| ---------------- | -------------------------------------------------------------- |
| **1CC**          | One credit clear. Beat the game without continuing.            |
| **TLB**          | True last boss (level 6). Requires no-continue clear.          |
| **Rank**         | Risk/reward system (0-10). Makes you stronger and game harder. |
| **Cherry**       | Score powerup. Builds streak toward multiplier increase.       |
| **Streak**       | Cherry collection counter. 10 cherries = +1 multiplier.       |
| **Multiplier**   | Score multiplier. Resets on hit. The core scoring mechanic.    |
| **Warp**         | Level transition animation. 6-second sequence between stages.  |
| **Loop / NG+**   | Replaying all 5 stages at higher difficulty after beating TLB. |
| **Rage mode**    | TLB phase 3. +10 bullets to all patterns. Pulsing aura.       |
| **Kamikaze**     | Normal enemy state 2. Locks onto player and dives.             |
| **Route**        | Planned path through a wave or stage.                          |
| **No-continue**  | Never used continue this run. Required for TLB.               |

---

> **THE SWARM IS LEARNING. SO ARE YOU.**
> Route five stages of shell-born violence. Cash power. Spend bombs before regret.
> Push for the clear, then come back for the score.
