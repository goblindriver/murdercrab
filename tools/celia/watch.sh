#!/usr/bin/env bash
# Watch the bot play in real time, with sound: ./watch.sh [seed] [speed]
# speed = game frames per displayed frame (2 = double speed).
# trace.sh's switches still apply: MC_GOD=1 never dies (reaches the true last
# boss), MC_NOCONT=1 runs out to name entry. Any key pauses; P resumes.
set -euo pipefail
cd "$(dirname "$0")"
MC_WATCH=1 MC_SEED="${1:-42}" MC_SPEED="${2:-1}" exec ./run.sh --audio
