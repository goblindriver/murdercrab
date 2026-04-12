# MURDERCRAB!

## Operator Manual

**Single source of truth for operators** — design vision, genre research, platform limits, tuning notes, and future features.

For the **player-facing manual** (controls, HUD, enemies, stages, score, credits, high scores): **[player-manual.md](player-manual.md)**.

This document is *why* the game is built the way it is, *where it should go*, and the *implementation limits* that affect tuning.

---

## Contents

1. Project Identity
2. Arcade Flow Model
3. PICO-8 Cart Budget
4. Design Philosophy
5. Combat Design Reference
6. Threat Language Framework
7. Boss Design Doctrine
8. Score Attack Philosophy
9. Practice Doctrine
10. Glossary
11. Future Features
12. Sources and References

---

# 1. PROJECT IDENTITY

## Core identity

- **Format:** Arcade game. Button in, play, die, initials, attract mode. No menus. No save files. No progression unlocks.
- **Platform:** PICO-8 fantasy console (128x128, 16 colors, 8192 tokens, 32KB cart)
- **Future port:** Picotron sequel (480x270, 64 colors, no token limit, X68000/FM Towns Marty aesthetic)
- **Visual spine:** Cosmic industrial horror + crab biology + machine shell design
- **Primary reference line:** Toaplan backbone, danmaku-aware boss design, doujin-style intensity
- **Player fantasy:** Tiny ship against impossible density, learning to cut stable lines through hostile space

## Pitch copy

> Humanity did not find peace in the void.
> It found armored claws, chitin cathedrals, and wave after wave of shell-born murder.
> Launch. Learn the lanes. Burn through the swarm.

## Tone

The manual and surrounding material should feel like a late-era **Super Nintendo / Sega Genesis pack-in manual** that got expanded into a **strategy zine** by people who actually play shmups seriously. Clean manual copy for systems. Magazine-style interstitials for philosophy. Operator notes for route-minded players.

## Doujin spirit

MurderCrab is a doujin work -- made by a small team out of passion, not obligation. Built on PICO-8 constraints, refined through play, stored in public Git, open to evolution.

## The mythic structure

From the *Shmup_Lyf Metaphor* issue, mapping Joseph Campbell's monomyth to the shmup:

| Monomyth element       | Shmup equivalent                                                     |
| ---------------------- | -------------------------------------------------------------------- |
| **The Hero**           | The player/ship. Gifted with prototype craft as a talisman.          |
| **An enemy force**     | The swarm. The reason for the conflict.                              |
| **The ultimate fiend** | The final boss. Multiple stages revealing true powers.               |
| **Threshold guardians**| Stage bosses. The warlords of their domains.                         |
| **Hero helpers**       | Power-up carriers, supply drops.                                     |
| **Journey**            | The stages themselves. Ever deeper into hostile territory.            |

MurderCrab's five-stage structure maps cleanly: the player is thrust outward through increasingly hostile territory toward the hive core, encountering threshold guardians before confronting the TLB.

## The Other: why crabs

MurderCrab sits in the **insectile/crustacean Other** space. Crabs are armored, alien in morphology, operate in swarms. The crab enemy is the biological Other given military shell -- nature weaponized.

## The ritual of play

From the DoDonPachi zine:

> "Another launch, another loop around the rosary. A moment of contemplation, of concentration, of meditation. Practiced hands count the beads, twitch the stick."

Each run is a ritual repetition. MurderCrab's NG+ system honors this: each loop is another passage through the rosary, familiar yet demanding deeper presence.

---

# 2. ARCADE FLOW MODEL

MurderCrab is an arcade game. Not "inspired by arcade games." It IS one.

## The loop

```
ATTRACT MODE (title: logo + high scores + how-to-play cycling every 6 seconds)
       |
       v  [press any button — costs 1 credit]
     GAME
       |
       +-- die --> GAME OVER (10-second countdown)
       |              |
       |              +-- [have credits? press Z to continue]
       |              |         --> back to GAME (costs 1 credit, 3 HP, reset multiplier)
       |              |
       |              +-- [no credits or press X or timer expires]
       |                        |
       |                        +-- score qualifies? --> ENTER INITIALS --> ATTRACT
       |                        +-- no high score --> ATTRACT
       |
       +-- beat TLB --> GAME COMPLETE (results screen)
                           |
                           +-- [press Z] --> NG+ loop (game continues, same credit)
                           +-- [press X]
                                     |
                                     +-- score qualifies? --> ENTER INITIALS --> ATTRACT
                                     +-- no high score --> ATTRACT
```

## Key principles

**No menu.** The title screen IS attract mode. Any button starts the game. Instructions, high scores, and attract visuals cycle on the title screen itself.

**Initials are entered when earned.** When your run ends and your score makes the board, the game takes you to enter initials. Z or X both confirm -- no cancel, no lost scores.

**Credits are quarters.** 3 per session. Starting costs 1. Continuing costs 1. Continuing gives 3 HP. Using a continue locks out the TLB.

**NG+ is not a new game.** Clearing loop 1 sends you into loop 2 on the same credit. Credits reset to 3. You play until you die.

---

# 3. PICO-8 CART BUDGET

## Platform specs

| Resource            | Limit         | Description                                                              |
| ------------------- | ------------- | ------------------------------------------------------------------------ |
| **Code tokens**     | 8,192         | Each word/operator = 1 token. local/end/comments are free.               |
| **Compressed code** | 15,360 bytes  | For .p8.png export. Not enforced for .p8 format.                         |
| **Total cart**      | 32 KB         | Includes code, sprites, map, SFX, music.                                 |
| **Sprites**         | 256           | 8x8 each, 16-color palette                                              |
| **SFX**             | 64 slots      | 4 channels, 32 notes per SFX                                            |
| **Music**           | 64 patterns   | Each pattern plays up to 4 SFX channels                                  |
| **Persistent**      | 64 numbers    | Via cartdata() / dget() / dset()                                         |
| **Display**         | 128x128       | 16 fixed colors, palette swaps via pal()                                 |
| **Input**           | 6 buttons     | DPAD + Z + X                                                             |
| **Frame rate**      | 60fps         | Using _update60()                                                        |

## Current usage (final cart)

| Resource       | Used                | Headroom                           |
| -------------- | ------------------- | ---------------------------------- |
| **Tokens**     | ~8,080 of 8,192     | ~112 tokens (essentially full)     |
| **Sprites**    | ~37% of rows        | Significant room for more art      |
| **SFX**        | 27 of 64            | 37 slots available                 |
| **Music**      | 18 of 64 patterns   | 46 patterns available              |
| **Cartdata**   | 21 of 64 slots      | 43 slots available                 |
| **Map**        | Not used             | Fully available                    |

### Cartdata allocation

| Slots | Usage                                                                         |
| ----- | ----------------------------------------------------------------------------- |
| 0-17  | High scores: 6 slots per entry (3 score components + 3 initials) x 3 entries |
| 18-20 | Saved initials (3 ASCII character codes)                                      |
| 21-63 | **Free**                                                                      |

Cartdata ID: `"murdercrab_v2"` (reset from v1 to clear pre-component-score data).

### Sprite allocation

| Sprite(s)       | Usage                                     |
| --------------- | ----------------------------------------- |
| 1, 17, 33       | Player ship (center, left-tilt, right-tilt) |
| 2, 18, 34, 50   | Player bullet animation (4 frames)        |
| 3, 19           | Enemy normal (2-frame animation)          |
| 35              | Enemy kamikaze dive sprite                |
| 4               | Enemy bullet                              |
| 5               | Bomb powerup                              |
| 6               | Health powerup                            |
| 7               | Cherry (score powerup)                    |
| 8 (2x2)         | Mini-boss / Final boss                    |
| 10 (4x4)        | True last boss                            |

Upper sprite rows (96-255) are empty. Shared sprite/map region entirely unused.

### Music layout

| Patterns | Usage                    |
| -------- | ------------------------ |
| 0-5      | Title / attract          |
| 6-9      | Gameplay                 |
| 10-13    | Boss                     |
| 14-17    | Additional (warp, etc.)  |
| 18-63    | **Free**                 |

## Hitboxes

| Entity                              | Collision box | Notes                                                |
| ----------------------------------- | ------------- | ---------------------------------------------------- |
| Player vs enemy bullets             | 2x2 px        | Centered in the 8x8 sprite (player.x+3, player.y+3) |
| Player vs normal enemies (hovering) | 2x2 px        | Same tiny hitbox                                     |
| Player vs kamikaze (dive state)     | 8x8 px        | Full player sprite vs enemy AABB                     |
| Player bullets                      | 8x8 px        | Per bullet                                           |
| Enemy bullets                       | 8x8 px        | Spawned centered on origin                           |
| Normal enemies                      | 8x8 px        |                                                      |
| Mini-boss / final boss              | 16x16 px      |                                                      |
| True last boss                      | 32x32 px      |                                                      |
| Powerups                            | 8x8 px        |                                                      |

## Bullet object pools

Player and enemy bullets are pooled (get_bullet/release_bullet, get_enemy_bullet/release_enemy_bullet). Freed bullets are reused instead of churning new tables every shot.

## Constants reference (60fps values)

All speeds are in pixels per frame at 60fps. All timers are in frames at 60fps.

**Player:**

| Constant | Value | Real-time      |
| -------- | ----- | -------------- |
| P_SPD    | 1     | 60 px/sec      |
| P_HP     | 100*  | *Testing value, release = 3* |
| P_BMBS   | 3     |                |
| B_SPD    | 3     | 180 px/sec     |
| BMB_DUR  | 60    | 1 second       |
| BMB_DMG  | 30    |                |
| shoot_cd | 8     | ~7.5 shots/sec |
| invincible_timer | 60 | 1 second  |

**Enemy:**

| Constant    | Value | Notes                        |
| ----------- | ----- | ---------------------------- |
| E_SPD       | 1     | Base speed                   |
| E_SPD_SCL   | 0.2   | Per-level speed increase     |
| E_SPD_MAX   | 1.75  | Speed cap                    |
| E_SHT_BASE  | 120   | 2-second base shoot interval |
| E_SHT_SCL   | 8     | Per-level interval reduction |
| E_SHT_MIN   | 80    | ~1.33 second floor           |
| E_B_SPD     | 2.25  | Shotgun bullet speed         |
| E_B_SPREAD  | 10    | Shotgun spread angle         |
| E_BURST_SPD | 2.5   | Burst bullet speed           |
| E_BURST_DLY | 6     | Frames between burst shots   |
| Normal HP   | min(3, level + loop - 1) | Caps at 3     |

**Boss:**

| Constant     | Value | Notes                           |
| ------------ | ----- | ------------------------------- |
| MB_HP        | 60    | Mini-boss base HP               |
| MB_HP_SCL    | 5     | Per-level HP increase           |
| FB_HP        | 100   | Final boss base HP              |
| FB_HP_SCL    | 5     | Per-level HP increase           |
| TLB HP       | 450   | True last boss base HP          |
| Loop mult    | 1 + (loop-1)*0.5 | 1x, 1.5x, 2x, etc. |
| BASE_CLUSTERS| 6     | Base bullets per pattern        |

**Rank:**

| Mechanic        | Formula                              | Notes                          |
| --------------- | ------------------------------------ | ------------------------------ |
| Rank rise       | min(10, max(rank, multiplier - 1))   | Sticky, only goes up           |
| Rank fall       | max(0, rank - 1)                     | On player hit only             |
| Weapon damage   | min(3, 1 + flr(rank/3))             | 1 at 0-2, 2 at 3-5, 3 at 6+  |
| Bullet speed    | 1 + rank * 0.04                      | Up to 1.4x at rank 10         |
| Spawn delay     | max(40, delay * (1 - rank * 0.03))   | Up to 30% faster at rank 10   |
| Bonus cherries  | rank >= 2 and rnd(10) < rank         | Chance per kill                |

**Timers:**

| Timer              | Frames | Real-time |
| ------------------ | ------ | --------- |
| warp_duration      | 360    | 6 seconds |
| game_over_timer    | 600    | 10 seconds|
| game_over_grace    | 60     | 1 second  |
| game_complete_grace| 90     | 1.5 sec   |
| boss_warning       | 180    | 3 seconds |
| boss_defeat_grace  | 180    | 3 seconds |
| spawn_delay (base) | 120    | 2 seconds |
| cherry timer       | 90     | 1.5 sec   |
| bomb_effect_timer  | 60     | 1 second  |
| hover timer        | 90     | 1.5 sec   |

**Scoring:**

| Constant | Value |
| -------- | ----- |
| S_NRM    | 10    |
| S_STRK   | 10    |
| S_BMB    | 25    |
| S_HP     | 25    |

Score uses split-variable system: `score` (units 0-999) + `score_hi` (thousands). Component format for display/comparison: `{m=millions, k=thousands, u=units}`. This overcomes PICO-8's 32767 integer limit.

---

# 4. DESIGN PHILOSOPHY

## Legibility under pressure

Dense shmups only work when they are legible. Even when a game becomes overwhelming, the player still needs readable movement, readable threat classes, and readable reasons for each tool. The point is not "make it easy." The point is **make the player's decisions informed**.

If a section kills the player, the player should eventually be able to say **why**.

## Survival is not the whole game

From *The Full Extent of the Jam*:

> "One thing I would like to stress is how much more fun STGs become when you play them for score instead of survival."

Scoring forces complex, planned play. The game should quietly teach players that it opens up once they start asking: not "How do I make it through?" but "What is the game rewarding me for doing?"

## Backgrounds are not wallpaper

From the *Shmup_Lyf Backgrounds* zine:

> "In shmups, backgrounds aren't just pieces of art we see but also places we go. They help, in large part, to tell the spatial narrative of a game."

The PICO-8 version uses distinct starfield color palettes per level to communicate progression. A future port's higher resolution creates room for real background art, parallax layers, and spatial narrative.

## The feeling of destruction

From the *Cho Ren Sha 68k* zine: Explosions should "unpack like a fractal." The lingering aftermath is what makes destruction feel weighty. MurderCrab implements this through chained explosions, hitstop frames, screen shake, and the bullet-to-explosion conversion on boss defeats.

## What a stage should teach

From the CRS68k zine, citing forum user Durandal:

> "introduction -> break -> test -> introduction 2 -> test 1 & 2 -> break -> test 1 & 2 climax."

A stage needs introductions, tests, and breaks. Without all three, the rhythm fails.

---

# 5. COMBAT DESIGN REFERENCE

## Game feel systems

These systems exist in the current cart and define MurderCrab's tactile identity:

**Hitstop:** 2 frames on normal enemy kill, 1 frame on boss hit. Freezes the entire game update loop. Creates visceral impact from every kill.

**Screen shake:** Scaled to event severity. 3 for bullet impacts, 8 for boss phase transitions, 10 for boss kills, 20 for bomb detonation.

**Enemy knockback:** Normal enemies hit but not killed get pushed back 1.5 pixels. Visual feedback that a shot connected and the enemy is taking damage.

**Progressive visual tint:** Ship palette shifts with rank using pal() swaps. Green at low rank, yellow at mid, red at high. Bullet trails appear at rank 3+ and lengthen with rank. Communicates power level without HUD clutter.

**Powerup physics:** Cherry bursts explode outward with velocity that decelerates via friction (0.95 per frame), then drift downward or get attracted to the player within 48px. Creates satisfying physical feel to every kill reward.

**Boss defeat spectacle:** All enemy bullets convert to small explosions. Chain explosions fire on the boss body. Screen shake. Music fade. Extended celebration sequence for final bosses with periodic secondary detonations.

## Movement

Fixed-speed digital movement at 1px/frame (60fps), 8-directional. No inertia. Tiny 2x2 hitbox centered on the 8x8 sprite. Full sprite used for kamikaze collisions only.

## Shot

Twin forward bullets on Z. Hold for rapid fire at ~7.5 volleys/sec (8-frame cooldown). Damage scales with rank from 1 to 3. No power levels, no spread change, no pierce.

## Bomb

Full-screen clear + 30 damage to all bosses. Clears all bullets (player and enemy). 1-second active duration with 1-second visual effect following. 3 starting stock. No score penalty for bombing.

## Rank as power system

Rather than a traditional power-up weapon progression, MurderCrab uses the rank system as its power scaling mechanic. The player's weapon improves through sustained skillful play (keeping the multiplier high) rather than through collecting power items. This means:

- Power is earned through performance, not drops
- Power is lost gradually (rank -1 on hit) rather than catastrophically
- The game pushes back proportionally (faster bullets, faster spawns)
- There is no "fully powered up" safe state -- high rank always means high risk

---

# 6. THREAT LANGUAGE FRAMEWORK

This framework defines the threat hierarchy. The current PICO-8 version has one normal enemy type with weapon variants. This is the roadmap for expansion.

## Current implementation

**Normal enemy** — one type, two weapons (shotgun/burst), three states (enter, hover, kamikaze). Serves as popcorn at low levels and midweight threat at high levels/loops. HP scales from 1 to 3.

**Mini-boss** — 16x16, 2 phases, spiral/radial patterns. First exam. 1 on level 1, 2 on levels 2-5.

**Final boss** — 16x16 palette-shifted, 3 phases, all pattern types. The real test. Same count scaling.

**True last boss** — 32x32, 3 phases with rage mode. +10 bullets to patterns in rage. The graduation.

## Desired expansion (future port)

| Tier | Role | Description |
| ---- | ---- | ----------- |
| Popcorn | Rhythm | Fragile, fast, arrive in waves. Die in one hit regardless of loop. |
| Midweight | Decision | Survive long enough to force target priority choices. |
| Turret | Lane shaping | Static or slow-moving. Force timing and positioning. |
| Elite | Urgency | "Kill me now or the stage gets worse." Unmistakable silhouette. |

## Bullet families (future port)

| Family             | Role                        |
| ------------------ | --------------------------- |
| Needle shots       | Speed pressure               |
| Shell pearls       | Lane denial / density        |
| Claw fans          | Spread pressure              |
| Aimed darts        | Streaming / herding          |
| Slow bloom clusters| Trap construction            |
| Crusher beams      | Territory denial             |

---

# 7. BOSS DESIGN DOCTRINE

## Principles

- **Opener must be readable.** A new player's first encounter should not feel random.
- **Phase changes must be announced.** Visual tells, audio cues, screen shake.
- **Dense patterns must still contain logic.** Chaos is not difficulty.
- **Death should feel educational, not arbitrary.**

## Current boss implementation

**Pattern system:** All bosses share three attack types that cycle based on game time and phase. Pattern rotation speed increases with phase. Phase 1 uses spiral and radial only; phase 2+ adds aimed bursts.

**Pattern scaling:** Bullet count scales with `BASE_CLUSTERS + current_level` plus a health-based bonus (`flr((1-health_ratio) * 5)`). Bullet speed scales with level and damage state. Rank applies its own speed multiplier on top.

**Phase transitions:** Tracked by health thresholds. Mini-boss: 2 phases (50% HP). Final boss and TLB: 3 phases (66% and 33% HP). Each transition triggers screen shake (8 + phase*2), explosions on the boss body, and a shoot interval reduction.

**TLB rage mode:** Phase 3 activates rage. +10 bullets to spiral and radial patterns. Pulsing red aura with dithered circle effect. Boss palette shifts with sine-driven color cycling.

## Pattern design rule

Every dense pattern should have at least one technique that makes it tractable. If the only survival strategy is "hope for a gap," the pattern is bad.

## Dodging techniques that should inform pattern design

From *The Full Extent of the Jam*:

| Technique              | Description                                                     |
| ---------------------- | --------------------------------------------------------------- |
| Bottom line reduction  | Diagonal against screen border reduces lateral speed            |
| Speed trick            | Moving perpendicular to needed axis reduces speed on that axis  |
| Moving with the flow   | Moving with bullets buys time to find gaps                      |
| Bullet herding         | Slow lateral bait, then fast arc to spread aimed density        |
| Emergency bombing      | Bomb when you have no visible path for the next second          |

---

# 8. SCORE ATTACK PHILOSOPHY

## The run is a route

A strong score run is repeated, not improvised. The game repeats from run to run, so the player's job is to find and stabilize a sequence of actions that maximizes scoring efficiency.

## Study replays

ProMeTheus is emphatic: using replays to learn is not cheating. Routes are communal knowledge refined through shared observation.

## Bombing and score

Bombing has no direct score penalty. It clears enemies (awarding kill points), protects your multiplier, and converts dangerous situations into safe ones. Unused bombs contribute to the end bonus (25 points each). Bombing is score-positive in the current design.

## Resource routing

> Don't just ask whether a bomb saves you. Ask what that bomb preserves.

- A bomb that preserves a x5 multiplier is worth more than the 25-point end bonus
- A cherry at x1 is worth 100; at x8 it's worth 800
- Getting hit to collect cherries is almost never worth it -- multiplier reset + rank loss costs more

---

# 9. PRACTICE DOCTRINE

## Practice mode is part of the game

ProMeTheus: isolated drilling is 4-5x faster than replaying easy sections to revisit the part you fail. If practice mode features are ever added, the game should endorse their use openly.

## Practice ladder

1. Learn the survival route.
2. Isolate the wave that keeps killing you.
3. Drill the boss opener until it stops feeling surprising.
4. Reconnect checkpoints into longer segments.
5. Return to full runs only after consistency improves.

80% practice, 20% full scoring runs.

## Learn what you cannot do

> "Don't practice what you can do, practice what you can't do."

Cut dead time. Drill the hard thing.

---

# 10. GLOSSARY

## Standard shmup terminology

**1CC** — One credit clear. Beat the game without continuing.
**Bomb** — Emergency/tactical resource that clears danger and/or deals damage.
**Bullet cancel** — When bullets are erased, often producing score or items.
**Bullet hell / Danmaku** — High-density shooter style with large projectile counts and pattern reading.
**Bullet herding** — Baiting aimed shots into a controlled portion of the screen.
**Capture** — Clear a pattern without getting hit or spending resources.
**Caravan** — Short-form score attack play (2-5 minutes).
**Extend** — Extra life.
**Micrododge** — Tiny movement through dense bullet spacing.
**PB** — Personal best.
**Popcorn** — Weak enemies that die quickly and establish stage rhythm.
**Route** — A planned sequence of actions through a stage or full game.
**Safespot** — A stable location inside or around a pattern.
**Streaming** — Dragging aimed shots into lines through steady movement.
**Superplay** — High-level demonstration run.

## MurderCrab-specific terms

| Term          | Meaning                                                           |
| ------------- | ----------------------------------------------------------------- |
| Attract mode  | Idle title screen. Cycles logo, high scores, how-to-play.        |
| Credit        | A quarter. 3 per session. 1 to start, 1 to continue.             |
| Cherry        | Score powerup. Builds streak toward multiplier increase.          |
| Streak        | Cherry counter. 10 cherries = +1 multiplier.                     |
| Multiplier    | Score multiplier. Resets on hit.                                  |
| Rank          | Risk/reward system (0-10). Tracks multiplier, only falls on hit. |
| Warp          | 6-second level transition animation.                              |
| Loop / NG+    | Replaying all 5 stages at higher difficulty after TLB.            |
| TLB           | True last boss. Level 6. Requires no-continue clear.             |
| Rage mode     | TLB phase 3. +10 bullets. Pulsing aura.                          |
| Kamikaze      | Normal enemy state 2. Locks onto player and dives.               |
| Hitstop       | 1-2 frame game freeze on enemy hit. Tactile impact.              |

---

# 11. FUTURE FEATURES

## Release checklist

- [ ] **Change P_HP from 100 to 3** — testing value needs to be set to release value

## Combat expansion (future port)

- [ ] **Focus mode** — Slow movement + visible hitbox + concentrated fire
- [ ] **Power levels** — Weapon progression through pickups with partial loss on death
- [ ] **Point-blank bonus** — Extra damage or score for close-range attacks
- [ ] **Bullet cancel conversion** — Bomb/boss kills convert bullets to score items

## Enemy expansion (future port)

- [ ] **Popcorn enemies** — Fragile, fast, arrive in waves
- [ ] **Turret enemies** — Static, shape the lane
- [ ] **Elite enemies** — High priority, unmistakable silhouette
- [ ] **Bullet families** — Visually distinct projectile types
- [ ] **Side-entry enemies** — Enter from screen edges

## Stage expansion (future port)

- [ ] **Stage names and theming** — Each level with identity beyond "Level N"
- [ ] **Background art** — Foreground/midground elements, parallax, environmental storytelling
- [ ] **Stage-specific mechanics** — Environmental hazards, destructible terrain
- [ ] **Stage-end bonus** — Points for speed, no-miss, no-bomb

## Scoring expansion (future port)

- [ ] **Chain system** — Kill within time windows to maintain chain
- [ ] **Medal / hidden item system** — Discoverable score items
- [ ] **No-miss / no-bomb bonus** — Per-stage rewards for clean play
- [ ] **Replay recording** — Save and share runs

## Quality of life (future port)

- [ ] **Practice mode** — Stage select, boss select, checkpoint restart
- [ ] **Caravan mode** — 2 or 5-minute score attack
- [ ] **Input display** — Show presses during replay
- [ ] **Detailed score breakdown** — Per-stage summary

## Lore (future port)

- [ ] Player ship name
- [ ] Faction terminology
- [ ] Boss names
- [ ] Enemy class names

---

# 12. SOURCES AND REFERENCES

All primary source PDFs are stored in `docs/reference-library/`.

## The Full Extent of the Jam — ProMeTheus (2010)

**File:** `reference-library/Full Extent of the Jam (English).pdf`

44-page guide to competitive shmup play by the occidental DoDonPachi record holder. Key concepts for MurderCrab:

- **Score play is the real game.** Scoring forces complex, planned play.
- **Route play.** Find, stabilize, and repeat a scoring sequence.
- **Replay study is not cheating.** Routes are communal knowledge.
- **Targeted practice.** Saved states = 4-5x faster improvement.
- **Emergency bombing.** "Always bomb if you don't have a path for the next second."
- **80/20 rule.** 80% practice mode, 20% full scoring runs.

### Technique library

| Technique                  | Description                                                |
| -------------------------- | ---------------------------------------------------------- |
| Lower Speed on Bottom Line | Diagonal against border reduces lateral speed              |
| Speed Trick                | Perpendicular movement reduces speed on adjustment axis    |
| Moving With the Flow       | Move with bullets to buy time finding gaps                  |
| Bullet Herding             | Slow bait, then fast arc to spread aimed density           |
| Emergency Bombing          | Bomb when no visible path for the next second              |

## Shmup_Lyf Zine Series — Marty_DYR

| File                                              | Focus                              |
| ------------------------------------------------- | ---------------------------------- |
| `Shmup_Lyf Zine #01 - MagCloud (1).pdf`          | First issue, general coverage      |
| `Shmup_Lyf Zine #02 - Metaphor (1).pdf`          | Phenomenological analysis          |
| `Shmup_Lyf Zine SP - Doujins - MGCL (1).pdf`    | Doujin shmup special               |
| `Shmup_Lyf Zine - Backgrounds.pdf`               | Background art as spatial narrative|
| `Shmup_Lyf Zine - ChoRenSha68k (3).pdf`          | CRS68k deep dive                   |
| `Shmup_Lyf Zine - DoDonpachi (1).pdf`            | DoDonPachi coverage                |
| `Shmup_Lyf Zine - Dezaemon Dimensions (1).pdf`   | Dezaemon creation tool             |
| `Shmup_Lyf Zine - Doujin Depths.pdf`             | Doujin deep dives                  |
| `Shmup_Lyf Zine - Doujin Discordancy (2).pdf`    | More doujin coverage               |

### Key concepts from the Backgrounds issue

- Backgrounds are places you go, not just art you see
- Each environment archetype carries psychological weight
- PICO-8 is noted as "increasingly becoming a place of shmup emergence"

### Key concepts from the CRS68k issue

- Enemy design: bigger means stronger. Break the rule knowingly for surprise.
- Stage rhythm formula: introduction -> break -> test -> climax
- Explosions as fractal layered sprite animations with lingering smoke
- Toaplan as foundation, Batsugun-era bullet hell as evolution
- Iterative development across Comiket events, shaped by community feedback

## Cave Shooting Artworks

**File:** `reference-library/Cave Shooting Artworks.cbz`

Visual reference for Cave's art direction. Useful for boss design, enemy design language, and the visual standards of the genre's most influential studio.

---

> **THE SWARM IS LEARNING. SO ARE YOU.**
