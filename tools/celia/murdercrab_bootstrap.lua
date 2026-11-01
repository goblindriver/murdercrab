-- murdercrab_bootstrap.lua
-- Host-side hooks for Murdercrab on Celia. Lives outside Celia's upstream
-- files so upstream pulls stay a small, focused diff.
--
-- Hook sites in the vendored Celia tree:
--   * api.lua ~L1700  → pre_init(cart, api)  : seeds RNG before cart _init
--   * tas.lua ~L156   → pre_update(pico8)    : runs before each cart _update
--
-- v2 adds the pre_update hook for a host-side bot. Bot writes directly into
-- pico8.keypressed[0][i] to override the cart's view of btn/btnp. This layer
-- is below Celia's TAS piano roll (which has already populated keypressed by
-- the time we run), so bot mode clobbers whatever the user / TAS was feeding.
--
-- Trace mode (MC_TRACE=<abs path>): pre_init runs the cart headlessly for
-- MC_FRAMES frames under the bot, writes one state line per frame, then exits.
-- Same seed + same cart logic => byte-identical trace, so diffing two traces
-- proves a refactor is behavior-preserving. See trace.sh.
--
-- The neural-net side (MC_RL env server, MC_POLICY playback) lives in
-- murdercrab_rl.lua.

local M = {}

-- ─── Config ────────────────────────────────────────────────────────────────

-- Any nonzero integer gives reproducible runs. Flip this to A/B-test variance
-- (different enemy spawn X, powerup drops) or to regression-test a TAS input
-- sequence across sessions. MC_SEED overrides it.
M.SEED = tonumber(os.getenv("MC_SEED") or "") or 42

-- Master bot toggle. Flip to false for manual TAS without bot interference.
-- (v2.2 will add a runtime keybind in Celia for this.)
M.BOT_ENABLED = true

-- MC_NOCONT=1: never continue, so game over runs out to name entry and the
-- high-score table. Default (continue forever) reaches later levels instead.
M.NO_CONTINUE = os.getenv("MC_NOCONT") == "1"

-- MC_GOD=1: hold the player's i-frames open so it never dies. No continues
-- means the L5 clear warps to the true last boss — the only way the bot
-- covers that fight (and the victory -> game_complete -> loop path).
M.GOD = os.getenv("MC_GOD") == "1"

-- MC_EXIT=1: at the victory screen press X (exit + record score) instead of
-- Z (loop). Pair with MC_GOD to cover the victory -> name entry path.
M.EXIT = os.getenv("MC_EXIT") == "1"

-- ─── Bot policy ────────────────────────────────────────────────────────────

-- Button bit indices (PICO-8 standard).
local BTN_LEFT, BTN_RIGHT, BTN_UP, BTN_DOWN, BTN_O, BTN_X = 0, 1, 2, 3, 4, 5
M.BTN = {LEFT = BTN_LEFT, RIGHT = BTN_RIGHT, UP = BTN_UP, DOWN = BTN_DOWN, O = BTN_O, X = BTN_X}

-- Kept as state so a HUD can read it.
M.last_mask = 0
M.last_threats = 0

local function press(mask, b) return bit.bor(mask, bit.lshift(1, b)) end
M.press = press

-- MC_BOT=sweep restores the v2.0b policy (fixed sweep + panic bomb) for
-- comparison. Default is the v2.1 dodger below.
M.SWEEP = os.getenv("MC_BOT") == "sweep"

-- MC_RL=1 turns the run into an env server for tools/rl; MC_POLICY=<file>
-- plays an exported net instead of the dodger. Both live in murdercrab_rl.lua.
M.RL = os.getenv("MC_RL") == "1"
local policy_path = os.getenv("MC_POLICY")
local rl = (M.RL or (policy_path and policy_path ~= "")) and require("murdercrab_rl") or nil
M.net = rl and policy_path and policy_path ~= "" and rl.load_policy(policy_path) or nil

-- v2.1 dodger weights. MC_W (JSON or a Lua table literal) overrides any of
-- them for one run, e.g. MC_W='{"hit":500}'. Unknown keys are ignored.
M.W = {
	horizon = 12,  -- frames of lookahead per candidate move
	hit = 1000,    -- predicted hit, scaled by how soon it lands
	near = 40,     -- threats passing within near_r px of the hitbox
	near_r = 6,
	decay = 0.85,  -- per-frame discount on the near penalty
	cherry = 30,   -- pull toward score cherries
	item = 60,     -- pull toward bomb / 1UP pickups
	align = 20,    -- sitting under enemies, so shots keep landing
	edge = 30,     -- inside edge_m px of a screen edge
	edge_m = 12,
	home_y = 100,  -- preferred height
	home = 30,     -- was 5: chasing drops up-screen caused most deaths
	bomb_h = 2,    -- bomb when every move is hit within this many frames
}

-- Parse MC_W / MC_RL_REWARD: flat JSON objects become Lua table literals by
-- rewriting "key": to key=. Returns nil on anything unparseable.
local function parse_table(src)
	if not src then return nil end
	local f = loadstring("return " .. src:gsub('"([%w_]+)"%s*:', "%1="))
	if not f then return nil end
	local ok, t = pcall(setfenv(f, {}))
	return ok and type(t) == "table" and t or nil
end
M.parse_table = parse_table

do
	local env = os.getenv("MC_W")
	if env and env ~= "" then
		local over = assert(parse_table(env), "MC_W: not a JSON object or Lua table: " .. env)
		for k, v in pairs(over) do
			if M.W[k] ~= nil and type(v) == "number" then M.W[k] = v end
		end
	end
end

-- True if any enemy bullet is within r px of the player's center.
local function bullet_near(cart, r)
	local p = cart.player
	for _, b in ipairs(cart.enemy_bullets or {}) do
		local dx, dy = b.x + 4 - (p.x + 4), b.y + 4 - (p.y + 4)
		if dx * dx + dy * dy < r * r then return true end
	end
	return false
end

-- v2.0b: hold fire, sweep across the playfield on a triangle wave (period
-- 6s), panic-bomb when a bullet gets close.
local function sweep_action(cart, frame_counter, mask)
	local t = frame_counter % 360
	local tx = 8 + (t < 180 and t or 360 - t) * 104 / 180
	local px = cart.player.x or 60
	if px > tx + 1 then mask = press(mask, BTN_LEFT)
	elseif px < tx - 1 then mask = press(mask, BTN_RIGHT) end
	if frame_counter % 2 == 0 and (cart.player.bombs or 0) > 0 and bullet_near(cart, 10) then
		mask = press(mask, BTN_X)
	end
	return mask
end

-- Things that hurt on contact, as boxes with a per-frame velocity, in the
-- shape cart.collides() tests. Bullets fly straight. Normal enemies follow
-- update_normal_enemy(): descend + drift (state 0), drift (1), dive (2).
-- A drifter whose timer runs out within the lookahead dives at the ship's
-- current spot (at = frame it turns, then v2). Divers hit the whole 8x8
-- ship; everything else hits the 2x2 core. Bosses slide on dx.
local function threats(cart, H)
	local list, p = {}, cart.player
	for _, b in ipairs(cart.enemy_bullets or {}) do
		list[#list + 1] = {x = b.x, y = b.y, w = b.width or 8, h = b.height or 8, vx = b.dx or 0, vy = b.dy or 0}
	end
	for _, e in ipairs(cart.enemies or {}) do
		local t = {x = e.x, y = e.y, w = e.width or 8, h = e.height or 8, vx = 0, vy = 0}
		if e.type == "normal" then
			if e.state == 0 then t.vx, t.vy = (e.dir or 0) * 0.25, e.dy or 0
			elseif e.state == 1 then
				t.vx = (e.dir or 0) * 0.35
				if (e.timer or H + 1) <= H then
					local at = math.max(e.timer, 1)
					local x0 = e.x + t.vx * at
					local dx, dy = p.x - x0, p.y - e.y
					local d = math.sqrt(dx * dx + dy * dy)
					local spd = (e.speed or 1) * 2 / (d > 0 and d or 1)
					t.at, t.x0, t.vx2, t.vy2 = at, x0, dx * spd, dy * spd
				end
			else t.vx, t.vy, t.full = e.dx or 0, e.dy or 0, true end
		else
			t.vx = e.dx or 0
		end
		list[#list + 1] = t
	end
	return list
end

-- Candidate moves; first wins ties, so standing still is the default.
local MOVES = {{0, 0}, {-1, 0}, {1, 0}, {0, -1}, {0, 1}, {-1, -1}, {1, -1}, {-1, 1}, {1, 1}}
M.MOVES = MOVES

local function clamp(v, lo, hi) return v < lo and lo or (v > hi and hi or v) end

-- Goal terms, judged where the move leaves the ship after the lookahead.
local function goal_score(cart, x, y, H, W)
	local cx, cy, s = x + 4, y + 4, 0
	for _, o in ipairs(cart.powerups or {}) do
		local ox, oy = o.x, o.y
		if (o.dx or 0) ~= 0 or (o.dy or 0) ~= 0 then ox, oy = ox + o.dx * H, oy + o.dy * H
		else oy = oy + (o.speed or 0) * H end
		local dx, dy = ox + 4 - cx, oy + 4 - cy
		local pull = 1 / (1 + math.sqrt(dx * dx + dy * dy) / 16)
		s = s + pull * (o.type == "score" and W.cherry or W.item)
	end
	-- Shots leave at cx-10 and cx+2, 8 px wide: anything centered within
	-- ~14 px (plus half its width) above the ship gets hit.
	for _, e in ipairs(cart.enemies or {}) do
		local ew = e.width or 8
		if e.y + (e.height or 8) < y then
			local tol = 10 + ew / 2
			s = s + W.align * math.max(0, 1 - math.abs(e.x + ew / 2 - cx) / tol)
		end
	end
	local m = math.max(W.edge_m, 1)
	s = s - W.edge * (math.max(0, 1 - x / m) + math.max(0, 1 - (120 - x) / m)
		+ math.max(0, 1 - y / m) + math.max(0, 1 - (120 - y) / m))
	s = s - W.home * math.abs(y - W.home_y) / 64
	return s
end

-- v2.1: try all 9 moves, holding each for `horizon` frames against threats
-- extrapolated at their own velocity. update_game() moves bullets and enemies
-- before the ship and tests collision after both, so frame k pairs threat
-- positions t+k*v with ship positions p+k*m. I-frames (invincible_timer,
-- decremented after the test) cover frames k <= timer; MC_GOD's are fake.
-- Returns move index, whether every move is hit within bomb_h frames, and
-- per move: first hit frame (false if none) and near-miss sum (RL features).
local function plan(cart)
	local p, W = cart.player, M.W
	local H = math.max(1, math.floor(W.horizon + 0.5))
	local inv = M.GOD and 0 or (p.invincible_timer or 0)
	local near_r, decay = math.max(W.near_r, 0.01), W.decay
	-- Drop threats that can't reach near_r of the ship within H frames even
	-- closing at full speed (gap vs the 8x8 ship bounds the 2x2 core's gap).
	local th = {}
	for _, t in ipairs(threats(cart, H)) do
		local g = math.max(t.x - (p.x + 8), p.x - (t.x + t.w), t.y - (p.y + 8), p.y - (t.y + t.h))
		local v = math.max(math.abs(t.vx), math.abs(t.vy), math.abs(t.vx2 or 0), math.abs(t.vy2 or 0))
		if g - H * (v + 1) < near_r then th[#th + 1] = t end
	end
	M.last_threats = #th
	local best, best_s, doomed, hits, nears = 1, -math.huge, true, {}, {}
	for mi, mv in ipairs(MOVES) do
		local x, y, hit_at, near, wk = p.x, p.y, nil, 0, 1
		for k = 1, H do
			x, y = clamp(x + mv[1], 0, 120), clamp(y + mv[2], 0, 120)
			if k > inv then
				for _, t in ipairs(th) do
					local tx, ty, full = t.x + t.vx * k, t.y + t.vy * k, t.full
					if t.at and k >= t.at then
						tx, ty, full = t.x0 + t.vx2 * (k - t.at), t.y + t.vy2 * (k - t.at), true
					end
					local ax, ay, aw = x + 3, y + 3, 2
					if full then ax, ay, aw = x, y, 8 end
					local g = math.max(tx - (ax + aw), ax - (tx + t.w), ty - (ay + aw), ay - (ty + t.h))
					if g <= 0 then hit_at = k break end
					if g < near_r then near = near + wk * (1 - g / near_r) end
				end
				if hit_at then break end
			end
			wk = wk * decay
		end
		if not hit_at or hit_at > W.bomb_h then doomed = false end
		hits[mi], nears[mi] = hit_at or false, near
		local ex, ey = clamp(p.x + mv[1] * H, 0, 120), clamp(p.y + mv[2] * H, 0, 120)
		local s = goal_score(cart, ex, ey, H, W) - W.near * near
		if hit_at then s = s - W.hit * (H - hit_at + 1) / H end
		if s > best_s then best, best_s = mi, s end
	end
	return best, doomed, hits, nears, H
end
M.plan = plan

-- MC_DEATHLOG=<file>: on every life lost, append the dodger's last frames
-- (position, chosen move, its predicted hit frame, earliest hit any move
-- had) and whatever was touching the ship, to see whether it was out-guessed
-- (no hit predicted) or boxed in (every move hit).
local deathlog = os.getenv("MC_DEATHLOG")
deathlog = deathlog ~= "" and deathlog or nil
local dl_ring, dl_lives = {}, nil
local function deathlog_frame(cart, mi, doomed, hits)
	local p = cart.player
	if dl_lives and (p.lives or 0) < dl_lives then
		local f = io.open(deathlog, "a")
		f:write(("== seed %d frame %d lvl %s loop %s phase %s lives %d bombs %d\n"):format(M.SEED,
			_G.pico8.frames, tostring(cart.current_level), tostring(cart.game_loop),
			tostring(cart.phase_state), p.lives or 0, p.bombs or 0))
		for _, r in ipairs(dl_ring) do f:write(r, "\n") end
		local cx, cy = p.x + 4, p.y + 4
		local function near(kind, list)
			for _, o in ipairs(list or {}) do
				local dx, dy = o.x + (o.width or 8) / 2 - cx, o.y + (o.height or 8) / 2 - cy
				if math.max(math.abs(dx), math.abs(dy)) < 12 then
					local keys = {}
					for k, v in pairs(o) do
						if type(v) == "number" or type(v) == "string" or type(v) == "boolean" then
							keys[#keys + 1] = k .. "=" .. (type(v) == "number" and ("%.2f"):format(v) or tostring(v))
						end
					end
					table.sort(keys)
					f:write(("  %s dx=%.1f dy=%.1f %s\n"):format(kind, dx, dy, table.concat(keys, " ")))
				end
			end
		end
		near("bullet", cart.enemy_bullets)
		near("enemy", cart.enemies)
		f:close()
	end
	dl_lives = p.lives
	local first = false
	for i = 1, 9 do if hits[i] and (not first or hits[i] < first) then first = hits[i] end end
	local safe = 0
	for i = 1, 9 do if not hits[i] then safe = safe + 1 end end
	dl_ring[#dl_ring + 1] = ("  f%d p=%.0f,%.0f inv=%d move=%d hit=%s earliest=%s safe_moves=%d doomed=%s threats=%d"):format(
		_G.pico8.frames, p.x, p.y, p.invincible_timer or 0, mi, tostring(hits[mi]), tostring(first), safe,
		tostring(doomed), M.last_threats or 0)
	if #dl_ring > 12 then table.remove(dl_ring, 1) end
end

local function dodge_action(cart, mask)
	local mi, doomed, hits = plan(cart)
	if deathlog then deathlog_frame(cart, mi, doomed, hits) end
	local mv = MOVES[mi]
	if mv[1] < 0 then mask = press(mask, BTN_LEFT) elseif mv[1] > 0 then mask = press(mask, BTN_RIGHT) end
	if mv[2] < 0 then mask = press(mask, BTN_UP) elseif mv[2] > 0 then mask = press(mask, BTN_DOWN) end
	-- btnp needs X released the frame before; a held X would never re-fire.
	if doomed and (cart.player.bombs or 0) > 0 and not cart.bomb_active
		and bit.band(M.last_mask, bit.lshift(1, BTN_X)) == 0 then
		mask = press(mask, BTN_X)
	end
	return mask
end

-- Murdercrab game_state values: "title", "starting", "game",
-- "enter_initials", "game_complete". Inside "game", a separate `game_over`
-- flag distinguishes active play from the post-death prompt.
--
-- btnp() is edge-triggered: it only fires on a *fresh* press, so to trigger
-- btnp on UI screens we must release the button for at least one frame
-- between presses. Menu presses pulse on alternating frames.
local function compute_action(cart, frame_counter)
	local mask = 0
	local state = cart.game_state
	local pulse = (frame_counter % 2 == 0)
	if M.net and not (state == "game" and not cart.game_over) then rl.policy_idle() end

	if state == "title" then
		-- X inserts a coin, Z starts. Alternate so both fire as btnp.
		local f = frame_counter % 4
		if f == 0 then mask = press(mask, BTN_X) elseif f == 2 then mask = press(mask, BTN_O) end
	elseif state == "enter_initials" and not (cart.current_initials and cart.current_initials[1] ~= "A") then
		-- Wait one frame for the cart to load the default initials, then bump
		-- the first letter A -> B once so traces show whether the entry that
		-- got renamed is the one that was just scored.
		if pulse and cart.current_initials then mask = press(mask, BTN_UP) end
	elseif state == "starting" or state == "game_complete" or state == "enter_initials" then
		-- Z advances / loops / accepts the default initials.
		if pulse then mask = press(mask, (M.EXIT and state == "game_complete") and BTN_X or BTN_O) end
	elseif state == "game" then
		if cart.game_over then
			-- Post-death prompt. credits>0 → Z (continue); otherwise X inserts
			-- a coin first. Net effect: the bot continues forever.
			if pulse and not M.NO_CONTINUE then
				mask = press(mask, (cart.credits or 0) > 0 and BTN_O or BTN_X)
			end
		else
			mask = press(mask, BTN_O)
			if M.net then mask = rl.policy_mask(M, M.net, cart)
			elseif M.SWEEP then mask = sweep_action(cart, frame_counter, mask)
			else mask = dodge_action(cart, mask) end
		end
	end

	return mask
end
M.compute_action = compute_action

-- Write mask bits into pico8.keypressed in the same shape Celia's own
-- update_buttons() uses (nil or increasing frame counter). This is what
-- api.btn() and api.btnp() read from.
local function apply_mask_to_keypressed(pico8, mask)
	for i = 0, 5 do
		local prev = pico8.keypressed[0][i]
		local pressed = bit.band(mask, bit.lshift(1, i)) ~= 0
		if pressed then
			pico8.keypressed[0][i] = (prev or -1) + 1
		else
			pico8.keypressed[0][i] = nil
		end
	end
end
M.apply_mask = apply_mask_to_keypressed

-- GOD runs still measure bullet pressure: count enemy bullets that touch the
-- player's hitbox (once per bullet, on first contact) — the hits a player
-- who never dodges would have taken.
M.would_hits = 0
local touching = {}
local function count_would_hits(cart)
	local p, now = cart.player, {}
	local hb = {x = p.x + 3, y = p.y + 3, width = 2, height = 2}
	for _, b in ipairs(cart.enemy_bullets or {}) do
		if cart.collides(hb, b) then
			now[b] = true
			if not touching[b] then M.would_hits = M.would_hits + 1 end
		end
	end
	touching = now
end

function M.pre_update(pico8)
	if not M.BOT_ENABLED then return end
	local cart = pico8.cart
	if not cart then return end
	local mask = compute_action(cart, pico8.frames or 0)
	M.last_mask = mask
	apply_mask_to_keypressed(pico8, mask)
	if M.GOD and cart.player and cart.player.lives then
		cart.player.invincible_timer = 2
		if cart.game_state == "game" and (cart.warp_time or 0) == 0 then count_would_hits(cart) end
	end
end

-- ─── Trace mode ────────────────────────────────────────────────────────────

local function n4(v) return string.format("%.4f", v or 0) end

-- Order-sensitive checksum over a list of objects' fields.
local function cksum(list, f)
	local s = 0
	for i, o in ipairs(list or {}) do s = s + i * f(o) end
	return n4(s)
end

-- One line of observable game state. Pre-init_game globals are skipped (a
-- token cleanup may legitimately leave them nil until a game starts).
local function trace_line(cart, frame)
	local c = cart
	local head = string.format("%d %s cr=%s lvl=%s warp=%s",
		frame, tostring(c.game_state), tostring(c.credits), tostring(c.current_level), tostring(c.warp_time))
	local p = c.player
	if not (p and p.lives) then return head end
	return head .. string.format(
		" used=%s hsp=%s ph=%s/%s loop=%s sc=%s,%s x%s/%s rank=%s hp=%s b=%s p=%s,%s go=%s/%s kills=%s warn=%s"
		.. " shk=%s hs=%s wh=%d e=%d:%s eb=%d:%s pb=%d:%s pu=%d:%s ex=%d",
		tostring(c.credits_used), tostring(c.hs_pos),
		tostring(c.phase), tostring(c.phase_state), tostring(c.game_loop),
		tostring(c.score_hi), tostring(c.score), tostring(c.score_multiplier), tostring(c.score_streak),
		tostring(c.rank), tostring(p.lives), tostring(p.bombs), n4(p.x), n4(p.y),
		tostring(c.game_over), tostring(c.game_over_timer), tostring(c.enemy_kill_count),
		tostring(c.boss_warning), tostring(c.shake_amount), tostring(c.hitstop), M.would_hits,
		#(c.enemies or {}), cksum(c.enemies, function(e) return e.x + e.y * 3 + (e.health or 0) * 7 end),
		#(c.enemy_bullets or {}), cksum(c.enemy_bullets, function(b) return b.x + b.y * 3 end),
		#(c.bullets or {}), cksum(c.bullets, function(b) return b.x + b.y * 3 end),
		#(c.powerups or {}), cksum(c.powerups, function(o) return o.x + o.y * 3 end),
		#(c.explosions or {}))
end

-- MC_ONEGAME=1: stop the trace on the frame the first game ends (pair with
-- MC_NOCONT for one-credit runs).
M.ONEGAME = os.getenv("MC_ONEGAME") == "1"

local function run_trace(cart, api, out_path)
	local pico8 = _G.pico8
	local frames = tonumber(os.getenv("MC_FRAMES") or "") or 36000
	local out = assert(io.open(out_path, "w"))

	if cart._init then cart._init() end
	pico8.fps = cart._update60 and 60 or 30
	pico8.frametime = 1 / pico8.fps

	local ok, err = pcall(function()
		for f = 1, frames do
			-- mirrors tas.lua rawstep(): frame++, bot input, update, draw
			pico8.frames = pico8.frames + 1
			M.pre_update(pico8)
			if cart._update60 then cart._update60() elseif cart._update then cart._update() end
			love.graphics.push()
			restore_clip()
			restore_camera()
			if cart._draw then cart._draw() end
			love.graphics.pop()
			out:write(trace_line(cart, f), "\n")
			if M.ONEGAME and cart.game_over then break end
		end
	end)
	if not ok then out:write("ERROR ", tostring(err), "\n") end
	-- Saved high-score table + initials (cartdata is in-memory under Celia).
	local cd = {}
	for i = 0, 63 do cd[#cd + 1] = tostring(pico8.cartdata[i]) end
	out:write("cartdata ", table.concat(cd, ","), "\n")
	-- RNG parity probe: equal only if both runs consumed rnd() identically.
	out:write(string.format("rng_probe %.8f\n", api.rnd()))
	out:close()
	os.exit(ok and 0 or 1)
end

-- ─── Watch mode ────────────────────────────────────────────────────────────

-- MC_WATCH=1 (watch.sh): start real-time playback on launch, keep running when
-- the window loses focus, and show live stats in the title bar (also echoed to
-- stdout every ~10s). MC_SPEED=n runs n game frames per displayed frame.
-- Savestates drop to one per 5s so a long watch doesn't eat ~0.5 MB a frame.
M.WATCH = os.getenv("MC_WATCH") == "1"
M.SPEED = tonumber(os.getenv("MC_SPEED") or "") or 1

local function watch_title(cart)
	local p = cart.player
	if not (p and p.lives) then return "murdercrab bot | seed " .. M.SEED .. " | " .. tostring(cart.game_state) end
	return string.format("murdercrab bot | seed %d | L%s loop %s %s | rank %s x%s | lives %s bombs %s | continues %s%s",
		M.SEED, tostring(cart.current_level), tostring(cart.game_loop), tostring(cart.phase),
		tostring(cart.rank), tostring(cart.score_multiplier), tostring(p.lives), tostring(p.bombs),
		tostring(cart.credits_used), M.GOD and (" | would-hits " .. M.would_hits) or "")
end

local function start_watch()
	if M.watching then return end
	M.watching = true
	local update, focus = love.update, love.focus
	local ticks = 0
	love.focus = function() focus(true) end
	love.update = function(dt)
		if ticks == 0 then
			require("console").ENV.savestate_every(300)
			love.keypressed("p", "p", false) -- same as pressing P: start playback
		end
		ticks = ticks + 1
		for _ = 1, M.SPEED do update(dt) end
		local cart = _G.pico8.cart
		if cart and ticks % 15 == 0 then
			local title = watch_title(cart)
			love.window.setTitle(title)
			if ticks % 600 == 0 then io.write(title, "\n") io.flush() end
		end
	end
end

-- ─── Headless drawing ──────────────────────────────────────────────────────

-- Traces and the RL server never show a frame, and the cart never reads
-- pixels back (no pget/sget/peek), so the GL calls behind its drawing are
-- dead weight, and parallel processes contend for the GPU (stubbing doubled
-- 6-env RL throughput; a lone trace runs 1.5x faster). Stub them: the cart's
-- _draw Lua, rnd() calls included, still runs, so game state is unchanged
-- (traces stay byte-identical).
function M.stub_gpu()
	local nop = function() end
	for _, k in ipairs({"draw", "points", "point", "rectangle", "line", "print", "clear"}) do
		love.graphics[k] = nop
	end
end

-- ─── pre_init: before cart _init ───────────────────────────────────────────

-- Eval mode (MC_EVAL=<plain Lua chunk>, MC_TRACE=<out>): run the chunk with
-- the cart's globals as its environment after _init, write what it returns,
-- exit. A unit-test hook for cart functions the bot can't easily reach.
local function run_eval(cart, code, out_path)
	if cart._init then cart._init() end
	local f = assert(loadstring(code))
	setfenv(f, cart)
	local out = assert(io.open(out_path, "w"))
	local ok, res = pcall(f)
	out:write(ok and tostring(res) or ("ERROR " .. tostring(res)), "\n")
	out:close()
	os.exit(ok and 0 or 1)
end

function M.pre_init(cart, api)
	api.srand(M.SEED)
	if M.RL then
		M.stub_gpu()
		rl.serve(M, cart, api)
	end
	local out_path = os.getenv("MC_TRACE")
	if not out_path or out_path == "" then
		if M.WATCH then start_watch() end
		return
	end
	M.stub_gpu()
	local code = os.getenv("MC_EVAL")
	if code and code ~= "" then run_eval(cart, code, out_path) end
	run_trace(cart, api, out_path)
end

return M
