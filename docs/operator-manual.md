# MURDERCRAB!
## Operator manual

**Single source of truth for operators** — design vision, genre research, arcade-flow targets, PICO-8 cart budget, tuning notes, glossary, and future features.

For the **player-facing manual** (controls, HUD, enemies, stages, score, credits, high scores, figures): **[player-manual.md](player-manual.md)**.

This document is *why* the game is built the way it is, *where it should go*, and *implementation limits* that affect tuning. It draws from the first-pass manual research and guides the PICO-8 cart and any future ports.

---

## CONTENTS

1. Project Identity
2. Arcade Flow Model
3. PICO-8 Cart Budget (platform limits, usage, cartdata, sprites, music, hitboxes, bullet pools)
4. Design Philosophy
5. Shmup Design Principles
6. Combat Design Reference
7. Threat Language Framework
8. Boss Design Doctrine
9. Score Attack Philosophy
10. Practice Doctrine
11. Glossary
12. Future Features
13. Sources and References

---

# 1. PROJECT IDENTITY

## Core identity

- **Format:** Arcade game. Quarter in, play, die, initials, attract mode. No menus. No save files. No progression unlocks.
- **Platform origin:** PICO-8 fantasy console (128x128, 16 colors, 8192 tokens, 32KB cart)
- **Future port:** Picotron fork when the PICO-8 version is polished (480x270, 64 colors, no token limit)
- **Visual spine:** cosmic industrial horror + crab biology + machine shell design
- **Primary reference line:** Toaplan backbone, danmaku-aware boss design, doujin-style intensity
- **Player fantasy:** tiny ship against impossible density, learning to cut stable lines through hostile space

## Pitch copy

> Humanity did not find peace in the void.
> It found armored claws, chitin cathedrals, and wave after wave of shell-born murder.
> Launch. Learn the lanes. Burn through the swarm.

## Back cover copy

> **THE SWARM IS LEARNING. SO ARE YOU.**
> Route five stages of shell-born violence. Cash power. Spend bombs before regret.
> Push for the clear, then come back for the score.
> *MURDERCRAB* is built for players who want survival to be only the first conversation.

## Tone

The manual and surrounding material should feel like a late-era **Super Nintendo / Sega Genesis pack-in manual** that got expanded into a **strategy zine** by people who actually play shmups seriously. Clean manual copy for systems. Magazine-style interstitials for philosophy. Operator notes for route-minded players.

## Doujin spirit

MurderCrab is a doujin work -- made by a small team out of passion, not obligation. The Shmup_Lyf zines use "doujin" lovingly, as "a marker of an artefact of immense passion created by a small group or an individual." The CRS68k issue shows how that game was developed iteratively across multiple Comiket events, shaped by community feedback, in conversation with the arcade games of its era.

MurderCrab follows the same path: built on PICO-8 constraints, refined through play, stored in public Git, open to evolution.

## The mythic structure

From the *Shmup_Lyf Metaphor* issue, mapping Joseph Campbell's monomyth to the shmup:

| Monomyth element | Shmup equivalent |
|-----------------|-----------------|
| **The Hero** | The player/ship. "Gifted with prototype craft as a talisman, like a young knight entrusted with a great and enchanted weapon." |
| **An enemy force** | The swarm. The reason for the conflict. |
| **The ultimate fiend** | The final boss. "Often with multiple stages as they reveal their true powers, when pushed into a corner." |
| **Threshold guardians** | Stage bosses. "The warlords of their domains." David vs Goliath encounters. |
| **Hero helpers** | Power-up carriers, option fighters, supply ships. "By your side through thick and thin." |
| **Journey through a world** | The stages themselves. "You move ever deeper into the lair or into foreign-held territory." |

MurderCrab's five-stage structure maps cleanly to this: the player is thrust outward through increasingly hostile territory toward the hive core, encountering threshold guardians (mini-bosses, final bosses) before confronting the TLB.

**Spatial metaphor:** "Shmups are about contest over territory. As a player you advance through a space owned by an opposing force and occupy it, cleansing and purging it of this 'evil' presence."

## The Other: why crabs

The *Metaphor* issue identifies how shmup enemies embody different forms of "the Other" -- the thing that is profoundly not-us:

- **Biological Other** — "toxic, mutated, cannot be reasoned with, they only devour." Tentacles, insects, parasites.
- **Insectile Other** — "glossy carapaces, segmented limbs and crunching mandible mouthpieces." Bees in DoDonPachi. Swarm behavior. Hive mind.
- **Cyborgian Other** — biomechanical fusion, Giger-esque. The fear that technology will consume the organic.

MurderCrab sits squarely in the **insectile/crustacean Other** space. Crabs are armored, alien in morphology, operate in swarms, and the "hive" language maps perfectly to crustacean biology (molting, carapace, chitin, brood). The crab enemy is the biological Other given military shell -- nature weaponized.

From the DoDonPachi zine: "The enemy stronghold. The hive. The stings fly thick and fast, as the mindless drones attack." Replace bees with crabs and you have MurderCrab's final stages.

## The ritual of play

From the DoDonPachi zine's epigraph:

> "Ritual is something that is part of our everyday lives; to engage in repetitive actions -- to centre ourselves, to add structure and continuity to life -- this is fundamental to being human. We enact it in the way we prepare ourselves for a day, when we eat, when we work, and of course in the games we play."

> "Another launch, another loop around the rosary. A moment of contemplation, of concentration, of meditation. Practiced hands count the beads, twitch the stick. Trace a line through a world of enemy fire, flow through a much repeated passage. The game plays us. We are the ritual."

This is the emotional truth behind route play and NG+ loops. Each run is a ritual repetition. The player doesn't just memorize -- they internalize until the game becomes meditation. MurderCrab's NG+ system should honor this: each loop is another passage through the rosary, familiar yet demanding deeper presence.

## Learning as untying knots

From the DoDonPachi zine on stage learning:

> "Untying knots. That's the feeling in my brain when I think about what it is to learn a particular stage. A great thread flowing through the level, through the possibility space. Some sections are smooth already, not difficult to trace, but then there are the knots. The parts where the enemies pile up or the intersecting bullet waves create binds."

> "In a run you can use a bomb and skip a particularly heinous knot -- wise -- but in stage focused practice you can take the time to understand the knots, to unpick them. Approach each one as a puzzle to be solved. Eventually you find a way to loosen it, and then through repeated action it becomes featureless."

This is the experiential counterpart to ProMeTheus's practice doctrine. The player's journey through a shmup is fractal: survival knots, then scoring knots, then optimization knots. "There are multitudinous different ways to cut the thread and bind it together in even more intricate patterns."

---

# 2. ARCADE FLOW MODEL

MurderCrab is an arcade game. Not "inspired by arcade games." It IS one. The mental model is a cabinet: you walk up, drop a quarter, play until you die, put your initials in if you earned a spot, and the machine goes back to attract mode.

## The loop

```
ATTRACT MODE (title + high scores + how-to-play cycling)
       │
       ▼  [press start — costs 1 credit]
     GAME
       │
       ├── die ──► GAME OVER
       │              │
       │              ├── [have credits? press Z to continue]
       │              │         └──► back to GAME (costs 1 credit, 3 HP)
       │              │
       │              └── [no credits or press X or timer expires]
       │                        │
       │                        ├── score qualifies? ──► ENTER INITIALS ──► ATTRACT MODE
       │                        └── no high score ──► ATTRACT MODE
       │
       └── beat TLB ──► GAME COMPLETE
                           │
                           ├── [press Z] ──► NG+ loop (game continues, same credit)
                           └── [press X or timeout]
                                     │
                                     ├── score qualifies? ──► ENTER INITIALS ──► ATTRACT MODE
                                     └── no high score ──► ATTRACT MODE
```

## Key principles

**No menu between attract and play.** The title screen IS attract mode. Press start to play. That's it. There is no separate menu with options. Instructions, high scores, and attract visuals cycle on the title screen itself.

**Initials are entered when you earn them.** Not before the game. Not from a menu. When your run ends and your score makes the board, the game says "enter your initials" right there. You stamp your name and the cabinet resets to attract.

**Credits are quarters.** You get 3 per session. Starting costs 1. Continuing costs 1. Continuing gives you 3 HP -- enough to see what's ahead, not enough to coast. Using a continue locks you out of the TLB.

**NG+ is not a new game.** It's the game continuing. In arcade terms, clearing loop 1 sends you into loop 2 on the same credit. You play until you die. There is no "return to menu" option mid-run.

**Attract mode cycles.** The idle screen should cycle through: title logo, high score table, brief how-to-play, back to title. The starfield scrolls. The music plays. The cabinet is alive even when nobody is playing.

## Delta from current implementation

The current cart has a separate menu state between title and gameplay with 4 options (start game, enter initials, instructions, high scores). This needs to be collapsed:

| Current | Target |
|---------|--------|
| `title` → `menu` → `start_game` | `attract` → `game` (press start) |
| `menu` → `enter_initials` (pre-game) | `game_over` → `enter_initials` (if qualified) → `attract` |
| `menu` → `instructions` | Instructions cycle as part of attract mode |
| `menu` → `highscores` | High scores cycle as part of attract mode |
| `game_over` → `menu` | `game_over` → `enter_initials` or `attract` |
| `game_complete` → `menu` (press X) | `game_complete` → `enter_initials` or `attract` (press X / timeout) |

---

# 3. PICO-8 CART BUDGET

How MurderCrab fits on the cart. These are the hard walls.

## Platform specs

| Resource | Limit | Description |
|----------|-------|-------------|
| **Code tokens** | 8,192 | Each word/operator is 1 token. Brackets and strings each count as 1. `local`, `,`, `;`, `end`, comments are free. |
| **Compressed code** | 15,360 bytes | For .p8.png/.p8.rom export. Not enforced for .p8 format. |
| **Total cart data** | 32 KB | Encoded as PNG. Includes code, sprites, map, SFX, music. |
| **Sprites** | 256 (128 + 128 shared) | 8x8 each, 16-color palette |
| **Map** | 128x32 tiles (+ 128x32 shared) | Shares memory with lower sprite bank |
| **SFX** | 64 slots | 4 channels, 32 notes per SFX |
| **Music** | 64 patterns | Each pattern plays up to 4 SFX channels |
| **Persistent storage** | 64 numbers (256 bytes) | Via `cartdata()` / `dget()` / `dset()` |
| **CPU** | 4M VM insts/sec | At 30fps that's ~133K instructions per frame |
| **Display** | 128x128, 16 fixed colors | No transparency, palette swaps via `pal()` |
| **Input** | 6 buttons per player (DPAD + Z + X) | 2 players supported |
| **Frame rate** | 30fps (`_update`) or 60fps (`_update60`) | MurderCrab uses 30fps |

## Current usage

| Resource | Used | Limit | Headroom |
|----------|------|-------|----------|
| **Lua code** | ~1,951 lines, 86 functions | 8,192 tokens | Moderate (exact token count requires PICO-8 `INFO` command) |
| **Sprites** | 48 of 128 pixel rows populated (~37%) | 128 rows (+ 128 shared) | Significant — room for more enemy types, effects, backgrounds |
| **SFX** | 27 of 64 slots | 64 | Good — 37 slots available for new sounds |
| **Music** | 18 of 64 patterns | 64 | Good — 46 patterns available |
| **Cartdata** | 21 of 64 slots | 64 | Good — 43 slots available |
| **Map** | Not used | 128x32 tiles | Fully available (could store level data, attract mode text, etc.) |

### Cartdata allocation

| Slots | Usage |
|-------|-------|
| 0-17 | High score table: 6 slots per entry (3 score components + 3 initials) x 3 entries |
| 18-20 | Saved initials (3 ASCII character codes) |
| 21-63 | **Free** (43 slots available) |

Plenty of room for future persistent features: settings, statistics, unlocks, or expanding the leaderboard later.

### Sprite allocation

| Sprite(s) | Usage |
|-----------|-------|
| 1, 17, 33 | Player ship (center, left-tilt, right-tilt) |
| 2, 18, 34, 50 | Player bullet animation (4 frames) |
| 3, 19 | Enemy (normal, animated) |
| 35 | Enemy (kamikaze dive sprite) |
| 4 | Enemy bullet |
| 5 | Bomb powerup |
| 6 | Health powerup |
| 7 | Cherry (score powerup) |
| 8 (2x2) | Mini-boss / Final boss |
| 10 (4x4) | True last boss |
| 48+ | Explosion sprite(s) |

The lower 6 rows (sprites 0-95) contain all game art. The upper 10 rows (sprites 96-255) are empty. The shared sprite/map region (sprites 128-255) is entirely unused.

### Music layout

| Patterns | Usage |
|----------|-------|
| 0-5 | Title / attract |
| 6-9 | Gameplay |
| 10-13 | Boss |
| 14-17 | Additional (warp, victory, etc.) |
| 18-63 | **Free** |

## Hitboxes (implementation)

Frame loop: `_update()` at **30fps** (not `_update60`).

| Entity | Collision box | Notes |
|--------|----------------|-------|
| Player vs **enemy bullets** | 2×2 px | Centered in the 8×8 ship sprite (`player.x+3`, `player.y+3`) |
| Player vs **normal enemies** (not diving) | 2×2 px | Same hitbox vs enemy AABB |
| Player vs **kamikaze** (dive, `state == 2`) | 8×8 px | Full player sprite vs enemy AABB |
| Player bullets | 8×8 px | Per bullet table |
| Enemy bullets | 8×8 px | Spawned centered on origin |
| Normal enemies | 8×8 px | |
| Mini-boss / final boss | 16×16 px | 2×2 tile sprite |
| True last boss | 32×32 px | 4×4 tile sprite |
| Powerups | 8×8 px | |

## Bullet object pools

Player bullets and enemy bullets are **pooled** (`get_bullet` / `release_bullet`, `get_enemy_bullet` / `release_enemy_bullet`) so freed bullets are reused instead of churning new tables every shot.

---

# 4. DESIGN PHILOSOPHY

## Why this game should feel good to play

Dense shmups only work when they are **legible under pressure**. Even when a game becomes overwhelming, the player still needs readable movement, readable threat classes, and readable reasons for each tool at their disposal. The point is not "make it easy." The point is **make the player's decisions informed**.

If a section kills the player, the player should eventually be able to say **why**.

## Survival is not the whole game

ProMeTheus opens *The Full Extent of the Jam* with what should be a north star for this project:

> "One thing I would like to stress is how much more fun STGs become when you play them for score instead of survival. I absolutely love scoring! Getting better and learning how to score means playing in a much, much more complex way. You will be playing with a plan in mind. Scoring opportunities will have to be balanced depending on how much risk they represent."

That doesn't mean the design should sneer at beginners. It means it should quietly teach them that the game opens up once they start asking different questions:

- not "How do I make it through?"
- but "Why is this wave ordered like this?"
- not "When should I panic?"
- but "What is the game rewarding me for doing?"

That is where the long tail is.

## Backgrounds are not wallpaper

From the *Shmup_Lyf Backgrounds* zine:

> "In shmups, backgrounds aren't just pieces of art we see but also places we go. They help, in large part, to tell the spatial narrative of a game. They build and bind sequences together to make a story -- an action adventure. To make us feel powerful, or infinitesimal. In the middle of history, or entirely alone."

Each environment type carries psychological weight. The black void is "where the monsters wait, the things that do not wish to be seen or understood." The enemy factory is "beyond the gates of the keep now, deep within the final stronghold." The final boss arena may exist "in an ura space, a place beyond space and time."

**Current state:** The PICO-8 version uses distinct starfield color palettes per level (black void -> blue -> green -> purple -> red -> chromatic chaos), which communicates progression but doesn't yet have foreground elements, terrain, or environmental storytelling. A future port's higher resolution would create room for real background art, parallax layers, and the kind of spatial narrative Marty_DYR describes.

### Background archetypes from the Shmup_Lyf Backgrounds zine

These are the genre's spatial vocabulary. Consider which apply to MurderCrab's five stages:

- **The Black** — infinite void and absence. Where we start. Pin pricks of distant stars as hope.
- **The Launchpad** — a birth, a beginning, a setting forth.
- **The Endless Metropolis** — faceless geometry, dehumanized, "fractal and endlessly repeatable."
- **Low Planetary Orbit** — humbling view of floating giants, perception of your own minuteness.
- **The Armada Battle** — epic grandness contrasted with your infinitesimal nature within it.
- **The Enemy Factory** — the bowels of the goliath, alone in the realm of the other.
- **The Nexus** — the throne of the monstrous god brain, the seat of power of the great evil.

## What a stage should teach

A stage is not just content. It is a lesson wrapped in rhythm.

From the *Cho Ren Sha 68k* zine, Marty_DYR highlights a stage design breakdown by forum user Durandal that should inform MurderCrab's level design:

> "introduction 1 -> break -> test 1 -> introduction 2 -> test 1 & 2 -> break -> test 1 & 2 climax. A stage with only introductions will fail to capitalize on anything, a stage with only tests doesn't bring anything new to the table, and a stage with constant climaxes without breaks or proper build-up will fail to properly end with a climax."

The takeaway: **use distinct enemies to create tests which overlap to make more difficult challenges, with breaks in between.** If you do this you have the makings of a strong enemy-centric rhythm and a story for a stage. Even without elaborate backgrounds, Cho Ren Sha 68k -- which uses the same parallax background throughout -- creates captivating stages purely through varied and structured enemy encounters.

---

# 5. SHMUP DESIGN PRINCIPLES

These are genre-level principles that should inform every design decision in *MurderCrab*.

## Legibility

Players must be able to read the screen under pressure. This means:
- Clear enemy silhouettes that communicate threat level at a glance
- Distinct bullet families that communicate behavior through shape/color
- Visible hitbox feedback (during focus, if added)
- Audio cues that reinforce visual information

## Silhouette hierarchy

From the *Cho Ren Sha 68k* zine:

> "In a lot, if not all, games the silhouette of an enemy is important for fast identification -- in shmups it's paramount due to the need to respond to the situation emerging on screen as soon as possible. Will you clear up the popcorn before spending time on the one that you know is going to be harder work because of its size? Or do you take that one out first while micro-dodging zaku fire because you know it's probably going to unload a nasty movement restricting spray if you give it too much of a chance?"

**Rule: Bigger means stronger.** Like all rules there are exceptions, but they should work because they play against the expectation. A big enemy that actually goes down easily gives a "Argh!!! Wait? oh thank God" feeling. Break this rule knowingly, not accidentally.

## Response feel

ProMeTheus is explicit about input: stick, pad, or keyboard are all valid. He personally believes keyboards are superior because "they're much faster at changing directions, and they're also better at tapping one direction very shortly multiple times." What matters is consistency and the ability to make fast, repeatable, low-panic corrections -- not dogma about "real" arcade input.

## Informed density

When the screen gets dense, the player still needs:
- Readable movement options
- Readable threat classes
- Readable reasons for using each tool (wide shot vs focused fire, bomb vs dodge)

The goal is not reduced difficulty. The goal is informed decision-making under pressure.

## The feeling of destruction

From the *Cho Ren Sha 68k* zine, on why explosions matter:

> CRS68k creator Yoshida-san wanted "the feeling of destruction" as a key part of the experience. His explosions "unpack like a fractal" -- a core 16x16 sprite animation repeated flipped, mirrored, and palette-swapped, triggered in a procedural layered cluster over a few frames. The lingering smoke cloud -- "a silhouette of flat colour that holds its shape for a few frames, unlike the rapid flash bang of the explosion, like the fumes of burning oil" -- is what makes the destruction feel weighty.

**Design takeaway for MurderCrab:** Boss explosions and bomb detonations should feel monumental even in 128x128. Lingering smoke/flash, screen shake, and layered sprite animations sell the "feeling of destruction."

---

# 6. COMBAT DESIGN REFERENCE

This section documents combat systems as both current implementation and aspirational targets. Items marked **[CURRENT]** exist in the PICO-8 cart. Items marked **[FUTURE]** are design goals for later revisions or a future port.

## Movement

**[CURRENT]** Fixed-speed digital movement at 2px/frame, 8-directional. No inertia. Tiny 2x2 hitbox centered on the 8x8 sprite.

**[FUTURE]** Consider a focus/slow mode: reduced movement speed with a visible hitbox indicator. This is the foundational affordance in bullet hell -- the relation between speed, damage, and precision. Fast movement to enter the lane, focus to own it.

> Source: Boghog highlights the fast-shot / slower-focus pairing as one of the foundational affordances of bullet hell design.

### Focus mode design notes

If focus is added:
- Should reduce speed by a fixed ratio (e.g. 50%)
- Should display a visible hitbox point on the ship
- Could alter damage profile (concentrated forward stream vs wider spread)
- Must not feel punishing to use -- it's a precision tool, not a handicap

## Shot

**[CURRENT]** Twin forward bullets on **Z**, using **`btnp`**: PICO-8 repeats the fire button while held (built-in repeat timing), so holding Z is already rapid fire without a separate autofire flag. No power levels, no spread change, no pierce.

**[FUTURE]** Consider a power-up progression system:
- Power levels that change spread, projectile count, or damage
- Power loss on death (partial or full)
- Recovery state is one of the most important emotional systems in any arcade shooter -- if added, the manual must explain exactly what is lost and what survives

### Shot design notes

> Manual wording should be blunt about recovery. Players need to know the stakes of dying beyond "try again." Loss of power makes death meaningful beyond the respawn.

## Bomb

**[CURRENT]** Full-screen clear + 30 damage to all bosses. Clears all bullets. 30-frame duration. 3 starting stock.

**[FUTURE]** Consider expanding bomb interaction:
- Bullet-to-item conversion (bullets destroyed by bomb become score pickups)
- Invulnerability window during bomb animation
- Score implications (bonus for not using bombs vs bomb-enabled scoring routes)

### Bomb doctrine

Bombs are not an apology. They are a conversion mechanic.

- Use bombs to preserve the run.
- Use bombs to convert impossible density into controllable space.
- Use bombs before death, not after regret.

From *The Full Extent of the Jam*:

> "Think of the bomb button as an emergency button, that you must press when you feel danger is extremely high and you are one second away from death... The best time to bomb is indeed less than one second before dangerous bullets reach your ship's hitbox."

> "Always bomb if you don't have a path through the bullets in your mind for the next second."

The ideal is to bomb as much as possible (never dying with bombs in stock), but also as little as possible (only in emergencies).

---

# 7. THREAT LANGUAGE FRAMEWORK

A good shmup teaches enemy meaning through shape and behavior. This framework defines the threat hierarchy that *MurderCrab* should build toward.

**Current state:** The PICO-8 version has one normal enemy type with weapon variants and a three-state behavior model. This framework is the roadmap for expansion.

## Tier 1: Popcorn

Weak enemies. Fast arrivals. Quick kills. Used to:
- Build rhythm
- Train lane control
- Reward route confidence
- Punish hesitation through clutter rather than raw HP

**MurderCrab flavor:** larvae, drones, shell fragments, tiny crab skitter-fighters.

## Tier 2: Midweight threats

Enemies that survive long enough to force a decision. Often the real stage teachers. They make the player choose between:
- Early deletion
- Bullet herding
- Point-blank aggression
- Route compromise

## Tier 3: Anchors / turrets / fixed threats

Static or semi-static enemies that shape the lane. They lock movement and force timing rather than just spraying extra bullets.

## Tier 4: Elite threats

Enemies that announce: **deal with me now or the stage gets worse.** These should have unmistakable silhouettes, obvious audio cues, and legible spawn timing.

## Bullet families

Suggested bullet families for future implementation:

| Family | Role | Visual |
|--------|------|--------|
| Needle shots | Speed pressure | Thin, fast |
| Shell pearls | Lane denial / density | Round, slow, many |
| Claw fans | Spread pressure | Wide arcs |
| Aimed darts | Streaming / herding lessons | Fast, directed |
| Slow bloom clusters | Trap construction | Expanding patterns |
| Crusher beams | Territory denial | Thick, lingering |

**Current state:** The PICO-8 version uses one bullet sprite for all enemy projectiles. Behavior varies (aimed, spread, spiral, radial) but visual distinction is limited by the 16-color palette and sprite constraints.

---

# 8. BOSS DESIGN DOCTRINE

## Principles

- **Opener must be readable.** A new player's first encounter should not feel random.
- **Phase changes must be announced.** Visual tells, audio cues, screen shake -- the player must know the rules changed.
- **Dense patterns must still contain logic.** Chaos is not difficulty. Unreadable patterns are bad patterns.
- **Death should feel educational, not arbitrary.** The player should learn something from every failed attempt.

## Boss page template

For each boss, documentation should cover:

### Visual profile
- Silhouette and scale
- Weak point presentation
- Phase change visual tells
- Intimidation factor

### Threat language
- Aimed or static openers
- Spread control
- Trap construction
- Desperation pattern behavior (rage mode)

### Survival note
What a new player must understand to live.

### Score note
What a scorer exploits for damage, item value, cancels, or timer reward.

## Current boss implementation notes

**Mini-bosses** are the first exam. They introduce the spiral and radial patterns at manageable density. Two phases. The transition is marked by screen shake and small explosions on the boss body.

**Final bosses** are the real test. Three phases, faster shoot intervals, all three pattern types in rotation. Palette-shifted to visually distinguish from mini-bosses.

**True last boss** is the graduation. Massive 4x4 sprite. Three phases with rage mode at the end. +10 bullets to every pattern in rage, visual aura, chromatic shifting. The only entity in the game that feels like it's fighting back with intent.

---

# 9. SCORE ATTACK PHILOSOPHY

## The run is a route

ProMeTheus on why route play works:

> "Because the game doesn't change from run to run, you have the possibility of making everything happen exactly the same from run to run, by executing the same sequence of actions every run. By doing this, you reduce the unpredictable to a minimum, and allow yourself, at each point in time, to put all of your focus on the one detail that you know is most dangerous for you at this moment."

> "You haven't looked directly at them, but you know they're here and exactly where they are. Therefore, you can concentrate on doing your best at dodging the bullets that are already near your hitbox."

A strong score run is repeated, not improvised. The game repeats from run to run, so the player's job is to find and stabilize a sequence of actions that makes survival and scoring as efficient as possible.

## Study replays

Do not fetishize ignorance. ProMeTheus is emphatic:

> "Do you think chess players learn to play by themselves, playing against themselves or against a few friends only, studying the game without outside help? No, they study the game in books, get help from chess teachers, take inspiration from their opponents' play, and from games that they spectate."

> "Stop thinking of the game as something you have to overcome all by yourself... Outside of that final high scoring run, any means, and I mean ANY, are good to practice and learn."

Routes are communal knowledge refined through shared observation. This project should actively encourage replay sharing and study.

## Score values must be transparent

The manual and in-game feedback should make scoring completely legible. Players should never have to guess what actions are worth points or what conditions affect their multiplier.

**Current scoring completeness checklist:**
- [x] Enemy kill value documented
- [x] Cherry pickup value documented
- [x] Boss kill values documented
- [x] Multiplier build rate documented
- [x] Multiplier reset conditions documented
- [x] End bonus formula documented
- [ ] No point-blank bonus system (future consideration)
- [ ] No bullet cancel conversion (future consideration)
- [ ] No stage-end bonus (future consideration)
- [ ] No no-miss / no-bomb reward (future consideration)

## Bombing and score

**Current state:** Bombing has no direct score penalty. It clears enemies (which awards kill points) and protects your multiplier by preventing deaths. Unused bombs contribute to the end bonus (25 points each).

**Design tension:** Bombing is currently score-positive (kills enemies for points, protects multiplier). This could be made more interesting:
- Bomb-converted bullets could spawn bonus pickups
- A no-bomb bonus per level could create a risk/reward decision
- Bomb damage to bosses could have a different point value than bullet damage

## Dodging techniques that should inform pattern design

These techniques from *The Full Extent of the Jam* should be considered when designing bullet patterns for MurderCrab. Good patterns are ones that reward these techniques; bad patterns are ones that can only be survived through luck.

| Technique | How it works | Design implication |
|-----------|-------------|-------------------|
| **Bottom line speed reduction** | Holding diagonal against the screen border reduces lateral speed | Spread patterns should be denser at the top and reward patient bottom-screen play |
| **Speed trick** | Moving perpendicular to the needed adjustment axis reduces speed on that axis | Aimed streams should leave room for orthogonal adjustment |
| **Moving with the flow** | Moving in the same direction as bullets buys time to find gaps | Dense curtains should have exploitable gaps that appear when moving with the flow |
| **Bullet herding** | Slow lateral bait, then fast arc near the source to spread the aimed stream | Aimed patterns should reward controlled movement and punish panicked zigzagging |
| **Changing location** | Identifying safer spots away from the bottom line | Patterns should not always be safest at the bottom -- reward spatial awareness |

**Pattern design rule:** Every dense pattern should have at least one technique that makes it tractable. If the only survival strategy is "hope for a gap," the pattern is bad.

## Resource routing

> Don't just ask whether a bomb saves you. Ask what that bomb preserves.

The best scoring play comes from understanding resource economics:
- A bomb that preserves a x5 multiplier is worth more than the 25-point end bonus
- A health pickup at 100 HP is worth 25 end-bonus points
- A cherry at x1 is worth 100 points; at x8 it's worth 800
- Getting hit to collect a cluster of cherries is almost never worth it -- the multiplier reset costs more than the pickups gain

---

# 10. PRACTICE DOCTRINE

This may be the single most important philosophy in the whole project.

## Practice mode is part of the game

If *MurderCrab* ever includes stage select, boss select, checkpoints, or any lab feature, the game should endorse their use openly.

ProMeTheus is categorical about this:

> "If you use 'my' way of practicing, I guarantee your results will improve at least four or five times faster than if you were not using saved states."

> "The poor Japanese players who played in arcades before DoDonPachi was playable on MAME had to practice this way. If they could have practiced differently, I'm sure they would have."

The *Shmup_Lyf Backgrounds* zine also references *Shmup Ascension* by Dace Anaxyrus as a book that changed the author's approach to practice. The core insight: "I had been playing by just sinking a single credit and trying to get as far as possible. I was thinking like I didn't deserve to get to learn later levels until I could get there cleanly... If I actually wanted to get better I could focus on getting good at all the levels simultaneously, not just building from the front. It's why practice modes and save states exist, and frankly it's just more fun."

## Practice ladder

1. Learn the survival route.
2. Isolate the wave that keeps killing you.
3. Drill the boss opener until it stops feeling surprising.
4. Reconnect checkpoints into longer segments.
5. Return to full runs only after consistency improves.

ProMeTheus recommends spending at least 80% of time in practice mode and no more than 20% doing full scoring runs.

## Learn what you cannot do

> "Don't practice what you can do, practice what you can't do. If a hard section is preceded by 20 seconds of gameplay that you already kind of master, cut those 20 seconds out by saving after them and practice only the next seconds."

> "Don't be afraid to repeat a 10 or even 5 seconds detail many times in a row to get it down."

## Nerves

When the PB pace appears:

> "Breathing deeply when you start getting nervous helps a great deal... Something else linked to nervousness is starting to think about 'what ifs.' What if I screw up at the boss? What if I don't and make a huge score? What are they going to say about it on the forum? Chase those thoughts out of your mind as soon as they come, and concentrate on the game!"

> "To help yourself focus, you can try picturing your next few actions in your mind as you play. This will keep your mind busy thinking about what you are doing and prevent it from straying."

Also: don't play when sick, depressed, or physically exhausted. Cold hands affect precision -- warm up before serious runs.

## Tracking progress

From *The Full Extent of the Jam*:

> "As soon as you start doing your final runs, create a little text file in which you shortly document each run that you play. Number the replay files, and write down in which stage you died first, and what kind of mistake you did."

> "Every fifty runs or so, look back... make statistics. In how many runs did you pass the first loop without dying? In how many runs did you die at this really critical part? Looking at these statistics is good for you to keep track of how feasible your goal really is, and also to keep track of your progress, which is not represented by your best score."

This is a design insight too: the game could build in run-tracking or statistics features.

---

# 11. GLOSSARY

Standard shmup terminology for reference. This language should be used consistently in documentation, comments, and design discussion.

**1CC** — One credit clear. Beat the game without continuing.
**Bomb** — Emergency or tactical resource that clears danger and/or deals damage.
**Bullet cancel** — When bullets are erased, often producing score or items. A core scoring component in many shmups.
**Bullet hell / Danmaku** — High-density shooter style centered on large projectile counts and pattern reading.
**Bullet herding** — Baiting aimed shots into a controlled portion of the screen so the rest stays safer.
**Capture** — Clear a pattern or boss without getting hit or spending safety resources.
**Caravan** — Short-form score attack play, often two to five minutes, designed for intense competition.
**Extend** — Extra life.
**Focus** — Reduced-speed movement / concentrated attack state.
**Micrododge** — Tiny movement through dense or tight bullet spacing.
**PB** — Personal best.
**Point-blank** — Attacking from very close range for extra damage or score value.
**Popcorn** — Weak enemies intended to die quickly and establish stage rhythm.
**Route** — A planned sequence of actions through a stage or full game.
**Safespot** — A stable location inside or around a pattern.
**Streaming** — Dragging aimed shots into lines through steady movement.
**Superplay** — High-level replay or demonstration run.
**Tate** — Vertical screen orientation.

### MurderCrab-specific terms

| Term | Meaning |
|------|---------|
| Attract mode | Idle title screen. Cycles logo, high scores, how-to-play. The cabinet at rest. |
| Credit | A quarter. 3 per session. 1 to start, 1 to continue. |
| Cherry | Score powerup (sprite 7). Builds streak toward multiplier |
| Streak | Cherry collection counter. 10 cherries = +1 multiplier |
| Multiplier | Score multiplier. Resets on hit. The core scoring mechanic |
| Warp | Level transition animation. 6-second sequence between stages |
| Loop / NG+ | Replaying all 5 stages at higher difficulty after beating TLB. Same credit. |
| TLB | True last boss. Level 6 encounter. Requires no-continue clear |
| Rage mode | TLB phase 3. +10 bullets to all patterns. Visual aura |
| Boss warning | 3-second flashing "! WARNING !" before boss spawn |
| Kamikaze | Normal enemy state 2. Locks onto player and dives |

---

# 12. FUTURE FEATURES

Everything the first-pass manual assumed that doesn't exist yet but could. This is the wishlist -- some may fit on the PICO-8 cart, others are for a future port.

## Combat expansion

- [ ] **Focus mode** — Slow movement + visible hitbox + concentrated fire. The single biggest missing affordance from the bullet hell playbook.
- [ ] **Power levels** — Weapon progression through pickups. Wider spread, more projectiles, or more damage per level. Partial loss on death for stakes.
- [ ] **Turbo / cadence option** — PICO-8 already repeats Z while held via `btnp`; optional faster fixed cadence or toggle for players who want a different rhythm than the default repeat rate.
- [ ] **Point-blank bonus** — Extra damage or score for attacking at close range. Rewards aggression.
- [ ] **Bullet cancel conversion** — Boss/bomb kills convert bullets to score items. Creates bomb-routing and risk/reward depth.

## Enemy expansion

- [ ] **Popcorn enemies** — Fragile, fast, arrive in waves. Build rhythm. Die in one hit regardless of loop.
- [ ] **Turret enemies** — Static or slow-moving. Shape the lane. Force timing.
- [ ] **Elite enemies** — Unmistakable silhouettes, high priority. "Kill me now or the stage gets worse."
- [ ] **Bullet families** — Visually distinct projectile types (needles, pearls, fans, darts, blooms, beams) that communicate behavior through appearance.
- [ ] **Side-entry enemies** — Enter from screen edges, not just the top. Force lateral awareness.

## Stage expansion

- [ ] **Stage names and theming** — Each level should have a name and identity beyond "Level N"
  - Working concepts: Edge of the Shellfield / Shell Reef / Biomech Corridors / Cruel Approach / Hive Core
- [ ] **Background art** — Foreground/midground elements, environmental storytelling.
- [ ] **Stage-specific mechanics** — Environmental hazards, destructible terrain, scrolling obstacles.
- [ ] **Stage-end bonus** — Points for speed, no-miss, no-bomb, or other per-stage criteria.

## Scoring expansion

- [ ] **Chain system** — Kill enemies within a time window to maintain a chain counter.
- [ ] **Medal / hidden item system** — Discoverable score items that reward exploration or specific kill orders.
- [ ] **No-miss / no-bomb bonus** — Per-stage or per-boss rewards for clean play.
- [ ] **Replay recording** — Save and share runs for community study.

## Arcade flow refactor

- [ ] **Collapse menu into attract mode** — Title screen cycles: logo, high scores, how-to-play. Press start to play. No menu.
- [ ] **Post-game initials entry** — When your run ends and your score qualifies, enter initials right there. No pre-game initials screen.
- [ ] **Attract mode → game → initials → attract mode** — The full loop. Game over always returns to attract. No intermediate menu.
- [ ] **Attract mode cycling** — Title logo (3-4 sec) → high score table (3-4 sec) → controls/how-to-play (3-4 sec) → repeat. Starfield scrolls. Music plays.

## Quality of life

- [ ] **Practice mode** — Stage select, boss select, checkpoint restart. Endorsed by the game itself.
- [ ] **Caravan mode** — 2-minute or 5-minute score attack. Arcade competition format.
- [ ] **Input display** — Show button presses on screen during replay.
- [ ] **Detailed score breakdown** — Per-stage scoring summary at end of run.

## Lore and flavor

- [ ] **Player ship name**
- [ ] **Faction terminology** — Name the crab swarm, the hive, the player's organization
- [ ] **Boss names** — Each boss should have a designation
- [ ] **Enemy class names** — Official names for each enemy type
- [ ] **Hive/infestation language** — Consistent terminology for the world

---

# 13. SOURCES AND REFERENCES

All primary source PDFs are stored in `docs/reference-library/` for direct consultation.

---

## *The Full Extent of the Jam* — Dimitri "ProMeTheus" Aupetit (2010)

**File:** `reference-library/Full Extent of the Jam (English).pdf`

A 44-page guide to playing shooting games competitively, written by the occidental DoDonPachi record holder (547M, 2-ALL with spare lives after ~600 hours of play). Uses DoDonPachi as primary example but principles apply universally.

### Key concepts for MurderCrab

- **Score play is the real game.** Scoring forces complex, planned play. Survival is just the prerequisite.
- **Route play.** The game repeats, so the player's job is to find, stabilize, and repeat a scoring sequence.
- **Replay study is not cheating.** Routes are communal knowledge. "Outside of that final high scoring run, any means, and I mean ANY, are good to practice and learn."
- **Targeted practice.** Saved states / stage select = 4-5x faster improvement. "Don't practice what you can do, practice what you can't do."
- **Emergency bombing.** "Always bomb if you don't have a path through the bullets in your mind for the next second."
- **Nerves.** Breathe, chase out "what if" thoughts, picture your next actions to stay focused.
- **Input.** Stick, pad, keyboard all valid. Consistency > dogma. ProMeTheus holds the record on keyboard.
- **Progress tracking.** Document every run. Track statistics per 50-run block.
- **The music analogy.** A full shmup run is like playing a 45-minute song. You decompose it, practice the hard bars, reassemble.
- **80/20 rule.** 80% practice mode, 20% full scoring runs.

### Technique library from the guide

| Technique | Description |
|-----------|-------------|
| Lower Speed on Bottom Line | Diagonal input against screen border reduces lateral speed for precision |
| Changing Location | Identify safer spots you can't reach from the bottom line |
| Speed Trick | Moving perpendicular to your needed adjustment reduces speed in that axis |
| Moving With the Flow | Move in the same direction as bullets to buy time finding gaps |
| Bullet Herding | Bait aimed shots slowly, then make a fast arc near the source to spread density |
| Emergency Bombing | Bomb when you have no visible path for the next second |

### The Shmup Story

ProMeTheus also includes a personal narrative (Section IV) tracking his progression from beginner to record holder, including tournament wins (Guwange tournament at Arcade Extreme, 49.8M from 100 hours of practice against established players), community meets (London, Milan, Paris, Toulouse), and a TV appearance on NoLifeTV's "Superplay" show. This demonstrates the community dimension of competitive shmup play -- congratulations, shared replays, travel to meets, and mutual improvement.

---

## *Shmup_Lyf* Zine Series — Marty_DYR

A series of fan publications covering shmup visual design, game design, culture, collecting, doujin history, and creative philosophy. Richly illustrated. All issues stored in `reference-library/`.

### Issues in the library

| File | Focus |
|------|-------|
| `Shmup_Lyf Zine #01 - MagCloud (1).pdf` | First issue, general coverage |
| `Shmup_Lyf Zine #02 - Metaphor (1).pdf` | Phenomenological / metaphorical analysis of shmup experiences |
| `Shmup_Lyf Zine SP - Doujins - MGCL (1).pdf` | Doujin shmup special |
| `Shmup_Lyf Zine - Backgrounds.pdf` | Background art as spatial storytelling |
| `Shmup_Lyf Zine - ChoRenSha68k (3).pdf` | Deep dive on Cho Ren Sha 68k |
| `Shmup_Lyf Zine - DoDonpachi (1).pdf` | DoDonPachi coverage |
| `Shmup_Lyf Zine - Dezaemon Dimensions (1).pdf` | Dezaemon shmup creation tool |
| `Shmup_Lyf Zine - Doujin Depths.pdf` | Doujin deep dives |
| `Shmup_Lyf Zine - Doujin Discordancy (2).pdf` | More doujin coverage |

### Key concepts from the Backgrounds issue

- **Backgrounds are places you go**, not just art you see. They tell the spatial narrative.
- **Each environment archetype carries psychological weight.** The Black = void/fear. The Sky = freedom. The Port = military industrial. The Metropolis = dehumanized geometry. The Enemy Factory = you're alone in the realm of the other. The Nexus = the seat of power.
- **Perceptual skullduggery.** The one-plane paradox (forward fire that hits both aircraft and ground tanks). Isometric lean from Japanese animation. Camera tilt from ground-tracking to space.
- **"Scramble Kit Bashing."** Reusing a common asset set (from STG Builder) creatively, like physical model kit-bashing. Demonstrates that what you do with assets matters more than their origin.
- **PICO-8 as emerging shmup platform.** The zine covers several PICO-8 shmups (Kalikan, Steel Surge: Revolution, "not sid meier's Danmaku") and notes "the galaxy of Pico8 is increasingly becoming a place of shmup emergence."
- **Background work is the "unsung hero of the genre"** -- a great place to tell the story without traditional narrative tools.
- **BIRDCAGE interview.** Insight from dev Giannis: "I'm constantly surprised at how fun it is to simply avoid projectiles. There's something about the direct connection between your ship and your reflexes that makes you feel incredible when you weave through bullet patterns."
- Sound design insight from Barry: "Even getting a placeholder sound in place to attach to a mechanic can add so much tactility to a player action."

### Key concepts from the Cho Ren Sha 68k issue

- **Enemy design: bigger means stronger.** Break the rule knowingly for surprise tension/release.
- **Stage rhythm formula.** "introduction -> break -> test -> introduction 2 -> test 1 & 2 -> break -> test 1 & 2 climax." Stages need all three: introductions, tests, and breaks.
- **Telling a story with enemies.** Even with a repeating background, CRS68k creates compelling stages through "varied and structured enemy encounters" using distinct enemy types that push the player around the screen in specific ways.
- **The art of detonation.** Explosions as fractal layered sprite animations. Palette swaps, flip/mirror variants, procedural clustering, lingering smoke clouds. "Pretty kaboom make good."
- **Invincibility frames as design tool.** Brief invulnerability on item pickup creates tactical opportunities beyond mere collection.
- **Rapid fire as tactile design.** CRS68k creator Yoshida-san considered the feeling of rapid-fire input to be "one of the chief pleasures of STG games."
- **Toaplan as foundation.** CRS68k's default scoreboard names are all Toaplan games. Left-right alternating enemy patterns, twin bosses, ominous eye motifs, and the powering-up system all trace back to Toaplan design language. But CRS68k stepped beyond Toaplan by incorporating Batsugun-era bullet hell elements: no death restart, less memorization dependence, more improvisational dodging.
- **Iterative development.** CRS68k appeared in incremental versions at successive Comiket events (C47 through C54, 1994-1998), shaped by community feedback through BBS forums. The game was developed "in conversation with" contemporary arcade releases like DonPachi, DoDonPachi, and Battle Garegga.

---

## *Cave Shooting Artworks*

**File:** `reference-library/Cave Shooting Artworks.cbz`

Visual reference for Cave's art direction across their shmup catalog. Useful for boss design, enemy design language, and the visual standards of the genre's most influential studio.

---

## *MurderCrab First Pass Manual* — Original research document

**File:** `reference-library/MurderCrab_First_Pass_Manual.md`

The original research document that prompted the creation of this design reference and the separate game manual. Contains a mix of accurate game documentation and aspirational design goals. Preserved as a historical artifact of the project's early design thinking.

---

## Additional referenced works

| Source | Description |
|--------|-------------|
| Boghog | Danmaku design guide -- readability under density, foundational player affordances |
| *Shmup Ascension* — Dace Anaxyrus | Mindset guide for competitive shmup play. Referenced in the Backgrounds zine |
| Shmups Forum / Shmups Wiki | Community glossary, technique documentation, shared language |
| DoDonPachi @ Bee Preying (Bernard Doria) | DDP rules and scoring system reference |
| Lazy Devs PICO-8 Shmup Tutorial | PICO-8 shmup development tutorials. Credited by Marty_DYR as catalyzing the PICO-8 shmup scene |
| shmuplations.com | Translated developer interviews and notes, including CRS68k dev notes by Yoshida-san |

---

> This document is a living reference. Update it as the game evolves.
> The game should always be able to answer: **what is it rewarding the player for doing?**
