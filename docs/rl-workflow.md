# Neural-net bot: two-machine workflow

Goal: a PPO-trained agent that plays MurderCrab, built so the trainer carries
over unchanged to MurderCrab 2 (Picotron). MC1 is the proving ground.

**Status (2026-10-31):** phase 1 is done on branch `claude/vigilant-gates-ddd7e0`; its `tools/celia/README.md` has the commands and results. Raw positions alone weren't enough, so the observation grew to 143 floats with per-move danger features from the heuristic dodger. On one credit, the net clears L1 on 12 of 12 held-out seeds. The dodger it learned from still survives about twice as long, so it remains the bar.

## Machines

| | iMac (M3, 8 cores, 10-core GPU, 24 GB) | GOBLINDRIVER (Windows, RTX 4060 Ti) |
|---|---|---|
| Role | Dev box: env and adapter code, CPU smoke runs, eval, watching | Main learner (CUDA) plus env workers on its CPU |
| Runs | Variant experiments (reward or obs ablations) in parallel with the main run | Long/overnight runs |

- **Network:** Tailscale (`goblindriver`, 100.71.235.42, direct LAN path).
- **Code:** git. Push from either machine, pull on the other.
- **Checkpoints:** a small MLP is under 1 MB. They go in `runs/<name>/` (gitignored) and are copied with `scp` over Tailscale SSH.
- **Logs:** TensorBoard on GOBLINDRIVER, viewed from the iMac at `http://goblindriver:6006`.
- **Sessions:** one Claude session per machine, talking through SendMessage with Remote Control on (the pattern already used for jambox). Once sshd is up, add an SSH connection in the app, so this side can start sessions there and tail logs directly.

## Layers

1. **Env server (per engine, Lua).**
   - Talks over stdin/stdout. `reset <seed>` returns an obs; `step <action>` returns obs, reward, done and info.
   - Runs 4 frames per action.
   - MC1: a Celia `MC_RL=1` mode in `murdercrab_bootstrap.lua`, the same loop as trace mode but interactive. The LÖVE window is minimized. On Windows, use `lovec.exe` so stdio is attached.
2. **Game adapter (per game, Lua).** Builds the obs vector, the reward and the action map. Lives with the game.
3. **Trainer (shared, Python).**
   - A gymnasium vector env over subprocesses.
   - Single-file CleanRL-style PPO.
   - TensorBoard logging.
   - Exports weights to a Lua table.
   - Knows nothing about the engine.
4. **Playback.** The game side runs the exported MLP in plain Lua, which is a tiny forward pass. `watch.sh` then plays the trained net with no Python involved.

## MC1 specifics

- **Observation:** about 100 floats.
  - player x, y, bombs, lives
  - the 16 nearest enemy bullets: dx, dy, vx, vy
  - the 8 nearest enemies: dx, dy, hp
  - the 4 nearest cherries
  - whether a boss is present, and its HP
  - level, phase, rank
- **Actions:** 18 discrete: 9 moves × bomb on/off. Fire is always held.
- **Reward:**
  - scaled score delta
  - a bonus for clearing a phase or level
  - a large penalty for losing a life
- **Episodes:** one credit (`MC_NOCONT`), with a new seed each episode.
- **Baseline and warm start:** the heuristic dodger from the bot-trainer session is the score to beat. It also works as a teacher: clone its behavior before PPO.
- **Throughput:** about 3,700 frames/s per Celia process on the iMac, drawing included.
  - With 4 frames per action, that's about 900 decisions/s per process.
  - With 6 processes, that's about 5k decisions/s, or roughly 18M an hour.
  - Training is limited by the env on CPU, not the GPU. Both machines' CPUs add env throughput.
  - The 4060 Ti matters once the net becomes an attention model over the entity list instead of a fixed-size MLP.
- **Number format:** Celia uses floats unless `--fixp`. Spot-check trained policies with `--fixp`, which matches real PICO-8's fixed-point math.

## MC2 (Picotron)

Celia can't run Picotron. Picotron reportedly has a `-x` headless flag (no display), but it likely runs at real-time 60 fps; this is unverified. Training needs thousands of frames per second, so that's too slow.

Plan: build MC2 with a **sim core**, meaning update logic that never calls graphics or sound directly. It runs under plain Lua 5.4 with a roughly 50-line shim (`btn`, `rnd`/`srand`, `time`, no-op `sfx`). PICO-8-style shorthand such as `+=` and `!=` needs a small preprocessor, or should be kept out of the sim core.

What this buys:

- the RL env server for MC2
- Celia-style deterministic traces and regression diffs for MC2
- the option to ship the trained net inside MC2, since Picotron has no token cap: an attract-mode demo player, a rival ship, or an automatic difficulty tester

## Phases

0. **Set up GOBLINDRIVER.**
   - Enable sshd (see below).
   - Install Python with CUDA PyTorch, and LÖVE 11.5.
   - Clone the repo.
1. **Build and smoke-test on the iMac (CPU).** Build the MC1 env server, the trainer and the Lua export. Pass: the agent survives L1 longer than the sweep bot.
2. **Run in parallel.** The main run goes on GOBLINDRIVER while a variant runs on the iMac. Compare in TensorBoard, then watch the best checkpoint on the iMac.
3. **Distributed actors, only if env-bound.** iMac env workers stream rollouts to the GOBLINDRIVER learner over Tailscale.
4. **MC2.** Write the Lua 5.4 env server for MC2's sim core. The trainer is reused unchanged.

## GOBLINDRIVER sshd (admin PowerShell)

```powershell
Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0
Start-Service sshd; Set-Service sshd -StartupType Automatic
```

For an admin account, append the iMac's key (`~/.ssh/id_ed25519_media_imac.pub`) to `C:\ProgramData\ssh\administrators_authorized_keys`. Then lock that file down:

```powershell
icacls C:\ProgramData\ssh\administrators_authorized_keys /inheritance:r /grant "Administrators:F" /grant "SYSTEM:F"
```

Check from the iMac with `ssh jason@goblindriver`. Use the Windows account name if it differs.
