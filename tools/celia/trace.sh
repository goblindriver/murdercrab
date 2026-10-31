#!/usr/bin/env bash
# Headless regression trace: run a cart under the bot for N frames and write
# one state line per frame. Diff two traces to prove a refactor changes no
# behavior (same seed + same logic => identical file).
#
#   ./trace.sh [cart.p8] [out.txt] [frames] [seed]
#
# Defaults: ../../pico8/murdercrab.p8, ./trace.txt, 36000 (10 min @60fps), 42.
# A LÖVE window flashes up briefly; the run itself never waits on it.
set -euo pipefail
here=$(cd "$(dirname "$0")" && pwd)
cart=$(cd "$(dirname "${1:-$here/../../pico8/murdercrab.p8}")" && pwd)/$(basename "${1:-murdercrab.p8}")
out=${2:-trace.txt}
case "$out" in /*) ;; *) out="$PWD/$out" ;; esac
cd "$here"
cp -f "$cart" carts/murdercrab.p8
MC_TRACE="$out" MC_FRAMES="${3:-36000}" MC_SEED="${4:-42}" love . murdercrab.p8 >/dev/null
tail -1 "$out"
