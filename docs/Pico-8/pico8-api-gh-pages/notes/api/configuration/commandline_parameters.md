### Commandline Parameters

> _These override settings found in_ `config.txt`

`pico-8 [switches] cart.p8`

```bash
-width&nbsp;&nbsp;				n			set the window width 
-height&nbsp;				n			set the window height 
-windowed&nbsp;&nbsp;&nbsp;			n			set windowed mode off (0) or on (1)
-volume&nbsp;				n			set audio volume 0..256
-joystick&nbsp;&nbsp;&nbsp;			n			joystick controls starts at player n (0..7)
-pixel_perfect&nbsp;&nbsp;		n			1 for unfiltered screen stretching at integer scales
-preblit_scale&nbsp;&nbsp;		n			scale the display by n before blitting to screen
-draw_rect&nbsp;&nbsp;			x,y,w,h		absolute window coordinates and size to draw the p8 screen 
-run					cart		load and run a cartridge
-x&nbsp;&nbsp;					cart		execute a PICO-8 cart headless and then quit (experimental!)
-export&nbsp;				args		run EXPORT command in headless mode and exit (see notes under export)
-p&nbsp;&nbsp;					args		pass a parameter string to the specified cartridge
-splore&nbsp;				 			boot in splore mode
-home&nbsp;&nbsp;&nbsp;				path		set the path to store config.txt and other user data files
-root_path&nbsp;&nbsp;			path		set the path to store cartridge files
-desktop				path		set a location for screenshots and gifs to be saved
-screenshot_scale&nbsp;&nbsp;&nbsp;	n			scale of screenshots.  default: 3 (368x368 pixels)
-gif_scale&nbsp;&nbsp;			n			scale of gif captures. default: 2 (256x256 pixels)
-gif_len				n			set the maximum gif length in seconds (1..120)
-gui_theme&nbsp;&nbsp;			n			use 1 for a higher contrast editor colour scheme
-timeout				n			how many seconds to wait before downloads timeout (d: 30)
-software_blit&nbsp;&nbsp;		n			use software blitting mode off (0) or on (1)
-foreground_sleep_ms	n			how many milliseconds to sleep between frames.
-background_sleep_ms	n			how many milliseconds to sleep between frames in bg
-accept_future&nbsp;&nbsp;		n			use 1 to allow loading cartridges made w/ newer P8 versions
```
