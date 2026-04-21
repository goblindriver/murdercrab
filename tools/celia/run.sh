#!/usr/bin/env bash
# Launch Celia with the Murdercrab cart.
# Requires LÖVE 11.4 (`brew install --cask love`).
#
# LÖVE's love.filesystem sandbox refuses to read outside the project directory,
# so we can't symlink the cart in from ../../pico8/. Instead we copy fresh on
# every launch — the canonical cart at pico8/murdercrab.p8 remains the single
# source of truth; carts/murdercrab.p8 is a transient build artifact and is
# gitignored.
set -euo pipefail
cd "$(dirname "$0")"
cp -f ../../pico8/murdercrab.p8 carts/murdercrab.p8
# Celia prepends `carts/` internally (see main.lua:182), so we pass only the
# filename. Passing `carts/murdercrab.p8` would resolve to `carts/carts/...`.
exec love . murdercrab.p8 "$@"
