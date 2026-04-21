-- murdercrab_bootstrap.lua
-- Host-side boot hook for Murdercrab on Celia.
-- Called from patched api.lua immediately before pico8.cart._init().
-- Lives OUTSIDE Celia's upstream files so pulling upstream is a one-diff merge.
--
-- In v1, this only seeds the RNG. Future phases will add:
--   * post_frame(cart) to observe state for the bot
--   * action_override(cart) to return a btn mask that replaces keyboard input
-- Kept intentionally minimal for v1 so the surface area stays stable.

local M = {}

-- Any nonzero integer gives reproducible runs. Flip this to A/B-test variance
-- (e.g. different enemy spawn X values) or to regression-test a TAS input
-- sequence across sessions.
M.SEED = 42

-- Called after cart lua is loaded into the pico8.cart sandbox, before _init.
-- `api` is the host-side picolove api module; api.srand writes to the
-- underlying love.math RNG that the cart's rnd() reads from.
function M.pre_init(cart_sandbox, api)
	api.srand(M.SEED)
end

return M
