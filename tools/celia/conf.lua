__picolove_version = "0.1.0"

scale = 4
__pico_resolution = { 128, 128 }

function love.conf(t)
	t.console = true

	t.identity = "Celia"

	t.version = "11.3"

	t.window.title = "Celia"
	t.window.icon = "icon.png"
	t.window.width = 1344
	t.window.height = 768
	t.window.resizable = true

	-- murdercrab: headless traces and the RL env server (MC_TRACE / MC_RL,
	-- see trace.sh, rl.sh) never present a frame, so park a tiny borderless
	-- window off-screen instead of flashing the TAS UI up on every run.
	-- No audio device either: each one is a CoreAudio client, and hundreds of
	-- short-lived ones left coreaudiod burning several cores.
	if os.getenv("MC_TRACE") or os.getenv("MC_RL") then
		t.window.width, t.window.height = 128, 128
		t.window.borderless, t.window.resizable = true, false
		t.window.x, t.window.y = -4000, -4000
		t.modules.audio, t.modules.sound = false, false
	end
end
