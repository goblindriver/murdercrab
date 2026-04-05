# MurderCrab Media Brief for Code / Repo

## Status in this repo *(current)*

The **v2 extraction pack is already committed** at [`media/MurderCrab_Media_Extraction_Pack/`](../media/MurderCrab_Media_Extraction_Pack/docs/README.md) under `assets/` and `docs/` (not necessarily under `media/extracted/` as in the diagram below). Remaining work from this brief skews toward **runtime capture**, provenance discipline, and optional layout renames.

---

## Objective
Take the extracted media pack and make it a **canonical repo asset layer** for manuals, promo, social, and future documentation.

Main bundle already produced:
- `MurderCrab_Media_Extraction_Pack_v2.zip`

## What exists now
### Exact cart-derived assets
- rebuilt spritesheet from `__gfx__`
- isolated pixel-vector SVGs
- 16x PNG exports
- 64x PNG exports
- explicit animation GIFs
- boss palette variants

### Logic-derived media
- level starfield/background plates
- HUD layout diagrams
- rebuilt instructions panel
- boss/TLB pattern sheets
- faux gameplay frame assembled from exact extracted assets

### Docs
- asset manifest
- repo placement guide
- runtime capture note

## Recommended repo placement
```text
media/
  extracted/
    raw/
    svg/
    png_16x/
    png_64x/
    gifs/
    backgrounds/
    hud/
    diagrams/
  manuals/
  promo/
```

**Current layout:** the merged pack mirrors this under `media/MurderCrab_Media_Extraction_Pack/assets/` and `…/docs/`. Renaming to `media/extracted/` is optional cleanup.

## Code-side tasks
### 1. Commit the asset layer
**Done in repo** — see `media/MurderCrab_Media_Extraction_Pack/` (v2).

Original priority list for reference:
1. raw spritesheet snapshot
2. SVGs
3. PNG exports
4. GIFs
5. backgrounds
6. HUD
7. diagrams
8. docs / manifest

### 2. Treat it as canonical reference material
Use these exports as the default source for:
- manuals
- press kit material
- social mockups
- store page art comps
- future UI / HUD documentation
- design communication inside the repo

### 3. Preserve provenance
Keep the manifest and notes with the assets so nobody confuses:
- exact cart-derived exports
- logic-derived diagrams
- faux frames
- future runtime screenshots

### 4. Add a runtime capture pipeline
This is the next major missing piece.

Needed:
- a reliable way to run the cart/build
- automated or semi-automated screenshot capture
- boss and mini-boss still capture
- HUD-on and HUD-off frame exports
- real animated clips from live play

### 5. Future expansion tickets
- real gameplay screenshot set
- title screen / menu capture
- warning overlay capture
- low-health HUD capture
- bomb explosion frame extraction
- boss phase contact sheets
- asset diffing between builds

## Rules for asset truthfulness
### Exact
Can be called exact:
- spritesheet from `__gfx__`
- isolated sprite SVGs / PNGs
- explicit animation GIFs with code-backed frame order

### Derived
Must be labeled derived:
- pattern diagrams
- reconstructed starfield plates
- HUD diagrams
- faux gameplay composition

### Runtime
Must be labeled runtime only after real capture:
- true screenshots
- true gameplay GIFs
- effects clips
- menu captures

## Short version for code
“Add the extracted media pack to the repo as a canonical asset layer, preserve the manifest/provenance labels, use exact exports for manuals/promo immediately, and build a runtime capture pipeline next so faux frames can be replaced with real screenshots.”
