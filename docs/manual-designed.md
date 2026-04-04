# MURDERCRAB!
## Player’s Manual — Throwback Pack-In / Strategy-Zine Edition

**PICO-8 arcade shooter** · *Living document: aligned with the cart, [manual.md](manual.md), and extracted ship art.*

A PDF snapshot of an earlier layout lives alongside this file: [MurderCrab_Designed_Manual.pdf](MurderCrab_Designed_Manual.pdf). **This markdown is the maintained edition** — systems, flow, and art references update with the repo.

---

## Inside cover — launch briefing

*MurderCrab* is built like a cabinet you keep coming back to: **3 credits** each time you hit the **title** screen, **five** stages of escalating shellfire, **bombs** that clear the screen and chunk bosses, **cherries** that feed multiplier and streak, and a **True Last Boss** reserved for **no-continue** runs.

This booklet is part manual, part magazine insert, part operator catechism. **Figures** below use **exact** pixel art from the cart, exported in the [media extraction pack](../media/MurderCrab_Media_Extraction_Pack/) (see `docs/asset_manifest.json` in that pack for sprite IDs).

**Quick start.** Title → **menu** → **start game** (1 credit). **Hold Z** to fire (PICO-8 `btnp` repeat). **Bomb** before regret. **Set initials** under *enter initials* if you want the **top-3** board to read yours — scores commit at game over using your **saved** tag.

---

## Contents

| | |
|--|--|
| 03 | [Mission brief](#mission-brief--the-outer-shells-have-opened) |
| 04 | [Control panel](#control-panel--three-inputs) |
| 05 | [HUD + combat](#readout--hud--core-combat) |
| 06 | [Resources + cherry chain](#resource-economy--the-cherry-chain) |
| 07 | [Enemy field guide](#enemy-field-guide--read-the-screen) |
| 08 | [Stage flow](#stage-anatomy) |
| 09 | [Bosses + TLB](#boss-doctrine) |
| 10 | [Score attack](#score-school) |
| 11 | [Cabinet ops](#cabinet-ops--credits-menu-high-scores) |
| 12 | [Operator school](#operator-school) |
| 13 | [Glossary + line](#glossary--terms--and-lineage) |

---

## Mission brief — the outer shells have opened

A cursed frontier, one impossible craft, five war-zones to cut through. At the edge of charted space, dead stations and broken fortresses became nesting ground for a **mechanized crab-host**: waves, cruel geometries, strongholds that molt and harden.

From a final strike hangar comes **MURDERCRAB** — compact output and a pilot half-mad enough to fly it into the choke of the swarm.

**Orders.**

- Break the outer formations  
- Ruin the nest chain  
- Survive **five** stages  
- Face what waits beneath the shell (**six** if you never continue)

**Field note.** The enemy does not advance like an army. It spreads like a bad idea.

---

## Control panel — three inputs

**Move.** Digital **2 px/frame**, eight directions. No inertia.

**Shot (Z).** Twin forward volleys. **`btnp`** = first press **plus** console repeat while held — tap for discipline, **hold** for volume fire.

**Bomb (X).** Clears **all** bullets (yours and theirs), wipes **normal** enemies on screen, **−30 HP** to every boss body on screen. Thirty frames active; follow-up flash and shake.

No focus. No charge. No submenu excuses.

**Operator tip.** Beginners over-move. Good players move enough. Great players move exactly once.

### Your ship (bank + idle)

| Bank left | Idle | Bank right |
|:---:|:---:|:---:|
| ![bank left](../media/MurderCrab_Media_Extraction_Pack/assets/png_16x/player_bank_left.png) | ![idle](../media/MurderCrab_Media_Extraction_Pack/assets/png_16x/player_idle.png) | ![bank right](../media/MurderCrab_Media_Extraction_Pack/assets/png_16x/player_bank_right.png) |

*PNG exports are 16× scale, nearest-neighbor — same pixels as PICO-8.*

### Twin shot cycle (four graphic frames)

![f1](../media/MurderCrab_Media_Extraction_Pack/assets/png_16x/player_bullet_f1.png)
![f2](../media/MurderCrab_Media_Extraction_Pack/assets/png_16x/player_bullet_f2.png)
![f3](../media/MurderCrab_Media_Extraction_Pack/assets/png_16x/player_bullet_f3.png)
![f4](../media/MurderCrab_Media_Extraction_Pack/assets/png_16x/player_bullet_f4.png)

GIFs for **banking**, **bullet cycle**, and **enemy idle** live in `../media/MurderCrab_Media_Extraction_Pack/assets/gifs/`.

---

## Readout — HUD + core combat

**Health** starts at **100**; each hit costs **1**. Pickups can push you above 100.

**Bombs** start at **3**. No hard cap.

**Cherries** score **100 × multiplier** and add **+1** streak; **10** cherries step the multiplier **+1**. **Any hit** zeroes multiplier **and** streak.

**Continue:** **3 HP**, streak and multiplier **reset**, **TLB locked** for that run.

**Hitbox truth (bullets).** Enemy bullets test a **2×2** box **centered in the 8×8 ship** — gaps that look rude are often legal.

**Hitbox truth (kamikaze).** When a crab **dives** (state 2), collision is **full ship bounds vs full enemy body** — rams are not pixel-hunt forgiving.

**Bomb doctrine.** Bombs are not an apology. They are a **conversion** tool. Use them before death, not after regret.

### Pickups (exact icons)

| Bomb | Health | Cherry |
|:---:|:---:|:---:|
| ![bomb](../media/MurderCrab_Media_Extraction_Pack/assets/png_16x/pickup_bomb.png) | ![hp](../media/MurderCrab_Media_Extraction_Pack/assets/png_16x/pickup_health.png) | ![cherry](../media/MurderCrab_Media_Extraction_Pack/assets/png_16x/pickup_cherry.png) |

### Boss silhouettes (composite sprites)

**Standard boss** (mini / final, 2×2 tiles on cart — export canvas is 32×32 px):

![boss](../media/MurderCrab_Media_Extraction_Pack/assets/png_16x/boss_standard_32x32.png)

**True last boss** (4×4 tiles):

![tlb](../media/MurderCrab_Media_Extraction_Pack/assets/png_16x/true_last_boss_32x32.png)

**Raw sheets** for the whole gfx bank: `../media/MurderCrab_Media_Extraction_Pack/assets/raw/spritesheet_from_code.png` and `asset_contact_sheet.png`.

---

## Resource economy — the cherry chain

Destroyed normals **usually** vomit a pickup burst: **2–4 cherries** (**90%**), plus **5%** extra **bomb** or **health**. Cherries **expire** in **30 frames** (blink in the last 15). Pickups **magnet** inside **48 px** — generous, not a license to yolo.

**Cherry law.** Chasing a cherry that kills you is not scoreplay. Preserving the route usually preserves more score.

**Continue penalty.** Enough HP to **peek** ahead, not enough to pretend dignity survived.

---

## Enemy field guide — read the screen

There is **one** core grunt type — read **behavior** and **weapon**, not a zoo of silhouettes.

| Phase | What it does |
|--------|----------------|
| **Entry** | Drops from top, drifts, **already shooting** |
| **Hover** | Patrols, bounces off walls, fires until a timer flips it |
| **Kamikaze** | Locks your position and **dives** at double speed — sprite swaps to the **dive** frame |

**Weapons (50/50).** **Shotgun** — three spread shots aimed at you. **Burst** — three quick aimed shots in sequence.

**Enemy bullet** (shared graphic):

![e bullet](../media/MurderCrab_Media_Extraction_Pack/assets/png_16x/enemy_bullet.png)

**Normal frames + dive:**

![e1](../media/MurderCrab_Media_Extraction_Pack/assets/png_16x/enemy_normal_f1.png)
![e2](../media/MurderCrab_Media_Extraction_Pack/assets/png_16x/enemy_normal_f2.png)
![dive](../media/MurderCrab_Media_Extraction_Pack/assets/png_16x/enemy_hit_frame.png)

**Field note.** Most “reflex deaths” are positioning errors from one or two seconds earlier.

**Readable density.** Fair pressure means you can tell **aimed** streams from **pattern** fire and **when** something must die first. *MurderCrab* grows density with **level** and **loop**; the long-term vision (see [design-reference.md](design-reference.md)) is even richer **threat language** — this ship is the honest baseline.

---

## Stage anatomy

**Five** stages on loop 1. Each stage: **normal waves** → **mini-boss threshold** → **! WARNING !** (90 frames) → **mini** → **more waves** → **final threshold** → **warning** → **final boss** → **warp** (six seconds, stars streak, level tick).

**Kill thresholds** (normals) scale by stage — see [manual.md](manual.md) §9 for the table.

**Starfields** shift **palette** and **density** by level (black void → cold blue → sick green → hive purple → core red; level 6 TLB goes chromatic). That is your **spatial story** until foreground art exists.

**Stage rule.** A good stage teaches, checks whether you learned, then punishes habits you failed to shed.

---

## Boss doctrine

**Mini-bosses** — compact exam, **two** phases (50% HP flip). **Final bosses** — longer argument, **three** phases (66% / 33%). Patterns share a family: **spiral**, **radial**, **aimed burst** — speed and count scale with **level**, **phase**, and boss **health**.

**TLB condition.** Reach stage **5’s** final boss **without any continue**; you **warp** to **level 6**. Spend a continue and the run **ends** at the loop-1 victory path — **no** hidden sixth fight. The game is not shy about what it values.

**Clean credit.** No-continue is the **gate** to the last layer, not just bragging rights.

**Bomb honor.** A bomb that keeps a clean credit is usually smarter than dying pretty.

---

## Score school

Survival is the floor. **Clearing** proves you can live; a **route** proves you can drive.

**End bonus** (applied when the run resolves): `(bombs × 25) + (health × 25)` — unused resources **cash out**.

**School of the jam.** Practice ugly slices until the good line stops being hypothetical. Reconnect. Then perform.

**Replay literacy.** Study runs — yours or others — so you inherit good ideas instead of reinventing bad ones.

---

## Cabinet ops — credits, menu, high scores

**Truth of the current build** (not fiction):

- **Title** resets **credits** to **3**; **menu** lists **start game**, **enter initials**, **instructions**, **high scores**.  
- **Start** costs **1** credit.  
- **Game over:** **credits** remaining and **countdown seconds** on screen; **Z** continues if you have credits; **X** bails to **menu**; timer **0** → menu.  
- **High scores:** **top 3** only; initials are whatever you **saved** in the menu — set them **before** a serious run.  
- **NG+** after TLB: **Z** rolls the next loop on the same run; **X** to menu.

For raw numbers (hitboxes, cartdata slots, token budget), keep [manual.md](manual.md) open — it is the **spec**. This zine is the **read**.

---

## Operator school

- Isolate the ugly section.  
- Learn spawn rhythm.  
- Name the real safe space.  
- Repeat until movement stops feeling **emotional**.  
- Plug the section back into the route.

**Targets.** No deaths with bombs in stock. Early consistency. Calmer pickups. Boss openers as **routine**.

**Cold truth.** The best runs feel boring until they suddenly do not.

**Another truth.** If the screen goes illegible, positioning failed before reflexes did.

**Hangar editor.** A beginner fears the end. An advanced player fears throwing away stage 1.

---

## Glossary — terms + lineage

| Term | Meaning |
|------|---------|
| **1CC** | One-credit clear (here: no **continue** — aligns with TLB gate) |
| **Route** | Repeated path through a section |
| **Popcorn** | *(Aspirational / genre)* — here, the one grunt type **behaves** like popcorn when you delete it fast |
| **Aimed** | Fire solving toward your position |
| **Herding** | Shaping aimed streams with movement |
| **Micrododge** | Tiny corrections through tight gaps |
| **TLB** | True last boss, stage 6 |
| **No-continue** | Never spent continue this run from title credit |

**Why this format.** A manual should teach **systems**, **mood**, and **values** at once. Otherwise it is only packaging.

**Sources in-repo.**

- [manual.md](manual.md) — authoritative mechanics  
- [design-reference.md](design-reference.md) — philosophy + future port notes  
- [../media/MurderCrab_Media_Extraction_Pack/docs/asset_manifest.json](../media/MurderCrab_Media_Extraction_Pack/docs/asset_manifest.json) — art map  
- [MurderCrab_Designed_Manual.pdf](MurderCrab_Designed_Manual.pdf) — original designed PDF export  

---

> **Humanity did not find peace in the void.**  
> It found armored claws, chitin cathedrals, and wave after wave of shell-born murder.  
> **Launch. Learn the lanes. Burn through the swarm.**
