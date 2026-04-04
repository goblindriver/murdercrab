# MURDERCRAB! DESIGN REFERENCE

## Source of Truth for What We're Building

This document preserves shmup genre research, design philosophy, and aspirational goals for the *MurderCrab* project. It draws from the first-pass manual research and serves as the guiding vision -- particularly for the Picotron port, where PICO-8's constraints no longer apply.

**This is not the game manual.** For how the game actually works today, see [manual.md](manual.md). This document is about *why* the game is built the way it is and *where it should go*.

---

## CONTENTS

1. Project Identity
2. Design Philosophy
3. Shmup Design Principles
4. Combat Design Reference
5. Threat Language Framework
6. Boss Design Doctrine
7. Score Attack Philosophy
8. Practice Doctrine
9. Glossary
10. Future Features
11. Sources and References

---

# 1. PROJECT IDENTITY

## Core identity

- **Platform origin:** PICO-8 fantasy console (128x128, 16 colors, 8192 tokens)
- **Platform target:** Picotron port planned (480x270, 64 colors, no token limit)
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

---

# 2. DESIGN PHILOSOPHY

## Why this game should feel good to play

Dense shmups only work when they are **legible under pressure**. Even when a game becomes overwhelming, the player still needs readable movement, readable threat classes, and readable reasons for each tool at their disposal. The point is not "make it easy." The point is **make the player's decisions informed**.

> Source: Boghog's danmaku design guide stresses that readability under density is the core constraint of bullet hell design.

If a section kills the player, the player should eventually be able to say **why**.

## Survival is not the whole game

Shmups become richer when played for score, because scoring forces more deliberate, more complex play than vague survival improvisation.

That doesn't mean the design should sneer at beginners. It means it should quietly teach them that the game opens up once they start asking different questions:

- not "How do I make it through?"
- but "Why is this wave ordered like this?"
- not "When should I panic?"
- but "What is the game rewarding me for doing?"

That is where the long tail is.

> Source: *The Full Extent of the Jam* (ProMeTheus) makes this point directly: score play means balancing risk and reward while performing a learned sequence rather than improvising your whole way through.

## Backgrounds are not wallpaper

Backgrounds tell the **spatial story** of a run and affect how a player experiences scale, danger, and transition. In shmups, backgrounds are places you go, not just textures under bullets.

If *MurderCrab* moves from open void to shell reef to biomech corridors to a final hive-core, the experience should not flatten those spaces into "Stage 1 / Stage 2 / Stage 3." Each stage should teach the player what kind of place it is and how that changes the psychological read of the action.

> Source: Marty_DYR's *Shmup_Lyf* work makes this point about backgrounds as spatial storytelling.

**Current state:** The PICO-8 version uses distinct starfield color palettes per level (black void -> blue -> green -> purple -> red -> chromatic chaos), which communicates progression but doesn't yet have foreground elements, terrain, or environmental storytelling. The Picotron port's higher resolution creates room for real background art.

## What a stage should teach

A stage is not just content. It is a lesson wrapped in rhythm.

The best shmup design keeps circling back to this: stages are memorable not only because of background art or music, but because each one changes what the player has to understand. The manual should keep asking, stage by stage: **what is this section trying to make the player better at?**

> Sources: Marty_DYR frames this as spatial and experiential storytelling. Community glossary and strategy discourse frame it as route literacy.

---

# 3. SHMUP DESIGN PRINCIPLES

These are genre-level principles that should inform every design decision in *MurderCrab*.

## Legibility

Players must be able to read the screen under pressure. This means:
- Clear enemy silhouettes that communicate threat level at a glance
- Distinct bullet families that communicate behavior through shape/color
- Visible hitbox feedback (during focus, if added)
- Audio cues that reinforce visual information

> Source: Boghog's guide argues that even classic dense danmaku should be built from readable fundamentals and clear player tools, not arbitrary chaos.

## Silhouette hierarchy

Enemy silhouette is paramount. The player must decide instantly what needs to be deleted first. Larger forms generally imply more commitment and threat unless the design is intentionally subverting that expectation.

> Source: Marty_DYR's *Cho Ren Sha 68k* zine spells this out -- enemy readability through silhouette is a foundational shmup design principle.

## Response feel

A shmup lives or dies on response feel. Stick, pad, or keyboard are all valid, and consistency matters more than dogma about "real" arcade input. Quick directional reversals and short taps are what matter functionally.

> Source: *The Full Extent of the Jam* is explicit here -- use whatever input lets you make fast, repeatable, low-panic corrections.

## Informed density

When the screen gets dense, the player still needs:
- Readable movement options
- Readable threat classes
- Readable reasons for using each tool (wide shot vs focused fire, bomb vs dodge)

The goal is not reduced difficulty. The goal is informed decision-making under pressure.

---

# 4. COMBAT DESIGN REFERENCE

This section documents combat systems as both current implementation and aspirational targets. Items marked **[CURRENT]** exist in the PICO-8 cart. Items marked **[FUTURE]** are design goals for the Picotron port or later revisions.

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

**[CURRENT]** Twin forward bullets, tap-to-fire. No power levels, no spread change, no pierce.

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

> Source: *The Full Extent of the Jam* treats bombing as a skill: the player should bomb when they no longer have a path for the next second of play, rather than hoard resources and die with stock in reserve.

---

# 5. THREAT LANGUAGE FRAMEWORK

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

**Current state:** The PICO-8 version uses one bullet sprite for all enemy projectiles. Behavior varies (aimed, spread, spiral, radial) but visual distinction is limited by the 16-color palette and sprite constraints. The Picotron port should differentiate bullet families visually.

---

# 6. BOSS DESIGN DOCTRINE

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

# 7. SCORE ATTACK PHILOSOPHY

## The run is a route

A strong score run is repeated, not improvised. The game repeats from run to run, so the player's job is to find and stabilize a sequence of actions that makes survival and scoring as efficient as possible.

> Source: *The Full Extent of the Jam* is especially strong on this: competitive shmup play is executing a plan under pressure, adjusting only where the plan breaks.

## Study replays

Do not fetishize ignorance. Using stronger players' replays to learn routes is not cheating. Routes are communal knowledge refined through shared observation.

> Source: ProMeTheus explicitly rejects the idea that replay study is cheating, comparing shmup study to chess study.

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

## Resource routing

> Don't just ask whether a bomb saves you. Ask what that bomb preserves.

The best scoring play comes from understanding resource economics:
- A bomb that preserves a x5 multiplier is worth more than the 25-point end bonus
- A health pickup at 100 HP is worth 25 end-bonus points
- A cherry at x1 is worth 100 points; at x8 it's worth 800
- Getting hit to collect a cluster of cherries is almost never worth it -- the multiplier reset costs more than the pickups gain

---

# 8. PRACTICE DOCTRINE

This may be the single most important philosophy in the whole project.

## Practice mode is part of the game

If *MurderCrab* includes stage select, boss select, checkpoints, or any lab feature (especially in the Picotron port), the game should endorse their use openly. Isolated drilling is vastly faster than replaying easy sections endlessly just to revisit the one part you still fail.

> Source: *The Full Extent of the Jam* argues that targeted practice is the single biggest accelerator of improvement.

## Practice ladder

1. Learn the survival route.
2. Isolate the wave that keeps killing you.
3. Drill the boss opener until it stops feeling surprising.
4. Reconnect checkpoints into longer segments.
5. Return to full runs only after consistency improves.

## Learn what you cannot do

**Don't practice what you can already do.** Practice the exact detail you still fail. Cut dead time. Drill the hard thing.

> Source: ProMeTheus's strongest line of advice is basically this -- stop replaying easy sections to feel good and start spending time on the thing that kills you.

## Nerves

When the PB pace appears:
- Breathe
- Stop thinking about the ending
- Play the next pattern

> Source: *The Full Extent of the Jam* discusses warm-up, breathing, and shutting down "what if" thinking during live runs.

---

# 9. GLOSSARY

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
| Cherry | Score powerup (sprite 7). Builds streak toward multiplier |
| Streak | Cherry collection counter. 10 cherries = +1 multiplier |
| Multiplier | Score multiplier. Resets on hit. The core scoring mechanic |
| Warp | Level transition animation. 6-second sequence between stages |
| Loop / NG+ | Replaying all 5 stages at higher difficulty after beating TLB |
| TLB | True last boss. Level 6 encounter. Requires no-continue clear |
| Rage mode | TLB phase 3. +10 bullets to all patterns. Visual aura |
| Boss warning | 3-second flashing "! WARNING !" before boss spawn |
| Kamikaze | Normal enemy state 2. Locks onto player and dives |

---

# 10. FUTURE FEATURES

Everything the first-pass manual assumed that doesn't exist yet but could. This is the wishlist for the Picotron port and beyond.

## Combat expansion

- [ ] **Focus mode** — Slow movement + visible hitbox + concentrated fire. The single biggest missing affordance from the bullet hell playbook.
- [ ] **Power levels** — Weapon progression through pickups. Wider spread, more projectiles, or more damage per level. Partial loss on death for stakes.
- [ ] **Auto-fire option** — Toggle or hold-to-fire. Reduces RSI, lets player focus on movement.
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
- [ ] **Background art** — Foreground/midground elements, environmental storytelling. Picotron's resolution supports real parallax backgrounds.
- [ ] **Stage-specific mechanics** — Environmental hazards, destructible terrain, scrolling obstacles.
- [ ] **Stage-end bonus** — Points for speed, no-miss, no-bomb, or other per-stage criteria.

## Scoring expansion

- [ ] **Chain system** — Kill enemies within a time window to maintain a chain counter.
- [ ] **Medal / hidden item system** — Discoverable score items that reward exploration or specific kill orders.
- [ ] **No-miss / no-bomb bonus** — Per-stage or per-boss rewards for clean play.
- [ ] **Replay recording** — Save and share runs for community study.

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

# 11. SOURCES AND REFERENCES

Research sources that informed the design philosophy of this project. These should be consulted when making design decisions, especially for the Picotron port.

## *The Full Extent of the Jam* — ProMeTheus

Shmup strategy guide covering competitive play philosophy. Key topics:
- Score play as a fundamentally different (and richer) mode of engagement than survival
- Route-based play: the game repeats, so the player's job is to learn and stabilize a sequence
- Replay study as legitimate and recommended practice (compared to chess study)
- Emergency bombing as a skill: bomb when you have no path, not when you're already dead
- Targeted practice: drill the thing that kills you, stop replaying easy sections
- Nerves management: breathe, stop future-thinking, play the next pattern
- Input consistency matters more than input type

## Boghog — Danmaku design guide

Design reference for bullet hell game construction. Key topics:
- Readability under density is the core constraint
- Even overwhelming screens need readable movement, threat classes, and tool usage
- The fast-shot / slower-focus pairing as a foundational player affordance
- Dense patterns should be built from readable fundamentals, not arbitrary chaos
- Player decisions should be informed, not lucky

## Marty_DYR — *Shmup_Lyf* and *Cho Ren Sha 68k* zine

Fan publications covering shmup visual design, game design, culture, and history. Key topics:
- Backgrounds as spatial storytelling, not decoration
- Enemy silhouette as paramount for instant threat reading
- Larger forms imply commitment and threat (break this rule knowingly, not accidentally)
- Stages as experiential and spatial stories, not just content containers

## Shmups Wiki

Community reference for genre terminology and technique. Key topics:
- Standard glossary (1CC, bullet cancel, herding, streaming, caravan, etc.)
- Technique documentation (micrododging, streaming, safespots)
- Bullet cancel as a core scoring component in many designs
- Shared language that enables community knowledge transfer

---

> This document is a living reference. Update it as the game evolves.
> The game should always be able to answer: **what is it rewarding the player for doing?**
