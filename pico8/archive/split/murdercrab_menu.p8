pico-8 cartridge // http://www.pico-8.com
version 42
__lua__

game_state, credits, credits_used, current_level, menu_selection = "title", 3, 0, 1, 1
current_music, menu_options = 0, 4
current_initials, current_index = nil, 1
high_scores = {}
warp_time, warp_duration = 0, 180  -- Add missing variables
transitioning_to_game = false
init_high_scores_flag = false  -- Flag to initialize high scores
last_entered_initials = {"A", "C", "E"}  -- Default initials for BBS compatibility
final_score = 0  -- Initialize final_score variable
local hold_up, hold_down, hold_left, hold_right = 0, 0, 0, 0  -- Button hold timers
menu_grace_period = nil  -- Grace period for menu transitions
shake_amount = 0  -- Screen shake effect

function _init()
  init_save_system()
  init_starfield()
  init_high_scores()
  load_transition_data()  -- Load any data passed from game cart
  current_music = -1
  update_music("title")
  
  current_initials = nil
  current_index = 1
  if not final_score then final_score = 0 end
end

function _update()
  update_starfield()
  
  if game_state == "title" then
    update_title()
  elseif game_state == "menu" then
    update_menu()
  elseif game_state == "instructions" then
    update_instructions()
  elseif game_state == "highscores" then
    update_highscores()
  elseif game_state == "enter_initials" then
    update_enter_initials()
  elseif game_state == "game" then
    start_game()
  end
  
  -- Handle warp effect (if not already handled by update_menu)
  if warp_time > 0 and not transitioning_to_game then
    warp_time -= 1
  end
end

function _draw()
  cls()
  draw_starfield()
  
  if transitioning_to_game then
    draw_warp_effect()
    return
  end
  
  if game_state == "title" then
    draw_title()
  elseif game_state == "menu" then
    draw_menu()
  elseif game_state == "instructions" then
    draw_instructions()
  elseif game_state == "highscores" then
    draw_highscores()
  elseif game_state == "enter_initials" then
    draw_enter_initials()
  end
end

function init_save_system()
  cartdata("murdercrab_v1")  -- Use consistent name across all carts
end

function init_high_scores()
  high_scores = {}
  
  if init_high_scores_flag then
    -- Initialize with some default high scores
    local default_scores = {
      {score=10000, initials="AAA"},
      {score=9000, initials="BBB"},
      {score=8000, initials="CCC"},
      {score=7000, initials="DDD"},
      {score=6000, initials="EEE"},
      {score=5000, initials="FFF"},
      {score=4000, initials="GGG"},
      {score=3000, initials="HHH"},
      {score=2000, initials="III"},
      {score=1000, initials="JJJ"}
    }
    
    for i=1,10 do
      high_scores[i] = default_scores[i]
    end
    save_high_scores()
    return
  end
  
  if stat(6) == 0 then
    init_save_system()
  end
  
  for i=1,10 do
    local base_slot = 100 + (i-1) * 6
    local mega_part = dget(base_slot) or 0
    local kilo_part = dget(base_slot + 1) or 0
    local unit_part = dget(base_slot + 2) or 0
    local score = mega_part * 1000000 + kilo_part * 1000 + unit_part
    
    local c1 = dget(base_slot + 3) or 65  -- Default to "A"
    local c2 = dget(base_slot + 4) or 67  -- Default to "C"
    local c3 = dget(base_slot + 5) or 69  -- Default to "E"
    
    if score > 0 then  -- Only use saved data if it exists
      -- Convert to characters, handling invalid ASCII values
      local init1 = (c1 >= 32 and c1 <= 126) and chr(c1) or "A"
      local init2 = (c2 >= 32 and c2 <= 126) and chr(c2) or "C"
      local init3 = (c3 >= 32 and c3 <= 126) and chr(c3) or "E"
      
      high_scores[i] = {score=score, initials=init1..init2..init3}
    else
      high_scores[i] = {score=0, initials="---"}
    end
  end
end

function init_starfield()
  starfield = {}
  
  local star_count = 80 + (current_level * 10)
  if star_count > 150 then star_count = 150 end
  
  local colors = {7} -- Default white
  local large_star_chance = 0.2 -- Default 20% large stars
  
  if current_level == 2 then
    colors = {7, 12, 13}
    large_star_chance = 0.25
  elseif current_level == 3 then
    colors = {7, 11, 3}
    large_star_chance = 0.3
  elseif current_level == 4 then
    colors = {7, 13, 14, 2}
    large_star_chance = 0.35
  elseif current_level == 5 then
    colors = {7, 6, 13, 12}  -- Replace red tones with cyan and light blue
    large_star_chance = 0.4
  elseif current_level >= 6 then
    colors = {7, 6, 13, 14, 11, 12, 1, 2}  -- Remove red tones, add more blues and purples
    large_star_chance = 0.5
  end
  
  for i=1, star_count do
    add(starfield, {
      x = rnd(128),
      y = rnd(128),
      speed = 0.5 + rnd(1),
      col = colors[flr(rnd(#colors)) + 1],
      size = rnd(1) < large_star_chance and 2 or 1
    })
  end
end

function update_music(screen)
  local new_music = 0
  
  if screen == "game" then
    new_music = 6  -- Pattern 6 (second song)
  elseif screen == "boss" then
    new_music = 10  -- Pattern 10 (third song)
  elseif screen == "title" or 
         screen == "menu" or
         screen == "enter_initials" or 
         screen == "instructions" or 
         screen == "highscores" then
    new_music = 0  -- Pattern 0 (first song)
  elseif screen == "silent" then
    new_music = -1
    music(-1, 0)  -- Stop immediately with no fade
    current_music = -1
    return  -- Exit early
  else
    new_music = 0
  end
  
  if new_music != current_music then
    -- Stop current music with a short fade
    music(-1, 50)
    -- Wait a frame to ensure clean transition
    current_music = -1
    -- Start new music with no fade in
    music(new_music, 0, 0)
    current_music = new_music
  end
end

function update_starfield()
  local spd_mult = 1  -- Default speed multiplier
  
  for star in all(starfield) do
    star.y += star.speed * spd_mult
    if star.y > 128 then
      star.y = 0
      star.x = rnd(128)
      star.size = rnd(1) < 0.2 and 2 or 1
    end
  end
end

function draw_starfield()
  if warp_time > 0 then
    local ratio = 1 - warp_time / warp_duration
    local c = 1 + flr(ratio * 7)
    rectfill(0, 0, 127, 127, c)
    
    for star in all(starfield) do
      local streak_len = (ratio * 20) * star.speed
      
      local color = 7 + (star.y % 8)
      
      line(star.x, star.y, star.x, star.y - streak_len, color)
    end
    
    if warp_time > warp_duration * 0.3 and warp_time < warp_duration * 0.7 then
      local text = "level " .. current_level
      center_text(text, 60, 7)
    end
    
    if warp_time < warp_duration * 0.2 then
      fillp(▒)
      rectfill(0, 0, 127, 127, 7)
      fillp()
    end
  else
    if current_level > 1 then
      if current_level == 2 then
        rectfill(0, 0, 127, 127, 1)  -- Dark blue
      elseif current_level == 3 then
        rectfill(0, 0, 127, 127, 3)  -- Dark green
      elseif current_level == 4 then
        rectfill(0, 0, 127, 127, 2)  -- Dark purple
      elseif current_level == 5 then
        rectfill(0, 0, 127, 127, 4)  -- Dark brown instead of red
      elseif current_level >= 6 then
        local pulse = sin(time() * 0.5)
        rectfill(0, 0, 127, 127, pulse > 0 and 1 or 2)  -- Alternate between dark blue and purple
      end
    end
  
    for star in all(starfield) do
      if current_level > 1 then
        star.y += star.speed * (0.2 + (current_level * 0.1))
        if star.y > 127 then
          star.y = 0
          star.x = rnd(128)
        end
      end
      
      local twinkle = 0
      if current_level == 2 and rnd(100) < 2 then
        twinkle = sin(time() * 6 + star.x/12) > 0.6 and 1 or 0
      elseif current_level == 3 and rnd(100) < 4 then
        twinkle = sin(time() * 7 + star.x/10) > 0.4 and 1 or 0
      elseif current_level == 4 and rnd(100) < 6 then
        twinkle = sin(time() * 8 + star.x/8) > 0.2 and 1 or 0
      elseif current_level >= 5 and rnd(100) < 8 then
        twinkle = sin(time() * 10 + star.x/6) > 0 and 1 or 0
      end
      
      if star.size == 1 then
        pset(star.x, star.y, star.col + twinkle)
      else
        rectfill(star.x, star.y, star.x+1, star.y+1, star.col + twinkle)
      end
    end
  end
  
  fillp()
end

function update_warp()
  if warp_time > 0 then
    warp_time -= 1
    
    if warp_time % 5 == 0 then
      local ratio = 1 - warp_time / warp_duration
      shake_amount = 3 + flr(ratio * 8)
    end
    
    if warp_time == warp_duration - 1 then
      update_music("silent")
      sfx(19, 3)  -- Play warp sound at normal speed
      for p in all(powerups) do
        p.attracted = true
        p.attract_speed = 2.0
      end
    end
    
    if warp_time == 90 then
      sfx(19, 3)  -- Play warp sound at normal speed
    end
    
    if warp_time <= 0 then
      phase = "normal"
      enemy_kill_count = 0
      fillp(░)
      rectfill(0, 0, 127, 127, 7)
      fillp() -- Reset the pattern after the flash
      shake_amount = 12  -- Final big shake when warp completes
      update_music("game")
      
      init_starfield()
    end
    
    return true
  end
  
  return false
end

function handle_grace_period(reset)
  if reset then
    menu_grace_period = 30 -- 1 second grace
    for i=0,5 do
      poke(0x5e00 + i, 0)
    end
  end
  
  if menu_grace_period and menu_grace_period > 0 then
    menu_grace_period -= 1
    return true
  end
  
  return false
end

function handle_screen_buttons(actions, auto_repeat)
  local result = false
  auto_repeat = auto_repeat or false
  
  if actions.navigate or (actions.up and actions.down) then
    if auto_repeat then
      if btn(2) then
        hold_up = hold_up + 1
        if btnp(2) or (hold_up > 12 and hold_up % 2 == 0) then
          if actions.navigate then 
            actions.navigate(-1)
          elseif actions.up then
            actions.up()
          end
          sfx(2, 1)
        end
      else
        hold_up = 0
      end
      
      if btn(3) then
        hold_down = hold_down + 1
        if btnp(3) or (hold_down > 12 and hold_down % 2 == 0) then
          if actions.navigate then 
            actions.navigate(1)
          elseif actions.down then
            actions.down()
          end
          sfx(2, 1)
        end
      else
        hold_down = 0
      end
    else
      if btnp(2) and (actions.navigate or actions.up) then
        if actions.navigate then 
          actions.navigate(-1)
        elseif actions.up then
          actions.up()
        end
        sfx(2, 1)
      end
      
      if btnp(3) and (actions.navigate or actions.down) then
        if actions.navigate then
          actions.navigate(1)
        elseif actions.down then
          actions.down()
        end
        sfx(2, 1)
      end
    end
  end
  
  if actions.horizontal or (actions.left and actions.right) then
    if auto_repeat then
      if btn(0) then
        hold_left = hold_left + 1
        if btnp(0) or (hold_left > 12 and hold_left % 2 == 0) then
          if actions.horizontal then
            actions.horizontal(-1)
          elseif actions.left then
            actions.left()
          end
          sfx(2, 1)
        end
      else
        hold_left = 0
      end
      
      if btn(1) then
        hold_right = hold_right + 1
        if btnp(1) or (hold_right > 12 and hold_right % 2 == 0) then
          if actions.horizontal then
            actions.horizontal(1)
          elseif actions.right then
            actions.right()
          end
          sfx(2, 1)
        end
      else
        hold_right = 0
      end
    else
      if btnp(0) and (actions.horizontal or actions.left) then
        if actions.horizontal then
          actions.horizontal(-1)
        elseif actions.left then
          actions.left()
        end
        sfx(2, 1)
      end
      
      if btnp(1) and (actions.horizontal or actions.right) then
        if actions.horizontal then
          actions.horizontal(1)
        elseif actions.right then
          actions.right()
        end
        sfx(2, 1)
      end
    end
  end
  
  if actions.select and btnp(4) then
    actions.select()
    sfx(3, 2)  -- Play selection sound
    result = true
  end
  
  if actions.back and btnp(5) then
    actions.back()
    sfx(4, 3)  -- Play back/cancel sound
    result = true
  end
  
  return result
end

function center_text(text, y, color)
  local x = (128 - #text * 4) / 2
  print(text, x, y, color)
end

title_timer = 0

function update_title()
  title_timer += 1
  
  credits = 3
  
  local title_actions = {
    select = function()
      game_state = "menu"
      if update_music then update_music("menu") end
    end,
    
    back = function()
      game_state = "menu"
      if update_music then update_music("menu") end
    end,
    
    horizontal = function()
      game_state = "menu"
      if update_music then update_music("menu") end
      sfx(3)
    end
  }
  
  handle_screen_buttons(title_actions)
end

function draw_title()
  cls()
  draw_starfield()

  local logo_y = 15
  local pulse_intensity = sin(time() * 0.8)
  local logo_color = 8
  if pulse_intensity > 0.3 then
    if pulse_intensity > 0.7 then
      logo_color = 1
    else
      logo_color = 8
    end
  end
  
  local pulse = sin(time() * 0.8) * 3
  
  center_text("m u r d e r c r a b", logo_y+1, 1)
  center_text("m u r d e r c r a b", logo_y, logo_color)  -- Main text
  
  local text_width = #"m u r d e r c r a b" * 4
  local text_center_x = 64
  local excl_x = text_center_x + text_width/2 + 1
  
  print("!", excl_x+1, logo_y+1 - pulse, 1)
  print("!", excl_x, logo_y - pulse, logo_color)  -- Actual mark
  
  local boss_x = 48  -- Center horizontally (128/2 - 32/2)
  local boss_y = 40  -- Middle of screen
  local bob = sin(time() * 0.4) * 4  -- Slow bobbing motion
  
  local aura_pulse = sin(time() * 0.6) * 2
  fillp(░)
  circfill(boss_x + 16, boss_y + 16, 26 + aura_pulse, 1)  -- Larger blue/dark aura
  
  spr(10, boss_x, boss_y + bob, 4, 4)  -- 32x32 sprite pattern starting at sprite 10
  
  if title_timer % 30 < 20 then
    center_text("- press any button -", 101, 1)
    center_text("- press any button -", 100, logo_color)
  end

  spr(1, 60, 115)
end

function start_game()
  if warp_time <= 0 then
    warp_time = warp_duration
    sfx(19, 3)
    update_music("silent")
    transitioning_to_game = true
  end
end

function update_menu()
  if transitioning_to_game then
    update_warp_transition()
    return
  end
  
  if menu_grace_period and menu_grace_period > 0 then
    menu_grace_period -= 1
    return
  end
  
  local menu_actions = {
    navigate = function(dir)
      menu_selection = (menu_selection + dir - 1) % menu_options + 1
    end,
    
    select = function()
      if menu_selection == 1 then -- Start Game
        start_game()
      elseif menu_selection == 2 then -- Enter Initials
        final_score = 0
        current_initials = nil
        game_state = "enter_initials"
        update_music("enter_initials")
      elseif menu_selection == 3 then -- Instructions
        game_state = "instructions"
        update_music("instructions")
      elseif menu_selection == 4 then -- High Scores
        game_state = "highscores"
        update_music("highscores")
      end
    end,
    
    back = function()
      game_state = "title"
      update_music("title")
    end
  }
  
  handle_screen_buttons(menu_actions, true)
end

function draw_menu()
  cls()
  draw_starfield()
  local logo_y = 20
  local pulse_intensity = sin(time() * 0.8)
  local logo_color = 8  -- Base red color
  
  if pulse_intensity > 0.3 then
    if pulse_intensity > 0.7 then
      logo_color = 1  -- Dark blue at peak
    else
      logo_color = 8  -- Red otherwise
    end
  end
  
  local pulse = sin(time() * 0.8) * 3
  
  center_text("m u r d e r c r a b", logo_y+1, 1)
  center_text("m u r d e r c r a b", logo_y, logo_color)  -- Main text
  
  local text_width = #"m u r d e r c r a b" * 4
  local text_center_x = 64
  local excl_x = text_center_x + text_width/2 + 1
  
  print("!", excl_x+1, logo_y+1 - pulse, 1)
  print("!", excl_x, logo_y - pulse, logo_color)  -- Actual mark
  
  local menu_y = 45  
  local spacing = 10
  
  local options = {
    "start game",
    "enter initials", 
    "instructions",
    "high scores"
  }
  
  for i=1, #options do
    local color = 1  -- Default color is blue
    local option_text = options[i]
    
    if i == menu_selection then
      color = 8  -- Highlighted color is red
      option_text = "> " .. option_text -- Cursor indicator
    else
      option_text = "  " .. option_text -- Space for alignment
    end
    
    center_text(option_text, menu_y + (i-1) * spacing, color)
  end
  
  center_text("credits: " .. credits, 115, logo_color)
end

function draw_highscores()
  cls()
  draw_starfield()
  
  center_text("high scores", 11, 1)
  center_text("high scores", 10, 8)
  
  local y = 22
  for i=1,10 do
    local entry = high_scores[i]
    local score_text = i .. ". " .. entry.initials .. " " .. entry.score
    
    center_text(score_text, y+1, 1)
    center_text(score_text, y, 8)  
    
    y += 9
  end
  
  center_text("press x to return to menu", 116, 1)
  center_text("press x to return to menu", 115, 8)
end

function update_highscores()
  local highscore_actions = {
    back = function()
      game_state = "menu"
      if update_music then update_music("menu") end
    end
  }
  
  handle_screen_buttons(highscore_actions)
end

function is_high_score(score)
  return score > 0 and score > high_scores[10].score
end

function update_high_scores(new_score, player_initials)
  if new_score <= 0 then return end
  
  -- Ensure initials are valid
  if not player_initials or #player_initials < 3 then
    player_initials = "---"
  end
  player_initials = sub(player_initials, 1, 3)
  
  -- Find insertion position
  local insert_pos = 11  -- Default position (beyond the end)
  for i=1,10 do
    if new_score > high_scores[i].score then
      insert_pos = i
      break
    end
  end
  
  if insert_pos <= 10 then
    -- Shift scores down
    for i=10,insert_pos+1,-1 do
      high_scores[i] = high_scores[i-1]
    end
    
    -- Insert new score
    high_scores[insert_pos] = {score=new_score, initials=player_initials}
    save_high_scores()
  end
end

function save_high_scores()
  if stat(6) == 0 then
    init_save_system()
  end
  
  for i=1,10 do
    local entry = high_scores[i]
    
    -- Store massive scores using three slots for even larger numbers
    local score = entry.score
    local mega_part = flr(score / 1000000)    -- Millions
    local kilo_part = flr((score % 1000000) / 1000)  -- Thousands
    local unit_part = score % 1000            -- Units
    
    -- Use slots 100+ for high scores to avoid conflicts
    local base_slot = 100 + (i-1) * 6
    dset(base_slot, mega_part)     -- Millions
    dset(base_slot + 1, kilo_part) -- Thousands
    dset(base_slot + 2, unit_part) -- Units
    
    -- Save each initial character
    local c1 = ord(sub(entry.initials,1,1)) or 65  -- Default to "A"
    local c2 = ord(sub(entry.initials,2,2)) or 67  -- Default to "C" 
    local c3 = ord(sub(entry.initials,3,3)) or 69  -- Default to "E"
    
    dset(base_slot + 3, c1)  -- First initial
    dset(base_slot + 4, c2)  -- Second initial
    dset(base_slot + 5, c3)  -- Third initial
  end
end

-- BBS-compatible transition data functions (shared with game cart)
function load_transition_data()
  if stat(6) == 0 then
    local saved_score = dget(50)
    local saved_level = dget(51)
    local saved_credits_used = dget(52)
    local saved_final = dget(56)
    
    if saved_score and saved_score > 0 then
      score = saved_score
      current_level = saved_level or 1
      credits_used = saved_credits_used or 0
      final_score = saved_final or saved_score
      
      -- Load initials if available
      local c1 = dget(53)
      local c2 = dget(54) 
      local c3 = dget(55)
      
      if c1 and c2 and c3 then
        last_entered_initials = {chr(c1), chr(c2), chr(c3)}
      end
    end
  end
end

function update_enter_initials()
  if current_initials == nil then
    current_initials = {}
    -- Use last entered initials, or default to "ACE"
    local default_initials = last_entered_initials[1] .. last_entered_initials[2] .. last_entered_initials[3]
    for i=1,3 do
      current_initials[i] = sub(default_initials, i, i)
    end
    current_index = 1
  end
  
  local initial_actions = {
    up = function()
      if current_initials then
        local current = ord(current_initials[current_index])
        -- Allow full ASCII range (33-126) instead of just A-Z
        -- 33 = '!', 126 = '~'
        current = ((current - 33 + 1) % 94) + 33
        current_initials[current_index] = chr(current)
      end
    end,
    
    down = function()
      if current_initials then
        local current = ord(current_initials[current_index])
        -- Allow full ASCII range (33-126) instead of just A-Z
        -- 33 = '!', 126 = '~'
        current = ((current - 33 - 1 + 94) % 94) + 33
        current_initials[current_index] = chr(current)
      end
    end,
    
    left = function()
      if current_initials then
        current_index = current_index - 1
        if current_index < 1 then current_index = 3 end
      end
    end,
    
    right = function()
      if current_initials then
        current_index = current_index + 1
        if current_index > 3 then current_index = 1 end
      end
    end,
    
    select = function()
      if current_initials then
        local initials_str = current_initials[1] .. current_initials[2] .. current_initials[3]
        
        -- Save initials to last_entered_initials for use in game
        last_entered_initials[1] = current_initials[1]
        last_entered_initials[2] = current_initials[2]
        last_entered_initials[3] = current_initials[3]
        
        -- Save initials to cartdata for persistence
        if stat(6) == 0 then
          init_save_system()
        end
        dset(53, ord(current_initials[1]) or 65)
        dset(54, ord(current_initials[2]) or 67)
        dset(55, ord(current_initials[3]) or 69)
        
        if type(final_score) == "number" and final_score > 0 then
          update_high_scores(final_score, initials_str)
          final_score = 0
        end
      end
      
      current_initials = nil
      current_index = 1    
      game_state = "menu"
      if update_music then update_music("menu") end
    end,
    
    back = function()
      current_initials = nil
      current_index = 1    
      game_state = "menu"
      if update_music then update_music("menu") end
    end
  }
  
  handle_screen_buttons(initial_actions, true)
end

function draw_enter_initials()
  cls(0)
  draw_starfield()

  local title_y = 30
  center_text("enter initials:", title_y+1, 1)
  center_text("enter initials:", title_y, 8)  
  
  if current_initials then
    local initials_x = 64 - 8
    for i=1,3 do
      local color = (i == current_index) and 8 or 1  -- Red for selected, blue for others
      print(current_initials[i], initials_x + (i-1)*8, 60, color)
    end
  else
    center_text("---", 60, 1)
  end
  
  center_text("up/down: letter", 81, 1)
  center_text("up/down: letter", 80, 8)
  
  center_text("left/right: position", 91, 1)
  center_text("left/right: position", 90, 8)
  
  center_text("z: confirm  x: cancel", 101, 1)
  center_text("z: confirm  x: cancel", 100, 8)
  
  if current_initials then
    local cursor_flash = (time() * 10) % 2 < 1
    if cursor_flash then
      local cursor_x = 56 + (current_index-1)*8
      line(cursor_x, 68, cursor_x + 4, 68, 8)
    end
  end
end

function draw_instructions()
  cls()
  draw_starfield()
  
  center_text("instructions", 11, 1)
  center_text("instructions", 10, 8)
  
  center_text("movement: arrow keys", 25, 1)
  center_text("movement: arrow keys", 24, 8)
  
  center_text("shoot: z button", 35, 1)
  center_text("shoot: z button", 34, 8)
  
  center_text("bomb: x button", 45, 1)
  center_text("bomb: x button", 44, 8)
  
  center_text("collect powerups", 59, 1)
  center_text("collect powerups", 58, 8)
  
  local health_text = "extra health"
  local bomb_text = "extra bomb"
  local score_text = "increase score"
  
  local health_x = 64 - (#health_text * 4) / 2
  local bomb_x = 64 - (#bomb_text * 4) / 2
  local score_x = 64 - (#score_text * 4) / 2
  
  center_text("extra health", 71, 1)
  center_text("extra health", 70, 8)
  spr(6, health_x - 12, 68)
  
  center_text("extra bomb", 81, 1)
  center_text("extra bomb", 80, 8)
  spr(5, bomb_x - 12, 78)
  
  center_text("increase score", 91, 1)
  center_text("increase score", 90, 8)
  spr(7, score_x - 12, 88)
  
  center_text("10x cherries increase multiplier", 101, 1)
  center_text("10x cherries increase multiplier", 100, 8)
  
  center_text("press x to return to menu", 121, 1)
  center_text("press x to return to menu", 120, 8)
end

function update_instructions()
  local instruction_actions = {
    back = function()
      game_state = "menu"
      if update_music then update_music("menu") end
    end
  }
  
  handle_screen_buttons(instruction_actions)
end

function update_warp_transition()
  update_starfield()
  
  if warp_time > 0 then
    warp_time -= 1
    
    -- Once warp is mostly complete, load the game cart
    if warp_time <= warp_duration * 0.3 then
      if credits > 0 then
        credits -= 1
        load("murdercrab_game.p8", "back to menu")  -- Local filename for testing
      else
        -- If no credits, cancel transition and return to menu
        transitioning_to_game = false
        warp_time = 0
        sfx(4, 3)
        update_music("title")
      end
    end
  else
    transitioning_to_game = false
  end
end

function draw_warp_effect()
  if warp_time > 0 then
    local ratio = 1 - warp_time / warp_duration
    local c = 1 + flr(ratio * 7)
    rectfill(0, 0, 127, 127, c)
    
    for star in all(starfield) do
      local streak_len = (ratio * 20) * star.speed
      local color = 7 + (star.y % 8)
      line(star.x, star.y, star.x, star.y - streak_len, color)
    end
    
    if warp_time < warp_duration * 0.2 then
      fillp(▒)
      rectfill(0, 0, 127, 127, 7)
      fillp()
    end
  end
  
  fillp()
end

__gfx__
00000000000b9000000000000280088000888000000007a0000000000000bbb00020000000000200000000280000000000000002820000000000000000000000
00000000000b900000800700280000880889888000007a0008808800000b0b000282000000002820000002820000000000000000282000000000000000000000
00700700000b900000008000280000888897aa880007a00087e8888000b00b002822000000002288000028200000000000000000028200000000000000000000
0007700090bc7b090000000008a00a80899a7a9800aaaaa08e888e8000b008802828800000028288000288200282000000000820002820000000000000000000
00077000bbbccbbb70000a070228828088a779980000a9000888e800088088782828800000028888002882002820000000000282002882000000000000000000
00700700bbbb9bbb0000900000888800088aa988000a900000888000887808880282020000202820028882228200000000000028222288200000000000000000
00000000b00b900b09099090020880800088888000a9000000080000888808800282272222722820028882882200000000000000888888820000000000000000
00000000000b90000088880020200808000888000000000000000000088000000028aaa88aaa8800022828820000000000000000228828820000000000000000
00000000000090000000000002800880000000000000000000000000007777702288888888888882288882200000200000000000022828200000000000000000
00000000000b90008000080a28000088000000000000000000000000077777770288882882888820288820000000202200022000000288820000000000000000
00000000000b90908000000728000088000000000000000000000000711771170022828228288200288200000022828822028200000028820000000000000000
00000000000b9bb0000a000008200280000000000000000000000000711771170288888888888820288200002288888888288820000000820000000000000000
00000000090c7bb00000709002a88a80000000000000000000000000777177772822888888882282282820008822888888282282000002280000000000000000
000000000bbccb009080000000888800000000000000000000000000077777700228222222228220282820028888888888888882000228820000000000000000
0000000000bb90000900090a20288808000000000000000000000000077777000282000000002820022882028228888888888882002888200000000000000000
00000000000b9000000000000200008000000000000000000000000007070700002000000000020000228828221a228888aa2820228882000000000000000000
00000000000b00000009900002800880000000000000000000000000000000000000000000000000000022882882211128aa8882882200000000000000000000
00000000000b90000009900028000088000000000000000000000000000000000000000000000000000002282888222288888882820000000000000000000000
00000000000b90000009900028000088000000000000000000000000000000000000000000000000000228288882888888888888202000000000000000000000
00000000090c70000009900008200280000000000000000000000000000000000000000000000000002888288882717172728828828200000000000000000000
000000000bbcc090000880000aa88aa0000000000000000000000000000000000000000000000000028888228882711171712828888820000000000000000000
0000000000bb9bb00008800000888800000000000000000000000000000000000000000000000000028228288882111111112888882282000000000000000000
00000000000b9b000000000000088000000000000000000000000000000000000000000000000000282002882882111111112888820028200000000000000000
00000000000b90000000000000000000000000000000000000000000000000000000000000000000820028888222171117128228282002220000000000000000
00000000000000000009900000000000000000000000000000000000000000000000000000000000200028228882271717122888222820220000000000000000
00000000000000000008800000000000000000000000000000000000000000000000000000000000200028208220222222200288202820020000000000000000
00000000000000000008800000000000000000000000000000000000000000000000000000000000000282202000000000000028200282000000000000000000
00000000000000000008800000000000000000000000000000000000000000000000000000000000000282002000000000000028200282000000000000000000
00000000000000000008800000000000000000000000000000000000000000000000000000000000000220002000000000000028200022000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000220002000000000000022000280000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000022002000000000000282000220000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000002202200000000000228002000000000000000000000
0000000bb00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000007bb70000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000033bb0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000044440000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000044ff4f4400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00bb4fff4fff4bb00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0bb4f4f4fff4f4bb0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
b334ff4fff4ff43b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
b30ff4fff4fff40b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000f4f4ff4fff4000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000f4fff4f4f40000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0004fff4fff440000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000bfff4ffffb3000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
003bb4f44ff4b3000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
003b3000b30033000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00030000b00003000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
000300280000000000246250000000000000000000000000246150000000000000000c30018625000000000018000180002430018000180001800024300180001800018000000000000000000000000000000000
011000010017000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010000001f75100002000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010c0000250352b055344352b20023500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000500001a35707350023003330034300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010a0000276462b6462e6462864626646246461f6451c645136450f6450764504643026430264300643000002e3000000029300000000000021300000000000000000173001330000000000000d3000930006300
011000002862300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011000002562619600026000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
012000000d9650d9550d9450d9351075510745107351072500855179551794517935179251792510755107450d9650d9550d9450d935107551074510735107250085417955179451793517925179250d9250d935
011d0c20107251995519945199351992510055100451003510025179550f7350f7350f7250f725107251072510725199351993519925199250b0250b0350b7350b0250b7250b72517935179350f7350f7350f725
012000001296512955129451293515755157451573515725008551095510945109351092510925157551574512965129551294512935157551574500854157351572519955199451993519925199250d9250d935
011d0c20107251e9351e9351e9351e9251503515035150251502517935147351472514725147251572515725157251e9351e9351e9251e92515025150351573515025157251572519935199350f7350f7350f725
0120000019955199450d935019551405014040147321472223935239450b9350b9551505015040157321572219955199450d935019551705019040197321972223935239450b9350b9551c0501e0401e7321e722
012000001e9551e94512935069552105021040217322172228945289352892520050200521e0401e7321e7221e9551e945129350695521050210402573225722289552894528935289251c0401e0301e7221e722
010d00000c0530445504255134453f6150445513245044550c0531344513245044553f6150445513245134450c0530445504255134453f6150445513245044550c0531344513245044553f615044551324513445
000d000028555234452d2352b5552a4452b2352f55532245395303725536540374353b2503954537430342553654034235325552f2402d5352b2502a4452b530284552624623530214551f24023535284302a245
010d00002b5552a4452823523555214451f2351e5551c4452b235235552a445232352d5552b4452a2352b555284452a235285552644523235215551f4451c2351a555174451e2351a5551c4451e2351f55523235
010d00000c0530045500255104453f6150045510245004550c0530044500245104553f6150045510245104450c0530045500255104453f6150045510245004550c0531044510245004553f615004551024500455
010d00000c0530245502255124453f6150245512245024550c0531244512245024553f6150245502255124450c0530245502255124453f6150245512245024550c0530244512245024553f615124550224512445
010d00002b5552a45528255235552b5452a44528545235452b5352a03528535235352b0352a03528735237352b0352a03528735237351f7251e7251c725177251f7151e7151c715177151371512715107150b715
010e000017500195000c0001750019500175000c000135001f0001f5000c0001750019500175000c0001e7001e7002a7000c00017500195001750000000000000000000000000000000000000000000000000000
010e0000070000a50000100070000c50000100070000a5000a5000a5000a5000a50000100070000c50000100070000a50000100070000c500001000b5000a5000a5000a5000a5000a50000000000000000000000
010e00000c0001e5001c5001e5000c0001c5001e5001c5000c0001e5001c5001e5000c0001c5001e5001c5000c0000c50018000185000c0001c5001e5001c5000c0001e7001e7002a7000c000175001950017500
010e0000051000c00011000051000c0000f000051000c00011000051000c0000f0000f0000f0000f0000f000061000d00012000071000e00013000081000f0001500012000140001200015000120001400012000
010700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011000003873317700017000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01100000176460c6463164339643366412c641276412764126641246412364121642206421d6421b6431864317644166441564513645106450e6450c6450964508645066450a6400464002600016000060000000
__music__
01 08094344
00 08094344
00 0a0b4344
00 080c4344
00 080c4344
02 0a0d4344
01 0e424344
00 11424344
00 12424344
00 0e424344
00 0e104344
00 11104344
00 120f4344
02 0e134344
00 18424344
01 15144344
00 15144344
02 17164344