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

-- Kept as state so a HUD can read it (v2.1).
M.last_mask = 0
M.last_threats = 0

local function press(mask, b) return bit.bor(mask, bit.lshift(1, b)) end

-- True if any enemy bullet is within r px of the player's center.
local function bullet_near(cart, r)
	local p = cart.player
	for _, b in ipairs(cart.enemy_bullets or {}) do
		local dx, dy = b.x + 4 - (p.x + 4), b.y + 4 - (p.y + 4)
		if dx * dx + dy * dy < r * r then return true end
	end
	return false
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
			-- v2.0b: hold fire, sweep across the playfield on a triangle wave
			-- (period 6s), panic-bomb when a bullet gets close. Deterministic,
			-- cheap, and reaches bosses + bombs for regression coverage.
			mask = press(mask, BTN_O)
			local t = frame_counter % 360
			local tx = 8 + (t < 180 and t or 360 - t) * 104 / 180
			local px = cart.player.x or 60
			if px > tx + 1 then mask = press(mask, BTN_LEFT)
			elseif px < tx - 1 then mask = press(mask, BTN_RIGHT) end
			if pulse and (cart.player.bombs or 0) > 0 and bullet_near(cart, 10) then
				mask = press(mask, BTN_X)
			end
		end
	end

	return mask
end

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

function M.pre_update(pico8)
	if not M.BOT_ENABLED then return end
	local cart = pico8.cart
	if not cart then return end
	local mask = compute_action(cart, pico8.frames or 0)
	M.last_mask = mask
	apply_mask_to_keypressed(pico8, mask)
	if M.GOD and cart.player and cart.player.lives then cart.player.invincible_timer = 2 end
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
		.. " shk=%s hs=%s e=%d:%s eb=%d:%s pb=%d:%s pu=%d:%s ex=%d",
		tostring(c.credits_used), tostring(c.hs_pos),
		tostring(c.phase), tostring(c.phase_state), tostring(c.game_loop),
		tostring(c.score_hi), tostring(c.score), tostring(c.score_multiplier), tostring(c.score_streak),
		tostring(c.rank), tostring(p.lives), tostring(p.bombs), n4(p.x), n4(p.y),
		tostring(c.game_over), tostring(c.game_over_timer), tostring(c.enemy_kill_count),
		tostring(c.boss_warning), tostring(c.shake_amount), tostring(c.hitstop),
		#(c.enemies or {}), cksum(c.enemies, function(e) return e.x + e.y * 3 + (e.health or 0) * 7 end),
		#(c.enemy_bullets or {}), cksum(c.enemy_bullets, function(b) return b.x + b.y * 3 end),
		#(c.bullets or {}), cksum(c.bullets, function(b) return b.x + b.y * 3 end),
		#(c.powerups or {}), cksum(c.powerups, function(o) return o.x + o.y * 3 end),
		#(c.explosions or {}))
end

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
	local out_path = os.getenv("MC_TRACE")
	if not out_path or out_path == "" then return end
	local code = os.getenv("MC_EVAL")
	if code and code ~= "" then run_eval(cart, code, out_path) end
	run_trace(cart, api, out_path)
end

return M
