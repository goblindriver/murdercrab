# murdercrab!

A vertical-scrolling shoot-em-up built for PICO-8, with a Picotron port in progress.

## Gameplay

- 5 levels, each with a mini-boss and final boss
- Secret **true last boss** on level 6 (requires no continues used)
- **Game loop / NG+**: beat the true last boss to replay at higher difficulty
- 3 credits with a continue system
- Score multiplier that builds from collecting cherry pickups (10 in a row = +1x)
- Bombs clear the screen and damage bosses
- Health, bomb, and score powerups drop from defeated enemies
- Persistent high score table with 3-character initials

## Controls

| Button | Action |
|--------|--------|
| Arrow keys | Move |
| Z | Shoot |
| X | Bomb |

## Documentation

| Doc | What it is |
|-----|------------|
| [docs/player-manual.md](docs/player-manual.md) | **Player manual** — mechanics, stages, score, figures from the [media extraction pack](media/MurderCrab_Media_Extraction_Pack/) |
| [docs/operator-manual.md](docs/operator-manual.md) | **Operator manual** — design vision, research, arcade-flow targets, PICO-8 cart budget, future features |
| [docs/MurderCrab_Designed_Manual.pdf](docs/MurderCrab_Designed_Manual.pdf) | PDF booklet export (optional snapshot) |
| [docs/manual.md](docs/manual.md), [docs/manual-designed.md](docs/manual-designed.md), [docs/design-reference.md](docs/design-reference.md) | Short redirects to the manuals above |

## Project Structure

```
pico8/
  murdercrab.p8              # canonical PICO-8 cartridge (combined single-cart)
  archive/
    split/                   # older split-cart version (menu + game, Jun 2025)
    legacy/                  # early shmup prototype, docs
docs/
  player-manual.md           # SSOT: players (mechanics + figures)
  operator-manual.md         # SSOT: operators (design + cart budget)
  manual.md                  # → player-manual (legacy link)
  manual-designed.md         # → player-manual (legacy link)
  design-reference.md        # → operator-manual (legacy link)
  MurderCrab_Designed_Manual.pdf
media/
  MurderCrab_Media_Extraction_Pack/   # v2: svg, png_16x/64x, gifs, raw sheet, backgrounds, hud, diagrams + docs/
picotron/                    # Picotron port (planned)
```

## Development History

- **Mar 2025**: Started as "shmup" / "shmup a2" -- a single-cart prototype with basic enemies, bosses, and a title screen that doubled as the menu via edge-navigation.
- **Mar 2025 (late)**: Split into two carts (`murdercrab_menu.p8` + `murdercrab_game.p8`) using `load()` for BBS compatibility. Published to the PICO-8 BBS as `goblindriver`.
- **Jun 2025**: Continued iteration on the split carts -- refined boss patterns, powerup system, scoring.
- **Feb 2026**: Consolidated back into a single combined cart (`murdercrab.p8`) with significant improvements: game loop/NG+ mode, boss warning system, cleaner architecture, consolidated boss defeat handling, component-based score storage for large numbers, shadow text rendering, and optimized token usage.

### GitHub History Note

This repo was previously named `shmup` and contained only the early prototype (`shmup a2.p8`, ~890 lines of Lua). A Copilot-generated PR fixed 12 bugs in that early version (warp effects, credit system, game states, boss sprites, collisions, powerups, duplicates). All of those fixes have been superseded by the complete rewrite that became the combined cart (~1,940 lines of Lua, 75 functions vs the original 31). The early version is preserved in `pico8/archive/legacy/shmup_a2_github.p8` for reference.

## Running

Load `murdercrab.p8` in PICO-8:

```
load murdercrab
run
```

## License

All rights reserved.
