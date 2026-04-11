pico-8 cartridge // http://www.pico-8.com
version 42
__lua__

-- murdercrab! combined cart
-- merged menu + game with optimizations

----------------------------------------
-- global state & constants
----------------------------------------
game_state = "title"
phase = "normal"
phase_state = "pre_mini_boss"
current_level = 1
max_level = 5
game_loop = 1
credits = 3
credits_used = 0
score = 0
score_hi = 0
final_score = nil
score_streak = 0
score_multiplier = 1
enemy_kill_count = 0
current_music = -1
title_timer = 0
shoot_cd = 0
warp_time = 0
warp_duration = 360
shake_amount = 0
game_over = false
game_over_timer = 600
game_over_grace = 60
game_complete_grace = 90
boss_defeat_grace = 0
boss_warning = 0
bomb_active = false
bomb_timer = 0
bomb_effect_timer = 0
spawn_timer = 0
spawn_delay = 120
last_entered_initials = {"A", "C", "E"}
current_initials = nil
current_index = 1
high_scores = {}
rank = 0
hitstop = 0

-- player constants
P_SPD, P_HP, P_BMBS = 1, 100, 3
B_SPD = 3
BMB_DUR, BMB_DMG = 60, 30

-- enemy constants
E_SPD, E_SPD_SCL, E_SPD_MAX = 1, 0.2, 1.75
E_SHT_BASE, E_SHT_SCL, E_SHT_MIN = 120, 8, 80
E_B_SPD, E_B_SPREAD = 2.25, 10
E_BURST_SPD, E_BURST_DLY = 2.5, 6



-- boss constants
MB_HP, MB_HP_SCL = 60, 5
FB_HP, FB_HP_SCL = 100, 5
B_ROT_SPD, B_PAT_CHG, B_SPRL_STP = 20, 20, 45
BASE_CLUSTERS = 6

-- scoring
S_NRM = 10
S_STRK = 10
S_BMB, S_HP = 25, 25

-- object tables
starfield,enemies,bullets,enemy_bullets,explosions,powerups,bullet_pool,enemy_bullet_pool,player = {},{},{},{},{},{},{},{},{}


----------------------------------------
-- utility functions
----------------------------------------
function center_text(text, y, color)
  print(text, (128 - #text * 4) / 2, y, color)
end

function shadow_text(text, y, color)
  center_text(text, y + 1, 1)
  center_text(text, y, color)
end

function draw_logo(y)
  local pulse = sin(time() * 0.8)
  local color = pulse > 0.7 and 1 or 8
  local bounce = pulse * 3
  shadow_text("m u r d e r c r a b", y, color)
  print("!", 103, y + 1 - bounce, 1)
  print("!", 102, y - bounce, color)
  return color
end

function collides(a, b)
  return not (a.x + a.width < b.x or b.x + b.width < a.x or
              a.y + a.height < b.y or b.y + b.height < a.y)
end

----------------------------------------
-- save system
----------------------------------------
function init_save_system()
  cartdata("murdercrab_v2")
end

function ensure_cartdata()
  if stat(6) == 0 then init_save_system() end
end

-- score helpers (component-based: {m=millions, k=thousands, u=units})
function score_to_comp(n)
  return {m=flr(n/1000000), k=flr((n%1000000)/1000), u=n%1000}
end

function score_gt(a, b)
  -- compare: returns true if a > b
  if type(a)=="number" then a=score_to_comp(a) end
  if type(b)=="number" then b=score_to_comp(b) end
  if a.m!=b.m then return a.m>b.m end
  if a.k!=b.k then return a.k>b.k end
  return a.u>b.u
end

function score_fmt(s)
  if type(s)=="number" then s=score_to_comp(s) end
  if s.m>0 then return s.m..","..sub("000"..s.k,-3)..","..sub("000"..s.u,-3)
  elseif s.k>0 then return s.k..","..sub("000"..s.u,-3) end
  return ""..s.u
end

function init_high_scores()
  high_scores = {}
  ensure_cartdata()
  
  -- load saved initials (slots 18-20)
  local c1, c2, c3 = dget(18), dget(19), dget(20)
  if c1 >= 32 and c1 <= 126 then last_entered_initials[1] = chr(c1) end
  if c2 >= 32 and c2 <= 126 then last_entered_initials[2] = chr(c2) end
  if c3 >= 32 and c3 <= 126 then last_entered_initials[3] = chr(c3) end
  
  -- load high scores (slots 0-17, 6 per entry, 3 entries)
  for i = 1, 3 do
    local base = (i - 1) * 6
    local m, k, u = dget(base), dget(base+1), dget(base+2)
    local c1, c2, c3 = dget(base+3), dget(base+4), dget(base+5)
    
    if m > 0 or k > 0 or u > 0 then
      local i1 = (c1 >= 32 and c1 <= 126) and chr(c1) or "A"
      local i2 = (c2 >= 32 and c2 <= 126) and chr(c2) or "C"
      local i3 = (c3 >= 32 and c3 <= 126) and chr(c3) or "E"
      high_scores[i] = {score={m=m,k=k,u=u}, initials=i1..i2..i3}
    else
      high_scores[i] = {score={m=0,k=0,u=0}, initials="---"}
    end
  end
end

function save_high_scores()
  ensure_cartdata()
  
  for i = 1, 3 do
    local e = high_scores[i]
    local s = e.score
    local base = (i - 1) * 6
    
    dset(base, s.m)
    dset(base+1, s.k)
    dset(base+2, s.u)
    dset(base+3, ord(sub(e.initials,1,1)) or 65)
    dset(base+4, ord(sub(e.initials,2,2)) or 67)
    dset(base+5, ord(sub(e.initials,3,3)) or 69)
  end
end

function update_high_scores(new_score, initials)
  local ns = type(new_score) == "number" and score_to_comp(new_score) or new_score
  if ns.m == 0 and ns.k == 0 and ns.u == 0 then return end
  if not initials or #initials < 3 then initials = get_initials() end
  initials = sub(initials, 1, 3)
  
  local pos = 4
  for i = 1, 3 do
    if score_gt(ns, high_scores[i].score) then
      pos = i
      break
    end
  end
  
  if pos <= 3 then
    for i = 3, pos + 1, -1 do
      high_scores[i] = high_scores[i - 1]
    end
    high_scores[pos] = {score={m=ns.m,k=ns.k,u=ns.u}, initials=initials}
    save_high_scores()
  end
end

function add_score(points)
  score += points * score_multiplier
  score_hi += flr(score / 1000)
  score %= 1000
end

function calc_bonus()
  return player.bombs * S_BMB + player.health * S_HP
end

function sc(b)
  b = score + (b or 0)
  return {m=0, k=score_hi + flr(b / 1000), u=b % 1000}
end

function get_initials()
  return last_entered_initials[1] .. last_entered_initials[2] .. last_entered_initials[3]
end

----------------------------------------
-- music system
----------------------------------------
function update_music(screen)
  local new_music = 0
  
  if screen == "game" then
    new_music = 6
  elseif screen == "boss" then
    new_music = 10
  elseif screen == "silent" then
    music(-1, 0)
    current_music = -1
    return
  elseif screen == "fade" then
    music(-1, 1500)
    current_music = -1
    return
  end
  
  if new_music != current_music then
    music(-1, 300)
    music(new_music)
    current_music = new_music
  end
end

----------------------------------------
-- starfield system
----------------------------------------
function init_starfield()
  starfield = {}
  local count = min(150, 80 + current_level * 10)
  local colors = {7}
  local large_chance = 0.2
  
  if current_level == 2 then
    colors = {7, 12, 13}
    large_chance = 0.25
  elseif current_level == 3 then
    colors = {7, 11, 3}
    large_chance = 0.3
  elseif current_level == 4 then
    colors = {7, 13, 14, 2}
    large_chance = 0.35
  elseif current_level == 5 then
    colors = {7, 6, 13, 12}
    large_chance = 0.4
  elseif current_level >= 6 then
    colors = {7, 6, 13, 14, 11, 12, 1, 2}
    large_chance = 0.5
  end
  
  for i = 1, count do
    add(starfield, {
      x = rnd(128), y = rnd(128),
      speed = 0.25 + rnd(0.5),
      col = colors[flr(rnd(#colors)) + 1],
      size = rnd(1) < large_chance and 2 or 1
    })
  end
end

function update_starfield()
  local spd_mult = game_state == "game" and (2 + current_level * 2) or 1
  
  for star in all(starfield) do
    local star_speed = star.speed * spd_mult
    if star.size > 1 then star_speed *= 1.2 end
    star.y += star_speed
    
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
    rectfill(0, 0, 127, 127, 1 + flr(ratio * 7))
    
    for star in all(starfield) do
      local streak = ratio * 20 * star.speed
      line(star.x, star.y, star.x, star.y - streak, 7 + (star.y % 8))
    end
    
    if warp_time > warp_duration * 0.3 and warp_time < warp_duration * 0.7 then
      center_text("level " .. current_level, 60, 7)
    end
    
    if warp_time < warp_duration * 0.2 then
      fillp(▒)
      rectfill(0, 0, 127, 127, 7)
      fillp()
    end
  else
    -- background colors per level
    local bg_colors = {0, 1, 3, 2, 4}
    local cl = min(current_level, max_level)
    local bg = bg_colors[cl] or 0
    if bg > 0 then rectfill(0, 0, 127, 127, bg) end

    for star in all(starfield) do
      local twinkle = 0
      if cl >= 2 then
        local chance = cl * 2
        if rnd(100) < chance then
          twinkle = sin(time() * (4 + cl * 2) + star.x / (14 - cl * 2)) > (0.8 - cl * 0.2) and 1 or 0
        end
      end
      
      if star.size == 1 then
        pset(star.x, star.y, star.col + twinkle)
      else
        rectfill(star.x, star.y, star.x + 1, star.y + 1, star.col + twinkle)
      end
    end
  end
  fillp()
end

----------------------------------------
-- attract / title screen
----------------------------------------
function update_title()
  title_timer += 1
  credits = 3
  if btnp(0) or btnp(1) or btnp(2) or btnp(3) or btnp(4) or btnp(5) then
    start_game()
  end
end

function draw_title()
  cls()
  draw_starfield()
  local ph = flr(title_timer / 360) % 3
  if ph == 0 then
    local logo_color = draw_logo(15)
    local bob = sin(time() * 0.4) * 4
    fillp(░)
    circfill(64, 56, 26 + sin(time() * 0.6) * 2, 1)
    fillp()
    spr(10, 48, 40 + bob, 4, 4)
    if title_timer % 30 < 20 then shadow_text("- press any button -", 100, logo_color) end
    spr(1, 60, 115)
  elseif ph == 1 then
    shadow_text("high scores", 10, 8)
    local y = 30
    for i = 1, 3 do
      local e = high_scores[i]
      shadow_text(i .. ". " .. e.initials .. " " .. score_fmt(e.score), y, 8)
      y += 14
    end
  else
    shadow_text("instructions", 10, 8)
    shadow_text("movement: arrow keys", 24, 8)
    shadow_text("shoot: z (hold=rapid)", 34, 8)
    shadow_text("bomb: x button", 44, 8)
    shadow_text("collect powerups", 58, 8)
    local hx = 64 - (#"extra health" * 4) / 2
    shadow_text("extra health", 70, 8) spr(6, hx - 12, 68)
    shadow_text("extra bomb", 80, 8) spr(5, hx - 12, 78)
    shadow_text("increase score", 90, 8) spr(7, hx - 12, 88)
    shadow_text("10 cherries = +1x", 100, 8)
  end
end

----------------------------------------
-- enter initials screen
----------------------------------------
function update_enter_initials()
  if current_initials == nil then
    current_initials = {}
    local def = get_initials()
    for i = 1, 3 do current_initials[i] = sub(def, i, i) end
    current_index = 1
  end
  if btnp(2) then
    local cur = ord(current_initials[current_index])
    cur = ((cur - 33 + 1 + 94) % 94) + 33
    current_initials[current_index] = chr(cur)
  end
  if btnp(3) then
    local cur = ord(current_initials[current_index])
    cur = ((cur - 33 - 1 + 94) % 94) + 33
    current_initials[current_index] = chr(cur)
  end
  if btnp(0) then current_index = ((current_index - 2) % 3) + 1 end
  if btnp(1) then current_index = (current_index % 3) + 1 end
  if btnp(4) or btnp(5) then
    local str = current_initials[1] .. current_initials[2] .. current_initials[3]
    last_entered_initials = {current_initials[1], current_initials[2], current_initials[3]}
    ensure_cartdata()
    dset(18, ord(current_initials[1]) or 65)
    dset(19, ord(current_initials[2]) or 67)
    dset(20, ord(current_initials[3]) or 69)
    if final_score then update_high_scores(final_score, str) final_score = nil end
    current_initials = nil
    game_state = "title"
    title_timer = 0
  end
end

function draw_enter_initials()
  cls()
  draw_starfield()
  shadow_text("enter initials:", 30, 8)
  if current_initials then
    local x = 56
    for i = 1, 3 do
      print(current_initials[i], x + (i - 1) * 8, 60, i == current_index and 8 or 1)
    end
    if (time() * 10) % 2 < 1 then line(56 + (current_index - 1) * 8, 68, 60 + (current_index - 1) * 8, 68, 8) end
  end
  shadow_text("up/down: letter  left/right: position", 80, 8)
  shadow_text("z/x: confirm", 90, 8)
end

----------------------------------------
-- game initialization
----------------------------------------
function start_game()
  if credits > 0 then
    credits -= 1
    warp_time = warp_duration
    sfx(19, 3)
    update_music("silent")
    game_state = "starting"
  end
end

function init_game()
  game_loop = 1
  phase = "normal"
  phase_state = "pre_mini_boss"
  current_level = 1
  enemy_kill_count = 0
  score = 0
  score_hi = 0
  score_streak = 0
  score_multiplier = 1
  final_score = nil
  game_over = false
  game_over_timer = 600
  game_over_grace = 60
  game_complete_grace = 90
  boss_defeat_grace = 0
  boss_warning = 0
  shake_amount = 0
  warp_time = 0
  bomb_active = false
  bomb_timer = 0
  bomb_effect_timer = 0
  spawn_timer = 0
  shoot_cd = 0
  hitstop = 0
  update_spawn_delay()
  
  player = {
    x = 60, y = 100,
    width = 8, height = 8,
    speed = P_SPD,
    health = P_HP, max_health = P_HP,
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
  
  init_starfield()
end

function update_spawn_delay()
  local loop_reduction = (game_loop - 1) * 5
  spawn_delay = max(60 - loop_reduction * 2, 110 - (current_level - 1) * 12 - loop_reduction * 2)
end

----------------------------------------
-- bullet pool system
----------------------------------------
function get_bullet()
  if #bullet_pool > 0 then return deli(bullet_pool, 1) end
  return {}
end

function release_bullet(b)
  add(bullet_pool, b)
end

function get_enemy_bullet()
  return #enemy_bullet_pool > 0 and deli(enemy_bullet_pool, 1) or {}
end

function release_enemy_bullet(b)
  add(enemy_bullet_pool, b)
end

----------------------------------------
-- player functions
----------------------------------------
function draw_player()
  if player.invincible_timer > 0 and time() % 0.2 < 0.1 then return end

  spr(player.sprite, player.x, player.y)

  if player.thrust_frame > 0 then
    local x, y = player.x + 4, player.y + 8
    local h = btn(0) and 1 or (btn(1) and -1 or 0)
    local f = flr(rnd(2))
    pset(x + h, y + 1 + f, 8 + f)
    pset(x + h + (f - 1), y + 2, 9)
    if rnd(1) < 0.7 then pset(x + h, y + 2 + f, 8) end
  end
end

function player_shoot()
  local cx = player.x + player.width / 2
  
  for i = 0, 1 do
    local b = get_bullet()
    b.x = cx + (i == 0 and -10 or 2)
    b.y = player.y
    b.width = 8
    b.height = 8
    b.anim_frame = 0
    add(bullets, b)
  end
  sfx(25, 3)
end

function player_hit()
  if player.invincible_timer > 0 or game_over then return end
  
  player.health -= 1
  player.invincible_timer = 60
  sfx(7, 2)
  create_hit_feedback(player.x + 4, player.y + 4)
  score_multiplier = 1
  score_streak = 0

  if player.health <= 0 then
    create_explosion_chain(player.x + 4, player.y + 4, 5, 16)
    game_over = true
  end
end

----------------------------------------
-- bullet functions
----------------------------------------
function update_bullets()
  local anim_next = {1, 2, 3, 4, 3}
  for i = #bullets, 1, -1 do
    local b = bullets[i]
    b.y -= B_SPD
    b.anim_frame = anim_next[b.anim_frame + 1] or 1
    
    if b.y < -8 then
      deli(bullets, i)
      release_bullet(b)
    end
  end
end

function update_enemy_bullets()
  for i = #enemy_bullets, 1, -1 do
    local b = enemy_bullets[i]
    b.x += b.dx
    b.y += b.dy
    
    if b.y > 128 or b.y < -8 or b.x > 128 or b.x < -8 then
      deli(enemy_bullets, i)
      release_enemy_bullet(b)
    end
  end
end

function spawn_enemy_bullet(cx, cy, dx, dy)
  local r = 1 + rank * 0.04
  local b = get_enemy_bullet()
  b.x, b.y = cx - 4, cy - 4
  b.dx, b.dy = dx * r, dy * r
  b.width, b.height = 8, 8
  add(enemy_bullets, b)
end

----------------------------------------
-- enemy functions
----------------------------------------
function spawn_enemy()
  local count = current_level >= 4 and 2 or 1
  for i = 1, count do spawn_normal_enemy() end
end

function spawn_normal_enemy()
  local loop_bonus = (game_loop - 1) * 2
  local interval = max(E_SHT_MIN - loop_bonus * 2, E_SHT_BASE - (current_level - 1) * E_SHT_SCL - loop_bonus * 3)
  local e = {
    x = flr(rnd(120)), y = -8,
    speed = min(E_SPD_MAX + game_loop * 0.25, E_SPD + (current_level - 1) * E_SPD_SCL + game_loop * 0.15),
    sprite = 3, width = 8, height = 8,
    shoot_timer = interval - 40 - flr(rnd(30)),
    shoot_interval = interval,
    weapon = rnd(1) < 0.5 and "shotgun" or "burst",
    burst_count = 0,
    type = "normal", health = min(3, current_level + game_loop - 1),
    dx = 0, dy = 0, state = 0,
    hover_y = 20 + rnd(15),
    dir = rnd(1) < 0.5 and -1 or 1,
    timer = 90, paused = false,
    anim_frame = 0, anim_timer = 0, anim_speed = 10
  }
  e.dy = e.speed
  add(enemies, e)
end

function normal_enemy_fire(enemy)
  -- calculate aim direction
  local x = enemy.x + enemy.width / 2
  local y = enemy.y + enemy.height / 2
  local tx = player.x + player.width / 2
  local ty = player.y + player.height / 2
  local vx, vy = tx - x, ty - y
  local d = sqrt(vx * vx + vy * vy)
  if d == 0 then d = 1 end
  local ndx, ndy = vx / d, vy / d
  
  -- burst weapon: rapid 3-shot aimed burst
  if enemy.burst_count > 0 then
    enemy.shoot_timer += 1
    if enemy.shoot_timer >= E_BURST_DLY then
      enemy.shoot_timer = 0
      spawn_enemy_bullet(x, y, E_BURST_SPD * ndx, E_BURST_SPD * ndy)
      sfx(6, 3)
      enemy.burst_count -= 1
    end
    return
  end
  
  enemy.shoot_timer += 1
  if enemy.shoot_timer >= enemy.shoot_interval then
    enemy.shoot_timer = 0
    
    if enemy.weapon == "shotgun" then
      -- shotgun: 3 bullets at once, spread
      for i = -1, 1 do
        local _o = i * E_B_SPREAD / 360
        local _c, _s = cos(_o), -sin(_o)
        local rx, ry = ndx * _c - ndy * _s, ndx * _s + ndy * _c
        spawn_enemy_bullet(x, y, E_B_SPD * rx, E_B_SPD * ry)
      end
      sfx(6, 3)
    else
      -- burst: start rapid 3-shot burst
      enemy.burst_count = 3
      enemy.shoot_timer = E_BURST_DLY
    end
  end
end

function update_normal_enemy(enemy)
  enemy.anim_timer += 1
  if enemy.anim_timer >= enemy.anim_speed then
    enemy.anim_timer = 0
    if enemy.state == 2 then
      enemy.sprite = 35
    else
      enemy.anim_frame = (enemy.anim_frame + 1) % 2
      enemy.sprite = enemy.anim_frame == 0 and 3 or 19
    end
  end
  
  if enemy.state == 0 then
    enemy.y += enemy.dy
    enemy.x += enemy.dir * 0.25

    if enemy.x < 0 then enemy.x = 0 enemy.dir = 1
    elseif enemy.x > 119 then enemy.x = 119 enemy.dir = -1 end
    
    if enemy.y >= enemy.hover_y then
      enemy.y = enemy.hover_y
      enemy.state = 1
    end
    
    normal_enemy_fire(enemy)
    
  elseif enemy.state == 1 then
    enemy.x += enemy.dir * 0.35
    if enemy.x < 0 or enemy.x > 119 then
      enemy.dir = -enemy.dir
      enemy.x = mid(0, enemy.x, 119)
    end
    
    enemy.timer -= 1
    if enemy.timer <= 0 then
      enemy.state = 2
      local ex, ey = enemy.x + 4, enemy.y + 4
      local px, py = player.x + 4, player.y + 4
      local dx, dy = px - ex, py - ey
      local d = sqrt(dx * dx + dy * dy)
      if d > 0 then dx /= d dy /= d end
      local spd = enemy.speed * 2
      enemy.dx = dx * spd
      enemy.dy = dy * spd
      enemy.sprite = 35
      enemy.anim_speed = 6
    end
    
    normal_enemy_fire(enemy)
  else
    enemy.x += enemy.dx
    enemy.y += enemy.dy
  end
  
  if enemy.y > 128 or enemy.x < -8 or enemy.x > 128 then
    del(enemies, enemy)
  end
end

function update_enemies()
  for i = #enemies, 1, -1 do
    local e = enemies[i]
    if not e.paused then
      if e.type == "normal" then
        update_normal_enemy(e)
      elseif e.type == "mini_boss" or e.type == "final_boss" or e.type == "true_last_boss" then
        update_boss_enemy(e)
      end
    end
  end
end

----------------------------------------
-- boss functions
----------------------------------------
function get_boss_max_health(t)
  local loop_mult = 1 + (game_loop - 1) * 0.5
  if t == "mini_boss" then return flr((MB_HP + (current_level - 1) * MB_HP_SCL) * loop_mult)
  elseif t == "final_boss" then return flr((FB_HP + (current_level - 1) * FB_HP_SCL) * loop_mult)
  else return flr(450 * loop_mult) end
end

function get_boss_count(t)
  if t == "mini_boss" or t == "final_boss" then
    return current_level >= 2 and 2 or 1
  end
  return 1
end

function boss_exists(t)
  local count = 0
  for e in all(enemies) do
    if e.type == t then count += 1 end
  end
  return count
end

function spawn_boss(btype)
  local is_final = btype == "final_boss"
  local count = get_boss_count(btype)
  local spacing = count > 1 and 32 or 0
  
  for i = 1, count do
    add(enemies, {
      x = 64 - 16 + spacing * (i - (count + 1) / 2), y = -32,
      dx = is_final and 0.15 or 0.25, dy = 0.5, speed = 1,
      width = 16, height = 16,
      health = get_boss_max_health(btype),
      type = btype,
      shoot_timer = 0, shoot_interval = is_final and 16 or 40,
      pattern = 1, rotate_counter = 0,
      cluster_count = BASE_CLUSTERS + current_level,
      sprite = 8, is_big_sprite = true,
      color_offset = is_final and 12 or 0, paused = false, phase = 1
    })
  end
end

function spawn_true_last_boss()
  add(enemies, {
    x = 48, y = -32,
    speed = 1.5, sprite = 10,
    width = 32, height = 32,
    shoot_timer = 0, shoot_interval = 12,
    health = get_boss_max_health("true_last_boss"),
    type = "true_last_boss",
    cluster_count = BASE_CLUSTERS + 4 + current_level,
    rotate_counter = 0,
    is_big_sprite = true, is_tlb = true,
    phase = 1, dx = 0.15, dy = 0, paused = false
  })
end

function update_boss_phase(enemy)
  if not enemy.type or not enemy.health then return end
  
  local old_phase = enemy.phase or 1
  local new_phase = 1
  local max_hp = get_boss_max_health(enemy.type)
  
  if enemy.type == "mini_boss" then
    new_phase = enemy.health <= max_hp * 0.5 and 2 or 1
  else
    new_phase = enemy.health <= max_hp / 3 and 3 or (enemy.health <= max_hp * 2 / 3 and 2 or 1)
  end
  
  if new_phase > old_phase then
    enemy.phase = new_phase
    shake_amount = 8 + new_phase * 2
    
    for i = 1, 2 + new_phase do
      create_explosion(enemy.x + rnd(enemy.width), enemy.y + rnd(enemy.height), 1)
    end
    
    sfx(7, 2)
    if enemy.type == "true_last_boss" and new_phase == 3 then enemy.rage_mode = true end
    enemy.shoot_interval = max(3, enemy.shoot_interval - 1)
  end
end

function update_boss_enemy(enemy)
  if enemy.y < 5 then
    enemy.y = min(5, enemy.y + 1)
    return
  end
  enemy.y = mid(5, enemy.y, 25)
  enemy.x += enemy.dx
  
  local c = 64 - enemy.width / 2
  local r = 30
  if enemy.x < c - r or enemy.x > c + r then
    enemy.dx = -enemy.dx
    enemy.x = mid(c - r, enemy.x, c + r)
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

function enemy_shoot_radial(e)
  local h = e.health / get_boss_max_health(e.type)
  local s = 0.75 + (current_level - 1) * 0.075 + (1 - h) * 0.15
  
  if e.burst_index and e.burst_index > 0 then
    create_aimed_pattern(e, 0, s)
    return
  end
  
  local ph = e.phase or 1
  local pattern_type
  
  if ph == 1 then
    pattern_type = flr(time() * B_PAT_CHG) % 2
  elseif ph == 2 then
    local t = flr(time() * B_PAT_CHG) % 5
    pattern_type = t < 2 and 2 or (t - 2)
  else
    pattern_type = flr(time() * B_PAT_CHG * 1.5) % 3
  end
  
  e.rotate_counter = (e.rotate_counter + B_ROT_SPD) % 360
  local health_boost = flr((1 - h) * 5)
  
  if pattern_type == 0 then
    e.burst_index = nil
    create_spiral_pattern(e, e.cluster_count + health_boost, s)
  elseif pattern_type == 1 then
    e.burst_index = nil
    create_radial_pattern(e, e.cluster_count + health_boost, s)
  else
    create_aimed_pattern(e, flr(e.cluster_count / 2) + health_boost, s)
  end
end

function create_spiral_pattern(enemy, count, speed)
  local cx, cy = enemy.x + enemy.width / 2, enemy.y + enemy.height / 2
  if enemy.type == "true_last_boss" and enemy.rage_mode then count += 10 end
  
  for i = 0, count - 1 do
    local a = enemy.rotate_counter + i * B_SPRL_STP
    local na = (a + sin(time() * 3 + i / 10) * 5 / 360) / 360 % 1
    spawn_enemy_bullet(cx, cy, speed * cos(na), -speed * sin(na))
  end
end

function create_radial_pattern(enemy, count, speed)
  local cx, cy = enemy.x + enemy.width / 2, enemy.y + enemy.height / 2
  if enemy.type == "true_last_boss" and enemy.rage_mode then count += 10 end
  
  for i = 0, count - 1 do
    local a = (i * (360 / count) + enemy.rotate_counter) / 360
    spawn_enemy_bullet(cx, cy, speed * cos(a), -speed * sin(a))
  end
end

function create_aimed_pattern(e, count, speed)
  if not e.burst_index then
    e.burst_index = 1
    e.burst_timer = 0
    e.burst_max = 3
    e.burst_delay = 16
  end
  
  if e.burst_timer <= 0 then
    local bx, by = e.x + e.width / 2, e.y + e.height / 2
    local px, py = player.x + 4, player.y + 4
    local dx, dy = px - bx, py - by
    local dist = sqrt(dx * dx + dy * dy)
    if dist > 0 then dx /= dist dy /= dist end
    
    spawn_enemy_bullet(bx, by, dx * speed, dy * speed)
    
    e.burst_index += 1
    if e.burst_index > e.burst_max then e.burst_index = 0 end
    e.burst_timer = e.burst_delay
  else
    e.burst_timer -= 1
  end
end

----------------------------------------
-- powerup functions
----------------------------------------
function spawn_powerup(x, y, ptype, value)
  local p = {
    x = x, y = y, type = ptype,
    value = value or 0.5,
    width = 8, height = 8,
    speed = 2, dx = 0, dy = 0
  }
  if ptype == "score" then p.timer = 90 end
  add(powerups, p)
  return p
end

function spawn_powerup_explosion(x, y)
  local total = flr(rnd(5)) + 4
  local angle_inc = 1 / total

  for i = 1, total do
    local angle = angle_inc * i
    local p = spawn_powerup(x, y, "score", 100)
    p.dx = cos(angle) * 1.5
    p.dy = sin(angle) * 1.5
  end
  
  if rnd(1) < 0.05 then
    local ptype = rnd(1) < 0.5 and "bomb" or "health"
    local p = spawn_powerup(x, y, ptype)
    p.dx = cos(rnd(1)) * 1
    p.dy = sin(rnd(1)) * 1
  end
end

function update_powerups()
  for p in all(powerups) do
    if p.type == "score" then
      p.timer -= 1
      if p.timer <= 0 then
        add(explosions, {x = p.x + 4, y = p.y + 4, radius = 1, max_radius = 6, life = 8, color = 9})
        sfx(6, 3)
        del(powerups, p)
      end
    end
    
    if p.dx != 0 or p.dy != 0 then
      p.x += p.dx
      p.y += p.dy
      p.dx *= 0.95
      p.dy *= 0.95
      if abs(p.dx) < 0.1 and abs(p.dy) < 0.1 then p.dx = 0 p.dy = 0 end
    end
    
    local dx = (player.x + 4) - (p.x + 4)
    local dy = (player.y + 4) - (p.y + 4)
    local dist = sqrt(dx * dx + dy * dy)
    
    if p.attracted or dist < 48 then
      local spd = p.attract_speed or 0.15
      p.x += dx * spd
      p.y += dy * spd
      p.dx = 0
      p.dy = 0
    elseif p.dx == 0 and p.dy == 0 then
      p.y += p.speed
    end
    
    if p.y > 128 or p.x < -8 or p.x > 136 then del(powerups, p) end
  end
end

function check_powerup_collection()
  for p in all(powerups) do
    if collides(p, player) then
      if p.type == "bomb" then
        player.bombs += 1
      elseif p.type == "health" then
        player.health += 1
      elseif p.type == "score" then
        add_score(p.value)
        score_streak += 1
        if score_streak >= S_STRK then
          score_multiplier += 1
          score_streak = 0
          shake_amount = 2
        end
      end
      sfx(3, 2)
      del(powerups, p)
    end
  end
end

----------------------------------------
-- explosion functions
----------------------------------------
function create_explosion(x, y, size)
  add(explosions, {
    x = x, y = y, radius = 1,
    max_radius = size == 1 and 8 or 16,
    life = size == 1 and 10 or 15,
    color = size == 1 and 8 or 7
  })
  shake_amount = size == 1 and 3 or 12
  sfx(size == 1 and 6 or 7, size == 1 and 3 or 2)
end

function create_explosion_chain(x, y, count, spread, is_tlb)
  create_explosion(x, y, 2)
  
  if is_tlb then
    for i = 0, 5 do
      create_explosion(x + cos(i / 6) * 16, y + sin(i / 6) * 16, 2)
    end
    count = 8
    spread = 24
    shake_amount = 20
    sfx(7, 0)
    sfx(7, 2)
  end
  
  for i = 1, count do
    create_explosion(x + rnd(spread) - spread / 2, y + rnd(spread) - spread / 2, 1)
  end
  
  if not is_tlb then shake_amount = max(shake_amount, count + 5) end
end

function create_hit_feedback(x, y)
  add(explosions, {x = x, y = y, radius = 1, max_radius = 6 + rnd(4), life = 6, color = 8 + flr(rnd(3))})
  for i = 1, 2 do
    add(explosions, {x = x + rnd(8) - 4, y = y + rnd(8) - 4, radius = 0.5, max_radius = 3, life = 4, color = 9 + flr(rnd(2))})
  end
  shake_amount = 2 + flr(rnd(2))
  sfx(6, 3)
end

function create_final_boss_defeat_explosion(x, y)
  create_explosion(x, y, 2)
  
  for i = 0, 7 do
    create_explosion(x + cos(i / 8) * 12, y + sin(i / 8) * 12, 2)
  end
  
  for i = 1, 12 do
    create_explosion(x + rnd(32) - 16, y + rnd(32) - 16, 1)
  end
  
  shake_amount = 15
  convert_enemy_bullets_to_explosions()
  sfx(7, 1)
  sfx(7, 2)
  sfx(5, 3)
end

function convert_enemy_bullets_to_explosions()
  for b in all(enemy_bullets) do
    add(explosions, {x = b.x + 4, y = b.y + 4, radius = 1, max_radius = 4, life = 6, color = 9})
    release_enemy_bullet(b)
  end
  enemy_bullets = {}
end

function update_explosions()
  for e in all(explosions) do
    e.radius += 0.4
    e.life -= 1
    if e.life <= 0 or e.radius >= e.max_radius then del(explosions, e) end
  end
end

function draw_explosions()
  for e in all(explosions) do
    if e.radius < 2 then circfill(e.x, e.y, e.radius + 2, 7) end
    circfill(e.x, e.y, e.radius, e.color)
    circfill(e.x, e.y, e.radius * 0.7, 10)
    circfill(e.x, e.y, e.radius * 0.4, 7)
    
    if e.radius < e.max_radius - 2 then
      for i = 1, 5 do
        local angle = rnd(1)
        local dist = rnd(e.radius)
        local px = e.x + cos(angle) * dist
        local py = e.y + sin(angle) * dist
        if rnd(1) < 0.4 then
          rectfill(px, py, px + 1, py + 1, 7)
        else
          pset(px, py, 7)
        end
      end
    end
  end
end

----------------------------------------
-- bomb functions
----------------------------------------
function activate_bomb()
  if player.bombs > 0 and not bomb_active then
    bomb_active = true
    bomb_timer = BMB_DUR
    player.bombs -= 1

    for i = 1, 3 do
      add(explosions, {
        x = player.x + 4, y = player.y + 4,
        radius = 2 * i, max_radius = 30 + i * 10,
        life = 20, color = 7 + i
      })
    end
    
    for b in all(enemy_bullets) do release_enemy_bullet(b) end
    enemy_bullets = {}
    
    for b in all(bullets) do release_bullet(b) end
    bullets = {}
    
    for enemy in all(enemies) do
      if enemy.type and enemy.health then
        enemy.health -= BMB_DMG
        if enemy.health <= 0 then
          create_explosion_chain(enemy.x + enemy.width / 2, enemy.y + enemy.height / 2, 8, enemy.width)
          del(enemies, enemy)
          handle_boss_defeat(enemy)
        end
      else
        add_score(S_NRM)
        enemy_kill_count += 1
        create_explosion_chain(enemy.x + 4, enemy.y + 4, 3, 10)
        del(enemies, enemy)
      end
    end
    
    bomb_effect_timer = 60
    shake_amount = 20
    sfx(26, 3)
  end
end

function update_bomb_effect()
  if bomb_effect_timer > 0 then
    if bomb_effect_timer == 30 then sfx(5, 2) end
    if bomb_effect_timer % 20 == 0 then shake_amount = 5 end
    bomb_effect_timer -= 1
  end
end

function draw_bomb_effect()
  if bomb_effect_timer > 0 then
    if bomb_effect_timer > 40 then rectfill(0, 0, 127, 127, 7) end
    circ(64, 64, 64 - bomb_effect_timer, 7)
    circfill(64, 64, 5 + bomb_effect_timer % 10, 7)
  end
end

----------------------------------------
-- boss defeat handling (consolidated)
----------------------------------------
function check_end_mini_boss()
  if boss_exists("mini_boss") == 0 then
    convert_enemy_bullets_to_explosions()
    phase = "normal"
    phase_state = "post_mini_boss"
    enemy_kill_count = 0
    update_music("game")
  end
end

function handle_boss_defeat(enemy)
  if enemy.type == "mini_boss" then
    check_end_mini_boss()
    add_score(50)
  elseif enemy.type == "final_boss" then
    add_score(100)
    if boss_exists("final_boss") == 0 then
      phase = "level_complete"
      boss_defeat_grace = 180
      create_final_boss_defeat_explosion(enemy.x + enemy.width / 2, enemy.y + enemy.height / 2)
    end
  elseif enemy.type == "true_last_boss" then
    create_explosion_chain(enemy.x + 16, enemy.y + 16, 0, 0, true)
    convert_enemy_bullets_to_explosions()
    add_score(50)
    enemy.health = 0
    enemy.paused = true
    phase = "victory_lap"
    game_complete_grace = 240
    final_score = sc(calc_bonus())
  end
end

----------------------------------------
-- collision checks
----------------------------------------
function check_enemy_bullet_collisions()
  if player.invincible_timer > 0 then return end
  
  local hitbox = {x = player.x + 3, y = player.y + 3, width = 2, height = 2}
  
  for b in all(enemy_bullets) do
    if collides(hitbox, b) then
      player_hit()
      del(enemy_bullets, b)
      release_enemy_bullet(b)
      break
    end
  end
end

function check_bullet_enemy_collisions()
  for bullet in all(bullets) do
    for enemy in all(enemies) do
      if collides(enemy, bullet) then
        if not enemy.type or enemy.type == "normal" then
          enemy.health -= 1
          del(bullets, bullet)
          release_bullet(bullet)
          if enemy.health <= 0 then
            add_score(S_NRM)
            enemy_kill_count += 1
            create_explosion_chain(enemy.x + 4, enemy.y + 4, 3, 10)
            shake_amount = 3
            hitstop = 2
            del(enemies, enemy)
            if rnd(1) < 0.9 then spawn_powerup_explosion(enemy.x, enemy.y) end
            if rank >= 2 and rnd(10) < rank then spawn_powerup(enemy.x, enemy.y, "score", 50) end
          else
            create_hit_feedback(bullet.x, bullet.y)
            enemy.y -= 1.5
          end
          break
        else
          enemy.health -= 1
          sfx(7, 2)
          shake_amount = 3
          hitstop = 1
          create_hit_feedback(mid(enemy.x, bullet.x + 4, enemy.x + enemy.width),
                              mid(enemy.y, bullet.y + 4, enemy.y + enemy.height))
          if rnd(1) < 0.4 then
            local p = spawn_powerup(bullet.x, bullet.y, "score", 50)
            p.dx = rnd(2) - 1
            p.dy = rnd(2) - 1
          end
          
          if enemy.health <= 0 then
            create_explosion(enemy.x, enemy.y, 2)
            for i = 1, 5 do
              create_explosion(enemy.x + rnd(enemy.width), enemy.y + rnd(enemy.height), 1)
            end
            shake_amount = 10
            del(enemies, enemy)
            handle_boss_defeat(enemy)
          end
          
          del(bullets, bullet)
          release_bullet(bullet)
          break
        end
      end
    end
  end
end

function check_player_enemy_collisions()
  if player.invincible_timer > 0 or game_over then return end
  
  local hitbox = {x = player.x + 3, y = player.y + 3, width = 2, height = 2}
  
  for enemy in all(enemies) do
    if enemy.state == 2 then
      if collides(player, enemy) then
        player_hit()
        create_explosion_chain(enemy.x + 4, enemy.y + 4, 3, 10)
        del(enemies, enemy)
        local dx, dy = player.x - enemy.x, player.y - enemy.y
        local d = max(1, sqrt(dx * dx + dy * dy))
        player.x += (dx / d) * 5
        player.y += (dy / d) * 5
      end
    elseif collides(hitbox, enemy) then
      player_hit()
      local dx, dy = player.x - enemy.x, player.y - enemy.y
      local d = max(1, sqrt(dx * dx + dy * dy))
      player.x += (dx / d) * 3
      player.y += (dy / d) * 3
    end
  end
end

----------------------------------------
-- threshold functions
----------------------------------------
function mini_threshold()
  return 8 + (current_level - 1) * 4
end

function final_threshold()
  return 12 + (current_level - 1) * 3
end

----------------------------------------
-- warp handling
----------------------------------------
function update_warp()
  if warp_time > 0 then
    if warp_time == warp_duration then
      explosions = {}
      sfx(19, 3)
    end
    if warp_time == flr(warp_duration * 0.5) then sfx(19, 3) end
    
    warp_time -= 1
    
    for b in all(enemy_bullets) do release_enemy_bullet(b) end
    enemy_bullets = {}
    for b in all(bullets) do release_bullet(b) end
    bullets = {}
    
    player.x = 60
    player.y = 100
    
    if warp_time == 0 then
      init_starfield()
      enemy_kill_count = 0
      score_streak = 0
      score_multiplier = 1
      
      if current_level > max_level then
        spawn_true_last_boss()
        phase = "true_last_boss"
        update_music("boss")
      else
        phase = "normal"
        phase_state = "pre_mini_boss"
        update_spawn_delay()
        update_music("game")
      end
    end
    return true
  end
  return false
end

----------------------------------------
-- main game update
----------------------------------------
function update_game()
  rank = min(10, score_multiplier - 1)
  if hitstop > 0 then hitstop -= 1 return end
  update_explosions()
  update_bomb_effect()
  update_powerups()
  check_powerup_collection()
  
  if update_warp() then return end
  
  -- music management (only when not transitioning)
  if phase == "mini_boss" or phase == "final_boss" or phase == "true_last_boss" then
    update_music("boss")
  elseif phase == "normal" then
    update_music("game")
  end
  
  update_enemies()
  update_bullets()
  update_enemy_bullets()
  
  -- spawn logic
  if phase == "normal" then
    spawn_timer += 1
    if spawn_timer >= max(40, spawn_delay * (1 - rank * 0.03)) then
      spawn_timer = 0
      spawn_enemy()
    end
    
    if boss_warning > 0 then
      boss_warning -= 1
      if boss_warning == 0 then
        if phase_state == "pre_mini_boss" then
          spawn_boss("mini_boss")
          phase = "mini_boss"
        else
          spawn_boss("final_boss")
          phase = "final_boss"
        end
      end
    elseif phase_state == "pre_mini_boss" and enemy_kill_count >= mini_threshold() and boss_exists("mini_boss") == 0 then
      boss_warning = 180
      sfx(5, 2)
    elseif phase_state == "post_mini_boss" and enemy_kill_count >= final_threshold() and boss_exists("final_boss") == 0 then
      boss_warning = 180
      sfx(5, 2)
    end
  elseif phase == "mini_boss" then
    check_end_mini_boss()
  elseif phase == "final_boss" then
    if boss_exists("final_boss") == 0 then
      phase = "level_complete"
      boss_defeat_grace = 180
      create_final_boss_defeat_explosion(64, 48)
      update_music("fade")
    end
  elseif phase == "level_complete" then
    if boss_defeat_grace > 0 then
      boss_defeat_grace -= 1
      if boss_defeat_grace > 0 and boss_defeat_grace % 20 == 0 then create_explosion(64 + rnd(60) - 30, 64 + rnd(60) - 30, 1) end
      if boss_defeat_grace > 0 and boss_defeat_grace % 60 == 0 then create_explosion(64 + rnd(40) - 20, 40 + rnd(20) - 10, 2) shake_amount = 8 end
      if boss_defeat_grace == 40 then sfx(19, 3) end
    else
      if current_level == max_level and credits_used >= 1 then
        phase = "victory_lap"
        game_complete_grace = 240
      elseif current_level < max_level and #explosions > 0 then
        boss_defeat_grace = 1
      else
        current_level += 1
        warp_time = warp_duration
        phase = "warping"
        sfx(19, 3)
        update_music("silent")
      end
    end
  elseif phase == "victory_lap" then
    if game_complete_grace > 0 then
      game_complete_grace -= 1
    else
      game_state = "game_complete"
      game_complete_grace = 90
      warp_time = 0
      current_level = min(current_level, max_level)
      init_starfield()
    end
  end
  
  -- game over handling
  if game_over then
    game_over_timer -= 1
    if game_over_grace > 0 then game_over_grace -= 1 end
    
    if game_over_timer == 599 then
      final_score = sc(calc_bonus())
      update_high_scores(final_score, get_initials())
    end

    if game_over_timer <= 0 or (game_over_grace <= 0 and btnp(5)) then
      final_score = sc(calc_bonus())
      if score_gt(final_score, high_scores[3].score) then
        current_initials = nil
        game_state = "enter_initials"
      else
        game_state = "title"
        title_timer = 0
      end
      update_music("title")
      return
    end

    if game_over_grace <= 0 and credits > 0 and btnp(4) then
      credits -= 1
      credits_used += 1
      game_over = false
      game_over_timer = 600
      game_over_grace = 60
      player.health = 3
      score_streak = 0
      score_multiplier = 1
    end
    return
  end
  
  -- player input
  if btnp(5) then activate_bomb() end
  
  if bomb_active then
    bomb_timer -= 1
    if bomb_timer <= 0 then bomb_active = false end
  end
  
  -- player movement
  if btn(0) and player.x > 0 then
    player.x -= player.speed
    player.sprite = 17
  elseif btn(1) and player.x < 120 then
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
  
  if shoot_cd > 0 then shoot_cd -= 1 end
  if btn(4) and shoot_cd <= 0 then player_shoot() shoot_cd = 8 end
  
  -- collision checks
  check_enemy_bullet_collisions()
  check_player_enemy_collisions()
  check_bullet_enemy_collisions()
  
  -- update timers
  if player.invincible_timer > 0 then
    player.invincible_timer -= 1
    player.visible = not player.visible
    if player.invincible_timer <= 0 then player.visible = true end
  end
  
  if shake_amount > 0 then shake_amount -= 1 end
  
  if btn(0) or btn(1) or btn(2) or btn(3) then
    player.thrust_frame = (player.thrust_frame + 1) % 3
  else
    player.thrust_frame = 0
  end
end

----------------------------------------
-- main game draw
----------------------------------------
function draw_game()
  if shake_amount > 0 then
    camera(rnd(shake_amount / 2) - shake_amount / 4, rnd(shake_amount / 2) - shake_amount / 4)
  else
    camera(0, 0)
  end
  
  cls()
  draw_starfield()
  draw_explosions()
  draw_bomb_effect()
  
  -- draw powerups
  for p in all(powerups) do
    if p.type == "bomb" then
      spr(5, p.x, p.y)
    elseif p.type == "health" then
      spr(6, p.x, p.y)
    elseif p.type == "score" then
      if p.timer and p.timer < 30 and (time() * 10) % 2 < 1 then pal(8, 7) end
      spr(7, p.x, p.y)
      pal()
    end
  end
  
  draw_player()
  
  -- draw player bullets
  for b in all(bullets) do
    local sprite = 2
    if b.anim_frame == 1 then sprite = 18
    elseif b.anim_frame == 2 then sprite = 34
    elseif b.anim_frame == 3 then sprite = 50
    elseif b.anim_frame == 4 then sprite = 34
    end
    if rank >= 3 then line(b.x + 4, b.y + 8, b.x + 4, b.y + 8 + rank, rank >= 7 and 8 or 10) end
    spr(sprite, b.x, b.y)
  end

  -- draw enemies
  for enemy in all(enemies) do
    if enemy.is_big_sprite then
      pal()
      if enemy.type == "final_boss" then
        pal(8, 12) pal(9, 13) pal(10, 14) pal(7, 7)
        if enemy.phase and enemy.phase >= 3 then
          pal(12, 8) pal(13, 9) pal(14, 10)
        end
      elseif enemy.type == "true_last_boss" and enemy.rage_mode then
        local pulse = sin(time() * 8) * 3
        local base = 8 + flr(abs(pulse))
        pal(8, base) pal(9, base + 1) pal(10, 7)
      elseif enemy.color_offset and enemy.color_offset > 0 then
        for c = 0, 15 do pal(c, (c + enemy.color_offset) % 16) end
      end
      
      if enemy.is_tlb then
        spr(enemy.sprite, enemy.x, enemy.y, 4, 4)
        if enemy.rage_mode then
          fillp(░)
          circfill(enemy.x + 16, enemy.y + 16, 20 + sin(time() * 4) * 3, 8)
          fillp()
        end
      else
        spr(enemy.sprite, enemy.x, enemy.y, 2, 2)
      end
      pal()
    else
      spr(enemy.sprite, enemy.x, enemy.y)
    end
  end
  
  -- draw enemy bullets
  for b in all(enemy_bullets) do spr(4, b.x, b.y) end
  
  -- draw HUD
  local hiscore = high_scores[1].score
  local hi_col = score_gt(sc(), hiscore) and (time() * 8 % 2 < 1 and 10 or 9) or 7
  print(score_fmt(sc()), 1, 1, 7)
  print(score_fmt(hiscore), 128 - #score_fmt(hiscore) * 4, 1, hi_col)
  for i = 1, min(player.health, 10) do spr(1, (i - 1) * 9, 120) end
  for i = 1, player.bombs do spr(5, 128 - i * 9, 120) end
  spr(7, 1, 9) print("x" .. score_multiplier, 10, 10, 7)
  
  if game_over and game_over_grace <= 0 then
    local y_off = sin(time()) * 2
    center_text("game over", 64 + y_off, 8)
    if credits > 0 then
      center_text("z: continue", 72, 7)
    end
    center_text("x: quit", 80, 7)
    center_text("credits "..credits, 88, 6)
    center_text(flr(game_over_timer / 60) .. "s", 96, 5)
  end
  
  -- boss warning
  if boss_warning > 0 and boss_warning % 20 < 10 then
    local warn_col = boss_warning % 40 < 20 and 8 or 10
    shadow_text("! warning !", 55, warn_col)
  end

  -- impact flash
  if hitstop > 0 then fillp(▒) rectfill(0, 0, 127, 127, 7) fillp() end
  camera(0, 0)
end

----------------------------------------
-- game complete screen
----------------------------------------
function draw_game_complete()
  pal()
  if #explosions > 0 then
    explosions = {}
    enemy_bullets = {}
    bullets = {}
    enemies = {}
    powerups = {}
  end
  
  cls()
  draw_starfield()
  
  if warp_time == 0 then
    rectfill(20, 24, 108, 104, 1)
    rect(20, 24, 108, 104, 7)
    
    center_text("victory!", 30, 10)
    if game_loop > 1 then
      center_text("loop " .. game_loop .. " clear!", 38, 11)
    end
    center_text("pilot: " .. get_initials(), 48, 9)
    center_text("score: " .. score_fmt(sc()), 58, 7)
    center_text("bonus: " .. calc_bonus(), 68, 8)
    center_text("final: " .. score_fmt(sc(calc_bonus())), 78, 7)
    
    if game_complete_grace > 0 then
      center_text("calculating...", 90, 7)
    else
      local pulse = 7 + flr(abs(sin(time() * 3) * 3))
      center_text("z: loop " .. (game_loop + 1), 88, pulse)
      center_text("x: exit", 96, 6)
    end
  end
end

----------------------------------------
-- main entry points
----------------------------------------
function _init()
  init_save_system()
  init_high_scores()
  init_starfield()
  current_music = -1
  update_music("title")
end

function _update60()
  update_starfield()
  if game_state == "title" then
    update_title()
  elseif game_state == "enter_initials" then
    update_enter_initials()
  elseif game_state == "starting" then
    warp_time -= 1
    if warp_time <= warp_duration * 0.3 then
      init_game()
      game_state = "game"
      update_music("game")
    end
  elseif game_state == "game" then
    update_game()
  elseif game_state == "game_complete" then
    if game_complete_grace > 0 then
      game_complete_grace -= 1
    elseif btnp(4) then
      game_loop += 1
      credits = 3
      credits_used = 0
      current_level = 1
      phase = "normal"
      phase_state = "pre_mini_boss"
      enemy_kill_count = 0
      enemies = {}
      enemy_bullets = {}
      bullets = {}
      explosions = {}
      powerups = {}
      bomb_active = false
      bomb_timer = 0
      bomb_effect_timer = 0
      shake_amount = 0
      warp_time = warp_duration
      game_state = "game"
      sfx(19, 3)
      update_music("silent")
    elseif btnp(5) then
      game_loop = 1
      warp_time = 0
      current_initials = nil
      game_state = "enter_initials"
      update_music("title")
    end
  end
end

function _draw()
  if game_state == "title" then
    draw_title()
  elseif game_state == "enter_initials" then
    draw_enter_initials()
  elseif game_state == "starting" then
    cls()
    draw_starfield()
  elseif game_state == "game" then
    draw_game()
  elseif game_state == "game_complete" then
    draw_game_complete()
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
