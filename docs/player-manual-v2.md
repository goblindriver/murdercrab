# MURDERCRAB!

## Pilot's Manual — Issue 1

> **8-bit shell. 16-bit attitude. Arcade doctrine.**

> *Designer note. This document is structured as a 12-page booklet plus front cover, inside-front, foldout poster, inside-back fanart page, and back cover. Image slots are tagged `[IMG: filename]` for assets already in hand or `[IMG: NEEDS-GEN-NN — short brief]` where they still need to be made. Real PICO-8 sprite rips are tagged `[SPRITE: filename]` and should be displayed at large pixelated scale (4×–8× nearest-neighbor) in the period-manual style. Page breaks are marked `---`. Pepper plants for retroactive lore (working-class read, MC2 reveal) are minimal and intentional — see notes at the end.*

---

## FRONT COVER

[IMG: hero_triptych.png]

> **MURDERCRAB!**
>
> *Five Stages of Shell-Born Murder*

---

## INSIDE FRONT — MISSION BRIEF

[IMG: murdercrab_defeat.png]

**The outer shells have opened.**

At the edge of charted space, broken stations became nesting ground for a mechanized crab-host: waves, cruel geometries, strongholds that molt and harden.

One compact craft answers — **HELLCAT** — enough output and a pilot mad enough to fly it into the choke.

> *Field note. The enemy does not advance like an army. It spreads like a bad idea.*

### WARNING TO NEW PILOTS

> Stay alive long enough to **understand the stage**.
>
> Learn **why the stage is built the way it is**.
>
> Then **turn survival into authority**.

Clearing proves you can live. A route proves you can drive.

---

> *Issued under contract for distribution at licensed amusement halls. Pilot Field Manual, Issue 1. Excerpts from after-action transcripts have been included where instructive.*

---

## PAGE 1 — MEET THE PILOT

[IMG: ace.png]

### CALLSIGN: **ACE**

The contractors did not pick him for his judgment.

The man with the helmet under his arm has done six tours through unsanctioned space, lost two ships before this one, and walked away from both wrecks grinning. **Reckless. Cocky. Fast in the cockpit.** He flies like he is being watched, because he usually is — by the people paying him, and by everyone else who heard about the people paying him.

> *Field note. Command calls it signal traffic. The pilots who sit too long with it stop calling.*

ACE does not sit with it. ACE drives forward.

This is his run. The crab-host took a chunk out of the mapped frontier and the contractors needed someone with a low survival probability and a very high upside. They needed someone who would not ask the second question.

You are flying him now.

---

## PAGE 2 — MEET THE SHIP

[IMG: ace_diagram.png]

### **HELLCAT** — single-pilot interceptor

| Spec | Value |
| --- | --- |
| Class | Compact strike interceptor |
| Crew | 1 |
| Primary armament | Twin forward bullet emitters |
| Secondary | Bomb dispersal field, 3 rounds standard |
| Powerplant | Twin plasma scramjets, augmented |
| Hitbox profile | 2×2 px center; 8×8 outer shell |

HELLCAT is on loan. You did not buy it. You will return it, ideally in better shape than the wreckage of the two ships before it. The contractors invoice damage. They invoice the airframe by the gram.

**Internals.** Center cockpit. Reactor stack behind the seat. Weapon emitters mounted to either side of the nose, with the bomb dispersal coil seated below the floor pan. Twin scramjets exhaust through the rear. Read the cutaway above and remember: **none of it is replaceable in the field.**

> *Pacification doctrine, §4. The pilot does not own the airframe. The airframe does not belong to the pilot. Damage incurred during pacification operations is invoiced at the contractor's discretion.*

---

## PAGE 3 — HOW THE CABINET WORKS

[IMG: laura_and_arcade.png]

Think in quarters. You get **3 credits** every time you visit the title screen — 1 to start, up to 2 more as harsh continues.

The title screen IS the menu. Three phases cycle every six seconds: logo with a boss tease, the high-score table, and a how-to-play card. **Press any button** to spend a credit and warp into Stage 1.

When you die, **GAME OVER** appears with a 10-second countdown. After a one-second grace, **Z** continues (costs 1 credit, restores 3 HP, multiplier resets) or **X** quits. Any continue locks you out of the true last boss for the rest of the run. Timer expires? The run ends.

If your final score lands in the top 3, you go to **enter initials**. Otherwise the game returns you to attract mode. Credits reset to 3.

After beating the true last boss, **Z** starts the next loop on the same credit. **X** ends the run.

[IMG: NEEDS-GEN-01 — small inset flow-chart diagram, sized for the bottom-right of this page, in the same blue-print style as IMG-NN earlier prompts. Boxes: ATTRACT → CREDIT → STAGE 1 → DEATH → CONTINUE/QUIT → INITIALS → ATTRACT, with NG+ loop arrow.]

---

## PAGE 4 — CONTROLS

[IMG: NEEDS-GEN-02 — D-pad and Z/X button line-art with directional fan, in the same mecha-technical style as ace_diagram.png. Hand-lettered margin callouts.]

| Input | Action |
| --- | --- |
| Arrow keys / D-pad | Move |
| **Z** | Shoot — hold for rapid fire |
| **X** | Bomb |

Movement is fixed at one pixel per frame, eight directions, no inertia. Your hitbox is a tight **2×2 box** centered in the 8×8 ship sprite — you will thread gaps that look impossible.

**Kamikaze rams use the full 8×8 sprite.** Bullet threading and dive-dodging are not the same puzzle.

There is no focus mode. No charge shot. Three inputs. That's the cockpit.

---

## PAGE 5 — HUD READOUT

[IMG: NEEDS-GEN-03 — annotated game-screen mock at booklet scale. Use the actual sprite rips below for content; we just need the screen frame, the bullet patterns visible, and the leader-line callouts going out to the margins.]

**Screen elements**

| Element | Sprite | Meaning |
| --- | --- | --- |
| **Player ship** | [SPRITE: player_idle.png] | Your HELLCAT |
| **Enemy** | [SPRITE: enemy_normal_f1.png] | The host |
| **Enemy bullet** | [SPRITE: enemy_bullet.png] | Touch it, lose HP and your multiplier |
| **Cherry pickup** | [SPRITE: pickup_cherry.png] | Score and streak |
| **Health pickup** | [SPRITE: pickup_health.png] | +1 HP |
| **Bomb pickup** | [SPRITE: pickup_bomb.png] | +1 bomb |

**HUD positions**

| Element | Where | Notes |
| --- | --- | --- |
| **Score** | Top-left | Current score, comma-formatted |
| **Hi-Score** | Top-right | Best on the board. Flashes gold when you beat it. |
| **Multiplier** | Below score | Cherry icon + current x-value |
| **Health** | Bottom-left | One ship icon per HP. Shows up to 10. |
| **Bombs** | Bottom-right | One bomb icon per bomb in stock |

**Boss warning.** Three seconds of flashing red and yellow at center screen. A boss is about to spawn. Don't be in the lane.

**Game over overlay.** The countdown lives mid-screen with remaining credits and seconds. After the grace period, **Z** continues or **X** quits.

---

## PAGE 6 — BOMB, HEALTH, INVINCIBILITY

[IMG: NEEDS-GEN-04 — bomb detonation painting, HELLCAT at center of expanding shockwave, in the painterly cinematic style of murdercrab_defeat.png and legion_attacks.png. Comic impact lines + chained explosions.]

### BOMB

Press **X**. Requires at least one bomb in stock.

In a single second the bomb clears every enemy bullet, every player bullet, every normal enemy on screen, deals **30 damage** to every boss on screen, throws expanding rings out from your ship, and shakes the cabinet.

> *Bombs are not an apology. They are a conversion mechanic. Use them before death, not after regret.*

### HEALTH

You start at **3 HP**. Every hit costs 1. Health pickups restore 1. There is no max cap — pickups can take you above 3.

> *The cost of getting hit is not the 1 HP. It's the multiplier you drop and the rank you lose.*

### INVINCIBILITY

After any hit, you flicker for 1 second and cannot be hit again. Use the window to reposition.

---

## PAGE 7 — THE RANK SYSTEM

[IMG: NEEDS-GEN-05 — three HELLCAT ships in a row, green / yellow / red tints, bullet trails progressively longer, in the same mecha-technical style as ace_diagram.png. Clean spec-sheet layout with empty stat boxes the designer can fill.]

Rank is the heart of MurderCrab. It runs from **0 to 10**, makes you stronger, and makes the game harder *at the same time*.

**Rank rises** to track your multiplier. The higher your multiplier climbs, the higher rank goes — and rank is **sticky**. Multiplier resets do not pull rank down.

**Rank falls** only when you take a hit: −1 per hit, never below 0.

### Rank tiers

| Rank | Damage | Visual |
| --- | --- | --- |
| **0 – 3** | Standard shots | Green ship, no bullet trail |
| **4 – 6** | Stronger shots | Yellow tint, bullet trails appear |
| **7 – 10** | Maximum power | Red tint, long bullet trails |

### What it costs you

Enemy bullets travel up to **40% faster** at max rank. Spawn rate accelerates by up to **30%**. Bonus cherry drops kick in at rank 2 and scale with rank.

**The deal.** High rank kills faster, scores more, attracts more cherries — and bullets come faster, waves come thicker. The pilot who holds high rank longest scores the most.

---

## PAGE 8 — SCORE ATTACK

[IMG: cherry_fever.png]

### Point values

| Source | Base | × multiplier? |
| --- | --- | --- |
| Normal enemy kill | 10 | yes |
| Cherry pickup | 100 | yes |
| Mini-boss kill | 50 | yes |
| Final boss kill | 100 | yes |
| True last boss kill | 50 | yes |

### The multiplier

Defeated enemies burst **4–8 cherries** on death (90% chance), with a small bonus chance of dropping a bomb or health pickup. Cherries are pulled toward your ship within 48 pixels and expire in 1.5 seconds.

[SPRITE: pickup_cherry.png — at large scale, beside the heading below]

**Every 10 cherries collected raises the multiplier by 1.**

**Getting hit resets the multiplier and the streak to 1.**

### End-of-run bonus

> bonus = (remaining bombs × 25) + (remaining HP × 25)

Every bomb you didn't spend, every hit you didn't take, pays at the end.

> *Don't ask whether a bomb saves you. Ask what that bomb preserves.*

---

## PAGE 9 — ENEMY FIELD GUIDE

[IMG: murdercrab_legion_diagram.png]

The host is one shape, repeated. Two weapon variants. Three states.

### Behavior states

**Entry.** Enters above the screen, drifts to a random hover line at the top. Already firing.

**Hover.** Patrols horizontally, bouncing off the edges, shooting at you. After 1.5 seconds it commits.

**Kamikaze.** Locks onto your position and dives at double speed. Sprite changes. Misses despawn off-screen.

### The sprite

| Frame | Sprite |
| --- | --- |
| Hover | [SPRITE: enemy_normal_f1.png] |
| Hit | [SPRITE: enemy_hit_frame.png] |
| Animated cycle | [SPRITE: enemy_normal_cycle.gif] |

### Weapons (50/50 per spawn)

**Shotgun.** Three-bullet aimed spread, 10° spread angle.

**Burst.** Three rapid aimed shots in sequence with a short delay between each.

> *Field note. Most "reflex deaths" are positioning errors from one or two seconds earlier.*

---

## PAGE 10 — STAGE GUIDE

[IMG: NEEDS-GEN-06 — six-panel stage strip, painted vignettes, escalating environments. See prompt pack for full brief.]

Each of the five stages follows the same rhythm:

> **Enemy phase → boss warning → mini-boss → enemy phase → boss warning → final boss → warp.**

### The starfields

| Stage | Background | Feel |
| --- | --- | --- |
| 1 | Black, white stars | Clean void. Training ground. |
| 2 | Dark blue, light-blue stars | Deeper space. Colder. |
| 3 | Dark green, green stars | Biological territory. Something alive out here. |
| 4 | Dark purple, pink stars | Approaching the hive. |
| 5 | Dark brown, yellow & cyan stars | The core. Everything is wrong. |
| **6** | Full spectrum | Reality breaking. |

Star density and twinkle aggression climb every stage. Between levels a six-second warp plays — stars streak, colors cycle, the screen brightens to white at peak.

### The true last boss

Stage 6 only appears if you used **zero continues** through stages 1–5. Use a continue, the game ends after stage 5. There is no menu, no shortcut. The TLB is earned.

---

## PAGE 11 — BOSS DOCTRINE

[IMG: murdercrab.png]

**This is what you came for.**

Bosses in MurderCrab are exams, not spectacles.

| Boss | Sprite size | Phases | Score | Notes |
| --- | --- | --- | --- | --- |
| **Mini-boss** | 16×16 | 2 (split at 50%) | 50 | Strafes within a 60-pixel range |
| **Final boss** | 16×16, recolored | 3 (66%, 33%) | 100 | Slower strafe; phase 3 palette shifts again |
| **True last boss** | 32×32 | 3 + Rage Mode | 50 | Phase 3 adds 10 bullets to every pattern; pulsing red aura |

The TLB sprite, blown up: [SPRITE: true_last_boss_32x32.png]

### Pattern types

**Spiral.** Rotating bullet stream with a sine-wobble offset.

**Radial burst.** Even circular spread from boss center. Demands positioning.

**Aimed burst.** Three-shot burst aimed at you. Fast and precise. Tests streaming.

Phase 1 cycles spiral and radial. Phase 2+ unlocks aimed bursts. The more damaged the boss, the faster the cycle and the denser the patterns. Rank speed-scaling stacks on top.

### Boss defeat

Every enemy bullet on screen converts to a small explosion. Chain explosions detonate on the boss body. Heavy shake. Music fades out. For final bosses, a 3-second celebration sequence plays before the warp begins.

---

## PAGE 12 — CREDITS, CONTINUES, HIGH SCORES

[IMG: ace_destroyed.png]

### Credits

Three per session. They reset every time you return to the title screen. **1 to start. 1 per continue.**

### Continuing

When you die, you have ten seconds. After the one-second grace:

| Press | Result |
| --- | --- |
| **Z** | Restore 3 HP, reset multiplier and streak to 1, spend 1 credit. Rank is preserved. |
| **X** | End the run. |
| (timer expires) | End the run. |

**Any continue locks the TLB out for the rest of the run.**

### New Game Plus

Beat the TLB and **Z** sends you into Loop 2 on the same credit. Score, HP, bombs, and rank carry. Credits reset to 3. Enemies get harder — speeds up, intervals down, boss HP × 1.5 per loop.

### High scores

[IMG: NEEDS-GEN-07 — small CRT high-score screen mock, 4:3, glowing teal/magenta, three-row board, "PRESS START" prompt. Inset, lower-half of this page.]

The board holds three entries with three-character initials. Up/down picks the character (full printable ASCII), left/right moves between positions, **Z or X** confirms. Initials save between sessions.

---

## CENTERFOLD POSTER (FOLDOUT)

[IMG: laura_fan_service.png]

> *Pull-out poster. Full bleed. No body copy. Optional small "MURDERCRAB! — © Murdercrab Industries" credit in a corner if the designer wants it.*

---

## INSIDE BACK — READER MAIL

> *Bottom-of-pile mail from amusement halls across the territory. Submissions printed without comment.*

[IMG: ChatGPT_Image_Apr_11_2026_06_47_25_PM.png]

> *↑ "HELLCAT vs. THE LEGION" — submitted by a player, contractor's territory.*

[IMG: victory_screen.png]

> *↑ Victory illustration. Submitted anonymously.*

[IMG: anime_hero_triptych.png]

> *↑ Triptych, no caption.*

> **Send your fan art and high-score photos to the address on your local cabinet's coin door. Featured submissions receive a free continue at participating amusement halls.**

---

## BACK COVER

[IMG: legion_attacks.png]

> **THE SWARM IS LEARNING. SO ARE YOU.**
>
> Route five stages of shell-born violence. Cash power. Spend bombs before regret.
>
> Push for the clear, then come back for the score.
>
> *— excerpted from after-action transcripts.*

---

## DESIGNER NOTES

### Pepper plants (intentional, do not edit out)

These four touches set up the MC2/MC3 retroactive read. They should remain subtle and unannotated in the final design — none of them call attention to themselves on first read.

1. **"Issued under contract..." line on the inside front.** Plants that the document has an issuer with a profit motive.
2. **"Pacification doctrine, §4" sidebar on Page 2.** Single use of the word "pacification" + explicit contractor framing of HELLCAT as on-loan property.
3. **"Command... pilots who sit too long with it stop calling" field note on Page 1.** Single use of "Command" + the implication that the role chews people up.
4. **"— excerpted from after-action transcripts" attribution on the back cover.** Frames the entire booklet as a leaked artifact rather than marketing copy.

That's the whole pepper. Adding more breaks the surprise of MC2.

### Visual idiom map (for designer)

Five distinct idioms in deliberate placement. The unifying thread is "1987 Japanese arcade-game multimedia ecosystem" — flyer art, manual interior, OAV adaptation, magazine fan-mail, in-game pixels. They are placed deliberately, not blended.

| Idiom | Where it appears |
| --- | --- |
| **Frazetta painterly** (covers, big spectacle) | Front cover, inside front, boss splash, Page 12 death art, back cover |
| **Anime-cel OAV** (character art) | Page 1 pilot bio, Page 8 cherry, inside-back triptych |
| **Mecha technical cutaway** (tech illustration) | Page 2 ship spread, NEEDS-GEN-02 controls, NEEDS-GEN-05 rank tier |
| **Kid-fanart watercolor** (zine collage) | Inside-back reader mail page |
| **Real PICO-8 pixels** (actual game art) | Pages 5, 8, 9, 11 — at large pixelated scale, leader-line callouts |

### Files referenced — quick index

| Slot | Status | File |
| --- | --- | --- |
| Front cover | ✓ in hand | hero_triptych.png |
| Inside front | ✓ in hand | murdercrab_defeat.png |
| Page 1 pilot | ✓ in hand | ace.png |
| Page 2 ship | ✓ in hand | ace_diagram.png |
| Page 3 cabinet | ✓ in hand | laura_and_arcade.png (+ inset NEEDS-GEN-01) |
| Page 4 controls | NEEDS-GEN-02 | — |
| Page 5 HUD | NEEDS-GEN-03 (+ sprite rips) | — |
| Page 6 bomb | NEEDS-GEN-04 | — |
| Page 7 rank | NEEDS-GEN-05 | — |
| Page 8 score | ✓ in hand | cherry_fever.png + pickup_cherry.png |
| Page 9 enemies | ✓ in hand | murdercrab_legion_diagram.png + sprite rips |
| Page 10 stages | NEEDS-GEN-06 | — |
| Page 11 boss splash | ✓ in hand | murdercrab.png + true_last_boss_32x32.png |
| Page 12 death art | ✓ in hand | ace_destroyed.png (+ inset NEEDS-GEN-07) |
| Foldout poster | ✓ in hand | laura_fan_service.png |
| Inside back | ✓ in hand | ChatGPT_Image_Apr_11_2026_06_47_25_PM.png + victory_screen.png + anime_hero_triptych.png |
| Back cover | ✓ in hand | legion_attacks.png |

**Seven NEEDS-GEN slots remain.** Prompts for all seven are in `asset-prompts-v2.md`, retuned to match the established style.
