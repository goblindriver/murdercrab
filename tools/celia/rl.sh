#!/usr/bin/env bash
# RL env server: Murdercrab under Celia speaking the line protocol in
# murdercrab_rl.lua on stdin/stdout. tools/rl spawns one per env worker.
#   ./rl.sh                 then type: reset 7 / step 4 / quit
# MC_RL_TEACHER=1 adds the dodger's action to each reply (behavior cloning);
# MC_RL_SKIP=n frames per action (default 4); MC_RL_REWARD='{"death":20}'.
# The window opens off-screen as a background app (conf.lua), like trace.sh.
# Windows: LÖVE's stdio only works with lovec.exe, so run that instead of love.
set -euo pipefail
cd "$(dirname "$0")"
# copy + rename, so parallel servers never load a half-written cart
tmp=carts/.tmp-$$.p8
cp -f ../../pico8/murdercrab.p8 "$tmp" && mv -f "$tmp" carts/murdercrab.p8
SDL_MAC_BACKGROUND_APP=1 MC_RL=1 exec love . murdercrab.p8
