"""PPO for line-protocol env servers (CleanRL-style, single file).

  uv run ppo.py --run smoke                                # PPO from scratch
  uv run ppo.py --run bc --bc-iters 4 --bc-steps 30000     # clone the dodger first
  uv run ppo.py --run bc --total-steps 0 ...               # behavior cloning only
  uv run tensorboard --logdir runs

Writes runs/<run>/: TensorBoard events, agent.pt, and policy.lua / best.lua
(the actor as a Lua table) for MC_POLICY=<file> ./watch.sh. best.lua is the
policy with the best rolling-mean episode survival seen during PPO;
--save-every keeps numbered snapshots in snap/ to score afterwards with
tools/celia/eval.sh (training survival is a noisy pick).

Long run, continuing from a checkpoint:
  uv run ppo.py --run long --init runs/mc1-danger/agent.pt --max-frames 108000 \
      --total-steps 50000000 --bc-decay-steps 3000000 --save-every 1000000

Warm start (--bc-iters > 0, needs a server that reports a "teacher" action,
MC1: the v2.1 dodger): DAgger. Iteration 0 plays the teacher, later ones play
the current student; every visited state is labelled with the teacher's
action, the set is aggregated, and the actor is refit (cross-entropy; the
critic fits discounted returns). PPO then fine-tunes, with an auxiliary
cross-entropy toward the teacher (--bc-coef) decaying to 0 over the run, so
early PPO updates don't wreck the cloned policy.

Knows nothing about the engine: lineenv.LineVecEnv runs any server command.
"""
import argparse, collections, os, time

import numpy as np
import torch
import torch.nn as nn
from torch.utils.tensorboard import SummaryWriter

from lineenv import LineVecEnv

HERE = os.path.dirname(os.path.abspath(__file__))


def layer(i, o, std=np.sqrt(2)):
    lin = nn.Linear(i, o)
    nn.init.orthogonal_(lin.weight, std)
    nn.init.constant_(lin.bias, 0.0)
    return lin


class Agent(nn.Module):
    def __init__(self, n_obs, n_act, hidden):
        super().__init__()
        self.critic = nn.Sequential(layer(n_obs, hidden), nn.Tanh(), layer(hidden, hidden), nn.Tanh(), layer(hidden, 1, 1.0))
        self.actor = nn.Sequential(layer(n_obs, hidden), nn.Tanh(), layer(hidden, hidden), nn.Tanh(), layer(hidden, n_act, 0.01))

    def value(self, x):
        return self.critic(x).squeeze(-1)

    def act(self, x, action=None):
        logits = self.actor(x)
        dist = torch.distributions.Categorical(logits=logits)
        if action is None:
            action = dist.sample()
        return action, dist.log_prob(action), dist.entropy(), self.value(x), logits


def export_lua(agent, path, skip):
    """Actor -> Lua table for murdercrab_rl.lua R.load_policy (row-major w)."""
    lins = [m for m in agent.actor if isinstance(m, nn.Linear)]
    with open(path, 'w') as f:
        f.write(f'-- exported by tools/rl/ppo.py\nreturn {{obs={lins[0].in_features}, act={lins[-1].out_features}, '
                f'skip={skip}, act_fn="tanh", layers={{\n')
        for lin in lins:
            w = lin.weight.detach().cpu().numpy().ravel()
            b = lin.bias.detach().cpu().numpy()
            f.write(' {w={' + ','.join(f'{v:.6g}' for v in w) + '},\n  b={' + ','.join(f'{v:.6g}' for v in b) + '}},\n')
        f.write('}}\n')


class Stats:
    """Episode bookkeeping + TensorBoard logging."""

    def __init__(self, writer):
        self.w, self.recent = writer, collections.deque(maxlen=30)

    def episodes(self, info, step, tag='charts'):
        out = []
        for i in np.nonzero(info['_episode'])[0]:
            e = info['episode'][i]
            self.w.add_scalar(f'{tag}/episodic_return', e['r'], step)
            self.w.add_scalar(f'{tag}/episodic_length', e['l'], step)
            for k in ('score', 'progress', 'frames'):
                if k in e:
                    self.w.add_scalar(f'{tag}/{k}', e[k], step)
            out.append(e)
            self.recent.append(e)
        return out

    def summary(self):
        if not self.recent:
            return 'no episodes yet'
        f = np.mean([e.get('frames', 0) for e in self.recent]) / 60
        p = np.mean([e.get('progress', 0) for e in self.recent])
        s = np.mean([e.get('score', 0) for e in self.recent])
        return f'last {len(self.recent)} eps: survive {f:.0f}s, progress {p:.1f}, score {s:.0f}'


def discounted(rews, dones, gamma):
    """Per-env discounted returns over a [T, N] buffer (0 past the end)."""
    ret, run = np.zeros_like(rews), np.zeros(rews.shape[1], dtype=np.float32)
    for t in reversed(range(len(rews))):
        run = rews[t] + gamma * run * (1 - dones[t])
        ret[t] = run
    return ret


def behavior_clone(a, envs, agent, opt, stats, writer, dev):
    obs, info = envs.reset(seed=a.seed)
    data_o, data_a, data_r = [], [], []
    step = 0
    for it in range(a.bc_iters):
        T = a.bc_steps // a.num_envs
        bo = np.zeros((T, a.num_envs, obs.shape[1]), np.float32)
        ba = np.zeros((T, a.num_envs), np.int64)
        br, bd = np.zeros((T, a.num_envs), np.float32), np.zeros((T, a.num_envs), np.float32)
        for t in range(T):
            teach = info['teacher'].astype(np.int64)
            if it == 0:
                act = teach
            else:
                with torch.no_grad():
                    act = agent.actor(torch.as_tensor(obs, device=dev)).argmax(-1).cpu().numpy()
            bo[t], ba[t] = obs, teach
            obs, r, term, trunc, info = envs.step(np.maximum(act, 0))
            br[t], bd[t] = r, term | trunc
            step += a.num_envs
            stats.episodes(info, step, 'bc')
        keep = ba.reshape(-1) >= 0
        data_o.append(bo.reshape(-1, bo.shape[2])[keep])
        data_a.append(ba.reshape(-1)[keep])
        data_r.append(discounted(br, bd, a.gamma).reshape(-1)[keep])
        X = torch.as_tensor(np.concatenate(data_o), device=dev)
        Y = torch.as_tensor(np.concatenate(data_a), device=dev)
        R = torch.as_tensor(np.concatenate(data_r), device=dev)
        for ep in range(a.bc_epochs):
            perm = torch.randperm(len(X), device=dev)
            for s in range(0, len(X), 512):
                idx = perm[s:s + 512]
                loss = nn.functional.cross_entropy(agent.actor(X[idx]), Y[idx], label_smoothing=a.bc_smooth) \
                    + 0.5 * ((agent.value(X[idx]) - R[idx]) ** 2).mean()
                opt.zero_grad()
                loss.backward()
                opt.step()
        with torch.no_grad():
            acc = (agent.actor(X).argmax(-1) == Y).float().mean().item()
        writer.add_scalar('bc/accuracy', acc, step)
        print(f'bc iter {it} ({"teacher" if it == 0 else "student"} plays): {len(X)} labelled states, '
              f'train acc {acc:.3f} | {stats.summary()}', flush=True)
        stats.recent.clear()
    export_lua(agent, os.path.join(a.out, 'bc.lua'), a.skip)
    return step


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('--run', default='ppo')
    ap.add_argument('--game', default='mc1', help="server: a lineenv.GAMES key or a command path")
    ap.add_argument('--num-envs', type=int, default=6)
    ap.add_argument('--max-frames', type=int, default=18000, help='episode cap (truncation), 0 = none')
    ap.add_argument('--skip', type=int, default=4, help='frames per action (MC_RL_SKIP)')
    ap.add_argument('--obs', default='danger', help='MC_RL_OBS: base | danger | teacher')
    ap.add_argument('--reward', default='', help='MC_RL_REWARD override, e.g. "{score=1e-4}"')
    ap.add_argument('--total-steps', type=int, default=1_000_000)
    ap.add_argument('--num-steps', type=int, default=256, help='rollout length per env')
    ap.add_argument('--lr', type=float, default=2.5e-4)
    ap.add_argument('--gamma', type=float, default=0.99)
    ap.add_argument('--gae-lambda', type=float, default=0.95)
    ap.add_argument('--minibatches', type=int, default=4)
    ap.add_argument('--epochs', type=int, default=4)
    ap.add_argument('--clip', type=float, default=0.2)
    ap.add_argument('--ent-coef', type=float, default=0.003)
    ap.add_argument('--vf-coef', type=float, default=0.5)
    ap.add_argument('--vf-clip', type=float, default=0.2, help='value-loss clip range (0 = plain MSE)')
    ap.add_argument('--vf-warmup', type=int, default=0,
                    help='first N updates train only the critic, so a cloned actor isn\'t steered by a cold value net')
    ap.add_argument('--bc-coef', type=float, default=0.5, help='aux CE toward the teacher, decays to 0')
    ap.add_argument('--bc-decay-steps', type=int, default=0, help='PPO steps for --bc-coef to reach 0 (0 = whole run)')
    ap.add_argument('--save-every', type=int, default=0, help='also keep snap/policy-<step>.lua every N steps')
    ap.add_argument('--max-grad-norm', type=float, default=0.5)
    ap.add_argument('--hidden', type=int, default=256)
    ap.add_argument('--bc-iters', type=int, default=0)
    ap.add_argument('--bc-steps', type=int, default=30000, help='states collected per DAgger iteration')
    ap.add_argument('--bc-epochs', type=int, default=8)
    ap.add_argument('--bc-smooth', type=float, default=0.1,
                    help='label smoothing on teacher CE, so a near-perfect clone keeps some entropy for PPO')
    ap.add_argument('--init', help='start from an agent.pt')
    ap.add_argument('--seed', type=int, default=1)
    a = ap.parse_args()
    a.out = os.path.join(HERE, 'runs', a.run)
    os.makedirs(a.out, exist_ok=True)
    torch.manual_seed(a.seed)
    np.random.seed(a.seed)
    dev = torch.device('cpu')
    writer = SummaryWriter(a.out)
    writer.add_text('args', str(vars(a)))
    # aux CE toward the teacher only when warm-starting (cloning now, or --init)
    teacher = a.bc_coef > 0 and (a.bc_iters > 0 or bool(a.init))
    envs = LineVecEnv(a.num_envs, a.game, a.max_frames, seed=a.seed,
                      env={'MC_RL_SKIP': str(a.skip), 'MC_RL_TEACHER': '1' if teacher else '0',
                           'MC_RL_OBS': a.obs, 'MC_RL_REWARD': a.reward})
    n_obs, n_act = envs.single_observation_space.shape[0], envs.single_action_space.n
    agent = Agent(n_obs, n_act, a.hidden).to(dev)
    if a.init:
        agent.load_state_dict(torch.load(a.init))
    stats = Stats(writer)
    t0 = time.time()
    print(f'{a.num_envs} envs, obs {n_obs}, actions {n_act}, out {a.out}', flush=True)

    step = 0
    if a.bc_iters:
        step = behavior_clone(a, envs, agent, torch.optim.Adam(agent.parameters(), lr=1e-3), stats, writer, dev)
        print(f'behavior cloning done in {time.time() - t0:.0f}s', flush=True)
    opt = torch.optim.Adam(agent.parameters(), lr=a.lr, eps=1e-5)

    N, T = a.num_envs, a.num_steps
    obs_b = torch.zeros((T, N, n_obs))
    act_b, logp_b, rew_b, done_b, val_b, teach_b = (torch.zeros((T, N)) for _ in range(6))
    next_obs, info = envs.reset(seed=a.seed + 1)
    next_obs, next_done = torch.as_tensor(next_obs), torch.zeros(N)
    next_teach = torch.as_tensor(info.get('teacher', np.full(N, -1.0)))
    updates = a.total_steps // (N * T)
    best = -1.0
    ppo_start, ppo_t0 = step, time.time()
    for u in range(1, updates + 1):
        frac = 1.0 - (u - 1) / updates
        opt.param_groups[0]['lr'] = frac * a.lr
        bc_frac = max(0.0, 1 - (step - ppo_start) / a.bc_decay_steps) if a.bc_decay_steps else frac
        bc_coef = a.bc_coef * bc_frac if teacher else 0.0
        for t in range(T):
            step += N
            obs_b[t], done_b[t], teach_b[t] = next_obs, next_done, next_teach
            with torch.no_grad():
                action, logp, _, value, _ = agent.act(next_obs)
            act_b[t], logp_b[t], val_b[t] = action, logp, value
            o, r, term, trunc, info = envs.step(action.numpy())
            r = torch.as_tensor(r)
            for i in np.nonzero(trunc)[0]:  # bootstrap a frame-cap cut
                with torch.no_grad():
                    r[i] += a.gamma * agent.value(torch.as_tensor(info['final_obs'][i])).item()
            rew_b[t] = r
            next_obs, next_done = torch.as_tensor(o), torch.as_tensor(term | trunc, dtype=torch.float32)
            next_teach = torch.as_tensor(info.get('teacher', np.full(N, -1.0)))
            stats.episodes(info, step)

        with torch.no_grad():  # GAE
            next_val = agent.value(next_obs)
            adv, last = torch.zeros_like(rew_b), 0
            for t in reversed(range(T)):
                nonterm = 1.0 - (next_done if t == T - 1 else done_b[t + 1])
                nv = next_val if t == T - 1 else val_b[t + 1]
                delta = rew_b[t] + a.gamma * nv * nonterm - val_b[t]
                adv[t] = last = delta + a.gamma * a.gae_lambda * nonterm * last
            ret = adv + val_b

        bo, ba, blp = obs_b.reshape(-1, n_obs), act_b.reshape(-1).long(), logp_b.reshape(-1)
        badv, bret, bval, bteach = adv.reshape(-1), ret.reshape(-1), val_b.reshape(-1), teach_b.reshape(-1).long()
        mb = N * T // a.minibatches
        for _ in range(a.epochs):
            perm = torch.randperm(N * T)
            for s in range(0, N * T, mb):
                idx = perm[s:s + mb]
                _, nlp, ent, nv, logits = agent.act(bo[idx], ba[idx])
                ratio = (nlp - blp[idx]).exp()
                with torch.no_grad():
                    kl = ((ratio - 1) - (nlp - blp[idx])).mean()
                    clipfrac = ((ratio - 1).abs() > a.clip).float().mean()
                madv = badv[idx]
                madv = (madv - madv.mean()) / (madv.std() + 1e-8)
                pg = torch.max(-madv * ratio, -madv * ratio.clamp(1 - a.clip, 1 + a.clip)).mean()
                vl = (nv - bret[idx]) ** 2
                if a.vf_clip > 0:
                    v_clip = bval[idx] + (nv - bval[idx]).clamp(-a.vf_clip, a.vf_clip)
                    vl = torch.max(vl, (v_clip - bret[idx]) ** 2)
                vl = 0.5 * vl.mean()
                warm = u <= a.vf_warmup
                loss = a.vf_coef * vl if warm else pg - a.ent_coef * ent.mean() + a.vf_coef * vl
                lab = bteach[idx]
                if bc_coef > 0 and not warm and (lab >= 0).any():
                    loss = loss + bc_coef * nn.functional.cross_entropy(logits[lab >= 0], lab[lab >= 0],
                                                                        label_smoothing=a.bc_smooth)
                opt.zero_grad()
                loss.backward()
                nn.utils.clip_grad_norm_(agent.parameters(), a.max_grad_norm)
                opt.step()

        sps = (step - ppo_start) / (time.time() - ppo_t0)
        agree = (bteach >= 0).any() and (ba[bteach >= 0] == bteach[bteach >= 0]).float().mean().item()
        for k, v in (('losses/policy', pg.item()), ('losses/value', vl.item()), ('losses/entropy', ent.mean().item()),
                     ('losses/approx_kl', kl.item()), ('losses/clipfrac', clipfrac.item()), ('charts/SPS', sps),
                     ('charts/lr', opt.param_groups[0]['lr']), ('charts/teacher_agreement', float(agree or 0)),
                     ('charts/bc_coef', bc_coef)):
            writer.add_scalar(k, v, step)
        if stats.recent:
            surv = np.mean([e.get('frames', 0) for e in stats.recent])
            if len(stats.recent) >= 10 and surv > best:
                best = surv
                export_lua(agent, os.path.join(a.out, 'best.lua'), a.skip)
        if a.save_every and step // a.save_every > (step - N * T) // a.save_every:
            os.makedirs(os.path.join(a.out, 'snap'), exist_ok=True)
            export_lua(agent, os.path.join(a.out, 'snap', f'policy-{step}.lua'), a.skip)
            torch.save(agent.state_dict(), os.path.join(a.out, 'snap', f'agent-{step}.pt'))
        if u % 10 == 0 or u == updates:
            print(f'update {u}/{updates} step {step} | {sps:.0f} sps | {stats.summary()} | '
                  f'ent {ent.mean().item():.2f} kl {kl.item():.4f} agree {float(agree or 0):.2f}', flush=True)
            torch.save(agent.state_dict(), os.path.join(a.out, 'agent.pt'))
            export_lua(agent, os.path.join(a.out, 'policy.lua'), a.skip)

    torch.save(agent.state_dict(), os.path.join(a.out, 'agent.pt'))
    export_lua(agent, os.path.join(a.out, 'policy.lua'), a.skip)
    envs.close()
    writer.close()
    print(f'done in {time.time() - t0:.0f}s: {a.out}/policy.lua (best rolling survival: best.lua)', flush=True)


if __name__ == '__main__':
    main()
