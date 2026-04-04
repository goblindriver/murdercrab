pico-8 cartridge // http://www.pico-8.com
version 42
__lua__

-- shared variables between carts
current_level = 1
current_music = -1
warp_time = 0
warp_duration = 180
game_state = "game"
last_entered_initials = {"A", "C", "E"}
high_scores = {}  -- Initialize high scores table
arriving_from_menu = true  -- Flag for arrival warp effect
max_level = 5  -- Maximum level before true last boss
warp_started = false  -- Flag to track if warp sound has played
boss_defeat_grace = 0

-- shared functions between carts
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
    colors = {7, 6, 13, 12}
    large_star_chance = 0.4
  elseif current_level >= 6 then
    colors = {7, 6, 13, 14, 11, 12, 1, 2}
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

function update_starfield()
  local spd_mult = 2 + (current_level * 2)  -- Base speed multiplier that increases with level
  
  for star in all(starfield) do
    -- Move stars faster based on their size and level
    local star_speed = star.speed * spd_mult
    -- Make large stars move even faster for a parallax effect
    if star.size > 1 then star_speed *= 1.2 end
    
    star.y += star_speed
    
    -- Reset stars that go off-screen
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
      -- Add movement speed to higher level stars but keep colors the same
      if current_level > 1 then
        -- This was moved to update_starfield for better performance
        -- Stars now move based on their base speed * level multiplier
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

function center_text(text, y, color)
  local x = (128 - #text * 4) / 2
  print(text, x, y, color)
end

function add_score(points)
  score += points * score_multiplier
end

function update_music(screen)
  local new_music = 0
  
  if screen == "game" then
    new_music = 6  -- Pattern 6 (second song)
  elseif screen == "boss" then
    new_music = 10  -- Pattern 15 (third song)
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
    music(-1, 300)
    music(new_music)
    current_music = new_music
  end
end

game_state, credits, credits_used, current_level, enemy_kill_count = "game", 3, 0, 1, 0
shake_amount, current_music, warp_duration = 0, 0, 180
game_over_timer, game_over_grace, game_complete_grace = 10 * 30, 30, 45
game_over, bomb_active, bomb_timer, bomb_effect_timer = false, false, 0, 0
boss_defeat_grace = 0

local hold_up, hold_down, hold_left, hold_right = 0, 0, 0, 0

enemies, bullets, enemy_bullets, explosions, powerups, bullet_pool, enemy_bullet_pool = {}, {}, {}, {}, {}, {}, {}

P_SPD,P_HP,P_BMBS = 2,100,3                 -- Player speed, health, bombs
B_SPD,B_W,B_H = 6,8,8                       -- Bullet speed, width, height
BMB_DUR,BMB_DMG = 30,30                     -- Bomb duration, damage
E_SPWN_NRM,E_SPWN_PST = 2,3                 -- Enemy spawn normal and post-boss intervals
E_SPD,E_SPD_SCL = 2,1                       -- Enemy speed base and scaling
E_B_SPD,BOSS_B_SPD = 2.5,1                  -- Enemy bullet speed, boss bullet speed
E_SHT_BASE,E_SHT_SCL = 12,2                 -- Enemy shoot interval base and scaling
B_ROT_SPD,B_PAT_CHG,B_SPRL_STP = 20,20,45    -- Boss rotation speed, pattern change interval, spiral step
B_SPRL_MULT,B_RAD_MULT,B_SPD_LVL,B_SPD_HP = 1.5,1.5,4,30  -- Boss spiral multiplier, radius mult, speed level, speed health threshold
MB_HP,MB_HP_SCL = 60,5                      -- Mini-boss HP and scaling
FB_HP,FB_HP_SCL = 100,5                      -- Final boss HP and scaling
TLB_HP = 450                                -- True last boss HP
BASE_CLUSTERS = 6                          -- Base number of bullet clusters for bosses
S_NRM,S_MB,S_FB = 10,50,100                   -- Score: normal enemy, mini-boss, final boss
S_TLB,S_ITM,S_STRK = 50,0.5,10               -- Score: true last boss, item, streak
S_BMB,S_HP = 25,25                          -- Score: bomb kill, health pickup
PWR_SPD,P_ATR,P_DUR = 4,48,30               -- Powerup speed, attraction range, duration
PWR_DROP_CHANCE,PWR_SCORE_CHANCE = 0.9,0.92  -- Powerup drop chance and score powerup chance
PWR_MULTI_MIN,PWR_MULTI_MAX = 2,4           -- Min/max powerups that can spawn per enemy

function _init()
  -- Initialize cartdata first
  init_save_system()
  
  -- Graphics, music, and sound data are embedded in this cart
  -- BBS should handle this automatically when the cart loads
  
  -- Initialize high scores
  init_high_scores()
  
  init_game()
  current_music = -1
  update_music("game")
  starfield = {}  -- Initialize starfield array
  init_starfield()  -- Call init_starfield after array is created
  
  -- Set warp time when arriving from menu
  if arriving_from_menu then
    warp_time = warp_duration * 0.4  -- Start at 40% of the warp sequence when coming from menu
    sfx(19, 3)  -- Play warp sound when arriving from menu
  end
end

function init_save_system()
  cartdata("murdercrab_v1")  -- Use consistent name across all carts
  -- We don't need to clear persistent memory since it's used for high scores
end

function _update()
  if arriving_from_menu then
    update_starfield()
    update_warp()
    return  -- Skip normal game update when warping in
  end

  update_starfield()
  
  -- Let update_warp handle the warp_time decrement
  if warp_time > 0 then
    update_warp()
    return
  end
  
  if game_state == "game" then
    update_game()
  elseif game_state == "game_complete" then
    -- Check to see if Z was pressed after grace period
    if game_complete_grace <= 0 then
      if btnp(4) then
        -- Play transition sound and immediately load menu
        sfx(19, 3)
        -- Pass score and initials back to menu cart using cartdata
        local initials = last_entered_initials[1]..last_entered_initials[2]..last_entered_initials[3]
        update_high_scores(final_score, initials)
        load("murdercrab_menu.p8", "back to game")  -- Local filename for testing
      end
    else
      game_complete_grace -= 1  
    end
  elseif game_state == "game_over" then
    -- Game over is already handled in update_game when game_over flag is true
    -- This state should never be reached as we use the game_over flag instead
  end

  -- Handle boss defeat grace period
  if boss_defeat_grace > 0 then
    boss_defeat_grace -= 1
    if boss_defeat_grace == 0 then
      -- Only transition to next phase after grace period
      if phase == "level_complete" then
        -- Clear bullets
        for bullet in all(enemy_bullets) do
          release_enemy_bullet(bullet)
        end
        enemy_bullets = {}

        for bullet in all(bullets) do
          release_bullet(bullet, bullet_pool)
        end
        bullets = {}
        
        current_level += 1
        if current_level <= 5 then
          -- Set up warp to next level
          warp_time = warp_duration
          phase = "warping"
          enemy_kill_count = 0
          update_music("silent")
        else
          -- We're beyond level 5
          if credits_used < 1 then
            -- Initiate warp effect first, then spawn true last boss after warp
            current_level += 1  -- Increment to level 6 for TLB
            warp_time = warp_duration
            phase = "warping"
            sfx(19, 3)  -- Play warp sound for transition
            update_music("silent")
          else
            -- Game complete if used continues
            game_state = "game_complete"
            game_complete_grace = 45
          end
        end
      else
        -- This shouldn't happen in normal gameplay, but handle gracefully
        phase_state = "pre_mini_boss"
      end
    end
  end
end

function _draw()
  if game_state == "game" then
    draw_game()
  elseif game_state == "game_complete" then
    draw_game_complete()
  elseif game_state == "game_over" then
    -- Game over visuals are handled in draw_game when game_over flag is true
    draw_game()
  end
end

function init_game()
  init_game_variables()
  init_game_objects()
  init_starfield()
end

function init_game_variables()
  phase = "normal"
  current_level = 1
  enemy_kill_count = 0
  phase_state = "pre_mini_boss"  -- Track sub-phases: pre_mini_boss, post_mini_boss
  
  current_music = -1
  
  final_score = 0
  score = 0
  score_streak = 1
  score_multiplier = 1
  final_score = 0
  
  game_over = false
  game_over_timer = 10 * 30
  game_over_grace = 30
  game_complete_grace = 45
  
  shake_amount = 0
  warp_time = 0
  bomb_active = false
  bomb_timer = 0
  
  spawn_timer = 0
  update_spawn_delay()  -- Calculate spawn delay based on current level
end

-- Calculate spawn delay based on current level
function update_spawn_delay()
  spawn_delay = max(15, 60 - (current_level - 1) * 10)  -- Spawn faster as levels increase
end

function init_game_objects()
  player = {
    x = 60,
    y = 100,
    width = 8,
    height = 8,
    speed = P_SPD,
    health = P_HP,
    max_health = P_HP,
    bombs = P_BMBS,
    invincible_timer = 0,
    visible = true,
    thrust_frame = 0,
    sprite = 1
  }
  
  enemies = {}
  bullets = {}
  enemy_bullets = {}
  explosions = {}
  powerups = {}
  bullet_pool = {}
  enemy_bullet_pool = {}
  
  bullet_speed = B_SPD
  bullet_width = B_W
  bullet_height = B_H
end

function collides(a, b)
  return not (
    a.x + a.width < b.x or
    b.x + b.width < a.x or
    a.y + a.height < b.y or
    b.y + b.height < a.y
  )
end

function rotate_vector(dx, dy, offset_deg)
  local offset = offset_deg / 360
  local c = cos(offset)
  local s = -sin(offset)
  local rx = dx * c - dy * s
  local ry = dx * s + dy * c
  return rx, ry
end

function draw_player()
  if player.invincible_timer > 0 then
    if time() % 0.2 < 0.1 then
      return
    end
  end
  
  spr(player.sprite, player.x, player.y)
  
  if player.thrust_frame > 0 then
    local x,y = player.x+4, player.y+8
    local h = btn(0) and 1 or (btn(1) and -1 or 0)
    local v = btn(2) and 1 or (btn(3) and -1 or 0)
    local f = flr(rnd(2))
    
    pset(x+h, y+1+f, 8+f)
    pset(x+h+(f-1), y+2, 9)
    if rnd(1)<0.7 then pset(x+h, y+2+f, 8) end
  end
end

function get_bullet(pool)
 if #pool > 0 then
  local b = pool[1]
  del(pool, b)
  return b
 end
 return {}
end

function release_bullet(b, pool)
 add(pool, b)
end

function player_shoot()
  local cx = player.x + player.width / 2
  local offset = 6
  
  for i=0,1 do
    local b = get_bullet(bullet_pool)
    b.x = cx + (i==0 and -offset or offset) - bullet_width/2
    b.y = player.y
    b.speed = bullet_speed
    b.width = bullet_width
    b.height = bullet_height
    b.dx = 0
    b.dy = -bullet_speed
    b.anim_frame = 0
    add(bullets, b)
  end
  
  sfx(25, 3)
end

function update_bullets(bullets, is_enemy)
  for i = #bullets, 1, -1 do
    local bullet = bullets[i]
    if is_enemy then
      bullet.x += bullet.dx
      bullet.y += bullet.dy
    else
      bullet.y -= bullet_speed
    end
    
    if not is_enemy then
      if bullet.anim_frame == 0 then
        bullet.anim_frame = 1
      elseif bullet.anim_frame == 1 then
        bullet.anim_frame = 2
      elseif bullet.anim_frame == 2 then
        bullet.anim_frame = 3
      elseif bullet.anim_frame == 3 then
        bullet.anim_frame = 4
      elseif bullet.anim_frame == 4 then
        bullet.anim_frame = 3
      end
    end
    
    bullet.hit_x = bullet.x + 3
    bullet.hit_y = bullet.y + 3
    
    if bullet.y > 128 or bullet.y < -bullet.height or 
       bullet.x > 128 or bullet.x < -bullet.width then
      del(bullets, bullet)
      release_bullet(bullet, is_enemy and enemy_bullet_pool or bullet_pool)
    end
  end
end

function create_enemy_bullet(x,y,dx,dy)
 local b = get_enemy_bullet()
 if b then
  b.x = x - 4
  b.y = y - 4
  b.dx = dx
  b.dy = dy
  b.width = 8
  b.height = 8
  b.hit_x = b.x + 3
  b.hit_y = b.y + 3
  b.hit_width = 2
  b.hit_height = 2
  return b
 end
end

function check_enemy_bullet_collisions()
  if player.invincible_timer > 0 then
    return
  end
  
  local player_hitbox = {
    x = player.x + 3,
    y = player.y + 3,
    width = 2,
    height = 2
  }
  
  for bullet in all(enemy_bullets) do
    if collides(player_hitbox, bullet) then
      player_hit()
      del(enemy_bullets, bullet)
      release_enemy_bullet(bullet)
      break
    end
  end
end

-- enemies & enemy bullets
enemies = {}
enemy_bullets = {}

enemy_bullet_speed = E_B_SPD
enemy_bullet_width = 8
enemy_bullet_height = 8
boss_bullet_speed = BOSS_B_SPD
enemy_bullet_pool = {}

function get_enemy_bullet()
 if #enemy_bullet_pool > 0 then
  local b = enemy_bullet_pool[1]
  del(enemy_bullet_pool, b)
  return b
 end
 return {}
end

function release_enemy_bullet(b)
 add(enemy_bullet_pool, b)
end

function spawn_enemy()
  local count = 1
  
  -- Spawn more enemies at once in higher levels
  if current_level >= 3 then
    count = 2
  end
  if current_level >= 5 then
    count = 3
  end
  
  for i = 1, count do
    spawn_normal_enemy()
  end
end

function normal_enemy_fire(enemy)
  if enemy.burst_index > 0 then
    if enemy.burst_timer > 0 then
      enemy.burst_timer -= 1
    else
      local x = enemy.x + enemy.width/2
      local y = enemy.y + enemy.height/2
      local tx = player.x + player.width/2
      local ty = player.y + player.height/2
      local vx = tx - x
      local vy = ty - y
      local d = sqrt(vx*vx + vy*vy)
      if d == 0 then d = 1 end
      local ndx = vx/d
      local ndy = vy/d
      
      local offsets
      if enemy.burst_index == 1 then
        offsets = -25
      elseif enemy.burst_index == 2 then
        offsets = 25
      else
        offsets = 0
      end
      
      local rx, ry = rotate_vector(ndx, ndy, offsets)
      local bullet = create_enemy_bullet(x, y, enemy_bullet_speed * rx, enemy_bullet_speed * ry)
      if bullet then -- Only add if we got a valid bullet
        add(enemy_bullets, bullet)
      end
      
      enemy.burst_index += 1
      if enemy.burst_index > 3 then
        enemy.burst_index = 0
      else
        enemy.burst_timer = enemy.burst_delay  -- Set delay before firing next shot in burst
      end
    end
  else
    enemy.shoot_timer += 1
    if enemy.shoot_timer >= enemy.shoot_interval then
      enemy.shoot_timer = 0
      enemy.burst_index = 1
      enemy.burst_timer = 0
    end
  end
end

function spawn_normal_enemy()
  local e = {
    x = flr(rnd(128 - 8)),
    y = -8,
    speed = E_SPD + (current_level - 1) * E_SPD_SCL,
    sprite = 3,
    width = 8,
    height = 8,
    shoot_timer = 0,
    shoot_interval = max(1, E_SHT_BASE - (current_level - 1) * E_SHT_SCL),
    burst_offsets = {-15, 15, 0},
    burst_index = 1,
    burst_delay = 5,
    burst_timer = 0,
    type = "normal",
    health = 1,
    dx = 0,
    dy = 0,
    state = 0,
    hover_y = 20 + rnd(15),
    dir = rnd(1) < 0.5 and -1 or 1,
    timer = 45,
    paused = false,
    anim_frame = 0,
    anim_timer = 0,
    anim_speed = 5
  }

  e.dy = e.speed
  
  add(enemies, e)
end

function update_enemies()
  for i = #enemies, 1, -1 do
    local enemy = enemies[i]
    if enemy.paused then goto continue end
    if enemy.type == "normal" then
      update_normal_enemy(enemy)
    elseif enemy.type == "mini_boss" or enemy.type == "final_boss" or enemy.type == "true_last_boss" then
      update_boss_enemy(enemy)
    end
    
    ::continue::
  end
end

function update_normal_enemy(enemy)
  -- Handle animation
  enemy.anim_timer += 1
  if enemy.anim_timer >= enemy.anim_speed then
    enemy.anim_timer = 0
    
    -- Different animation based on state
    if enemy.state == 2 then
      enemy.sprite = 35  -- Use sprite 35 for kamikaze
    else
      -- Simple alternation between sprite 3 and 19 for normal movement
      enemy.anim_frame = (enemy.anim_frame + 1) % 2
      if enemy.anim_frame == 0 then
        enemy.sprite = 3
      else
        enemy.sprite = 19
      end
    end
  end

  if enemy.state == 0 then
    enemy.y += enemy.dy
    enemy.x += enemy.dir * 0.5
    
    -- Prevent getting stuck on screen edges during entry phase
    if enemy.x < 0 then
      enemy.x = 0
      enemy.dir = 1  -- Reverse direction
    elseif enemy.x > 127 - enemy.width then
      enemy.x = 127 - enemy.width
      enemy.dir = -1  -- Reverse direction
    end
    
    if enemy.y >= enemy.hover_y then
      enemy.y = enemy.hover_y
      enemy.state = 1
    end
    
    if enemy.burst_index > 0 then
      normal_enemy_fire(enemy)
    else
      enemy.shoot_timer += 1
      if enemy.shoot_timer >= enemy.shoot_interval then
        enemy.shoot_timer = 0
        normal_enemy_fire(enemy)
      end
    end
    
  elseif enemy.state == 1 then
    enemy.x += enemy.dir * 0.7
    if enemy.x < 0 or enemy.x > 127 - enemy.width then
      enemy.dir = -enemy.dir
      
      -- Ensure enemy is within bounds after direction change
      if enemy.x < 0 then
        enemy.x = 0
      elseif enemy.x > 127 - enemy.width then
        enemy.x = 127 - enemy.width
      end
    end
    
    enemy.timer -= 1
    if enemy.timer <= 0 then
      enemy.state = 2
      local ex = enemy.x + enemy.width/2
      local ey = enemy.y + enemy.height/2
      local px = player.x + player.width/2
      local py = player.y + player.height/2
      local dx = px - ex
      local dy = py - ey
      local d = sqrt(dx*dx + dy*dy)
      if d > 0 then dx /= d dy /= d end
      local spd = enemy.speed * 2
      enemy.dx = dx * spd
      enemy.dy = dy * spd
      
      -- Immediately set to kamikaze sprite when transitioning
      enemy.sprite = 35
      enemy.anim_speed = 3  // Faster animation for kamikaze mode
    end
    
    if enemy.burst_index > 0 then
      normal_enemy_fire(enemy)
    else
      enemy.shoot_timer += 1
      if enemy.shoot_timer >= enemy.shoot_interval then
        enemy.shoot_timer = 0
        normal_enemy_fire(enemy)
      end
    end
  else
    enemy.x += enemy.dx
    enemy.y += enemy.dy
  end
  
  if enemy.y > 128 or enemy.x < -enemy.width or enemy.x > 128 then
    del(enemies, enemy)
  end
end

function update_enemy_bullets()
  for i = #enemy_bullets, 1, -1 do
    local bullet = enemy_bullets[i]
    bullet.x += bullet.dx
    bullet.y += bullet.dy
    bullet.hit_x = bullet.x + 3
    bullet.hit_y = bullet.y + 3
    
    if bullet.y > 128 or bullet.y < -bullet.height or 
       bullet.x > 128 or bullet.x < -bullet.width then
      del(enemy_bullets, bullet)
      release_enemy_bullet(bullet)
    end
  end
end

function enemy_shoot_radial(e)
  local h = e.type and e.health and e.health/get_boss_max_health(e.type) or 1
  local s = boss_bullet_speed*(1.5+(current_level-1)*0.15+(1-h)*0.3)
  
  -- Use pattern change interval to alternate between patterns
  -- The boss phase will affect which patterns are used
  local phase = e.phase or 1
  local pattern_type
  
  -- If we're in the middle of an aimed burst, continue with it
  if e.burst_index and e.burst_index > 0 then
    create_aimed_pattern(e, 0, s)  -- Count is ignored in the new implementation
    return
  end
  
  -- Calculate pattern based on time and phase
  if phase == 1 then
    -- Phase 1: alternate between radial and spiral
    pattern_type = flr(time() * B_PAT_CHG) % 2
  elseif phase == 2 then
    -- Phase 2: use all three patterns with emphasis on aimed
    local t = flr(time() * B_PAT_CHG) % 5
    if t < 2 then
      pattern_type = 2  -- Aimed
    else
      pattern_type = t - 2  -- 0 or 1
    end
  else
    -- Phase 3: rapid alternation between patterns
    pattern_type = flr(time() * B_PAT_CHG * 1.5) % 3
  end
  
  -- Increment rotation counter
  e.rotate_counter = (e.rotate_counter + B_ROT_SPD) % 360
  
  -- Add more bullets at lower health
  local health_boost = flr((1-h) * 5)
  
  if pattern_type == 0 then
    -- Reset burst variables when switching to non-aimed patterns
    e.burst_index = nil
    -- Spiral pattern
    create_spiral_pattern(e, e.cluster_count + health_boost, s)
  elseif pattern_type == 1 then
    -- Reset burst variables when switching to non-aimed patterns
    e.burst_index = nil
    -- Radial pattern
    create_radial_pattern(e, e.cluster_count + health_boost, s)
  else
    -- Aimed pattern - now uses burst firing
    create_aimed_pattern(e, flr(e.cluster_count/2) + health_boost, s)
  end
end

-- Spiral pattern with bullets arranged in a spiral formation
function create_spiral_pattern(enemy, count, speed)
  local cx=enemy.x+enemy.width/2
  local cy=enemy.y+enemy.height/2
  
  if enemy.type=="true_last_boss" and enemy.rage_mode then
    count+=10
  end
  
  for i=0,count-1 do
    local a=enemy.rotate_counter+(i*B_SPRL_STP)
    local na=(a+sin(time()*3+i/10)*5/360)/360%1
    local dx=speed*cos(na)
    local dy=-speed*sin(na)
    spawn_enemy_bullet(cx,cy,dx,dy)
  end
end

-- Classic radial pattern with evenly spaced bullets
function create_radial_pattern(enemy, count, speed)
  local cx=enemy.x+enemy.width/2
  local cy=enemy.y+enemy.height/2
  
  if enemy.type=="true_last_boss" and enemy.rage_mode then
    count+=10
  end
  
  for i=0,count-1 do
    local a=(i*(360/count))+enemy.rotate_counter
    local na=a/360
    local dx=speed*cos(na)
    local dy=-speed*sin(na)
    
    spawn_enemy_bullet(cx,cy,dx,dy)
  end
end

function create_aimed_pattern(e, bullet_count, speed)
  if not e.burst_index then
    e.burst_index = 1
    e.burst_timer = 0
    e.burst_max = 3
    e.burst_delay = 8
  end
  
  if e.burst_timer <= 0 then
    local boss_x = e.x + e.width / 2
    local boss_y = e.y + e.height / 2
    local player_x = player.x + player.width / 2
    local player_y = player.y + player.height / 2
    
    local dx = player_x - boss_x
    local dy = player_y - boss_y
    
    local dist = sqrt(dx*dx + dy*dy)
    if dist > 0 then
      dx = dx/dist
      dy = dy/dist
    end
    
    local b = get_enemy_bullet()
    if b then
      b.x = boss_x - 4
      b.y = boss_y - 4
      b.dx = dx * speed
      b.dy = dy * speed
      b.width = enemy_bullet_width
      b.height = enemy_bullet_height
      b.hit_x = b.x + 3
      b.hit_y = b.y + 3
      b.hit_width = 2
      b.hit_height = 2
      add(enemy_bullets, b)
    end
    
    e.burst_index += 1
    if e.burst_index > e.burst_max then
      e.burst_index = 0
    end
    e.burst_timer = e.burst_delay
  else
    e.burst_timer -= 1
  end
end

-- Helper function to create and add a bullet
function spawn_enemy_bullet(cx, cy, dx, dy)
  local bullet = get_enemy_bullet()
  if bullet then
    bullet.x = cx - enemy_bullet_width/2
    bullet.y = cy - enemy_bullet_height/2
    bullet.dx = dx
    bullet.dy = dy
    bullet.width = enemy_bullet_width
    bullet.height = enemy_bullet_height
    bullet.hit_x = cx - enemy_bullet_width/2 + 3
    bullet.hit_y = cy - enemy_bullet_height/2 + 3
    bullet.hit_width = 2
    bullet.hit_height = 2
    add(enemy_bullets, bullet)
  end
end

function boss_exists(boss_type)
  local count = 0
  for e in all(enemies) do
    if e.type == boss_type then
      count += 1
    end
  end
  return count
end

function get_boss_max_health(enemy_type)
  if enemy_type == "mini_boss" then
    return MB_HP + (current_level - 1) * MB_HP_SCL
  elseif enemy_type == "final_boss" then
    return FB_HP + (current_level - 1) * FB_HP_SCL
  else
    return TLB_HP
  end
end

function spawn_mini_boss()
  local count = get_boss_count("mini_boss")
  local spacing = 0
  if count > 1 then spacing = 32 end
  
  for i=1,count do
    local e = {
      x = 64-16 + spacing*(i-(count+1)/2),  -- Center the formation
      y = -32,
      dx = 0.5,
      dy = 1,
      speed = 2,
      width = 16,
      height = 16,
      health = get_boss_max_health("mini_boss"),
      type = "mini_boss",
      shoot_timer = 0,
      shoot_interval = 30,
      pattern = 1,
      rotate_counter = 0,
      cluster_count = BASE_CLUSTERS + current_level,
      sprite = 8,
      is_big_sprite = true,
      color_offset = 0,
      paused = false
    }
    add(enemies, e)
  end
end

function spawn_final_boss()
  local c,s=get_boss_count("final_boss"),0
  if c>1 then s=32 end
  local level_scaling=flr(current_level*1)
  for i=1,c do
    add(enemies,{
      x=64-16+s*(i-(c+1)/2),y=-32,
      dx=0.3,dy=1,speed=2,
      width=16,height=16,
      health=get_boss_max_health("final_boss"),
      type="final_boss",shoot_timer=0,
      shoot_interval=12,pattern=1,
      rotate_counter=0,
      cluster_count=BASE_CLUSTERS+level_scaling,
      sprite=8,is_big_sprite=true,
      color_offset=12,paused=false,phase=1
    })
  end
end

function spawn_true_last_boss()
  local level_scaling=flr(current_level*1)
  local tb = {
    x = 64 - 16,  -- Center the 32-pixel wide boss (64 - 32/2)
    y = -32,      -- Start higher since boss is taller
    speed = 3,
    sprite = 10,
    width = 32,
    height = 32,
    shoot_timer = 0,
    shoot_interval = 10,
    health = get_boss_max_health("true_last_boss"),
    type = "true_last_boss",
    cluster_count = BASE_CLUSTERS+2+level_scaling,  -- TLB gets 2 extra clusters
    rotate_counter = 0,
    is_big_sprite = true,
    is_tlb = true,
    phase = 1,
    dx = 0.3,
    dy = 0,
    paused = false
  }
  add(enemies, tb)
end

function get_boss_count(t)
  if (t=="mini_boss" or t=="final_boss") then
    if (current_level>4) then
      return 3
    end
    if (current_level>2) then
      return 2
    end
    return 1
  end
  return 1
end

function update_boss_phase(enemy)
  if not enemy.type or not enemy.health then return end
  
  local old_phase = enemy.phase or 1
  local new_phase = 1
  local max_health = get_boss_max_health(enemy.type)
  
  if enemy.type == "mini_boss" then
    new_phase = enemy.health <= max_health * 0.5 and 2 or 1
  elseif enemy.type == "final_boss" then
    new_phase = enemy.health <= (max_health / 3) and 3 or (enemy.health <= (max_health * 2/3) and 2 or 1)
  elseif enemy.type == "true_last_boss" then
    new_phase = enemy.health <= (max_health / 3) and 3 or (enemy.health <= (max_health * 2/3) and 2 or 1)
  end
  
  if new_phase > old_phase then
    enemy.phase = new_phase
    shake_amount = 8 + new_phase * 2
    
    for i=1, 2 + new_phase do
      create_explosion(enemy.x + rnd(enemy.width), enemy.y + rnd(enemy.height), 1)
    end
    
    sfx(7, 2)
    if enemy.type == "true_last_boss" and new_phase == 3 then enemy.rage_mode = true end
    enemy.shoot_interval = max(3, enemy.shoot_interval - 1)
  end
end

function update_boss_enemy(enemy)
  if enemy.y > 25 then enemy.y = 25 end
  if enemy.y < 5 then enemy.y = 5 end
  enemy.x += enemy.dx
  local c = 64 - (enemy.width/2)
  local r = 30
  if enemy.x < c - r or enemy.x > c + r then
    enemy.dx = -enemy.dx
    if enemy.x < c - r then enemy.x = c - r
    elseif enemy.x > c + r then enemy.x = c + r end
  end

  if enemy.burst_index and enemy.burst_index > 0 then
    enemy_shoot_radial(enemy)
  else
    enemy.shoot_timer += 1
    if enemy.shoot_timer >= enemy.shoot_interval then
      enemy.shoot_timer = 0
      enemy_shoot_radial(enemy)
    end
  end
  
  update_boss_phase(enemy)
end

-- powerup & score items
function spawn_powerup(x, y, type, value)
  local p = {
    x = x,
    y = y,
    type = type,
    value = value or S_ITM,
    width = 8,
    height = 8,
    speed = PWR_SPD,
    dx = 0,
    dy = 0
  }
  if type == "score" then
    p.timer = P_DUR
  end
  add(powerups, p)
  return p
end

function spawn_powerup_explosion(x, y, count)
  local powerups_spawned = {}
  
  -- Determine how many score powerups to spawn (2-4)
  local total_score_powerups = flr(rnd(PWR_MULTI_MAX - PWR_MULTI_MIN + 1)) + PWR_MULTI_MIN
  
  -- Calculate base angle for spreading powerups
  local angle_increment = 1 / total_score_powerups
  
  -- Spawn score powerups
  for i=1, total_score_powerups do
    local angle = angle_increment * i
    -- Calculate velocity vector
    local vx = cos(angle) * 2
    local vy = sin(angle) * 2
    
    local p = spawn_powerup(x, y, "score", 100)
    p.dx = vx
    p.dy = vy
    add(powerups_spawned, p)
  end
  
  -- Small chance to spawn health or bomb
  if rnd(1) < 0.05 then  -- Reduced from 0.2 (20%) to 0.05 (5%)
    local ptype = (rnd(1) < 0.5) and "bomb" or "health"
    local angle = rnd(1)
    local vx = cos(angle) * 2
    local vy = sin(angle) * 2
    
    local p = spawn_powerup(x, y, ptype)
    p.dx = vx
    p.dy = vy
    add(powerups_spawned, p)
  end
  
  return powerups_spawned
end

function update_powerups()
  for p in all(powerups) do
    if p.type == "score" then
      p.timer -= 1
      
      if p.timer <= 0 then
        -- Create small explosion effect when score powerup expires
        add(explosions, {
          x = p.x + 4,  -- Center of powerup
          y = p.y + 4,
          radius = 1,
          max_radius = 6,
          life = 8,
          color = 9
        })
        sfx(6, 3)  -- Play small explosion sound
        del(powerups, p)
      end
    end
    
    -- Apply initial explosive velocity if present
    if p.dx != 0 or p.dy != 0 then
      p.x += p.dx
      p.y += p.dy
      
      -- Dampen velocity to simulate friction
      p.dx *= 0.9
      p.dy *= 0.9
      
      -- Stop movement when velocity gets very small
      if abs(p.dx) < 0.1 and abs(p.dy) < 0.1 then
        p.dx = 0
        p.dy = 0
      end
    end
    
    local dx = (player.x + player.width/2) - (p.x + p.width/2)
    local dy = (player.y + player.height/2) - (p.y + p.height/2)
    local dist = sqrt(dx*dx + dy*dy)
    
    if p.attracted or dist < P_ATR then
      local speed = p.attract_speed or 0.3
      p.x += dx * speed
      p.y += dy * speed
      
      -- When attracted, override any explosion velocity
      p.dx = 0
      p.dy = 0
    else
      -- Only apply normal downward velocity if not moving from explosion
      if p.dx == 0 and p.dy == 0 then
        p.y += p.speed
      end
    end
    
    if p.y > 128 or p.x < -8 or p.x > 136 then
      del(powerups, p)
    end
  end
end

function check_powerup_collection()
  for p in all(powerups) do
    if collides(p, player) then
      if p.type == "bomb" then
        player.bombs += 1
        sfx(3, 2)
      elseif p.type == "health" then
        player.health += 1
        sfx(3, 2)
      elseif p.type == "score" then
        score += p.value * score_multiplier
        score_streak += 1
        if score_streak >= S_STRK then
          score_multiplier += 1  -- No cap on multiplier
          score_streak = 0
        end
        

        
        sfx(3, 2)
      end
      del(powerups, p)
    end
  end
end

-- main game update
function update_game()
  if game_state != "game_complete" and phase == "mini_boss" or phase == "final_boss" or phase == "true_last_boss" then
    update_music("boss")
  else
    update_music("game")
  end

  update_explosions()
  update_bomb_effect()
  update_powerups()
  check_powerup_collection()
  
  if update_warp() then
    return
  end

  update_enemies()
  update_bullets(bullets, false)
  update_enemy_bullets()
  
  -- Enemy spawn logic based on phase and enemy_kill_count
  if phase == "normal" then
    spawn_timer += 1
    if spawn_timer >= spawn_delay then
      spawn_timer = 0
      spawn_enemy()
    end

    -- First check for mini-boss threshold in pre_mini_boss phase
    if phase_state == "pre_mini_boss" and enemy_kill_count >= mini_threshold() and boss_exists("mini_boss") == 0 then
      spawn_mini_boss()
      phase = "mini_boss"
    -- Then check for final boss threshold in post_mini_boss phase
    elseif phase_state == "post_mini_boss" and enemy_kill_count >= final_threshold() and boss_exists("final_boss") == 0 then
      spawn_final_boss()
      phase = "final_boss"
    end
  elseif phase == "mini_boss" then
    if #enemies == 0 then
      phase = "normal"  -- Return to normal phase after mini-boss
      phase_state = "post_mini_boss"  -- Mark that we're in the post-mini-boss phase
      enemy_kill_count = 0  -- Reset kill count for the post-mini-boss phase
    end
  elseif phase == "final_boss" then
    if boss_exists("final_boss") == 0 then
      phase = "level_complete"
      boss_defeat_grace = 90  -- Increased from 45 to 90 frames (3 seconds) to allow more time for effects
      -- Trigger the initial boss defeat explosion
      local center_x, center_y = 64, 48  -- Approximate center of where the boss was
      create_final_boss_defeat_explosion(center_x, center_y)
      
      -- Transition from boss music to a silent period
      update_music("silent")
    end
  elseif phase == "level_complete" then
    -- Handle the grace period with special effects
    if boss_defeat_grace > 0 then
      boss_defeat_grace -= 1
      
      -- Add extra explosion effects during grace period
      if boss_defeat_grace % 10 == 0 then
        create_explosion(64 + rnd(60) - 30, 64 + rnd(60) - 30, 1)
      end
      
      -- Add larger explosion at specific intervals
      if boss_defeat_grace % 30 == 0 then
        create_explosion(64 + rnd(40) - 20, 40 + rnd(20) - 10, 2)
        shake_amount = 8
      end
      
      -- Play warp sound near the end of the grace period
      if boss_defeat_grace == 20 then
        sfx(19, 3)  -- Warp sound preparing for transition
      end
      
      -- Allow all explosions to finish before proceeding
      if boss_defeat_grace == 1 and #explosions > 0 then
        boss_defeat_grace = 2  -- Keep waiting if explosions are still active
      end
    else
      -- No more grace period, now handle level transition
      if current_level == max_level then
        -- After level 5, either spawn TLB or go to victory
        if credits_used < 1 then
          -- Initiate warp effect first, then spawn true last boss after warp
          current_level += 1  -- Increment to level 6 for TLB
          warp_time = warp_duration
          phase = "warping"
          sfx(19, 3)  -- Play warp sound for transition
          update_music("silent")
        else
          -- Game complete if used continues
          phase = "victory_lap"
          game_complete_grace = 120
        end
      else
        -- Not at level 5 yet, move to next level
        -- Ensure all explosions have finished before starting warp
        if #explosions == 0 then
          current_level += 1
          warp_time = warp_duration
          phase = "warping"
          sfx(19, 3)  -- Explicitly play warp sound at transition start
          update_music("silent")
        else
          -- Wait one more frame for explosions to finish
          boss_defeat_grace = 1
        end
      end
    end
  elseif phase == "victory_lap" then
    if game_complete_grace > 0 then
      game_complete_grace -= 1
    else
      game_state = "game_complete"
      game_complete_grace = 45  -- Additional grace period for the game complete screen
    end
  elseif phase == "true_last_boss" then
    -- Let the boss_exists check in the bullet collision
    -- code handle the transition to victory when boss is defeated
  elseif phase == "warping" then
    -- Nothing to do here, just wait for warp_time to expire
  end

  if game_over then
    game_over_timer -= 1
    
    if game_over_grace > 0 then
      game_over_grace -= 1
    end
    
    if game_over_timer == 10 * 30 - 1 then  -- First frame of game over
      local bonus = player.bombs * S_BMB + player.health * S_HP
      final_score = score + bonus
      local initials = last_entered_initials[1] .. last_entered_initials[2] .. last_entered_initials[3]
      update_high_scores(final_score, initials)
    end
    
    if game_over_timer <= 0 then
      -- Store initials in cartdata for BBS compatibility
      save_transition_data()
      
      -- Load the menu cart directly, score already saved above
      sfx(4, 3)
      load("murdercrab_menu.p8", "back to game")  -- Local filename for testing
      return
    end
    
    if game_over_grace <= 0 then
      if credits > 0 and btnp(4) then
        credits -= 1
        credits_used += 1
        game_over = false
        game_over_timer = 10 * 30
        game_over_grace = 30
        player.health = 3
        score_streak = 0
        score_multiplier = 1
      elseif btnp(5) then
        -- Store initials in cartdata for BBS compatibility
        save_transition_data()
        
        -- Load the menu cart, score already saved above
        load("murdercrab_menu.p8", "back to game")  -- Local filename for testing
      end
    end
    return
  end

  if not game_over then
    if btnp(5) then
      activate_bomb()
    end

    if bomb_active then
      bomb_timer -= 1
      if bomb_timer <= 0 then
        bomb_active = false
      end
    end

    if btn(0) and player.x > 0 then
      player.x -= player.speed
      player.sprite = 17
    elseif btn(1) and player.x < 128 - player.width then
      player.x += player.speed
      player.sprite = 33
    else
      player.sprite = 1
    end
    if btn(2) and player.y > 0 then
      player.y -= player.speed
    end
    if btn(3) and player.y < 128 - player.height then
      player.y += player.speed
    end

    if btnp(4) then
      player_shoot()
    end
  end

  check_enemy_bullet_collisions()
  
  if player.invincible_timer <= 0 and not game_over then
    local player_hitbox = {
      x = player.x + 3,
      y = player.y + 3,
      width = 2,
      height = 2
    }
    
    for enemy in all(enemies) do
      if enemy.state == 2 then -- Kamikaze state
        local kamikaze_center_x = enemy.x + enemy.width/2
        local kamikaze_center_y = enemy.y + enemy.height/2
        
        local kamikaze_precision_box = {
          x = kamikaze_center_x - 1,
          y = kamikaze_center_y - 1,
          width = 2,
          height = 2
        }
        
        if collides(player, kamikaze_precision_box) then
          player_hit()
          create_explosion_chain(enemy.x + enemy.width/2, enemy.y + enemy.height/2, 3, 10)
          del(enemies, enemy)
          
          local dx = player.x - enemy.x
          local dy = player.y - enemy.y
          local d = max(1, sqrt(dx*dx + dy*dy))
          player.x += (dx/d) * 5
          player.y += (dy/d) * 5
        end
      elseif collides(player_hitbox, enemy) then
        player_hit()
        local dx = player.x - enemy.x
        local dy = player.y - enemy.y
        local d = max(1, sqrt(dx*dx + dy*dy))
        player.x += (dx/d) * 3
        player.y += (dy/d) * 3
      end
    end
  end

  for bullet in all(bullets) do
    for enemy in all(enemies) do
      if enemy.dx and enemy.dy and not enemy.health then
        goto continue_bullet_check
      end
      
      if collides(enemy, bullet) then
        if not enemy.type or enemy.type == "normal" then
          add_score(S_NRM)
          enemy_kill_count += 1
          
          create_explosion_chain(enemy.x + enemy.width/2, enemy.y + enemy.height/2, 3, 10)
          
          shake_amount = 3
          
          del(enemies, enemy)
          del(bullets, bullet)
          release_bullet(bullet, bullet_pool)
          
          -- Use the modified powerup spawning system
          if rnd(1) < PWR_DROP_CHANCE then
            spawn_powerup_explosion(enemy.x, enemy.y)
          end
          break
        else
          enemy.health -= 1
          sfx(7, 2)
          shake_amount = 3
          
          local hit_x = mid(enemy.x, bullet.x + bullet_width/2, enemy.x + enemy.width)
          local hit_y = mid(enemy.y, bullet.y + bullet_height/2, enemy.y + enemy.height)
          
          create_hit_feedback(hit_x, hit_y)
          
          if enemy.health > 0 then
            -- Hit feedback already created above
          else
            -- Big explosion for bosses
            create_explosion(enemy.x, enemy.y, 2)
            
            -- Add multiple explosions around the boss when it dies
            for i=1,5 do
              local px = enemy.x + rnd(enemy.width)
              local py = enemy.y + rnd(enemy.height)
              create_explosion(px, py, 1)
            end
            
            -- Heavy screen shake for boss death
            shake_amount = 10
            
            if enemy.type == "mini_boss" then
              -- Only transition if all mini-bosses are gone
              if boss_exists("mini_boss") == 0 then
                convert_enemy_bullets_to_explosions()
                phase = "normal"  -- Immediately return to normal phase
                phase_state = "post_mini_boss"  -- Mark that we're in the post-mini-boss phase
                enemy_kill_count = 0  -- Reset kill count for next threshold
                update_music("game")  -- Return to game music after boss
              end
              add_score(S_MB)
            elseif enemy.type == "final_boss" then
              add_score(S_FB)
              
              -- Only initiate level completion if all final bosses are gone
              if boss_exists("final_boss") == 0 then
                phase = "level_complete"
                boss_defeat_grace = 90  -- Increased from 45 to 90 frames for better effect visibility
                -- Trigger the final boss defeat explosion at the boss's position
                create_final_boss_defeat_explosion(enemy.x + enemy.width/2, enemy.y + enemy.height/2)
              end
            elseif enemy.type == "true_last_boss" then
              handle_tlb_defeat(enemy)
            end
            del(enemies, enemy)
            del(bullets, bullet)
            release_bullet(bullet, bullet_pool)
            break
          end
          
          del(bullets, bullet)
          release_bullet(bullet, bullet_pool)
          break
        end
      end
      ::continue_bullet_check::
    end
  end

  if player.invincible_timer > 0 then
    player.invincible_timer -= 1
    player.visible = not player.visible
    if player.invincible_timer <= 0 then
      player.visible = true
    end
  end

  if shake_amount > 0 then
    shake_amount -= 1
  end

  if btn(0) or btn(1) or btn(2) or btn(3) then
    player.thrust_frame = (player.thrust_frame + 1) % 3
  else
    player.thrust_frame = 0
  end
end

function player_hit()
  if player.invincible_timer > 0 or game_over then
    return
  end
  
  player.health -= 1
  player.invincible_timer = 30  -- 1.5 seconds of invincibility (reduced from 3 seconds)
  sfx(7, 2)
  create_hit_feedback(player.x + 4, player.y + 4)  -- Use hit feedback for player damage

  score_multiplier = 1
  
  if player.health <= 0 then
    create_explosion_chain(player.x + 4, player.y + 4, 5, 16)
    game_over = true
  end
end

-- draw game
function draw_game()
  local shake_x, shake_y = 0, 0
  if shake_amount > 0 then
    shake_x = rnd(shake_amount/2) - shake_amount/4
    shake_y = rnd(shake_amount/2) - shake_amount/4
    camera(shake_x, shake_y)
    shake_amount -= 1
  else
    camera(0, 0)
  end

  cls()
  draw_starfield()
  draw_explosions()
  draw_bomb_effect()
  
  for p in all(powerups) do
    if p.type == "bomb" then
      spr(5, p.x, p.y)
    elseif p.type == "health" then
      spr(6, p.x, p.y)
    elseif p.type == "score" then
      -- Make the score powerup flash when timer is low
      if p.timer and p.timer < 15 and (time() * 10) % 2 < 1 then
        -- Draw with flashing white outline when close to expiring
        pal(8, 7)  -- Replace red with white for flashing effect
      end
      spr(7, p.x, p.y)
      
      pal() -- Reset palette after drawing
    end
  end
  
  draw_player()
  
  for bullet in all(bullets) do
    local sprite = 2
    if bullet.anim_frame == 1 then
      sprite = 18
    elseif bullet.anim_frame == 2 then
      sprite = 34
    elseif bullet.anim_frame == 3 then
      sprite = 50
    elseif bullet.anim_frame == 4 then
      sprite = 34
    end
    spr(sprite, bullet.x, bullet.y)
  end
  
  for enemy in all(enemies) do
    if enemy.is_big_sprite then
      pal() -- Reset palette
      
      if enemy.type == "final_boss" then
        pal(8, 12)
        pal(9, 13)
        pal(10, 14)
        pal(7, 7)
        
        if enemy.phase and enemy.phase >= 3 then
          pal(12, 8)
          pal(13, 9)
          pal(14, 10)
        end
      elseif enemy.type == "true_last_boss" and enemy.rage_mode then
        local pulse = sin(time() * 8) * 3
        local base_color = 8 + flr(abs(pulse))
        
        pal(8, base_color)
        pal(9, base_color + 1)
        pal(10, 7)
      elseif enemy.color_offset and enemy.color_offset > 0 then
        for c=0,15 do
          pal(c, (c + enemy.color_offset) % 16)
        end
      end
      
      if enemy.is_tlb then
        spr(enemy.sprite, enemy.x, enemy.y, 4, 4)  -- 32x32 boss uses 4x4 sprites
        
        if enemy.rage_mode then
          local aura_size = 4 + sin(time() * 4) * 3
          fillp(░)
          circfill(enemy.x + 16, enemy.y + 16, 20 + aura_size, 8)  -- Center on 32x32 boss with aura
          fillp()
        end
      else
        spr(enemy.sprite, enemy.x, enemy.y, 2, 2)
      end
      
      pal() -- Reset palette after drawing
    else
      spr(enemy.sprite, enemy.x, enemy.y)
    end
  end
  
  for bullet in all(enemy_bullets) do
    spr(4, bullet.x, bullet.y)
  end
  
  local hiscore = 0
  for entry in all(high_scores) do
    if entry.score > hiscore then
      hiscore = entry.score
    end
  end
  
  local hiscore_text = "" .. hiscore
  while #hiscore_text < 5 do
    hiscore_text = "0" .. hiscore_text
  end
  
  print("hi:", 70, 1, 7)
  print(hiscore_text, 82, 1, 7)
  
  local score_text = "" .. score
  while #score_text < 5 do
    score_text = "0" .. score_text
  end
  print("score:", 1, 1, 7)
  print(score_text, 28, 1, 7)
  
  print("health: " .. player.health, 1, 8, 7)
  print("bombs: " .. player.bombs, 1, 16, 7)
  print("level: " .. current_level, 1, 24, 7)
  print("multiplier: x" .. score_multiplier, 1, 32, 7)
  
  if game_over then
    if game_over_grace <= 0 then
      local y_offset = sin(time()) * 2
      center_text("game over", 64 + y_offset, 8)
      center_text("press z to continue", 72, 7)
      center_text("press x for menu", 80, 7)
    end
  end
  
  if game_state == "game_complete" then
    draw_game_complete()
  end
end

function draw_game_complete()
  -- Clear unnecessary objects when entering game completion
  if game_state == "game_complete" and #explosions > 0 then
    -- Clear game objects
    explosions = {}
    enemy_bullets = {}
    bullets = {}
    enemies = {}
    powerups = {}
  end
  
  -- Draw the background and starfield
  cls()
  draw_starfield()
  
  -- Only draw the completion screen if we're not warping
  if warp_time == 0 then
    rectfill(24,28,104,92,1)
    rect(24,28,104,92,7)
    
    center_text("victory!",35,10)
    center_text("pilot: "..last_entered_initials[1]..last_entered_initials[2]..last_entered_initials[3],45,9)
    center_text("score: "..score,55,7)
    center_text("bonus: "..(player.bombs*S_BMB+player.health*S_HP),65,8)
    center_text("final: "..(score+player.bombs*S_BMB+player.health*S_HP),75,7)
    
    if game_complete_grace > 0 then
      center_text("calculating...",85,7)
    else
      -- Use pulsing effect to draw attention to the instruction
      local pulse = sin(time() * 3) * 3
      local color = 7 + flr(abs(pulse))
      center_text("press z for menu",85,color)
    end
  end
end

function activate_bomb()
  if player.bombs > 0 and not bomb_active then
    bomb_active = true
    bomb_timer = BMB_DUR
    player.bombs -= 1
    
    for i=1,3 do
      add(explosions, {
        x = player.x + player.width/2,
        y = player.y + player.height/2,
        radius = 2 * i,
        max_radius = 30 + i * 10,
        life = 20,
        color = 7 + i
      })
    end
    
    for bullet in all(enemy_bullets) do
      release_enemy_bullet(bullet)
    end
    enemy_bullets = {}
    
    for bullet in all(bullets) do
      release_bullet(bullet, bullet_pool)
    end
    bullets = {}
    
    for enemy in all(enemies) do
      if enemy.type and enemy.health then
        enemy.health -= BMB_DMG
        if enemy.health <= 0 then
          create_explosion_chain(enemy.x + enemy.width/2, enemy.y + enemy.height/2, 8, enemy.width)
          del(enemies, enemy)
          
          if enemy.type == "mini_boss" then
            -- Only transition if all mini-bosses are gone
            if boss_exists("mini_boss") == 0 then
              convert_enemy_bullets_to_explosions()
              phase = "normal"  -- Immediately return to normal phase
              phase_state = "post_mini_boss"  -- Mark that we're in the post-mini-boss phase
              enemy_kill_count = 0  -- Reset kill count for next threshold
              update_music("game")  -- Return to game music after boss
            end
            add_score(S_MB)
          elseif enemy.type == "final_boss" then
            add_score(S_FB)
            
            -- Only initiate level completion if all final bosses are gone
            if boss_exists("final_boss") == 0 then
              phase = "level_complete"
              boss_defeat_grace = 90  -- Increased from 45 to 90 frames for better effect visibility
              -- Trigger the final boss defeat explosion at the boss's position
              create_final_boss_defeat_explosion(enemy.x + enemy.width/2, enemy.y + enemy.height/2)
            end
          elseif enemy.type == "true_last_boss" then
            handle_tlb_defeat(enemy)
          end
        end
      else
        add_score(S_NRM)
        enemy_kill_count += 1
        create_explosion_chain(enemy.x + enemy.width/2, enemy.y + enemy.height/2, 3, 10)
        del(enemies, enemy)
      end
    end
    
    trigger_bomb_effect()
  end
end

function trigger_bomb_effect()
  bomb_effect_timer = 30
  shake_amount = 20
  sfx(26, 3)
end

function update_bomb_effect()
  if bomb_effect_timer > 0 then
    if bomb_effect_timer == 15 then
      sfx(5, 2)
    end
    
    if bomb_effect_timer % 10 == 0 then
      shake_amount = 5
    end
    
    bomb_effect_timer -= 1
  end
end

function draw_bomb_effect()
  if bomb_effect_timer > 0 then
    if bomb_effect_timer > 20 then
      rectfill(0, 0, 127, 127, 7)
    end
    
    local rad = 64 - bomb_effect_timer * 2
    circ(64, 64, rad, 7)
    
    local pulse = 5 + (bomb_effect_timer % 5)
    circfill(64, 64, pulse, 7)
  end
end

function create_explosion(x, y, size)
  add(explosions, {
    x = x,
    y = y,
    radius = 1,
    max_radius = size == 1 and 8 or 16,
    life = size == 1 and 10 or 15,
    color = size == 1 and 8 or 7
  })
  
  shake_amount = size == 1 and 3 or 12
  
  if size == 1 then
    sfx(6, 3)
  else
    sfx(7, 2)
  end
end

function update_explosions()
  for explosion in all(explosions) do
    explosion.radius += 0.8
    explosion.life -= 1
    
    if explosion.life <= 0 or explosion.radius >= explosion.max_radius then
      del(explosions, explosion)
    end
  end
end

function draw_explosions()
  for explosion in all(explosions) do
    circfill(explosion.x, explosion.y, explosion.radius, explosion.color)
    circfill(explosion.x, explosion.y, explosion.radius * 0.7, 10)
    circfill(explosion.x, explosion.y, explosion.radius * 0.4, 9)
    
    if explosion.radius < explosion.max_radius - 2 then
      for i=1,5 do
        local angle = rnd(1)
        local dist = rnd(explosion.radius)
        local px = explosion.x + cos(angle) * dist
        local py = explosion.y + sin(angle) * dist
        
        if rnd(1) < 0.4 then
          rectfill(px, py, px+1, py+1, 7)
        else
          pset(px, py, 7)
        end
      end
    end
  end
end

function create_explosion_chain(x, y, count, spread, is_tlb)
  create_explosion(x, y, 2)
  
  if is_tlb then
    for i=0,5 do
      local a = i/6
      create_explosion(x + cos(a) * 16, y + sin(a) * 16, 2)
    end
    count = 8
    spread = 24
    shake_amount = 20
    sfx(7, 0)
    sfx(7, 2)
  end
  
  for i=1,count do
    local offset_x = rnd(spread) - spread/2
    local offset_y = rnd(spread) - spread/2
    create_explosion(x + offset_x, y + offset_y, is_tlb and 1 or 1)
  end
  
  if not is_tlb then
    shake_amount = max(shake_amount, count + 5)
  end
end

function create_final_boss_defeat_explosion(x, y)
  create_explosion(x, y, 2)
  
  for i=0,7 do
    local a = i/8
    create_explosion(x + cos(a) * 12, y + sin(a) * 12, 2)
  end
  
  for i=1,12 do
    local offset_x = rnd(32) - 16
    local offset_y = rnd(32) - 16
    create_explosion(x + offset_x, y + offset_y, 1)
  end
  
  shake_amount = 15
  
  convert_enemy_bullets_to_explosions()
  
  sfx(7, 1)
  sfx(7, 2)
  
  sfx(5, 3)
end

function create_tlb_explosion(x, y)
  create_explosion_chain(x, y, 0, 0, true)
end

function create_hit_feedback(x, y)
  add(explosions,{x=x,y=y,radius=1,max_radius=4,life=5,color=10})
  shake_amount=1
  sfx(6,3)
end

function convert_enemy_bullets_to_explosions()
  for bullet in all(enemy_bullets) do
    -- Create a small explosion at bullet position
    local x = bullet.x + 4  -- Center of bullet
    local y = bullet.y + 4
    add(explosions, {
      x = x,
      y = y,
      radius = 1,
      max_radius = 4,
      life = 6,
      color = 9
    })
    
    -- Remove the bullet
    del(enemy_bullets, bullet)
    release_enemy_bullet(bullet)
  end
  
  -- Clear the enemy bullets table
  enemy_bullets = {}
end

function handle_tlb_defeat(enemy)
  create_tlb_explosion(enemy.x + enemy.width/2, enemy.y + enemy.height/2)
  convert_enemy_bullets_to_explosions()
  add_score(S_TLB)
  
  enemy.health = 0
  enemy.paused = true
  
  phase = "victory_lap"
  game_complete_grace = 120
  
  final_score = score + player.bombs*S_BMB + player.health*S_HP
  
  local initials = last_entered_initials[1] .. last_entered_initials[2] .. last_entered_initials[3]
  update_high_scores(final_score, initials)
  
  -- Store initials in cartdata for BBS compatibility
  save_transition_data()
  
  -- Don't immediately set game_state to "game_complete"
  -- Let the victory_lap phase handle the transition after grace period
end

function update_warp()
  if warp_time > 0 then
    if warp_time == warp_duration then
      explosions = {}
      sfx(19, 3)
    end
    
    if warp_time == flr(warp_duration * 0.5) then
      sfx(19, 3)
    end
    
    warp_time -= 1
    
    for bullet in all(enemy_bullets) do
      release_enemy_bullet(bullet)
    end
    enemy_bullets = {}
    
    for bullet in all(bullets) do
      release_bullet(bullet, bullet_pool)
    end
    bullets = {}
    
    player.x = 60
    player.y = 100
    
    if warp_time <= warp_duration * 0.3 then
      if arriving_from_menu then
        arriving_from_menu = false
        phase = "normal"
        phase_state = "pre_mini_boss"
        update_music("game")
      end
    end
    
    if warp_time == 0 then
      init_starfield()
      enemy_kill_count = 0
      score_streak = 0
      score_multiplier = 1
      warp_started = false
      
      if current_level > max_level then
        spawn_true_last_boss()
        phase = "true_last_boss"
        update_music("boss")
      elseif not arriving_from_menu and phase == "warping" then
        phase = "normal"
        phase_state = "pre_mini_boss"
        update_spawn_delay()
      end
    end
    
    return true
  end
  warp_started = false
  return false
end

function mini_threshold()
  return 8 + (current_level - 1) * 4
end

function final_threshold()
  return 12 + (current_level - 1) * 3
end

function init_high_scores()
  high_scores = {}
  
  if stat(6) == 0 then
    init_save_system()
  end
  
  -- Load existing scores using new format
  for i=1,10 do
    local base_slot = 100 + (i-1) * 6
    local mega_part = dget(base_slot) or 0
    local kilo_part = dget(base_slot + 1) or 0
    local unit_part = dget(base_slot + 2) or 0
    local score = mega_part * 1000000 + kilo_part * 1000 + unit_part
    
    local c1 = dget(base_slot + 3) or 65  -- Default to "A"
    local c2 = dget(base_slot + 4) or 67  -- Default to "C"
    local c3 = dget(base_slot + 5) or 69  -- Default to "E"
    
    if score > 0 then
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

function update_high_scores(score, initials)
  if score <= 0 then return end
  
  -- Ensure initials are valid
  if not initials or #initials < 3 then
    initials = last_entered_initials[1]..last_entered_initials[2]..last_entered_initials[3]
  end
  initials = sub(initials, 1, 3)
  
  -- Find insertion position
  local insert_pos = 11  -- Default position (beyond the end)
  for i=1,10 do
    if score > high_scores[i].score then
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
    high_scores[insert_pos] = {score=score, initials=initials}
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

-- BBS-compatible transition data functions
function save_transition_data()
  if stat(6) == 0 then  -- Only save if cartdata is available
    dset(50, score or 0)
    dset(51, current_level or 1)
    dset(52, credits_used or 0)
    dset(53, ord(last_entered_initials[1]) or 65)  -- Default 'A'
    dset(54, ord(last_entered_initials[2]) or 67)  -- Default 'C'
    dset(55, ord(last_entered_initials[3]) or 69)  -- Default 'E'
    dset(56, final_score or 0)
  end
end

function load_transition_data()
  if stat(6) == 0 then
    score = dget(50) or 0
    current_level = dget(51) or 1
    credits_used = dget(52) or 0
    last_entered_initials[1] = chr(dget(53) or 65)  -- Default 'A'
    last_entered_initials[2] = chr(dget(54) or 67)  -- Default 'C'
    last_entered_initials[3] = chr(dget(55) or 69)  -- Default 'E'
    final_score = dget(56) or 0
  end
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