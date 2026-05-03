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

local M = {}

-- ─── Config ────────────────────────────────────────────────────────────────

-- Any nonzero integer gives reproducible runs. Flip this to A/B-test variance
-- (different enemy spawn X, powerup drops) or to regression-test a TAS input
-- sequence across sessions.
M.SEED = 42

-- Master bot toggle. Flip to false for manual TAS without bot interference.
-- (v2.2 will add a runtime keybind in Celia for this.)
M.BOT_ENABLED = true

-- ─── pre_init: before cart _init ───────────────────────────────────────────

function M.pre_init(cart, api)
	api.srand(M.SEED)
end

-- ─── pre_update: before cart _update each frame ────────────────────────────

-- Button bit indices (PICO-8 standard).
local BTN_LEFT, BTN_RIGHT, BTN_UP, BTN_DOWN, BTN_O, BTN_X = 0, 1, 2, 3, 4, 5

-- Kept as state so a HUD can read it (v2.1).
M.last_mask = 0
M.last_threats = 0

-- Murdercrab game_state values: "title", "starting", "game",
-- "enter_initials", "game_complete". Inside "game", a separate `game_over`
-- flag distinguishes active play from the post-death prompt.
--
-- btnp() is edge-triggered: it only fires on a *fresh* press, so to trigger
-- btnp on UI screens we must release the button for at least one frame
-- between presses. We use `pico8.frames % 2 == 0` to pulse the button
-- on/off, which makes btnp fire ~30 times per second.
local function compute_action(cart, frame_counter)
	local mask = 0
	local state = cart.game_state
	local pulse = (frame_counter % 2 == 0)

	if state == "title" or state == "starting" or state == "game_complete" then
		-- Any-button starts game / advances. Pulse Z so btnp fires.
		if pulse then mask = bit.bor(mask, bit.lshift(1, BTN_O)) end
	elseif state == "enter_initials" then
		-- TODO(v2.x): proper initials entry (cycle letter + submit). For now
		-- pulse Z; will time-out or accept default initials.
		if pulse then mask = bit.bor(mask, bit.lshift(1, BTN_O)) end
	elseif state == "game" then
		if cart.game_over then
			-- Post-death prompt. credits>0 → Z (continue); credits==0 → X (quit).
			-- Pulse to fire btnp.
			if pulse then
				if (cart.credits or 0) > 0 then
					mask = bit.bor(mask, bit.lshift(1, BTN_O))
				else
					mask = bit.bor(mask, bit.lshift(1, BTN_X))
				end
			end
		else
			-- Active gameplay. v2.0a: hold Z continuously (btn, not btnp,
			-- so no pulse needed — fire keeps streaming).
			mask = bit.bor(mask, bit.lshift(1, BTN_O))
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
end

return M
