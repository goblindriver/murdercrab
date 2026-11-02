#!/usr/bin/env bash
# Publish the latest MurderCrab to tigerdust.party/games/murdercrab.
#
# Exports pico8/murdercrab.p8 from origin/main with PICO-8's CLI, drops the
# HTML/JS into the site's public/play/murdercrab, and opens a PR on
# goblindriver/tigerdust.party. Merging that PR deploys it (Vercel).
# Run it after every cart merge to main. Skips if the site already has this commit.
#
#   tools/publish-web.sh            # export + push a branch + open the site PR
#   tools/publish-web.sh --dry-run  # export only, print where it landed
#
# Env: TIGERDUST_DIR (site clone), PICO8 (binary path), REF (cart commit, default origin/main).
set -euo pipefail

MC=$(cd "$(dirname "$0")/.." && pwd)
SITE=${TIGERDUST_DIR:-$HOME/projects/tigerdust.party}
PICO8=${PICO8:-"$HOME/Library/Application Support/itch/apps/pico-8/pico-8/PICO-8.app/Contents/MacOS/pico8"}
DRY=${1:-}

git -C "$MC" fetch -q origin main
SHA=$(git -C "$MC" rev-parse "${REF:-origin/main}")
SHORT=${SHA:0:7}
STAMP="<!-- murdercrab-source: $SHA -->"

if [ "$DRY" != "--dry-run" ]; then
  git -C "$SITE" fetch -q origin main
  if git -C "$SITE" show origin/main:public/play/murdercrab/index.html 2>/dev/null | grep -qF "$STAMP"; then
    echo "tigerdust.party already has murdercrab $SHORT; nothing to do."
    exit 0
  fi
fi

TMP=$(mktemp -d)
trap 'git -C "$SITE" worktree remove --force "$TMP/site" 2>/dev/null || true; rm -rf "$TMP"' EXIT

# Export from a scratch copy so PICO-8 never writes into the repo.
mkdir "$TMP/export"
git -C "$MC" show "$SHA:pico8/murdercrab.p8" > "$TMP/export/murdercrab.p8"
(cd "$TMP/export" && "$PICO8" murdercrab.p8 -export murdercrab.html)
[ -f "$TMP/export/murdercrab.html" ] || { echo "export failed (does the cart still have a __label__?)" >&2; exit 1; }

# Site touches: tab title, black page, and the source stamp the skip check reads.
sed -i '' \
  -e "s#<title>PICO-8 Cartridge</title>#<title>MurderCrab</title>$STAMP#" \
  -e 's/<body style="padding:0px; margin:0px; background-color:#222/<body style="padding:0px; margin:0px; background-color:#000/' \
  "$TMP/export/murdercrab.html"

if [ "$DRY" = "--dry-run" ]; then
  trap - EXIT
  echo "dry run: $TMP/export"
  exit 0
fi

BRANCH="claude/murdercrab-$SHORT"
git -C "$SITE" worktree add -q -b "$BRANCH" "$TMP/site" origin/main
mkdir -p "$TMP/site/public/play/murdercrab"
cp "$TMP/export/murdercrab.html" "$TMP/site/public/play/murdercrab/index.html"
cp "$TMP/export/murdercrab.js" "$TMP/site/public/play/murdercrab/murdercrab.js"
git -C "$TMP/site" add public/play/murdercrab
git -C "$TMP/site" commit -q -m "games: MurderCrab -> murdercrab main @ $SHORT"
git -C "$TMP/site" push -q -u origin "$BRANCH"
(cd "$TMP/site" && gh pr create --base main \
  --title "games: MurderCrab -> murdercrab main @ $SHORT" \
  --body "Re-exports the playable MurderCrab at /games/murdercrab from goblindriver/murdercrab main @ \`$SHA\` (tools/publish-web.sh). Merge to deploy.")
