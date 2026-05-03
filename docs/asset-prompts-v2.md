# MurderCrab Pilot's Manual — Asset Prompts v2

Seven prompts for the still-needed images, retuned to match the visual world you've already built. Style references are now your own files instead of Gamest pages — so the new gens read as the same project.

## Style anchors (use these as image-reference inputs where your tool supports it)

| Anchor file | What it teaches the model |
| --- | --- |
| `ace_diagram.png` | Mecha technical cutaway — clean white-and-red ship, schematic margin lines, painted-but-flat finish |
| `murdercrab_defeat.png` | Frazetta painterly hero — orange chitin boss, deep starfield, ship-as-tiny-dot-of-defiance, dramatic light |
| `legion_attacks.png` | Cinematic poster — radial composition, motion lines, painterly-with-airbrush finish |
| `hero_triptych.png` | Painted-poster face composition — multi-figure arrangement, Drew Struzan / Frazetta crossover |
| `cherry_fever.png` | Anime-cel OAV — late-80s cel paint, sparkle highlights, mascot framing |

## House rules (unchanged from v1)

- **PICO-8 16-color palette anchor.** Painterly assets can extend, but should rhyme with the in-game palette.
- **No generated text.** Where labels are part of the composition, render them as illustrated marks.
- **No real IP.** No Toaplan / Cave / Konami logos, no recognizable real ships.
- **Pilot is ACE (callsign).** Ship is HELLCAT — F-14-styled white-and-red interceptor with twin plasma scramjet engines, established in `ace_diagram.png`. **Always use this exact ship silhouette.**
- **Aspect / safe area.** Each prompt names a target ratio. Leave a quiet edge of ~8% for trim and gutter.

---

## NEEDS-GEN-01 — Cabinet Flow Inset (Page 3)

**Style:** Mecha technical cutaway, sized smaller than the page's hero painting. Sits in the bottom-right corner alongside `laura_and_arcade.png`.

A small schematic flowchart in the same blue-print and ink-line style as a 1987 Japanese game-magazine technical sidebar. Five labeled boxes connected by directional arrows: ATTRACT MODE → CREDIT INSERTED → STAGE 1 → DEATH (branch) → CONTINUE / END. A second arrow loops from "TLB DEFEATED" back to ATTRACT MODE labeled "NG+". Drawn in two-tone blue ink on cream paper, slightly noisy paper grain, hand-lettered labels. The whole inset is small — designed to nest under the cabinet pinup on the same page, not compete with it.

- **Style anchor:** `ace_diagram.png` for the line weight and margin schematic feel.
- **Aspect:** Square to 4:3.
- **Avoid:** color, photorealism, modern UI elements, text rendered larger than the labels in `ace_diagram.png`.

---

## NEEDS-GEN-02 — Controls Diagram (Page 4)

**Style:** Mecha technical cutaway. Match `ace_diagram.png` exactly — same paper, same ink, same finish. This is a "Page 2 of the technical spec sheet" feel.

A clean overhead illustration of an arcade joystick and two buttons (labeled Z and X), drawn in line-art with a soft duotone wash and the same painted-on-dark-paper finish as `ace_diagram.png`. The joystick has eight directional arrows fanning out from its base. The Z button has a small "FIRE" callout pointing at it; the X button has a "BOMB" callout. Around the diagram, four short note-style labels in the margins: "1 PIXEL/FRAME", "TIGHT 2×2 HITBOX", "HOLD Z FOR RAPID FIRE", "PANIC = X". The labels should look like they were drafted by the same hand that drafted the HELLCAT cutaway — same line weight, same letter shapes, same tiny corner schematic boxes in the margins.

- **Style anchor:** `ace_diagram.png` (this is its sibling page).
- **Aspect:** Wide landscape (16:9 or 2:1).
- **Avoid:** real arcade-stick brand details. The controls are abstracted, period-generic.

---

## NEEDS-GEN-03 — HUD Annotated Screen (Page 5)

**Style:** Frame and callouts only. The actual screen content can be sourced from the existing PICO-8 sprite rips, so this prompt produces the wrapper and leader-line callout layer.

A pixel-art game screenshot at booklet resolution, freeze-framed mid-stage. The screen is roughly 128×128 pixel-art proportioned, rendered crisply at full booklet resolution. Inside the screen: the HELLCAT player ship at lower center (small green sprite), two enemy crab sprites hovering at the top with bullet patterns mid-flight, several cherry pickups scattered, a faint "! WARNING !" flash hint at the screen edges. Around the screen frame, six leader lines extend out into the page margins, each ending at a hand-lettered label: "SCORE", "HI-SCORE (flashes when beaten)", "MULTIPLIER (× cherry icon)", "HEALTH PIPS", "BOMB STOCK", "! WARNING ! flash". The screen itself uses the PICO-8 sixteen-color palette with crisp pixel boundaries.

- **Style anchor:** `ace_diagram.png` for the callout / leader-line / hand-lettered margin label style.
- **Aspect:** Landscape (3:2).
- **Avoid:** modern flat-UI conventions. Pixels must look pixelated, not anti-aliased.

---

## NEEDS-GEN-04 — Bomb Detonation Painting (Page 6)

**Style:** Frazetta painterly hero, full intensity. The HELLCAT at the eye of the storm.

A dynamic painted illustration of the HELLCAT (white-and-red F-14-style fighter from `ace_diagram.png`) at the dead center of an expanding white-and-orange shockwave. Multiple crab enemies caught in the rings dissolve into chained sprite-explosion bursts of yellow and red. Bullets in mid-flight are converting into puffs of smoke as the bomb sweeps the screen. Comic-book impact lines and stylized shockwave geometry radiate diagonally across the frame. Painterly oil-paint finish with chunky colored highlights — same painted hand as `murdercrab_defeat.png` and `legion_attacks.png`.

- **Style anchors:** `legion_attacks.png` for the radial composition; `murdercrab_defeat.png` for the painted-explosion finish.
- **Aspect:** Square or vertical (1:1 or 4:5).
- **Avoid:** generated text, modern motion-graphic aesthetics. This is a painted poster, not a screen-grab.

---

## NEEDS-GEN-05 — Rank Tier Visual (Page 7)

**Style:** Mecha technical cutaway. Three HELLCATs in a row, three rank states. Match `ace_diagram.png`.

Three vertical panels side by side, each showing the same HELLCAT fighter (the white-and-red F-14-style interceptor from `ace_diagram.png`) in a different rank tint state.

- **Left panel:** standard green-tint hull paint, no bullet trails, calm posture. Label: "0–3 STANDARD".
- **Middle panel:** yellow-tint hull paint, short bright bullet trails streaming from the wing emitters, more aggressive cant. Label: "4–6 STRONGER".
- **Right panel:** red-tint hull paint, long aggressive bullet trails, full forward thrust pose. Label: "7–10 MAXIMUM".

Below each panel, a small empty rectangle reserved for stat text the designer will set. Style is technical-spec-sheet meets period magazine: drawn in flat clean colors with thin ink outlines, two-tone backgrounds behind each panel for separation. Same line weight and margin schematic feel as `ace_diagram.png`. Imagine a Gundam mecha file card spread.

- **Style anchor:** `ace_diagram.png` (this is the third page of the spec sheet).
- **Aspect:** Wide horizontal (16:9 or wider, 2.39:1 cinemascope works).
- **Avoid:** real text in stat boxes (leave blank for designer); over-rendered "anime power-up" finish.

---

## NEEDS-GEN-06 — Six-Panel Stage Strip (Page 10)

**Style:** Frazetta painterly. A thin painted strip of six environmental impressions, one per stage.

A horizontal strip of six small painted vignettes in a row, each framed by a thin painted border, reading left to right as a journey deeper into hostile territory. Each panel a small painted impression in the same painted hand as `murdercrab_defeat.png`:

1. **Stage 1.** Black void with white stars — clean, austere, training ground.
2. **Stage 2.** Dark blue space with light-blue stars and the silhouette of a cold orbital — deeper, colder.
3. **Stage 3.** Dark green nebula with green stars and faint biological hints — alive, watchful.
4. **Stage 4.** Dark purple/pink with hive-like structures forming at the panel edges — hive approach.
5. **Stage 5.** Dark brown/yellow corruption, broken geometry, chitin-chrome architecture — the core, wrong.
6. **Stage 6 (TLB).** Full-spectrum hyperspace bleeding into chaos. Treat as a "secret" partially obscured panel — slightly blurred, scratched, or veiled relative to the other five.

The whole strip should read as a single journey across one image. Painted illustration style throughout — these are illustrated impressions, not literal screenshots.

- **Style anchor:** `murdercrab_defeat.png` for the painted-galaxy mood; `legion_attacks.png` for the panel-six chaos register.
- **Aspect:** Wide horizontal — at least 3:1, ideally 4:1 or 5:1.
- **Avoid:** modern game-screenshot framing; literal pixel art (panels are paintings of the *feel* of each stage, not screenshots of it).

---

## NEEDS-GEN-07 — High-Score CRT Mock (Page 12 inset)

**Style:** CRT bezel mock. Single image. Lives as an inset on Page 12 alongside `ace_destroyed.png`.

A retro arcade-screen mock-up of a high-score table: three rows, each showing three-character initials, a score number area (left blank for designer-set numbers), and a stage-reached label area. Above the table, a stylized "HIGH SCORES" banner shape (rendered as illustrated lettering, not generated text). Below, a "PRESS START" prompt that suggests pulsing. The whole screen has a CRT-glow halo, scanlines, and chromatic aberration at the edges. Color palette is teal/cyan and magenta on a near-black background. Outside the screen frame, small decorative elements suggest an arcade-cabinet bezel — sticker-style mock badges or button outlines.

- **Style anchor:** Period CRT-revival aesthetic. The bezel surround should feel like the cabinet visible in `laura_and_arcade.png`.
- **Aspect:** 4:3, monitor proportions.
- **Avoid:** modern flat-UI vibes; generated readable text in the score rows (leave blank for the designer).

---

## Generation tips

- **Run NEEDS-GEN-02 and NEEDS-GEN-05 in the same session as `ace_diagram.png`** if you can re-feed that file as a style anchor. Those two prompts must read as the same hand drafted them — designer will be placing all three near each other.
- **Run NEEDS-GEN-04 and NEEDS-GEN-06 together** with `murdercrab_defeat.png` + `legion_attacks.png` as anchors. Both want the same painted-galaxy painter.
- **NEEDS-GEN-01 is the cheapest** — small inset, simple composition. Good first run to test that your style-anchor pipeline is dialed in.
- **Skip text in every prompt.** Even tools that *can* render text are unreliable, and the booklet's typography will be set by the designer. Letting the model attempt text is the most common cause of having to re-roll.
- **If a gen comes back with the wrong ship silhouette** (anything that isn't the white-and-red F-14-style HELLCAT from `ace_diagram.png`), reject and re-roll. Ship continuity across the booklet is more important than getting any single prompt on the first try.
