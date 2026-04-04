# MurderCrab Media Extraction Pack v2

This pack was generated from the current PICO-8 cart in `murdercrab-main.zip`.

## Included in this pass

### Exact cart-derived assets
- Rebuilt spritesheet from the cart `__gfx__` section
- Isolated SVGs for code-referenced sprites/composites
- 16x and 64x nearest-neighbor PNG exports
- Explicit animation GIFs only where frame order is clear in code

### New extraction sets
- Background/starfield plates reconstructed from level-specific starfield logic
- HUD/icon extraction and HUD layout diagrams
- Boss-pattern diagrams based on the current pattern-generation code
- Boss palette-variant exports based on code-visible palette shifts
- A faux gameplay composition built from exact extracted assets

## Important boundaries

This pass does **not** include true runtime screenshots because no emulator/runtime capture loop was used.
The included `faux_gameplay_frame_from_assets.png` is useful for layout and promo blocking, but it is not a screenshot.

## Source cart
- `murdercrab-main/pico8/murdercrab.p8`

## Key code-derived findings
- No `__map__` section is present in the cart, so there is no traditional tilemap extraction pass to perform.
- Backgrounds are procedural starfields with level-specific color sets and densities.
- HUD text is drawn procedurally; pickups/icons are sprite-based.
- Boss and TLB patterns are generated from spiral, radial, and aimed-burst logic.
