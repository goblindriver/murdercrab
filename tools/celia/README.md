# Murdercrab TAS / bot harness (Celia)

Celia is a PICO-8 TAS framework (built on picolove) that runs `.p8` files
unmodified. We use it for Murdercrab because the cart is token-full and cannot
be instrumented from inside. All TAS controls, RNG seeding, and (future) bot
logic live host-side.

Current state: seeded frame-by-frame TAS, headless regression traces, a
heuristic dodging bot (v2.2), and an RL env server + PPO trainer
(`tools/rl/`) whose nets play back in plain Lua. The dodger holds fire,
scores all 9 moves each frame against extrapolated bullets and enemies, chases
cherries, lines up under enemies, bombs only when every move is a hit, and
drives every menu. On one credit it clears loop 1 and dies somewhere in
loop 2-4. It's the baseline the nets have to beat and their behavior-cloning
teacher. The old scripted sweep (v2.0b) is still there as `MC_BOT=sweep`.

## Setup (macOS)

```
brew install --cask love      # LÖVE 11.4
./run.sh                      # launches Celia + Murdercrab
```

If `love --version` prints 11.4 (or 11.5) you're fine. Earlier versions have
known Celia incompatibilities.

## What you get

- Murdercrab running in Celia with `srand(42)` seeded before `_init` — every
  playthrough is reproducible frame-for-frame.
- All Celia TAS tooling:
  - `L` — advance one frame
  - `K` — rewind one frame
  - `D` — rewind to frame 0
  - `P` — real-time play
  - `Shift+P` — seek to the last input frame
  - `M` — save current input sequence to a `.lua` file
  - `Shift+W` — load an input sequence
  - `F3` / `F4` — start / stop GIF recording
  - `F6` — screenshot
  - `Ctrl+N` — new tab (parallel TAS attempt)
  - `Ctrl+Z` / `Ctrl+Shift+Z` — undo / redo (30 deep)
  - Interactive Lua console — inspect any cart global mid-TAS without editing
    the cart

## Watching the bot

```
./watch.sh [seed] [speed]     # e.g. ./watch.sh 7 2 for seed 7 at double speed
MC_GOD=1 ./watch.sh           # never dies: every level, bosses, true last boss
```

Starts playing on launch with sound and keeps running when the window isn't
focused. The title bar shows level, phase, rank, multiplier, lives, bombs and
continues (also echoed to the terminal every ~10s). Any key pauses; `P`
resumes. Savestates drop to one per 5s, so long watches stay light on memory.

## The bot (v2.2 dodger)

Each gameplay frame the bot holds fire and scores the 9 moves (8 directions +
standing still). It holds each move for `horizon` frames against every enemy
bullet and enemy body, extrapolated at their own velocity, using the cart's
`collides()` test: the 2x2 core at `p.x+3, p.y+3`, or the whole 8x8 ship for
diving enemies. A drifting enemy whose dive timer runs out inside the
lookahead is predicted to dive at the ship. I-frames are honored. Score terms,
weights in `M.W`:

| Weight | Term |
|--------|------|
| `hit` | a predicted hit, worse the sooner it lands |
| `near`, `near_r`, `decay` | threats passing within `near_r` px, discounted per frame |
| `cherry`, `item` | pull toward score cherries / bomb and 1UP pickups |
| `align` | enemies above within shot width, so fire keeps landing |
| `edge`, `edge_m` | within `edge_m` px of a screen edge |
| `home`, `home_y` | distance from a preferred height |
| `bomb_h` | bomb when the chosen move is hit by a bullet within this many frames (v2.1: when every move is) |
| `lex` | 1 = v2.2 move choice (safe beats hit, later hit beats sooner); 0 = v2.1 single score |

Goal terms are judged where the move leaves the ship after the lookahead.

`home` was 5 until `MC_DEATHLOG` showed where the dodger died: 80% of lives
were lost in the top 40 px of the screen, where it spent 10% of its time
chasing drops into close-range shotgun bursts with every move already hit.
One credit, seeds 201-212, 30-min cap:

| `home` | Mean survival | Alive at 30 min | Lives lost / hour | Mean score |
|-------:|--------------:|----------------:|------------------:|-----------:|
| 5 (old) | 920 s | 3/12 | 17.6 | 1332k |
| 20 | 1631 s | 9/12 | 10.3 | 1826k |
| **30** | 1683 s | 11/12 | 5.2 | 1530k |
| 45 | 1696 s | 10/12 | 4.1 | 1076k |
| 80 | 1779 s | 11/12 | 2.5 | 690k |
| 30, item/cherry halved | 1792 s | 12/12 | 2.8 | 744k |

Past 30 it trades score (fewer drops, slower kills) for little safety.

v2.2 (`lex`, default 1) fixes how it picks a move once no move is safe. The
death log showed 19 of 27 deaths where every move was predicted hit but not
all within `bomb_h`, so v2.1 never bombed, and goal terms could still outbid
a hit 1 frame out over one 4 frames out. Now a safe move always beats a hit
move, a later hit beats an earlier one (the score only breaks ties), and it
bombs when the chosen move is hit within `bomb_h` by a bullet: the cart's
bomb clears enemy bullets but not enemy bodies, and grants no i-frames.
Same seeds and cap:

| Dodger | Mean survival | Alive at 30 min | Lives lost / hour | Mean score |
|--------|--------------:|----------------:|------------------:|-----------:|
| v2.1, `home=30` | 1683 s | 11/12 | 5.2 | 1530k |
| **v2.2** | 1792 s | 12/12 | 3.7 | 1625k |
| v2.2, `bomb_h=3` | 1791 s | 12/12 | 5.2 | 1626k |

Bombing earlier doesn't help: `bomb_h` 5 and 9 on v2.1 lost 6.5 and 11.3 lives
an hour. `MC_W='{lex=0}'` reproduces v2.1.

The next death log (v2.2, 60-min runs) showed slow traps: a hit predicted at
the edge of the 12-frame lookahead, then counting down every frame because
no move escaped, often with the bombs already spent. A longer lookahead sees
them in time. One credit, seeds 201-212, 60-min cap:

| Dodger | Mean survival | Alive at 60 min | Lives lost / hour | Mean score |
|--------|--------------:|----------------:|------------------:|-----------:|
| v2.2, `horizon=12` | 3468 s | 10/12 | 5.6 | 2783k |
| **v2.2, `horizon=16`** (default) | 3589 s | 12/12 | 2.1 | 3078k |
| v2.2, `horizon=20` | 3590 s | 12/12 | 2.3 | 2844k |

A two-segment escape search (when no held move is safe, try turning once
after 4 or 8 frames, 81 paths) didn't beat `horizon=16` (3.2 and 2.3 lives
lost per hour) and was dropped.
`MC_W` overrides weights for one run. (An evolutionary tuner over these
weights was tried and dropped for the RL route; its first generation already
beat the defaults: fitness 6035 vs 4631 on 4 seeds, every seed alive at the
20-min cap vs none, so hand-tuning `M.W` still has headroom.)

## Neural-net bot (RL, `tools/rl/`)

Four pieces; the trainer knows nothing about the engine, so it carries over to
MurderCrab 2 unchanged:

1. **Env server** (`rl.sh`, `MC_RL=1`, `murdercrab_rl.lua`): the cart runs
   headlessly and speaks a line protocol on stdin/stdout. `reset <seed>
   [max_frames]` starts a one-credit game and returns once the ship is under
   control; `step <action>` holds the action for 4 frames (`MC_RL_SKIP`);
   replies are `@<reward> <done> <info...> <obs...>`. Try it by hand:
   `./rl.sh`, then `reset 7`, `step 4`, `quit`. On Windows LÖVE only has
   stdio as `lovec.exe`, so run that instead of `love`.
2. **Adapter** (also `murdercrab_rl.lua`), shared by the server and playback:
   - obs, 143 floats: ship (x, y, bombs, lives, i-frames), the 16 nearest
     enemy bullets (dx, dy, vx, vy), 8 nearest enemies (dx, dy, vx, vy, hp),
     4 nearest pickups (dx, dy), boss (present, hp fraction, dx, dy), level,
     phase, rank, loop, and 18 danger features: for each of the 9 moves, how
     soon the dodger's physics says it's hit and how close threats pass.
     `MC_RL_OBS=base` drops the danger features (125 floats);
     `MC_RL_OBS=teacher` adds the dodger's own pick as 10 more (one-hot move
     plus bomb flag, 153 floats), so the net starts as a copy of the dodger
     and learns when to overrule it. Playback picks the mode from the net's
     input size.
   - 18 actions: 9 moves x bomb on/off; fire is always held.
   - reward: score delta / 1000, +1 per phase reached, +3 per level, -10 per
     life lost (`MC_RL_REWARD='{"death":20}'` to change). `ppo.py --obs` and
     `--reward` set both for a run.
   - `MC_RL_TEACHER=1` adds the dodger's action to each reply.
3. **Trainer** (`tools/rl/`, Python, engine-agnostic): `lineenv.py` is a
   gymnasium vector env over server subprocesses, and `ppo.py` is single-file
   CleanRL-style PPO with TensorBoard logging, an optional DAgger
   behavior-cloning warm start from the teacher, and a Lua export of the actor.
4. **Playback**: `MC_POLICY=<policy.lua>` makes the bootstrap play the net
   with a plain-Lua MLP forward pass (greedy, a decision every 4 frames). Works
   with `watch.sh`, `trace.sh` and `eval.sh`.

```
cd ../rl && uv sync                                      # CPU torch, gymnasium, tensorboard
uv run ppo.py --run mine --bc-iters 4 --total-steps 1500000
uv run tensorboard --logdir runs
cd ../celia && MC_POLICY=../rl/runs/mine/policy.lua ./watch.sh
./eval.sh /tmp/ev ../rl/runs/mine/policy.lua 201 202 203  # one-credit eval (default seeds 201-206)
./eval.sh /tmp/ev sweep                                  # or dodger
```

Headless runs stub out LÖVE's draw calls: the cart never reads pixels back,
so game state is unchanged (traces stay byte-identical), and 6 parallel
servers no longer serialize on the GPU (about 2.7k steps/s across 6 envs on
the iMac M3; lockstep stepping waits on whichever process landed on an
efficiency core).

### Phase-1 smoke run (iMac M3, CPU only)

`uv run ppo.py --run mc1-danger --bc-iters 4 --total-steps 1500000` (other
flags at their defaults): 61 s of DAgger cloning (120k labelled
states), then 1.5M PPO steps in 13 min (~1.9k steps/s over 6 envs). Scored on
one credit, held-out seeds 201-212, 10-min cap, every net played through its
Lua export (`eval.sh`):

| Bot | Mean survival | Range | Clears L1 | Reached | Mean score | Alive at cap |
|-----|--------------:|------:|----------:|---------|-----------:|-------------:|
| sweep (v2.0b) | 60 s | 40-90 s | 1/12 | L1-L2 | 2k | 0/12 |
| net, raw obs only (BC + 0.4M PPO steps) | 50 s | 24-89 s | 1/12 | L1-L2 | 13k | 0/12 |
| net + danger features, BC only | 199 s | 112-316 s | 12/12 | L2-L4 | 121k | 0/12 |
| net + danger, PPO snapshot ~1/3 in | 337 s | 227-596 s | 12/12 | L4 to loop 2 L3 | 370k | 1/12 |
| net + danger, PPO final | 242 s | 186-315 s | 12/12 | L3-L5 | 409k | 0/12 |
| dodger (v2.1, the teacher) | 493 s | 265-596 s | 12/12 | L4 to loop 2 L2 | 696k | 7/12 |

- Raw coordinates weren't enough at this budget: that net never got box
  collision right and lost to the sweep bot. The danger features are what
  made it learn.
- PPO on top of cloning tripled the score and made runs consistent (every
  seed reaches L3+). Survival peaked mid-run and drifted back, likely because
  training episodes cap at 5 min (`--max-frames 18000`), which hides survival
  differences past that point. Longer caps or a heavier death penalty are the
  next knobs.
- The dodger is still well ahead. It replans every frame; the net decides
  every 4.

### Train-harder pass (Nov 2026)

What it took to get a net that plays as well as the dodger, and why PPO
hasn't beaten it yet:

1. **A 50M-step run made things worse.** 30-min episodes, 6.6 h. Once the
   teacher loss faded, PPO tripled its scoring rate and gave up survival
   (held-out 195 s): at score/1000 a lost life cost only ~3 s of points.
   Now `--reward '{score=1e-4}'`.
2. **The decision interval was a ceiling.** The dodger held to skip 4 is
   only as good as the best skip-4 nets (~330 s). Nets now train at skip 1.
3. **`--obs teacher`** shows the net the dodger's own pick, so cloning is
   exact (100% accuracy) and the clone plays like the dodger. It reads the
   pick live, so a better dodger makes a better net with no retraining.
   `--bc-smooth` keeps the clone from starting PPO at zero entropy.
4. **The dodger itself had the big wins** (`MC_DEATHLOG`, above): `home`
   5 -> 30 and the v2.2 move choice took it from 17.6 to 3.7 lives lost per
   hour.
5. **PPO on top of the clone hasn't found improvements.** With the teacher
   loss fading to 0 (`teach4`), it overruled the dodger on 10% of states by
   3M steps and lost 26.4 lives an hour. With `--bc-floor 0.1` (`teach5`) it
   stayed stable but never overruled it in 10M steps (greedy action = the
   dodger's on 6000 probe states). At 1-frame actions single moves barely
   change the outcome, and advantage normalization blows that noise up.

Results on one credit, seeds 201-212, 30-min cap:

| Bot | Mean survival | Alive at 30 min | Lives lost / hour | Mean score |
|-----|--------------:|----------------:|------------------:|-----------:|
| dodger v2.1, old weights | 920 s | 3/12 | 17.6 | 1332k |
| clone at skip 2 (v2.1 teacher) | 795 s | 0/12 | 23.4 | 1164k |
| PPO from that clone, skip 2, 4M steps (`teach-v1`) | 460 s | 0/12 | | |
| dodger v2.1, `home=30` | 1683 s | 11/12 | 5.2 | 1530k |
| clone at skip 1 (`home=30` teacher) | 1683 s | 11/12 | 5.7 | 1484k |
| PPO, skip 1, no floor, 3M steps (`teach4`) | 501 s | 0/12 | 26.4 | 328k |
| **dodger v2.2** | 1792 s | 12/12 | 3.7 | 1625k |

At a 60-min cap the clone tracks the dodger it reads (same seeds):

| Bot | Mean survival | Alive at 60 min | Lives lost / hour | Mean score | Reached |
|-----|--------------:|----------------:|------------------:|-----------:|---------|
| dodger v2.2, `horizon=12` | 3468 s | 10/12 | 5.6 | 2783k | loop 4 L4 to loop 6 L2 |
| net (skip-1 clone) on it | 3315 s | 10/12 | 5.6 | 2699k | loop 2 L5 to loop 6 L2 |
| **dodger v2.2, `horizon=16`** (current) | 3589 s | 12/12 | 2.1 | 3078k | loop 5 L6 to loop 6 L1 |
| net (same clone, no retraining) on it | 3503 s | 11/12 | 2.7 | 2934k | loop 4 L6 to loop 5 L6 |

The clone was cloned with 12-frame danger features; re-cloning at
`horizon=16` would likely close the small gap.

Commands for the current best net (the skip-1 clone):

```
uv run ppo.py --run clone --obs teacher --skip 2 --gamma 0.995 --bc-iters 4 --total-steps 0
sed 's/skip=2/skip=1/' runs/clone/bc.lua > runs/clone/bc-s1.lua   # the clone's weights don't depend on skip
```

## Changing the seed

Edit `murdercrab_bootstrap.lua`:

```lua
M.SEED = 42  -- any nonzero integer
```

Setting a different integer produces different enemy spawn positions,
powerup drops, etc. Use this to stress-test TAS inputs against RNG variance,
or to pick a "lucky" seed for score runs. `MC_SEED=7 ./run.sh` overrides it
without editing the file.

## Regression traces (headless)

`trace.sh` runs a cart under the bot with no TAS UI, writing one line of game
state per frame (score, rank, phase, player, enemy/bullet checksums), then the
saved high-score table and an RNG probe. Same seed + same logic gives a
byte-identical file. The LÖVE window opens off-screen as a background app
(`conf.lua` patch + `SDL_MAC_BACKGROUND_APP=1`), so traces don't pop up or
steal focus and several can run at once.

```
./regress.sh           # working-copy cart vs git HEAD, 6 scenarios, ~2 min
./trace.sh [cart] [out.txt] [frames] [seed]
```

`regress.sh` prints `IDENTICAL` or `DIFF` per scenario. Use it after token
cleanups and refactors: all-IDENTICAL means no observable behavior changed.
Deliberate gameplay changes will show DIFF, so check those with targeted traces.
It pins `MC_BOT=sweep` so its scenarios keep dying, continuing and reaching
name entry however good the dodger gets.

Scenario switches (env vars, combinable):

| Var | Effect |
|-----|--------|
| `MC_NOCONT=1` | never continue, so game over runs out to name entry and the table |
| `MC_GOD=1` | player never dies, so no continues and the L5 clear reaches the true last boss |
| `MC_EXIT=1` | press X at the victory screen (record score + exit) instead of looping |
| `MC_WATCH=1` | interactive only (see `watch.sh`): auto-play, run unfocused, stats in the title bar. `MC_SPEED=n` = n frames per displayed frame |
| `MC_ONEGAME=1` | stop the trace on the frame the first game ends (pair with `MC_NOCONT` for one-credit runs) |
| `MC_W='json'` | dodger weights for this run, e.g. `MC_W='{"hit":500}'` (JSON or a Lua table literal) |
| `MC_BOT=sweep` | the v2.0b bot instead of the dodger: fixed sweep, panic bomb, never dodges |
| `MC_POLICY=file` | play an exported net (`tools/rl` `policy.lua`) instead of the dodger |
| `MC_DEATHLOG=file` | dodger only: on each life lost, append its last 12 frames (position, move, predicted hit frame, how many moves were safe) and everything touching the ship |
| `MC_EVAL='lua'` | skip the run: execute a plain-Lua chunk against the cart's globals after `_init` and write its return value. Cart env has PICO-8's API, so use `tostr`, not `tostring`. |

In `MC_GOD=1` traces, `wh=` counts would-be hits: enemy bullets that touched
the player's hitbox (once per bullet). With `MC_BOT=sweep` that's the hits a
player who never dodges would have taken (raw bullet pressure); with the
dodger it's the bullets it failed to dodge. `balance.py` turns god + nocont traces into a per-level
table (time, would-hits/min, bullets on screen, rank, pickups, where one-credit
games end). Its docstring has the trace commands.

Example unit check:

```
MC_EVAL='credits_used = 2 init_game() return tostr(credits_used)' ./trace.sh "" /tmp/out.txt 1 && cat /tmp/out.txt
```

## Known limitations (upstream Celia)

- Celia uses floats by default where real PICO-8 uses 16.16 fixed-point. If
  you see sub-pixel drift relative to the real PICO-8 binary, launch with
  `./run.sh --fixp`.
- Savestates are ~0.5 MB per frame. A 20-minute NG+ run would be ~1.8 GB of
  memory. Short runs are fine; plan savestate budget for long runs.
- Spritesheet and audio buffers don't rewind perfectly. Cosmetic only — game
  logic is exact.
- No coroutine serialization. Murdercrab has no coroutines, so irrelevant for
  us. (Verified: no `cocreate` / `coresume` in `pico8/murdercrab.p8`.)

## What's next

- **RL phase 2+:** PPO needs a different setup to beat the dodger: a
  residual action that only fires in danger states, or RL over the dodger's
  weights per situation instead of raw moves. Then long runs on GOBLINDRIVER
  (CUDA) and MC2's env server (plan: `docs/rl-workflow.md`, drafted on the
  status-check branch).
- **v2.3:** the last death log (v2.2, `horizon=16`, 12 h of play, 25 lives
  lost, every one with all moves predicted hit) points at bomb economy (7
  with no bombs left, 5 inside the 60-frame bomb cooldown) and corners (ship
  pinned at x=120 during the loop-3 L6 true last boss, 25-52 bullets up).
- **v3:** cherry-chain + bomb-economy heuristics for the dodger (bombs refill
  on every death, so it should spend them freely), aiming for a loop-2 1CC.
- **v4:** hand-TAS starting from a Celia savestate, push into NG+ / secret
  L6 boss for a score-record run.

See `UPSTREAM.md` for Celia provenance and patch locations.

## Directory layout

```
tools/celia/
├── README.md                     # this file
├── README-celia-upstream.md      # Celia's original README
├── UPSTREAM.md                   # upstream commit SHA + patch notes
├── murdercrab_bootstrap.lua      # our host-side hook (RNG seed, bots, trace/eval modes)
├── run.sh                        # launcher
├── watch.sh                      # watch the bot play in real time
├── trace.sh                      # headless per-frame state trace
├── regress.sh                    # working copy vs HEAD across 6 seeded scenarios
├── balance.py                    # per-level balance table from traces
├── eval.sh                       # one-credit eval of sweep / dodger / a net over seeds
├── rl.sh                         # RL env server (stdin/stdout line protocol)
├── murdercrab_rl.lua             # RL adapter: obs, reward, actions, server, net playback
├── carts/
│   └── murdercrab.p8             # copy from ../../pico8/ (regenerated by run.sh; gitignored)
├── api.lua                       # Celia (modified: +4 lines near 1699)
└── ... (rest of vendored Celia)
```
