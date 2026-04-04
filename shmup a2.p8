pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
------------------------------
-- global variables & level progression
------------------------------
game_state = "menu"   -- start at menu

credits = 0           -- credits inserted
credits_used = 0      -- number of credits used (1 = no continues)

current_level = 1
enemy_kill_count = 0
-- phases: "normal", "mini_boss", "post_mini", "final_boss", "level_complete", "true_last_boss"
phase = "normal"

warp_time = 0         -- frames remaining in warp
warp_duration = 180   -- total warp frames

function mini_threshold()
  return 5 + (current_level - 1) * 3
end

function final_threshold()
  return 10 + (current_level - 1) * 3
end

------------------------------
-- score variables
------------------------------
score = 0
score_streak = 0       -- starting streak (resets on damage)
score_multiplier = 1   -- increases by 1 every 5 score items
final_score = 0        -- stored final score when game ends

------------------------------
-- bomb & powerup globals
------------------------------
bomb_duration = 60
bomb_active = false
bomb_timer = 0

powerups = {}  -- holds powerups and score items

------------------------------
-- starfield background
------------------------------
starfield = {}

function init_starfield()
  starfield = {}
  for i=1,50 do
    add(starfield, {
      x = rnd(128),
      y = rnd(128),
      speed = 0.5 + rnd(1),
      col = 7
    })
  end
end

function update_starfield()
  local spd_mult = 1
  if warp_time > 0 then
    local ratio = 1 - warp_time / warp_duration  -- goes from 0 to 1
    spd_mult = 1 - sin(ratio * 0.5) * 19  -- ramps up to ~20x at mid-warp then back to 1
  end
  for star in all(starfield) do
    star.y += star.speed * spd_mult
    if warp_time > 0 then
      star.col = flr(rnd(3)) + 7
    else
      star.col = 7
    end
    if star.y > 128 then
      star.y = 0
      star.x = rnd(128)
    end
  end
end

function draw_starfield()
  if warp_time > 0 then
    -- draw each star as a vertical streak.
    local ratio = 1 - warp_time / warp_duration
    local spd_mult = 1 - sin(ratio * 0.5) * 19
    for star in all(starfield) do
      -- use the multiplier to determine the streak length:
      line(star.x, star.y, star.x, star.y - spd_mult, star.col)
    end
  else
    for star in all(starfield) do
      pset(star.x, star.y, star.col)
    end
  end
end

------------------------------
-- explosion effects (intense)
------------------------------
explosions = {}

function create_explosion(x, y, size)
  local count = 10 + size * 5
  local exp = {
    x = x,
    y = y,
    timer = 20 + size * 10,
    particles = {}
  }
  for i=1,count do
    add(exp.particles, {
      x = x,
      y = y,
      dx = (rnd(2)-1) * (1+size),
      dy = (rnd(2)-1) * (1+size),
      col = flr(rnd(8)) + 8
    })
  end
  add(explosions, exp)
  sfx(1)  -- explosion sound
end

function update_explosions()
  for exp in all(explosions) do
    exp.timer -= 1
    for p in all(exp.particles) do
      p.x += p.dx
      p.y += p.dy
    end
    if exp.timer <= 0 then
      del(explosions, exp)
    end
  end
end

function draw_explosions()
  for exp in all(explosions) do
    for p in all(exp.particles) do
      pset(p.x, p.y, p.col)
    end
  end
end

------------------------------
-- bomb visual effect
------------------------------
bomb_effect_timer = 0

function trigger_bomb_effect()
  bomb_effect_timer = 20
  sfx(2)  -- bomb activation sound
end

function draw_bomb_effect()
  if bomb_effect_timer > 0 then
    rectfill(0, 0, 127, 127, 7)
    bomb_effect_timer -= 1
  end
end

------------------------------
-- collision detection
------------------------------
function collides(a, b)
  return not (
    a.x + a.width < b.x or
    b.x + b.width < a.x or
    a.y + a.height < b.y or
    b.y + b.height < a.y
  )
end

------------------------------
-- player & player bullets
------------------------------
player = {
  x = 60,
  y = 100,
  speed = 2,
  sprite = 1,
  width = 8,
  height = 8,
  power = false,  -- false = single shot; true = double shot
  bombs = 3,
  health = 3
}

bullets = {}
bullet_speed = 3
bullet_width = 8
bullet_height = 8

function player_shoot()
  local cx = player.x + player.width/2
  if player.power then
    local offset = 6
    local left_bullet = {
      x = cx - offset - bullet_width/2,
      y = player.y,
      speed = bullet_speed,
      width = bullet_width,
      height = bullet_height
    }
    local right_bullet = {
      x = cx + offset - bullet_width/2,
      y = player.y,
      speed = bullet_speed,
      width = bullet_width,
      height = bullet_height
    }
    add(bullets, left_bullet)
    add(bullets, right_bullet)
  else
    local bullet = {
      x = cx - bullet_width/2,
      y = player.y,
      speed = bullet_speed,
      width = bullet_width,
      height = bullet_height
    }
    add(bullets, bullet)
  end
  sfx(0)  -- player shoot sound
end

------------------------------
-- enemies & enemy bullets
------------------------------
enemies = {}
enemy_bullets = {}

enemy_bullet_speed = 3  -- slower enemy bullets
enemy_bullet_width = 8
enemy_bullet_height = 8
boss_bullet_speed = 3

function spawn_enemy()
  local e = {
    x = flr(rnd(128 - 8)),
    y = -8,
    speed = 1 + (current_level - 1) * 0.1,
    sprite = 3,
    width = 8,
    height = 8,
    shoot_timer = 0,
    shoot_interval = 15 - (current_level - 1) * 2,
    burst_offsets = {0, 10, -10},
    burst_index = 0,
    burst_delay = 3,
    burst_timer = 0,
    type = nil,
    health = 1
  }
  add(enemies, e)
end

------------------------------
-- helper: rotate vector
------------------------------
function rotate_vector(dx, dy, offset_deg)
  local offset = offset_deg / 360
  local c = cos(offset)
  local s = -sin(offset)
  local rx = dx * c - dy * s
  local ry = dx * s + dy * c
  return rx, ry
end

------------------------------
-- normal enemy: sequential 3-shot burst
------------------------------
function normal_enemy_fire(enemy)
  if enemy.burst_index > 0 then
    if enemy.burst_timer > 0 then
      enemy.burst_timer -= 1
    else
      local cx = enemy.x + enemy.width/2
      local cy = enemy.y + enemy.height/2
      local tx = player.x + player.width/2
      local ty = player.y + player.height/2
      local vx = tx - cx
      local vy = ty - cy
      local d = sqrt(vx*vx + vy*vy)
      if d == 0 then d = 1 end
      local ndx = vx/d
      local ndy = vy/d

      local offset_deg = enemy.burst_offsets[enemy.burst_index]
      local rx, ry = rotate_vector(ndx, ndy, offset_deg)
      local bullet = {
        x = cx - enemy_bullet_width/2,
        y = cy - enemy_bullet_height/2,
        dx = enemy_bullet_speed * rx,
        dy = enemy_bullet_speed * ry,
        width = enemy_bullet_width,
        height = enemy_bullet_height
      }
      add(enemy_bullets, bullet)
      enemy.burst_index += 1
      if enemy.burst_index > #enemy.burst_offsets then
        enemy.burst_index = 0
      else
        enemy.burst_timer = enemy.burst_delay
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

------------------------------
-- boss enemies: radial burst (touhou style)
------------------------------
function enemy_shoot_radial(enemy)
  local cluster_count = enemy.cluster_count or 12
  for i = 0, cluster_count - 1 do
    local angle_deg = (i * (360 / cluster_count)) + (enemy.rotate_counter or 0)
    local norm_angle = angle_deg / 360
    local dx = boss_bullet_speed * cos(norm_angle)
    local dy = -boss_bullet_speed * sin(norm_angle)
    local b = {
      x = enemy.x + enemy.width/2 - enemy_bullet_width/2,
      y = enemy.y + enemy.height/2 - enemy_bullet_height/2,
      dx = dx,
      dy = dy,
      width = enemy_bullet_width,
      height = enemy_bullet_height
    }
    add(enemy_bullets, b)
  end
  enemy.rotate_counter = (enemy.rotate_counter + 10) % 360
end

------------------------------
-- boss spawning & health
------------------------------
function boss_exists(boss_type)
  for e in all(enemies) do
    if e.type == boss_type then
      return true
    end
  end
  return false
end

function spawn_mini_boss()
  printh("spawning mini boss!")
  local mini = {
    x = 56,
    y = 10,
    speed = 0.5,
    sprite = 7,
    width = 16,
    height = 16,
    shoot_timer = 0,
    shoot_interval = 20,
    health = 20 + current_level * 10,
    type = "mini_boss",
    cluster_count = 30,
    rotate_counter = 0
  }
  add(enemies, mini)
  sfx(1)
end

function spawn_final_boss()
  printh("spawning final boss!")
  local final = {
    x = 40,
    y = 10,
    speed = 0.5,
    sprite = 8,
    width = 24,
    height = 24,
    shoot_timer = 0,
    shoot_interval = 20,
    health = 40 + current_level * 20,
    type = "final_boss",
    cluster_count = 40,
    rotate_counter = 0
  }
  add(enemies, final)
  sfx(1)
end

function spawn_true_last_boss()
  printh("spawning true last boss!")
  local tb = {
    x = 32,
    y = 10,
    speed = 0.5,
    sprite = 9,
    width = 32,
    height = 32,
    shoot_timer = 0,
    shoot_interval = 30,
    health = 200,
    type = "true_last_boss",
    cluster_count = 60,
    rotate_counter = 0
  }
  add(enemies, tb)
  sfx(1)
end

------------------------------
-- powerup & score items
------------------------------
function spawn_powerup(x, y, type, value)
  local p = {
    x = x,
    y = y,
    type = type,  -- "bomb", "double", or "score"
    value = value or 100,
    width = 8,
    height = 8,
    speed = 0.5
  }
  if type == "score" then
    p.timer = 60  -- score item now lasts 60 frames
  end
  add(powerups, p)
end

function update_powerups()
  for p in all(powerups) do
    if p.type == "score" then
      p.timer -= 1
      if p.timer <= 0 then
        del(powerups, p)
      end
    end
    local dx = (player.x + player.width/2) - (p.x + p.width/2)
    local dy = (player.y + player.height/2) - (p.y + p.height/2)
    local dist = sqrt(dx*dx + dy*dy)
    if dist < 32 then
      p.x += dx * 0.3
      p.y += dy * 0.3
    else
      p.y += p.speed
    end
    if p.y > 128 then
      del(powerups, p)
    end
  end
end

function check_powerup_collection()
  for p in all(powerups) do
    if collides(p, player) then
      if p.type == "bomb" then
        player.bombs += 1
        sfx(3)
      elseif p.type == "double" then
        if player.power then
          player.health += 1
        else
          player.power = true
        end
        sfx(3)
      elseif p.type == "score" then
        score += p.value * score_multiplier
        score_streak += 1
        if score_streak >= 5 then
          score_multiplier += 1
          score_streak = 0
          printh("multiplier increased to " .. score_multiplier)
        end
        sfx(3)
      end
      del(powerups, p)
    end
  end
end

------------------------------
-- bomb functionality
------------------------------
function activate_bomb()
  if player.bombs > 0 and not bomb_active then
    bomb_active = true
    bomb_timer = bomb_duration
    player.bombs -= 1
    for e in all(enemies) do
      if not e.type then
        e.health = (e.health or 1) - 20
        if e.health <= 0 then
          create_explosion(e.x, e.y, 1)
          del(enemies, e)
        end
      else
        e.health -= 20
        if e.health <= 0 then
          create_explosion(e.x, e.y, 2)
          if e.type == "mini_boss" then
            phase = "post_mini"
            enemy_kill_count = 0
            score += 50
            printh("mini boss defeated -> phase = post_mini")
          elseif e.type == "final_boss" then
            phase = "level_complete"
            score += 100
            printh("final boss defeated -> level_complete")
          elseif e.type == "true_last_boss" then
            score += 200
            final_score = score  -- store final score
            game_state = "game_complete"
            printh("true last boss defeated -> game_complete")
          end
          del(enemies, e)
        end
      end
    end
    enemy_bullets = {}
    bullets = {}
    trigger_bomb_effect()
    sfx(2)
    printh("bomb activated! bombs remaining:" .. player.bombs)
  end
end

------------------------------
-- menu screen (arcade style)
------------------------------
function update_menu()
  if btnp(4) then
    credits += 1
    sfx(4)
    printh("credit inserted! total credits: " .. credits)
  end
  if btnp(5) and credits > 0 then
    credits -= 1
    credits_used = 1
    game_state = "game"
    init_game()
    sfx(4)
    printh("game started! credits remaining: " .. credits)
  end
end

function draw_menu()
  cls()
  draw_starfield()
  print("insert coin", 35, 40, 7)
  print("press z to insert credit", 20, 50, 7)
  print("press x to start", 35, 60, 7)
  print("credits: " .. credits, 45, 80, 7)
end

------------------------------
-- main game update (level progression, warp, & continue)
------------------------------
function update_game()
  update_starfield()
  update_explosions()

  if game_over then
    if credits > 0 and btnp(5) then
      credits -= 1
      credits_used += 1
      game_over = false
      player.health = 3
      player.power = false
      score_streak = 0
      score_multiplier = 1
      sfx(4)
      printh("continue! credits remaining: " .. credits)
    elseif btnp(4) then
      game_state = "menu"
      init_game()
    end
    return
  end

  if warp_time > 0 then
    warp_time -= 1
    if warp_time <= 0 then
      phase = "normal"
      enemy_kill_count = 0
      printh("warp complete. level " .. current_level .. " begins!")
      sfx(5)
    end
    powerups = {}  -- clear items during warp
    return
  end

  printh("score:" .. score .. " | streak:" .. score_streak .. " | multiplier:x" .. score_multiplier)
  printh("killcount=" .. enemy_kill_count .. ", minit=" .. mini_threshold() .. ", finalt=" .. final_threshold() .. ", phase=" .. phase)

  if phase == "normal" then
    if enemy_kill_count >= mini_threshold() and not boss_exists("mini_boss") then
      spawn_mini_boss()
      phase = "mini_boss"
    end
  elseif phase == "post_mini" then
    if enemy_kill_count >= final_threshold() and not boss_exists("final_boss") then
      spawn_final_boss()
      phase = "final_boss"
    end
  end

  if btnp(5) then
    activate_bomb()
  end

  if bomb_active then
    bomb_timer -= 1
    if bomb_timer <= 0 then
      bomb_active = false
    end
  end

  if btn(0) then player.x -= player.speed end
  if btn(1) then player.x += player.speed end
  if btn(2) then player.y -= player.speed end
  if btn(3) then player.y += player.speed end
  if player.x < 0 then player.x = 0 end
  if player.x > 128 - player.width then player.x = 128 - player.width end
  if player.y < 0 then player.y = 0 end
  if player.y > 128 - player.height then player.y = 128 - player.height end

  if btnp(4) then
    player_shoot()
  end

  for bullet in all(bullets) do
    bullet.y -= bullet.speed
    if bullet.y < -bullet_height then
      del(bullets, bullet)
    end
  end

  if phase == "normal" then
    if rnd(100) < 2 then
      spawn_enemy()
    end
  elseif phase == "post_mini" then
    if rnd(100) < 5 then
      spawn_enemy()
    end
  end

  for enemy in all(enemies) do
    enemy.y += enemy.speed
    if enemy.type == nil then
      normal_enemy_fire(enemy)
    else
      enemy.shoot_timer += 1
      if enemy.shoot_timer >= enemy.shoot_interval then
        enemy_shoot_radial(enemy)
        enemy.shoot_timer = 0
      end
    end

    for bullet in all(bullets) do
      if collides(enemy, bullet) then
        if not enemy.type then
          score += 10
          enemy_kill_count += 1
          create_explosion(enemy.x, enemy.y, 1)
          del(enemies, enemy)
          del(bullets, bullet)
          if rnd(1) < 0.5 then
            spawn_powerup(enemy.x, enemy.y, "score", 100)
          else
            local ptype = (rnd(1) < 0.5) and "bomb" or "double"
            spawn_powerup(enemy.x, enemy.y, ptype)
          end
          break
        else
          enemy.health -= 1
          if enemy.health <= 0 then
            create_explosion(enemy.x, enemy.y, 2)
            if enemy.type == "mini_boss" then
              phase = "post_mini"
              enemy_kill_count = 0
              score += 50
              printh("mini boss defeated -> phase = post_mini")
            elseif enemy.type == "final_boss" then
              phase = "level_complete"
              score += 100
              printh("final boss defeated -> level_complete")
            elseif enemy.type == "true_last_boss" then
              score += 200
              final_score = score  -- preserve final score
              game_state = "game_complete"
              printh("true last boss defeated -> game_complete")
            end
            del(enemies, enemy)
            del(bullets, bullet)
            break
          end
        end
      end
    end

    if not bomb_active and not enemy.type and collides(enemy, player) then
      create_explosion(enemy.x, enemy.y, 1)
      del(enemies, enemy)
      if player.power then
        player.power = false
      else
        player.health -= 1
        score_streak = 0
        score_multiplier = 1
      end
      if player.health <= 0 then
        create_explosion(player.x, player.y, 2)
        game_over = true
      end
    elseif enemy.y > 128 then
      del(enemies, enemy)
    end
  end

  if phase == "level_complete" and not boss_exists("final_boss") then
    enemy_bullets = {}
    bullets = {}
    current_level += 1
    if current_level <= 5 then
      warp_time = warp_duration
      printh("final boss defeated. warping to level " .. current_level)
      sfx(5)
    else
      if credits_used == 1 then
        spawn_true_last_boss()
        phase = "true_last_boss"
      else
        final_score = score
        game_state = "game_complete"
      end
    end
  end

  for bullet in all(enemy_bullets) do
    bullet.x += bullet.dx
    bullet.y += bullet.dy
    if bullet.x < -enemy_bullet_width or bullet.x > 128 or bullet.y < -enemy_bullet_height or bullet.y > 128 then
      del(enemy_bullets, bullet)
    elseif not bomb_active and collides(bullet, {x = player.x+3, y = player.y+3, width = 2, height = 2}) then
      if player.power then
        player.power = false
      else
        player.health -= 1
        score_streak = 0
        score_multiplier = 1
      end
      create_explosion(bullet.x, bullet.y, 1)
      del(enemy_bullets, bullet)
      if player.health <= 0 then
        create_explosion(player.x, player.y, 2)
        game_over = true
      end
    end
  end

  update_powerups()
  check_powerup_collection()
end

------------------------------
-- draw game
------------------------------
function draw_game()
  cls()
  draw_starfield()
  draw_explosions()
  draw_bomb_effect()
  
  spr(player.sprite, player.x, player.y)
  
  for bullet in all(bullets) do
    spr(2, bullet.x, bullet.y)
  end
  
  for enemy in all(enemies) do
    if enemy.type == "true_last_boss" then
      spr(enemy.sprite, enemy.x, enemy.y, 4, 4)
    elseif enemy.type == "final_boss" then
      spr(enemy.sprite, enemy.x, enemy.y, 3, 3)
    elseif enemy.type == "mini_boss" then
      spr(enemy.sprite, enemy.x, enemy.y, 2, 2)
    else
      spr(enemy.sprite, enemy.x, enemy.y)
    end
  end
  
  for bullet in all(enemy_bullets) do
    spr(4, bullet.x, bullet.y)
  end
  
  for p in all(powerups) do
    if p.type == "bomb" then
      spr(5, p.x, p.y)
    elseif p.type == "double" then
      spr(6, p.x, p.y)
    elseif p.type == "score" then
      spr(10, p.x, p.y)
    end
  end
  
  print("score: " .. score, 1, 1, 7)
  print("health: " .. player.health, 1, 8, 7)
  print("bombs: " .. player.bombs, 1, 16, 7)
  print("level: " .. current_level, 1, 24, 7)
  print("multiplier: x" .. score_multiplier, 1, 32, 7)
  
  if bomb_active then
    print("bomb!", 50, 60, 8)
  end
  
  if game_over then
    rectfill(20,50,108,78,0)
    rect(20,50,108,78,7)
    print("game over", 40, 60, 7)
    print("press z to restart / x to continue", 10, 68, 7)
  end
  
  if game_state == "game_complete" then
    -- use the preserved final_score.
    rectfill(20,50,108,78,0)
    rect(20,50,108,78,7)
    print("you win!", 44, 60, 7)
    print("final score: " .. final_score, 36, 68, 7)
  end
end

------------------------------
-- global _update and _draw
------------------------------
function _update()
  if game_state == "menu" then
    update_menu()
  elseif game_state == "game" then
    update_game()
  elseif game_state == "game_complete" then
    if btnp(4) then
      game_state = "menu"
      init_game()
    end
  end
end

function _draw()
  if game_state == "menu" then
    draw_menu()
  elseif game_state == "game" or game_state == "game_complete" then
    draw_game()
  end
end

------------------------------
-- init game
------------------------------
function init_game()
  player.x = 60
  player.y = 100
  player.health = 3
  player.power = false
  player.bombs = 3
  score = 0
  score_streak = 0
  score_multiplier = 1
  game_over = false
  bullets = {}
  enemies = {}
  enemy_bullets = {}
  powerups = {}
  bomb_active = false
  bomb_timer = 0
  
  current_level = 1
  enemy_kill_count = 0
  phase = "normal"
  warp_time = 0
  credits_used = 0
  init_starfield()
  explosions = {}
  bomb_effect_timer = 0
end

function _init()
  game_state = "menu"
  credits = 0
  credits_used = 0
  init_game()
end
__gfx__
00000000000b60000007c00000777770008880000aaaaaa00aaaa00088888888eeeeeeee99999999000000000000000000000000000000000000000000000000
00000000000b600000c7cc000777777708898880aa7777aaaaa7aa0088888888eeeeeeee99999999000000000000000000000000000000000000000000000000
00700700000b600000c7cc00700770078897aa88a77aa77aaaaa7a0088888888eeeeeeee99999999000999900000000000000000000000000000000000000000
0007700080bc7b0800c7cc0070077007899a7a98a7aaaa7aaaaa7a0088888888eeeeeeee999999990099aa990000000000000000000000000000000000000000
00077000bbbccbbb007777007770777788a77998a7aaaa7aaaaaaa0088888888eeeeeeee99999999009aaaa90000000000000000000000000000000000000000
00700700bbbb6bbb0077770007777770088aa988a77aa77a0aaaa00088888888eeeeeeee999999990099aa990000000000000000000000000000000000000000
00000000b00b600b007007000777770000888880aa7777aa0000000088888888eeeeeeee99999999000999900000000000000000000000000000000000000000
00000000000b60000000000007070700000888000aaaaaa00000000088888888eeeeeeee99999999000000000000000000000000000000000000000000000000
__label__
99999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999
98884444555550000000000022221111aaa77700000000000000000000000000000000000000000000000000000aaaaa00000000000000000000000000000009
9888444455555000000000002222111aaa777770000000000000000000000000000000000000000000000000000aa77700000000000000000000000000000009
9888444445550000000000000222111aaa7777700000000000000000000000000000000000000000000000000000777770000000000000000000000000000009
98880aaa00000000000000000000011aaa7777700000000000000000000000000000000000000000000000000000777770000000000000000000000000000009
9000aaaaa00090000990099099900000a99799000000000099900000000000000000000000000000000000000000777770000000000909099900000999000009
9000aa7aa00090009090909090900000909090900900000000900000000000000000000000fff000000000000000077700000000000909000900000909000009
9000aaa7a0009000909090909990000090909090000000009990000000000000000000000fffff00000000000000000000000000000909099900000909000009
9000aaa7a00090009090909090000000909090900900000f9ffbbb0000000000000000000ffbbb00000000000000000000000000000999090000000909000009
9000aaaaa00099909900990090000000990090900000000f999bbbb000000000000000000fbbbbb0000000000000000000000000000090099900900999000009
90009999900000000000000000000000000000000000000fffbbb666000000000000000000bbbbb0000000000000000000000000000000000000000000000009
900000000000000000000000000000000000000000000000ffbb6666600000000000000000bb6660000000000000000000000000000000000000222000000009
900000000000099090009090099099909990999000000990099b9699990099900000000099069696000000000009990999099900000000099009992999000009
90000000000090009000909090000900900090900000900090909699999009000900000009069699900000000009990900099900900000009009292209000009
90000000000090009000909099900900990099000000900090909699999009000000000009069999990000000009090990090900000000009009992999000009
90000000000090009000909000900900900090900000900090909099999009000900000009006999990000000009090900090900900000009009191900000009
90000000000009909990099099000900999090900000099099000999999009000000000099900999990000000009090999f90900000000099909991999000009
900000000000000000000000000000000000000000000000000000000000000000000000000000999000000000000000fffff000000000000001111100000009
900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000fffff000000000000001aaa100000009
900000000000999090909000099f999b000000009090000000000000000000000000000000000000000000000000000099b9990909000000000999a909000009
90000000aaa79790909090009fff9bb66999900090900000000000000000000000000000000000000000000000000009bbb9b90909009000000aa9a909000009
9000011aaa77999090909000999f996669999900999000000000000000000000ccc00000000000000000000000000009bbb9990909000000000a997999000009
9022111aaa779770909090000f9f9b666999990000900000000000000000000ccccc0000000000000000000000000009b669b009090090000007797709000009
9222111aaa7797700990999099ff99966999990000900000000000000000000cceee000000000000000000000000000099696000990000000009997709000009
92221111aaa7770000000000000000066699900000000000000000000000000ceeeee00000000000000000000000000069996000000000000007777700000009
9222211100000000000000000000000000000000000000ccc000000000000000eeddd000000000000ccc00000000000099999000000000000000777000000009
9022200000009990099099909990999099900000000099cceee0000000000000eddddd0000000000ccccc0000000000999999900990000000009000999000009
9000000000009090909009009090090090000900000009ceeeddd000000000000dd3330000000000ccccc0000000000999999909000090000009000909000009
9000000000009900909009009990090099000000000009ceeddddd00000000000d33333000000000cceee0000000000999999909990000000009990909000009
9000000000009090909009009090090090000900000009ceeddd33300000000000333330000000000eeeee000000000900090000090090000009090909000009
900000000000909099000900909009009990000000009990edd333330000000000333330000000000eddde000000000900090009900000000009990999000009
90000000000000000000000000000000000000000000000000d333330000000000033300000000000ddddd000000000000000000000000000000000000000009
900000000000000000000000000000000000000000000000000333330000000000000000000000000ddddd000000000000000000000000000000000000000009
900000000000999090909000900099909990000099909090999099900000000009909990999009909d3399900000000000000000000000000000000000000009
90000000000090909090900090009000090000000900909090909000090000009000090090909000933393000000000000000000000000000000000000000009
90000000000099009090900090009900090000000900999099909900000000009000090099009000933399000000000000000000000000000fff000000000009
9000000000009090909090009000900cc9eeddd0090000909000900009000000900009009090900093339300000000000000000000000000fffff00000000009
9000000000009990699999909990999cc9eddd333900999090009990000888000990999090900990999399900000000ccc00000000000000fffff00000000009
9000000000000bb666999990000000ccceedd333330000000000000000888880000000888000000000000000000000ccccc0000000000000bbbff00000000009
90000000000fbbb666999990000000ccceedd333330000000000000000884440000008888800000000000000000000ceeec000000000000bbbbb000000000009
9000000000ff9996999999909990999c999e9933330000009990999099849994999098444800000000000000000000eeeee000000000000bbbbb000000000009
9000000000ff9b9b969999000900900090909093390000009898909090944955909094444400000000000000000000eeeee000000000000666bb000000000009
9000000000ff999b999009000900990099009090000000009988999090945955999094455500000000000000000000dddee00000000000666660000000000009
90000000000f9f0090900900090090009090909009000000989494909090592290909455555000000000000000000ddddd000000000000999660000000000009
900000000000900090900900090099909090909000000000989495909990999292909995555000008880000000000333dd000000000009999960000000000009
9000000000000000000000000000000000000000000000000845552220000222220000222550000888880000000033333d000000000009999900000000000009
90000000000000000000000000000000000000000000000000455222220002222200022222000004448800000000333330000000000009999900000000000009
90000000000000000000000000000000000000000000000000055222220000222000022222000044444800000000333330000000000000999000000000000009
90000000000000000000000000000000000000000000000000005222220000000000022222000055544000000000033300000000000000000000000000000009
90000000000000000000000000000000000000000000000000000022200000000000002220000222554000000000000000000000000000000000000000000009
90000000000000000000000000000033300000000884445550000000000000000000000000002222250000000000000000000000000000000000000000000009
9000000000000000000000000eeed333330000008844455522200000000000000000000000002222250000000000000000000000000000000000000000000009
90000000000000000000000ceeedd333330000008844455222220000000000000000000000002222200000000000000000000000000000000000000000000009
9000000000000000000000cceeedd333330000008844455222220000000011101110000000000222000000888000000000000000000000000000000000000009
9000000000000000000000cceeeddd3330000000088444522222000000011111111111100000000000000444880000000000000ccc0000000000000000000009
9000000000000000000000ccceeeddd000000000000000002220000000011aaaaaa1111100000000000044444800000000000eeeccc000000000000000000009
90000000000000000000000ccc0000000000000000000000000000000111aaaaaaaaaa110000000000055544480000000000eeeeecc000000000000000000009
9000000000000000000000000000000000000000000000000000000011aaaa77777aaaa11100000002225554400000000000dddeecc000000000000000000009
900000000000000000000000000000000000000000000000000000001aaa777777777aa111100000222225540000000000333dddec0000000000000000000009
900000000000999000000000000000000000000000552220000000011aa777fffff777aa111000002222255000000000033333dd000000000000000000000009
90000000006999990000000000000000000000884552222200000011aa777fffffff77aaa11000002222250000000000033333dd0000000000000000fff00009
90000000066999990000000000000000000008844552222200000011a777fffffffff77aa11000000222000000000000033333d0000000000000000fffff0009
90000000b66999990000000000000000000008844552222200000011a77fffffffffff7aa111000000000000000000000033300000000000000000bbbfff0009
9000000bb6669990000000000000000000000884445522200000001aa77fffffffffff77aa1100000000000000000000000000000000000000000bbbbbff0009
900000fbbb666000000000000000000000000088444000000000011aa77fffff0fffff77aa110000000000444880000000000000000000000000666bbbf00009
90000ffbbbbb0000000000000000000000000000000000000000011aa77fffffffffff77aa1000000022255444880000000000000000000000999666bb000009
90000fffbbb000000000000000003330000000000000000000000111aa7fffffffffff77a11000000222225544880000000000000000000009999966b0000009
90000fffff0000000000000000d33333000000000000022200000011aa77fffffffff777a1100000022222554488000000000000000000000999996600000009
900000fff0000000000000000dd33333000000000005222220000011aaa77fffffff777aa1100000022222554880000000000000000000000999996000000009
9000000000000000000000000dd333330000000000552222200000111aa777fffff777aa11000000002225500000000000000000000000000099900000000009
90000000000000000000000ceddd333000000000045522222000001111aa777777777aaa10000000000000000000000000000000000000000000000000000009
9000000000000000000000cceeddd00000000000445552220000000111aaaa77777aaaa110000000000000000000000000000000000000000000000000000009
9000000000000000000000cceeeee000000000084445550000000000011aaaaaaaaaa1110000000000000000000000000000000ccc0000000000000000000009
9000000000000000000000ccceee0000000000084444400000000000011111aaaaaa110000000022200000000000000000dddeeeccc000000000000000000009
90000000000000000000000ccc0000000000000884440000000000000011111111111100000002222254448800000000333dddeeecc000000000000000000009
9000000000000000000000000000000000000000888000000222000000000011101110000000022222554448800000033333ddeeecc000000000000000000009
9000000000000000000000000000000000000000000000002222200000000000000000000000022222554448800000033333ddeeec0000000000000000000009
9000000000000000000000000000000000000000000000052222200000000000000000000000002225554448800000033333deee000000000000000000000009
90000000000000000000000000000000000000000000000522222000000000000000000000000000555444880000000033300000000000000000000000000009
90000000000000000000000000000000000000000000004552220000222000000000000022200000000000000000000000000000000000000000000000000009
90000000000000000000000000000000033300000000004455500002222200000000000222225000000000000000000000000000000000000000000000000009
90000000000000009990000000000000333330000000084444400002222200002220000222225500000000000000000000000000000000000000000000000009
90000000000000099999000000000000333330000000088444000002222200022222000222225540000000000000000000000000000000000000000000000009
9000000000000009999900000000000d333330000000088888000055222000022222000022255548000000000000000000000000000000000000000000000009
9000000000000069999900000000000dd33300000000008880000055555000022222500000555448800000000000000000000000000000000000000000000009
9000000000000066999000000000000ddddd0000000000000000005555540000222550000004448880000000000000000000000000000000000fff0000000009
900000000000006666600000000000eeddd000000000000000000005554400005555540000008888800000000000000000000000000000000bbbfff000000009
9000000000000bb666000000000000eeeee000000000000000000004444400000555440000000888000000003330000000000000000999666bbbbff000000009
9000000000000bbbbb000000000000eeeee000000000000000000008444800000444448000000000000000033333deeccc0000000099999666bbbff000000009
9000000000000bbbbb000000000000ceeec000000000000000000008888800000044488000000000000000033333ddeeccc000000099999666bbbf0000000009
900000000000ffbbb0000000000000ccccc000000000000000000000888000000088888000000000000000033333ddeeccc000000099999666bb000000000009
900000000000fffff00000000000000ccc000000000033300000000000000000000888000000000000000000333dddeeccc00000000999666000000000000009
900000000000fffff0000000000000000000000000033333000000000000000000000000000000000000000000dddeeccc000000000000000000000000000009
9000000000000fff0000000000000000000000000003333300000000000000000000000000000000000000000000000000000000000000000000000000000009
90000000000000000000000000000000000000000003333300000000000000000000000000000000000000000000000000000000000000000000000000000009
9000000000000000000000000000000000000000000d333d00000000000000000000000000333000000000000000000000000000000000000000000000000009
9000000000000000000000000000000000000000000ddddd00000000000000000000000003333300000000000000000000000000000000000000000000000009
9000000000000000000000000000000000000000000ddddd000000000003330000000000033333d0000000000000000000000000000000000000000000000009
9000000000000000000000000000000000000000000eddde000000000033333000000000033333dde00000000000000000000000000000000000000000000009
9000000000000000000000000000000000000000000eeeee00000000003333300000000000333dddeec000000000000000000000000000000000000000000009
90000000000000000000000000000999000000000000eeecc00000000033333d00000000000dddddeecc00000000000000000000000000000000000000000009
90000000000000000000000000009999900000000000ccccc0000000000333dd000000000000dddeeecc00000000000000000000000000000000000000000009
90000000000000000000000000009999900000000000ccccc0000000000ddddde0000000000000eeeccc00000000000000000000000000000000000000002229
900000000077700000000000000099999000000000000ccc000000000000dddee000000000000000ccc000000000000000000000000000000000000001112229
900000000777770000000000000069996000000000000000000000000000eeeeec0000000000000000000000000099966600000000000000000777aaa1111229
9000000007777700000000000000666660000000000000000000000000000eeecc000000000000000000000000099999666bfff0000000000077777aaa111229
9000000007777700000000000000b666b0000000000000000000000000000ccccc000000000000000000000000099999666bbfff000000000077777aaa111229
900000000a777a00000000000000bbbbb00000000000000000000000000000ccc0000000000000000000000000099999666bbfff000000000077777aaa110009
900000000aaaaa00000000000000bbbbb00000000000000000000000000000000000000000000000000000000000999666bbbfff00000000000777aaa0000009
900000000aaaaa00000000000000fbbbf0000000000000000000000000000000000000000000000000000000000000000bbbfff0000000000000000000000009
9000000001aaa100000000000000fffff00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000009
9000000001111100000000000000fffff00000000000000099900000000000000000000000000000000000000000000000000000000000000000000000000009
90000000011111000000000000000fff000000000000000999990000000000000000000999000000000000000000000000000000000000000000000000000009
90000000001110000000000000000000000000000000000999996000000000000000009999900000000000000000000000000000000000000000000000000009
90000000022222000000000000000000000000000000000999996600000000000000009999960000000000000000000000000000000000000000000000000009
90000000022222000000000000000000000000000000000099966600000000000000009999966000000000000000000000000000000000000000000000000009
90000000022222000000000000000000000000000000000006666600000000000000000999666b00000000000000000000000000000000000000000000000009
90000000002220000000000000000000000000000000000000666bb0000000000000000066666bbff00000000000000000000000000000000000000000000009
90000000000000000000000000000000000000000000000000bbbbb000000000000000000666bbbfff0000000000000000000000000000000000000000000009
90000000000000000000000000000000000000000000000000bbbbbf000000000000000000bbbbbfff0000000000000000000000000000000000000000000009
900000000000000000000000000000000000000000000000000bbbff0000000000000000000bbbffff0000000000000000000000000000000000000000000009
900000000000000000000000000000000000000000000000000fffff0000000000000000000000fff00000000000000000000000000000000000000000000009
9000000000000000000000000000000007770000000000000000fff0000000000000000000000000000000000000000000000000000000000000000000000009
9000000000000000000000000000000077777000000000000000000000000000000000000000000000000000000777aaa0000000000000000000000000000009
90000000000000000000000000000000777770000000000000000000000000000000000000000000000000000077777aaa110000000000000000000004440889
90000000000000000000000000000000777770000000000000000000000000000000000000000000000000000077777aaa111222000000000000055544444889
900000000000000000000000000000000777aa000000000000000000000000000000000000000000000000000077777aaa111222200000000000555554444889
99999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999

__sfx__
000000003f3503e3503c3503a35038350373503535032350303502e3502c350293502735024350223501f3501d3501b3501935018350163501435012350113500e3500d3500c3500c3500a350083500635000350
0010000036650136503f6503f6503f6500a65009650076500665001650006500000000000000002060020600000000000000000000000d6000d60000000000000000000000000000000000000000000000000000
001000003665005650236502a65004650046502b65003650086503c650036500365004650056503765004650026500465002650046503b6503b65002650026500765007650076500665006650056500565005650
000500003f3503c0503e050030503a0503b0500f05034050000000b0500b0500000000000000000000000000000000000000000000003d7003d7003d7003d7003d70000000000000000000000000000000000000
001000003e4503d450384503745000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00100000000003d450000000345032450104500e4500000031450014503445000000000000d4503645036450000003b4503c450000000000007450074500645031450314500b4500000000000000003f45000000
__music__
00 01424344
00 01424344

