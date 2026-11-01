-- murdercrab_rl.lua
-- Neural-net side of the Murdercrab bot, loaded by murdercrab_bootstrap.lua:
--
--   * Env server (MC_RL=1, see rl.sh): runs the cart headlessly and speaks a
--     line protocol on stdin/stdout so tools/rl/ can train against it.
--   * Adapter: the observation vector, reward and action map. Shared by the
--     server and playback so both see exactly the same inputs.
--   * Playback (MC_POLICY=<policy.lua>): a plain-Lua MLP forward pass that
--     drives the ship, so watch.sh / trace.sh can play an exported net.
--
-- Protocol (one line each way; replies start with "@", anything else on
-- stdout is noise for the trainer to skip):
--   startup             -> @ready obs=<n> act=<n> info=<k1,k2,...>
--   reset <seed> [maxf] -> @<reward> <done> <info...> <obs...>
--   step <action>       -> @<reward> <done> <info...> <obs...>
--   quit
-- reset starts a fresh one-credit game on <seed> and returns once the ship
-- is under control; maxf caps the episode at that many gameplay frames
-- (counted as a truncation, info trunc=1). step holds <action> for SKIP
-- frames. done=1 on game over or the cap.

local R = {}

-- ─── Adapter ───────────────────────────────────────────────────────────────

-- Frames per action. Bomb (btnp) is pressed on the first of them only, so the
-- next bomb action is a fresh press.
R.SKIP = tonumber(os.getenv("MC_RL_SKIP") or "") or 4

-- 18 actions: move index (0 = still, then the dodger's MOVES order) + 9 if
-- bombing. Fire is always held.
R.N_ACT = 18

local N_BUL, N_ENE, N_PICK = 16, 8, 4
R.N_BASE = 5 + N_BUL * 4 + N_ENE * 5 + N_PICK * 2 + 4 + 4
-- Danger features: the dodger's physics per move (how soon it's hit, how
-- close threats pass), so the net doesn't have to rediscover box collision
-- from raw coordinates. MC_RL_OBS=base drops them; playback picks by the
-- net's input size.
R.N_DANGER = 9 * 2
R.DANGER = os.getenv("MC_RL_OBS") ~= "base"
R.N_OBS = R.N_BASE + (R.DANGER and R.N_DANGER or 0)

-- Reward per step: score delta, a bonus per phase advanced (5 a level) and
-- per level cleared, a penalty per life lost. MC_RL_REWARD overrides any of
-- them (JSON or Lua table).
R.REWARD = {score = 1 / 1000, phase = 1, level = 3, death = 10}

R.INFO = {"score", "progress", "lives", "frames", "trunc", "teacher"}

local PHASES = {pre_mini_boss = 0, mini_boss = 1, post_mini_boss = 2, final_boss = 3,
	level_complete = 4, victory_lap = 4, true_last_boss = 4}

-- Furthest point reached, as one number: 5 phases a level, 25 a loop.
function R.progress(c)
	local name = c.phase == "normal" and c.phase_state or c.phase
	return (((c.game_loop or 1) - 1) * 5 + ((c.current_level or 1) - 1)) * 5 + (PHASES[name] or 0)
end

function R.score(c) return (c.score_hi or 0) * 1000 + (c.score or 0) end

-- Normal enemies' per-frame velocity, as in update_normal_enemy().
local function enemy_v(e)
	if e.type ~= "normal" then return e.dx or 0, 0 end
	if e.state == 0 then return (e.dir or 0) * 0.25, e.dy or 0 end
	if e.state == 1 then return (e.dir or 0) * 0.35, 0 end
	return e.dx or 0, e.dy or 0
end

local boss_max = setmetatable({}, {__mode = "k"}) -- boss -> highest health seen

-- Fill `slots` nearest of `list` (by Chebyshev distance of centers, the
-- metric collides() effectively uses) into o via put(o, item, dx, dy);
-- empty slots get pad(o).
local function nearest(o, list, cx, cy, slots, put, pad, keep)
	local cand = {}
	for _, it in ipairs(list or {}) do
		if not keep or keep(it) then
			local dx = it.x + (it.width or 8) / 2 - cx
			local dy = it.y + (it.height or 8) / 2 - cy
			cand[#cand + 1] = {it, dx, dy, math.max(math.abs(dx), math.abs(dy))}
		end
	end
	table.sort(cand, function(a, b) return a[4] < b[4] end)
	for i = 1, slots do
		local c = cand[i]
		if c then put(o, c[1], c[2], c[3]) else pad(o) end
	end
end

local function push(o, ...)
	for i = 1, select("#", ...) do o[#o + 1] = select(i, ...) end
end

-- Observation, all roughly in [-1, 1]. Positions are relative to the ship's
-- center in 64 px units; empty slots sit 128 px off (above for threats,
-- below for pickups) so they read as harmless. The dodger's plan for this
-- state is kept in R.last_plan (teacher reuses it).
function R.observe(c, M, danger)
	local p, o = c.player, {}
	local cx, cy = p.x + 4, p.y + 4
	push(o, p.x / 120, p.y / 120, math.min(p.bombs or 0, 5) / 5, math.min(p.lives or 0, 5) / 5,
		math.min(p.invincible_timer or 0, 60) / 60)
	nearest(o, c.enemy_bullets, cx, cy, N_BUL,
		function(o, b, dx, dy) push(o, dx / 64, dy / 64, (b.dx or 0) / 4, (b.dy or 0) / 4) end,
		function(o) push(o, 0, -2, 0, 0) end)
	nearest(o, c.enemies, cx, cy, N_ENE,
		function(o, e, dx, dy)
			local vx, vy = enemy_v(e)
			push(o, dx / 64, dy / 64, vx / 4, vy / 4, math.min(e.health or 0, 3) / 3)
		end,
		function(o) push(o, 0, -2, 0, 0, 0) end)
	nearest(o, c.powerups, cx, cy, N_PICK,
		function(o, _, dx, dy) push(o, dx / 64, dy / 64) end,
		function(o) push(o, 0, 2) end)
	local boss
	for _, e in ipairs(c.enemies or {}) do
		if e.type ~= "normal" then boss = e break end
	end
	if boss then
		boss_max[boss] = math.max(boss_max[boss] or 0, boss.health or 0)
		push(o, 1, (boss.health or 0) / math.max(boss_max[boss], 1),
			(boss.x + (boss.width or 8) / 2 - cx) / 64, (boss.y + (boss.height or 8) / 2 - cy) / 64)
	else
		push(o, 0, 0, 0, -2)
	end
	local name = c.phase == "normal" and c.phase_state or c.phase
	push(o, (c.current_level or 1) / 6, (PHASES[name] or 0) / 4, (c.rank or 0) / 10, ((c.game_loop or 1) - 1) / 3)
	if danger then
		local plan = {M.plan(c)}
		R.last_plan = plan
		local hits, nears, H = plan[3], plan[4], plan[5]
		for mi = 1, 9 do
			push(o, hits[mi] and (H - hits[mi] + 1) / H or 0, math.min(nears[mi] / 4, 1))
		end
	end
	return o
end

-- Button mask for action a on the i-th frame of its SKIP.
function R.action_mask(M, a, i)
	local mv = M.MOVES[a % 9 + 1]
	local mask = M.press(0, M.BTN.O)
	if mv[1] < 0 then mask = M.press(mask, M.BTN.LEFT) elseif mv[1] > 0 then mask = M.press(mask, M.BTN.RIGHT) end
	if mv[2] < 0 then mask = M.press(mask, M.BTN.UP) elseif mv[2] > 0 then mask = M.press(mask, M.BTN.DOWN) end
	if a >= 9 and i == 1 then mask = M.press(mask, M.BTN.X) end
	return mask
end

-- The v2.1 dodger's choice in action-space terms (behavior-cloning target).
-- Reuses the plan observe() just made, when it made one.
function R.teacher(M, c, plan)
	local mi, doomed = unpack(plan or {M.plan(c)})
	local bomb = doomed and (c.player.bombs or 0) > 0 and not c.bomb_active
	return mi - 1 + (bomb and 9 or 0)
end

-- ─── Env server ────────────────────────────────────────────────────────────

local function fmt(v)
	if v == math.floor(v) and math.abs(v) < 1e9 then return string.format("%d", v) end
	return string.format("%.4g", v)
end

function R.serve(M, cart, api)
	local pico8 = _G.pico8
	local over = M.parse_table(os.getenv("MC_RL_REWARD"))
	for k, v in pairs(over or {}) do
		if R.REWARD[k] ~= nil and type(v) == "number" then R.REWARD[k] = v end
	end
	local W, want_teacher = R.REWARD, os.getenv("MC_RL_TEACHER") == "1"
	pico8.fps = cart._update60 and 60 or 30
	pico8.frametime = 1 / pico8.fps

	-- mirrors tas.lua rawstep(): frame++, input, update, draw
	local function frame(mask)
		pico8.frames = pico8.frames + 1
		M.apply_mask(pico8, mask)
		M.last_mask = mask
		if cart._update60 then cart._update60() elseif cart._update then cart._update() end
		love.graphics.push()
		restore_clip()
		restore_camera()
		if cart._draw then cart._draw() end
		love.graphics.pop()
	end

	local function playing()
		return cart.game_state == "game" and cart.player and cart.player.lives and not cart.game_over
	end

	local ep = {}
	local function reply(reward, done)
		local c, info = cart, {}
		info[1], info[2], info[3] = R.score(c), R.progress(c), c.player.lives or 0
		info[4], info[5] = ep.frames, ep.trunc and 1 or 0
		R.last_plan = nil
		local obs = R.observe(c, M, R.DANGER)
		info[6] = (want_teacher and not done) and R.teacher(M, c, R.last_plan) or -1
		local parts = {"@" .. fmt(reward), done and "1" or "0"}
		for _, v in ipairs(info) do parts[#parts + 1] = fmt(v) end
		for _, v in ipairs(obs) do parts[#parts + 1] = fmt(v) end
		io.write(table.concat(parts, " "), "\n")
		io.flush()
	end

	local function snapshot()
		ep.score, ep.progress, ep.lives, ep.level = R.score(cart), R.progress(cart), cart.player.lives, cart.current_level
	end

	local function reset(seed, maxf)
		api.srand(seed)
		pico8.frames = 0
		-- file-scope globals, as on a fresh load, then _init
		cart.game_state, cart.title_timer, cart.current_level, cart.credits = "title", 0, 1, 0
		cart.warp_time, cart.current_music = 0, -1
		cart._init()
		local guard = 0
		while not playing() do -- bot drives the menus: coin, start, warp in
			frame(M.compute_action(cart, pico8.frames))
			guard = guard + 1
			assert(guard < 6000, "reset: never reached gameplay")
		end
		ep = {frames = 0, maxf = maxf, trunc = false}
		snapshot()
		reply(0, false)
	end

	local function step(a)
		for i = 1, R.SKIP do
			frame(R.action_mask(M, a, i))
			ep.frames = ep.frames + 1
			if cart.game_over then break end
		end
		local lives = cart.player.lives or 0
		local r = (R.score(cart) - ep.score) * W.score
			+ math.max(0, R.progress(cart) - ep.progress) * W.phase
			+ math.max(0, (cart.current_level or 1) - ep.level) * W.level
			- math.max(0, ep.lives - lives) * W.death
		ep.trunc = not cart.game_over and ep.maxf > 0 and ep.frames >= ep.maxf
		snapshot()
		reply(r, cart.game_over or ep.trunc)
	end

	io.write(string.format("@ready obs=%d act=%d info=%s\n", R.N_OBS, R.N_ACT, table.concat(R.INFO, ",")))
	io.flush()
	-- an error must exit (the trainer sees EOF), not park LÖVE on its error screen
	local ok, err = pcall(function()
		for line in io.lines() do
			local cmd, a, b = line:match("^(%S+)%s*(%S*)%s*(%S*)")
			if cmd == "reset" then reset(tonumber(a) or 1, tonumber(b) or 0)
			elseif cmd == "step" then step(math.max(0, math.min(R.N_ACT - 1, tonumber(a) or 0)))
			elseif cmd == "quit" then break end
		end
	end)
	if not ok then io.stderr:write("murdercrab_rl: ", tostring(err), "\n") end
	os.exit(ok and 0 or 1)
end

-- ─── Playback ──────────────────────────────────────────────────────────────

-- Load an exported policy (tools/rl/export.py): a Lua file returning
-- {obs=, act=, skip=, act_fn="tanh", layers={{w={...}, b={...}}, ...}}
-- with each w row-major (out x in). Runs sandboxed: data only.
function R.load_policy(path)
	local f = assert(io.open(path, "r"), "MC_POLICY: can't open " .. path)
	local src = f:read("*a")
	f:close()
	local chunk = assert(loadstring(src, "=" .. path))
	local net = setfenv(chunk, {})()
	net.danger = net.obs == R.N_BASE + R.N_DANGER
	assert(net.danger or net.obs == R.N_BASE,
		("MC_POLICY: net expects %d obs, adapter makes %d (+%d danger)"):format(net.obs or -1, R.N_BASE, R.N_DANGER))
	return net
end

-- Greedy action: argmax of the logits.
function R.forward(net, x)
	local h, n = x, #net.layers
	for li, L in ipairs(net.layers) do
		local w, b, nin, out = L.w, L.b, #h, {}
		for j = 1, #b do
			local s, base = b[j], (j - 1) * nin
			for i = 1, nin do s = s + w[base + i] * h[i] end
			out[j] = li < n and math.tanh(s) or s
		end
		h = out
	end
	local best = 1
	for j = 2, #h do if h[j] > h[best] then best = j end end
	return best - 1
end

-- Gameplay input from the net: a fresh decision every `skip` frames.
local held, left = 0, 0
function R.policy_mask(M, net, c)
	if left <= 0 then
		held, left = R.forward(net, R.observe(c, M, net.danger)), net.skip or R.SKIP
	end
	local i = (net.skip or R.SKIP) - left + 1
	left = left - 1
	return R.action_mask(M, held, i)
end

-- Call when gameplay isn't running, so the next game starts a new decision.
function R.policy_idle() left = 0 end

return R
