#!/usr/bin/env bash
# Behavior-regression check: trace the committed cart (git HEAD, or a ref)
# and the working-copy cart under the same seeded bot scenarios, then diff.
# IDENTICAL on every row = the edit changed no observable behavior (state,
# saved high scores, and total rnd() consumption all match).
#
#   ./regress.sh [ref]        default ref: HEAD
#
# Use it for token cleanups / refactors. Deliberate gameplay changes will
# (correctly) show DIFF; check those with targeted traces instead.
set -euo pipefail
# Pin the v2.0b sweep bot: it dies on schedule, so the scenarios keep covering
# continues, game over and name entry no matter how good the dodger gets.
export MC_BOT=sweep
here=$(cd "$(dirname "$0")" && pwd)
root=$(cd "$here/../.." && pwd)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
git -C "$root" show "${1:-HEAD}:pico8/murdercrab.p8" > "$tmp/ref.p8"

fail=0
run() { # name frames seed [VAR=value ...]
	local name=$1 frames=$2 seed=$3
	shift 3
	env "$@" "$here/trace.sh" "$tmp/ref.p8" "$tmp/$name.ref" "$frames" "$seed" >/dev/null
	env "$@" "$here/trace.sh" "$root/pico8/murdercrab.p8" "$tmp/$name.new" "$frames" "$seed" >/dev/null
	if cmp -s "$tmp/$name.ref" "$tmp/$name.new"; then
		echo "IDENTICAL  $name"
	else
		fail=1
		echo "DIFF       $name  (first divergence below)"
		diff "$tmp/$name.ref" "$tmp/$name.new" | head -4 | cut -c1-200 || true
	fi
}

run continue-s42   36000 42                       # L1-L5 + loop 2 via continues
run continue-s7    36000 7
run nocont-s42     36000 42 MC_NOCONT=1           # game over -> name entry -> table
run nocont-s7      36000 7  MC_NOCONT=1
run god-loop-s42   54000 42 MC_GOD=1              # true last boss -> loop 2
run god-exit-s7    54000 7  MC_GOD=1 MC_EXIT=1    # true last boss -> exit -> name entry
exit $fail
