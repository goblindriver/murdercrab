# Picotron Port Notes

Reference for porting murdercrab! from PICO-8 to Picotron.

## Lua Language Changes (PICO-8 -> Picotron / Lua 5.4)

| PICO-8 | Picotron (Lua 5.4) | Notes |
|--------|-------------------|-------|
| `!=` | `~=` | Not-equal operator |
| `if (x) y` | `if x then y end` | No shorthand single-line if |
| `+=`, `-=`, `*=`, `/=` | not built-in | Use `x = x + 1` or define helpers |
| `add(t, v)` | `table.insert(t, v)` | Or write a compat `add()` |
| `del(t, v)` | manual remove | No built-in by-value delete |
| `deli(t, i)` | `table.remove(t, i)` | Direct equivalent |
| `#"string"` | `#"string"` or `string.len()` | Works the same |
| `foreach(t, fn)` | `for _,v in ipairs(t) do fn(v) end` | |
| `all(t)` | `ipairs(t)` | Iterator |
| `print(s,x,y,c)` | Picotron print API | Different signature |
| `spr(n,x,y)` | Picotron spr API | Multiple sprite sheets supported |
| `btn(i)` / `btnp(i)` | Picotron input API | Supports keyboard + gamepad |
| `sfx(n)` / `music(n)` | Picotron audio API | Different tracker format |
| `rnd(n)` | `math.random()` | |
| `flr(n)` | `math.floor(n)` | |
| `mid(a,b,c)` | `math.max(a, math.min(b, c))` | Or write a compat `mid()` |
| `sin(n)` / `cos(n)` | `math.sin(n*2*math.pi)` | PICO-8 uses 0-1 range, Lua uses radians |
| `sqrt(n)` | `math.sqrt(n)` | |
| `abs(n)` | `math.abs(n)` | |
| `max(a,b)` / `min(a,b)` | `math.max` / `math.min` | |
| `sub(s,i,j)` | `string.sub(s,i,j)` | |
| `ord(s)` | `string.byte(s)` | |
| `chr(n)` | `string.char(n)` | |
| `time()` | Picotron clock API | |
| `cartdata()` / `dget()` / `dset()` | Picotron file I/O / pods | Much more flexible |
| `stat(n)` | Picotron system API | |
| `pal()` / `fillp()` | Picotron draw API | More palette options |
| `poke()` / `peek()` | Direct memory not applicable | Different architecture |

## Resolution and Layout

- **PICO-8**: 128x128, 16 colors, 8x8 sprites
- **Picotron**: 480x270, 64 colors, variable sprite sizes

The 3.75x width and 2.1x height increase means this is NOT a simple upscale. Options:
1. **Pixel-perfect upscale**: render to a 128x128 buffer, scale 2x to 256x256, letterbox. Preserves exact feel but wastes the extra resolution.
2. **Native resolution redesign**: redraw sprites at higher res, expand the play field. More work but takes full advantage of Picotron.
3. **Hybrid**: keep the 128x128 game area centered, use the extra space for expanded HUD, boss health bars, minimap, score displays.

## Sprite / Art Assets

PICO-8 sprites are stored as hex strings in `__gfx__`. For Picotron:
- Export sprite sheet from PICO-8 as PNG
- Import into Picotron sprite editor
- Optionally redraw at higher resolution with the expanded 64-color palette

Key sprites to port:
- Player ship (sprites 1, 17, 33 -- center, left-tilt, right-tilt)
- Player bullet animation (sprites 2, 18, 34, 50)
- Enemy (sprites 3, 19 -- normal, animated; sprite 35 -- kamikaze)
- Enemy bullet (sprite 4)
- Powerups: bomb (5), health (6), score/cherry (7)
- Mini-boss / final boss (sprite 8, 2x2 tiles)
- True last boss (sprite 10, 4x4 tiles)

## Music / SFX

PICO-8 tracker data (`__sfx__` and `__music__`) is a proprietary format. For Picotron:
- Picotron has its own tracker with more channels and instrument options
- Music will need to be recreated manually
- Consider exporting MIDI or recreating from memory
- SFX (shoot, explosion, hit, warp, etc.) can be approximated with Picotron's synth

Current music layout:
- Patterns 0-5: title/menu music
- Patterns 6-9: gameplay music
- Patterns 10-13: boss music
- Patterns 14-17: additional tracks

## Architecture Opportunities

Things that were constrained by PICO-8's limits that can be improved:
- **Object pooling** (bullet_pool, enemy_bullet_pool): unnecessary with more memory
- **Token-saving tricks** (compact variable declarations, terse code): can be expanded for readability
- **Component-based scores** (score_to_comp splitting into millions/thousands/units): Lua 5.4 handles large numbers natively
- **Single-file constraint**: can split into multiple source files
- **Hard-coded constants**: can use a proper config/data file
- **Particle effects**: can be much more elaborate with more CPU/memory
- **Screen shake**: can be smoother with sub-pixel rendering

## Porting Strategy

Recommended approach:
1. Start with a compatibility layer (`compat.lua`) that provides PICO-8-like functions
2. Get the game logic running with minimal changes
3. Then iteratively replace compat functions with native Picotron equivalents
4. Redesign visuals last (this is the biggest effort)

## Installation

Picotron is available from https://lexaloffle.com/picotron.php ($19.99).
Current version: v0.2.2b (as of early 2026).
Runs on macOS, Windows, and Linux.
