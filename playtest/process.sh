#!/usr/bin/env bash
# process.sh — turn an OBS playtest recording into a chronological log.
#
# Usage:
#   ./process.sh <path/to/recording.mp4>
#
# Expects OBS to be configured for separate audio tracks:
#   Track 1 = full mix (game + voice)
#   Track 2 = mic only
# If only Track 1 exists (older recordings), falls back to demucs vocal isolation.

set -euo pipefail

if [ $# -lt 1 ]; then echo "usage: $0 <recording.mp4>"; exit 1; fi
SRC="$1"
[ -f "$SRC" ] || { echo "missing: $SRC"; exit 1; }

ROOT="$(cd "$(dirname "$0")" && pwd)"
NAME="$(basename "$SRC" .mp4 | tr ' :' '__')"
OUT="$ROOT/$NAME"
mkdir -p "$OUT"
cd "$OUT"

VENV="$ROOT/.venv/bin"
[ -x "$VENV/mlx_whisper" ] || { echo "missing venv: $ROOT/.venv"; exit 1; }
DEMUCS="$HOME/Library/Python/3.9/bin/demucs"

# how many audio streams in the source?
TRACK_COUNT=$(ffprobe -v error -select_streams a -show_entries stream=index -of csv=p=0 "$SRC" | wc -l | tr -d ' ')
echo "[1/4] source has $TRACK_COUNT audio track(s)"

if [ "$TRACK_COUNT" -ge 2 ]; then
  # multi-track: grab Track 2 directly (mic-only)
  echo "[2/4] extracting Track 2 (mic-only)"
  ffmpeg -y -i "$SRC" -map "0:a:1" -ac 1 -ar 16000 -loglevel error voice.wav
else
  # single-track: isolate vocals with demucs
  echo "[2/4] one track only — isolating vocals with demucs (slow)"
  ffmpeg -y -i "$SRC" -vn -ac 2 -ar 44100 -loglevel error mix.wav
  [ -x "$DEMUCS" ] || { echo "demucs not found at $DEMUCS"; exit 1; }
  "$DEMUCS" --two-stems=vocals -n htdemucs mix.wav -o demucs_out
  cp demucs_out/htdemucs/mix/vocals.wav voice.wav
fi

# extract frames at 2 fps for tight commentary↔visual pairing
echo "[3/4] extracting frames (2 fps)"
ffmpeg -y -i "$SRC" -vf "fps=2,scale=480:-1" -loglevel error 'frame_%05d.jpg'

# transcribe with word-level timestamps; ignore previous-text conditioning
# to kill repetition loops; high no_speech_threshold rejects silence
echo "[4/4] transcribing"
"$VENV/mlx_whisper" voice.wav \
  --model mlx-community/whisper-large-v3-turbo \
  --language en \
  --output-format json \
  --output-dir . \
  --condition-on-previous-text False \
  --no-speech-threshold 0.7 \
  --temperature 0 \
  --word-timestamps True

# build a clean transcript with [mm:ss] prefixes, dropping likely hallucinations
python3 - <<'PY' > transcript.txt
import json
with open('voice.json') as f: d = json.load(f)
prev = ''
for s in d['segments']:
    txt = s['text'].strip()
    if not txt or txt == prev: continue
    w = txt.split()
    if len(w) > 3 and len(set(w)) <= 2: continue  # repetition loop
    t = int(s['start']); mm, ss = t // 60, t % 60
    print(f'[{mm:02d}:{ss:02d}] {txt}')
    prev = txt
PY

echo "done -> $OUT/transcript.txt + $OUT/frame_*.jpg"
