#!/usr/bin/env bash
# One-credit eval of a bot over seeds: ./eval.sh <out_dir> <bot> [seeds...]
#   bot = sweep (v2.0b) | dodger (v2.1) | path/to/policy.lua (tools/rl export)
# Writes <out_dir>/nocont-<seed>.txt (MC_NOCONT=1 MC_ONEGAME=1, capped at
# MC_FRAMES, default 36000 = 10 min) 3 at a time, then prints balance.py's
# one-credit line per seed. Defaults to seeds 201-206.
set -euo pipefail
here=$(cd "$(dirname "$0")" && pwd)
out=$1 bot=$2
shift 2
seeds=${*:-201 202 203 204 205 206}
mkdir -p "$out"
out=$(cd "$out" && pwd)
case "$bot" in
	sweep) export MC_BOT=sweep ;;
	dodger) ;;
	*) export MC_POLICY=$(cd "$(dirname "$bot")" && pwd)/$(basename "$bot") ;;
esac
export MC_NOCONT=1 MC_ONEGAME=1
for s in $seeds; do echo "$s"; done |
	xargs -P 3 -I{} "$here/trace.sh" "" "$out/nocont-{}.txt" "${MC_FRAMES:-36000}" {} >/dev/null
python3 "$here/balance.py" "$out" $seeds
