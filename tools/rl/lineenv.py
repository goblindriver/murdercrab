"""Gymnasium vector env over line-protocol env servers (one subprocess each).

Engine-agnostic: a server is any command that speaks this protocol on
stdin/stdout (replies start with "@"; other stdout lines are skipped):

  startup             -> @ready obs=<n> act=<n> info=<k1,k2,...>
  reset <seed> [maxf] -> @<reward> <done> <info...> <obs...>
  step <action>       -> @<reward> <done> <info...> <obs...>
  quit

MC1's server is tools/celia/rl.sh (Celia, murdercrab_rl.lua). An MC2 server
under Lua 5.4 only has to print the same lines.

Servers run concurrently: step() writes every action first, then reads every
reply. Finished episodes reset in the same step with a fresh seed (the
returned obs is the new episode's first); the finished episode's stats and
final obs are in infos["episode"] / infos["final_obs"], masked by "_episode".
An info field named "trunc" marks a frame-cap ending as truncated instead of
terminated.
"""
import os, subprocess

import gymnasium as gym
import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
GAMES = {
    'mc1': [os.path.join(HERE, '..', 'celia', 'rl.sh')],
}


class Server:
    def __init__(self, cmd, env=None):
        self.p = subprocess.Popen(cmd, stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL,
                                  text=True, bufsize=1, env={**os.environ, **(env or {})})
        head = self.readline().split()
        assert head[0] == 'ready', f'bad server greeting: {head}'
        kv = dict(t.split('=', 1) for t in head[1:])
        self.n_obs, self.n_act = int(kv['obs']), int(kv['act'])
        self.info_keys = kv.get('info', '').split(',') if kv.get('info') else []

    def readline(self):
        while True:
            line = self.p.stdout.readline()
            if not line:
                raise RuntimeError(f'env server exited (code {self.p.poll()})')
            if line.startswith('@'):
                return line[1:]

    def send(self, line):
        self.p.stdin.write(line + '\n')
        self.p.stdin.flush()

    def recv(self):
        t = self.readline().split()
        k = len(self.info_keys)
        info = dict(zip(self.info_keys, map(float, t[2:2 + k])))
        return float(t[0]), t[1] == '1', info, np.asarray(t[2 + k:], dtype=np.float32)

    def close(self):
        try:
            self.send('quit')
            self.p.wait(timeout=5)
        except Exception:
            self.p.kill()


class LineVecEnv(gym.vector.VectorEnv):
    def __init__(self, num_envs, game='mc1', max_frames=0, env=None, seed=0):
        cmd = GAMES.get(game, [game])
        self.servers = [Server(cmd, env) for _ in range(num_envs)]
        s = self.servers[0]
        self.num_envs, self.max_frames, self.info_keys = num_envs, max_frames, s.info_keys
        self.single_observation_space = gym.spaces.Box(-np.inf, np.inf, (s.n_obs,), np.float32)
        self.single_action_space = gym.spaces.Discrete(s.n_act)
        self.observation_space = gym.vector.utils.batch_space(self.single_observation_space, num_envs)
        self.action_space = gym.vector.utils.batch_space(self.single_action_space, num_envs)
        self.rng = np.random.default_rng(seed)
        self.ep_ret = np.zeros(num_envs)
        self.ep_len = np.zeros(num_envs, dtype=np.int64)
        self.last_info = [{} for _ in range(num_envs)]

    def next_seed(self):
        return int(self.rng.integers(1, 2**31 - 1))

    def _infos(self, infos):
        return {k: np.array([inf.get(k, 0.0) for inf in infos]) for k in self.info_keys}

    def reset(self, seed=None, options=None):
        if seed is not None:
            self.rng = np.random.default_rng(seed)
        for srv in self.servers:
            srv.send(f'reset {self.next_seed()} {self.max_frames}')
        obs, infos = [], []
        for i, srv in enumerate(self.servers):
            _, _, info, o = srv.recv()
            obs.append(o); infos.append(info)
        self.ep_ret[:] = 0
        self.ep_len[:] = 0
        self.last_info = infos
        return np.stack(obs), self._infos(infos)

    def step(self, actions):
        for srv, a in zip(self.servers, actions):
            srv.send(f'step {int(a)}')
        n = self.num_envs
        obs, rew = [None] * n, np.zeros(n, dtype=np.float32)
        term, trunc = np.zeros(n, dtype=bool), np.zeros(n, dtype=bool)
        infos, ep_mask = [None] * n, np.zeros(n, dtype=bool)
        episode = [None] * n
        final_obs = [None] * n
        done_idx = []
        for i, srv in enumerate(self.servers):
            r, done, info, o = srv.recv()
            rew[i], obs[i], infos[i] = r, o, info
            self.ep_ret[i] += r
            self.ep_len[i] += 1
            if done:
                trunc[i] = info.get('trunc', 0) > 0
                term[i] = not trunc[i]
                ep_mask[i] = True
                episode[i] = {'r': self.ep_ret[i], 'l': self.ep_len[i], **info}
                final_obs[i] = o
                done_idx.append(i)
        for i in done_idx:  # autoreset: all resets in flight at once
            self.servers[i].send(f'reset {self.next_seed()} {self.max_frames}')
        for i in done_idx:
            _, _, infos[i], obs[i] = self.servers[i].recv()
            self.ep_ret[i] = 0
            self.ep_len[i] = 0
        out = self._infos(infos)
        out['episode'], out['final_obs'], out['_episode'] = episode, final_obs, ep_mask
        return np.stack(obs), rew, term, trunc, out

    def close(self, **kwargs):
        for srv in self.servers:
            srv.close()
