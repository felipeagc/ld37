local mainstate = {}

function mainstate:new()
  local state = {
    assets = {},
    world = love.physics.newWorld(0, 0, true),
    entities = {},
    can = true,
    left = {
      wall = 0,
      shrinkStep = 0,
      expandStep = 0
    },
    right = {
      wall = 0,
      shrinkStep = 0,
      expandStep = 0
    },
    top = {
      wall = 0,
      shrinkStep = 0,
      expandStep = 0
    },
    bottom = {
      wall = 0,
      shrinkStep = 0,
      expandStep = 0
    },
    enemies = {},
    queue = {},
    gameover = false,
    ggText = {
      sx = 1,
      sy = 1
    },
    spawnRate = 0.2,
    spawnCooldown = 2,
    bombRate = 0.08,
    bombCooldown = 0,
    time = 0
  }

  local function ggTween(back)
    local function after()
      ggTween(not back)
    end
    local target = 1.2
    if back then
      target = 1
    end
    flux.to(state.ggText, 0.2, {sx = target, sy = target}):oncomplete(after)
  end

  ggTween(false)

  function state:beginContact(a, coll)
    local fa, fb = coll:getFixtures()

    -- Enemy damage to player
    if fa == state.player.fixture then
      for i, entity in ipairs(state.entities) do
        if entity.type == "enemy" then
          if fb == entity.fixture then
            state.player:damage(1)
          end
        end
      end
    elseif fb == state.player.fixture then
      for i, entity in ipairs(state.entities) do
        if entity.type == "enemy" then
          if fa == entity.fixture then
            state.player:damage(1)
          end
        end
      end
    end

    -- Bullet damage to enemies
    for i, bullet in ipairs(state.player.bullets) do
      if fa == bullet.fixture then
        for i2, entity in ipairs(state.entities) do
          if entity.type == "enemy" then
            if fb == entity.fixture then
              entity.lastHitDir = bullet.direction
              entity:damage(4)
              bullet.body:destroy()
              table.remove(state.player.bullets, i)
            end
          end
        end
      end
      if fb == bullet.fixture then
        for i2, entity in ipairs(state.entities) do
          if entity.type == "enemy" then
            if fa == entity.fixture then
              entity.lastHitDir = bullet.direction
              entity:damage(4)
              bullet.body:destroy()
              table.remove(state.player.bullets, i)
            end
          end
        end
      end
    end
  end

  function state:endContact(a, b, coll)
  end

  function state:preSolve(a, b, coll)
  end

  function state:postSolve(a, b, coll, normalimpulse, tangentimpulse)
  end

  state.world:setCallbacks(state.beginContact, state.endContact, state.preSolve, state.postSolve)

  -- Create the player
  state.player = {
    type = "player",
    image = love.graphics.newImage("assets/player.png"),
    bullets = {},
    shootCooldownMax = 0.12,
    shootCooldown = 0.12
  }

  state.player.body = love.physics.newBody(state.world, gameWidth/2, gameHeight/2, "dynamic")
  state.player.shape = love.physics.newCircleShape(6)
  state.player.fixture = love.physics.newFixture(state.player.body, state.player.shape, 0.5)
  state.player.fixture:setCategory(2)
  state.player.fixture:setMask(5)
  state.player.body:setLinearDamping(8)
  state.player.maxHealth = 10
  state.player.health = 10

  function state.player:damage(amount)
    if not state.gameover then
      local sound = love.math.random(1, 2)
      if sound == 1 then
        state.assets.hitSound1:stop()
        state.assets.hitSound1:play()
      else
        state.assets.hitSound2:stop()
        state.assets.hitSound2:play()
      end

      if self.health > 0 then
        self.health = self.health - amount
      end
      if self.health < 0 then
        self.health = 0
      end

      local sides = {"right", "left", "top", "bottom"}
      if state.left.wall + state.right.wall >= 4 then
        if state.left.wall + state.right.wall > state.top.wall + state.bottom.wall then
          sides = {"top", "bottom", "top", "bottom"}
        end
      end
      if state.top.wall + state.bottom.wall >= 4 then
        if state.left.wall + state.right.wall < state.top.wall + state.bottom.wall then
          sides = {"left", "right", "left", "right"}
        end
      end
      local si = love.math.random(1, 4)
      local side = sides[si]
      state:queueWall("shrink", side)

      if self.health <= 0 then
        -- Player dies
        state.gameover = true
      end
    end
  end

  function state.player:shoot(direction)
    if state.player.shootCooldown > 0 then
      return
    end

    state.player.shootCooldown = state.player.shootCooldownMax

    local bullet = {}

    bullet.body = love.physics.newBody(state.world, self.body:getX(), self.body:getY(), "dynamic")
    bullet.body:setBullet(true)
    bullet.shape = love.physics.newCircleShape(4)
    bullet.fixture = love.physics.newFixture(bullet.body, bullet.shape, 0.5)
    bullet.fixture:setCategory(4)
    bullet.fixture:setMask(5)
    bullet.fixture:setSensor(true)
    bullet.direction = direction
    bullet.time = 5

    local impulse = 16
    if direction == "left" then
      bullet.body:setAngle(180)
      bullet.body:applyLinearImpulse(-impulse, 0)
    elseif direction == "right" then
      bullet.body:setAngle(0)
      bullet.body:applyLinearImpulse(impulse, 0)
    elseif direction == "bottom" then
      bullet.body:setAngle(90)
      bullet.body:applyLinearImpulse(0, impulse)
    elseif direction == "top" then
      bullet.body:setAngle(270)
      bullet.body:applyLinearImpulse(0, -impulse)
    end

    state.assets.gunshot:stop()
    local pitch = love.math.random(7, 15)/10
    state.assets.gunshot:setPitch(pitch)
    state.assets.gunshot:play()
    screen:setShake(3)

    table.insert(state.player.bullets, bullet)
  end

  table.insert(state.entities, state.player)

  function state:createBomb(x, y)
    local bomb = {}

    bomb.type = "bomb"
    bomb.body = love.physics.newBody(state.world, x, y, "dynamic")
    bomb.shape = love.physics.newCircleShape(6)
    bomb.fixture = love.physics.newFixture(bomb.body, bomb.shape, 0.5)
    bomb.fixture:setCategory(6)
    bomb.body:setLinearDamping(6)
    bomb.sx = 1
    bomb.sy = 0
    bomb.opacity = 255
    bomb.time = 2

    flux.to(bomb, 0.1, {sx = 1.2, sy = 1.2}):after(bomb, 0.05, {sx = 1, sy = 1})

    local function bombTween(on)
      local function again()
        bombTween(not on)
      end
      local target = 0
      if on then
        target = 0.5*255
      end
      flux.to(bomb, 0.1, { opacity = target }):oncomplete(again)
    end

    bombTween(false)

    function bomb:explode()
      state.assets.explosion:play()
      screen:setShake(20)
      local distance = love.physics.getDistance(bomb.fixture, state.player.fixture)
      if distance <= 1*16 then
        state.player:damage(5)
      elseif distance < 3*16 then
        state.player:damage(2)
      end

      local afterExplosion = {}

      afterExplosion.type = "afterExplosion"
      afterExplosion.body = love.physics.newBody(state.world, bomb.body:getX(), bomb.body:getY(), "dynamic")
      afterExplosion.shape = love.physics.newCircleShape(8)
      afterExplosion.fixture = love.physics.newFixture(afterExplosion.body, afterExplosion.shape, 0.5)
      afterExplosion.fixture:setCategory(5)
      afterExplosion.fixture:setMask(5)
      afterExplosion.sx = 1
      afterExplosion.sy = 0
      afterExplosion.opacity = 255

      local function deleteAfterExplosion()
        for i, entity in ipairs(state.entities) do
          if entity == afterExplosion then
            afterExplosion.body:destroy()
            table.remove(state.entities, i)
          end
        end
      end

      flux.to(afterExplosion, 0.2, {sy = 1}):after(afterExplosion, 0.05, {sx = 1.2, sy = 1.2}):after(afterExplosion, 0.05, {sx = 1, sy = 1})
      flux.to(afterExplosion, 2, {opacity = 0}):delay(10):oncomplete(deleteAfterExplosion)

      table.insert(state.entities, afterExplosion)

      for i, entity in ipairs(state.entities) do
        if entity == bomb then
          bomb.body:destroy()
          table.remove(state.entities, i)
        end
      end
    end

    table.insert(state.entities, bomb)
  end

  function state:createEnemy(x, y)
    local enemy = {}

    enemy.type = "enemy"
    enemy.body = love.physics.newBody(state.world, x, y, "dynamic")
    enemy.shape = love.physics.newCircleShape(6)
    enemy.fixture = love.physics.newFixture(enemy.body, enemy.shape, 0.5)
    enemy.fixture:setCategory(3)
    enemy.fixture:setMask(5)
    enemy.body:setLinearDamping(8)
    enemy.maxHealth = 10
    enemy.health = 10
    enemy.maxCooldown = 1
    enemy.cooldown = 1
    enemy.lastHitDir = nil
    enemy.sx = 1
    enemy.sy = 0

    flux.to(enemy, 0.1, {sx = 1.2, sy = 1.2}):after(enemy, 0.05, {sx = 1, sy = 1})

    function enemy:damage(amount)
      local sound = love.math.random(1, 2)
      if sound == 1 then
        state.assets.hitSound1:stop()
        state.assets.hitSound1:play()
      else
        state.assets.hitSound2:stop()
        state.assets.hitSound2:play()
      end

      self.health = self.health - amount
    end

    function enemy:kill()
      local blood = {}

      blood.type = "blood"
      blood.body = love.physics.newBody(state.world, self.body:getX(), self.body:getY(), "dynamic")
      blood.shape = love.physics.newCircleShape(5)
      blood.fixture = love.physics.newFixture(blood.body, blood.shape, 0.5)
      blood.fixture:setCategory(5)
      blood.fixture:setMask(5)
      blood.sx = 1
      blood.sy = 0
      blood.opacity = 255

      local function deleteBlood()
        for i, entity in ipairs(state.entities) do
          if entity == blood then
            blood.body:destroy()
            table.remove(state.entities, i)
          end
        end
      end

      flux.to(blood, 0.2, {sy = 1}):after(blood, 0.05, {sx = 1.2, sy = 1.2}):after(blood, 0.05, {sx = 1, sy = 1})
      flux.to(blood, 2, {opacity = 0}):delay(10):oncomplete(deleteBlood)

      table.insert(state.entities, blood)

      state:queueWall("expand", self.lastHitDir)
      if state.player.health < state.player.maxHealth then
        state.player.health = state.player.health + 1
      end
    end

    table.insert(state.entities, enemy)
  end

  -- Create wall bodies
  state.left.body = love.physics.newBody(state.world, 0, 0, "static")
  state.left.shape = love.physics.newEdgeShape(0, 0, 0, gameHeight)
  state.left.fixture = love.physics.newFixture(state.left.body, state.left.shape, 0.5)
  state.left.fixture:setCategory(1)

  state.right.body = love.physics.newBody(state.world, gameWidth, 0, "static")
  state.right.shape = love.physics.newEdgeShape(0, 0, 0, gameHeight)
  state.right.fixture = love.physics.newFixture(state.right.body, state.right.shape, 0.5)
  state.right.fixture:setCategory(1)

  state.bottom.body = love.physics.newBody(state.world, 0, gameHeight, "static")
  state.bottom.shape = love.physics.newEdgeShape(0, 0, gameWidth, 0)
  state.bottom.fixture = love.physics.newFixture(state.bottom.body, state.bottom.shape, 0.5)
  state.bottom.fixture:setCategory(1)

  state.top.body = love.physics.newBody(state.world, 0, 0, "static")
  state.top.shape = love.physics.newEdgeShape(0, 0, gameWidth, 0)
  state.top.fixture = love.physics.newFixture(state.top.body, state.top.shape, 0.5)
  state.top.fixture:setCategory(1)

  -- Create tile images
  state.assets.topRight = love.graphics.newImage("assets/top_right.png")
  state.assets.topLeft = love.graphics.newImage("assets/top_left.png")
  state.assets.top = love.graphics.newImage("assets/top.png")
  state.assets.bottom = love.graphics.newImage("assets/bottom.png")
  state.assets.bottomRight = love.graphics.newImage("assets/bottom_right.png")
  state.assets.bottomLeft = love.graphics.newImage("assets/bottom_left.png")
  state.assets.right = love.graphics.newImage("assets/right.png")
  state.assets.left = love.graphics.newImage("assets/left.png")
  state.assets.center = love.graphics.newImage("assets/center.png")

  state.assets.bullet = love.graphics.newImage("assets/bullet.png")
  state.assets.enemy = love.graphics.newImage("assets/enemy.png")
  state.assets.blood = love.graphics.newImage("assets/blood.png")
  state.assets.smallfont = love.graphics.newFont("assets/kenpixel_mini_square.ttf", 8)
  state.assets.bigfont = love.graphics.newFont("assets/kenpixel_mini_square.ttf", 8*5)

  state.assets.bomb1 = love.graphics.newImage("assets/bomb1.png")
  state.assets.bomb2 = love.graphics.newImage("assets/bomb2.png")
  state.assets.afterexplosion = love.graphics.newImage("assets/afterexplosion.png")

  state.assets.gunshot = love.audio.newSource("assets/gunshot.wav", "static")
  state.assets.explosion = love.audio.newSource("assets/explosion.wav", "static")
  state.assets.music = love.audio.newSource("assets/music.wav")
  state.assets.wallSound = love.audio.newSource("assets/wall.wav", "static")
  state.assets.hitSound1 = love.audio.newSource("assets/hit1.wav", "static")
  state.assets.hitSound2 = love.audio.newSource("assets/hit2.wav", "static")

  state.assets.healthbar = {}
  state.assets.healthbar[10] = love.graphics.newImage("assets/healthbar10.png")
  state.assets.healthbar[9] = love.graphics.newImage("assets/healthbar9.png")
  state.assets.healthbar[8] = love.graphics.newImage("assets/healthbar8.png")
  state.assets.healthbar[7] = love.graphics.newImage("assets/healthbar7.png")
  state.assets.healthbar[6] = love.graphics.newImage("assets/healthbar6.png")
  state.assets.healthbar[5] = love.graphics.newImage("assets/healthbar5.png")
  state.assets.healthbar[4] = love.graphics.newImage("assets/healthbar4.png")
  state.assets.healthbar[3] = love.graphics.newImage("assets/healthbar3.png")
  state.assets.healthbar[2] = love.graphics.newImage("assets/healthbar2.png")
  state.assets.healthbar[1] = love.graphics.newImage("assets/healthbar1.png")
  state.assets.healthbar[0] = love.graphics.newImage("assets/healthbar0.png")

  state.assets.music:setLooping(true)
  state.assets.music:setVolume(0.2)
  state.assets.music:play()

  function state:update(dt)
    -- Process wall queue
    for i, v in ipairs(state.queue) do
      if state.can then
        if v.command == "expand" then
          state:expandWall(v.direction)
        elseif v.command == "shrink" then
          state:shrinkWall(v.direction)
        end
        table.remove(state.queue, i)
      else
      end
    end

    if not state.gameover then
      state.time = state.time + dt
    end

    if not state.gameover then
      state.spawnRate = state.spawnRate + dt/100
      local spawnTime = 1/state.spawnRate

      state.spawnCooldown = state.spawnCooldown - dt
      if state.spawnCooldown <= 0 then
        state.spawnCooldown = spawnTime

        --Spawn enemy here

        local x = 0.5 + love.math.random(0 + self.left.wall, (gameWidth/16) - 1 - self.right.wall)
        local y = 0.5 + love.math.random(0 + self.top.wall, (gameHeight/16) - 1 - self.bottom.wall)
        x, y = x*16, y*16

        state:createEnemy(x, y)
      end

      if state.time > 30 then
        state.bombRate = state.bombRate + dt/100
        local bombTime = 1/state.bombRate

        state.bombCooldown = state.bombCooldown - dt
        if state.bombCooldown <= 0 then
          state.bombCooldown = bombTime

          -- Spawn bomb here

          local x = 0.5 + love.math.random(0 + self.left.wall, (gameWidth/16) - 1 - self.right.wall)
          local y = 0.5 + love.math.random(0 + self.top.wall, (gameHeight/16) - 1 - self.bottom.wall)
          x, y = x*16, y*16

          state:createBomb(x, y)
        end
      end

    end

    -- Shooting cooldown
    if not state.gameover then
      state.player.shootCooldown = state.player.shootCooldown - dt
    end

    -- Player movement
    if not state.gameover then
      local fx = 0
      local fy = 0
      local speed = 40
      if love.keyboard.isDown("w") then
        fy = fy - speed
      end
      if love.keyboard.isDown("s") then
        fy = fy + speed
      end
      if love.keyboard.isDown("d") then
        fx = fx + speed
      end
      if love.keyboard.isDown("a") then
        fx = fx - speed
      end

      self.player.body:applyForce(fx, fy)
    end

    for i, bullet in ipairs(state.player.bullets) do
      bullet.time = bullet.time - dt
      if bullet.time <= 0 then
        table.remove(state.player.bullets, i)
      end
    end

    if not state.gameover then
      -- Bomb explosions
      for i, entity in ipairs(state.entities) do
        if entity.type == "bomb" then
          entity.time = entity.time - dt
          if entity.time <= 0 then
            entity:explode()
          end
        end
      end
    end

    for i, entity in ipairs(state.entities) do
      if entity.type == "enemy" then
        if entity.health <= 0 then
          entity:kill()
          entity.body:destroy()
          table.remove(state.entities, i)
        else
          -- enemyai
          if not state.gameover then
            entity.cooldown = entity.cooldown - dt
            if entity.cooldown <= 0 then
              entity.cooldown = entity.maxCooldown
              -- Attack here
              local px, py = state.player.body:getPosition()
              local angle = math.atan2(py - entity.body:getY(), px - entity.body:getX())
              local speed = 40
              if entity.health < entity.maxHealth then
                if love.math.random(1, 3) == 3 then
                  entity.body:applyLinearImpulse(math.sin(angle)*speed, math.cos(angle)*speed)
                end
                entity.body:applyLinearImpulse(math.cos(angle)*speed, math.sin(angle)*speed)
              else
                entity.body:applyLinearImpulse(math.cos(angle)*speed, math.sin(angle)*speed)
              end
            end
          end
        end
      end
    end

    self.world:update(dt)
  end

  function state:draw()
    -- First pass
    for x = 0+self.left.wall, 15-self.right.wall do
      for y = 0+self.top.wall, 8-self.bottom.wall do
        local ox, oy = x-self.left.wall, y-self.top.wall
        if ox == 0 and oy == 0 then
          -- Top Left
          if self.left.shrinkStep ~= 0 then
            love.graphics.draw(self.assets.top, x*16, y*16)
          elseif self.top.shrinkStep ~= 0 then
            love.graphics.draw(self.assets.left, x*16, y*16)
          elseif self.left.expandStep ~= 0 or self.top.expandStep ~= 0 then
            -- Don't draw anything
          else
            love.graphics.draw(self.assets.topLeft, x*16, y*16)
          end
        elseif ox == 15-(self.right.wall + self.left.wall) and oy == 8-(self.bottom.wall + self.top.wall) then
          -- Bottom Right
          if self.right.shrinkStep ~= 0 then
            love.graphics.draw(self.assets.bottom, x*16, y*16)
          elseif self.bottom.shrinkStep ~= 0 then
            love.graphics.draw(self.assets.right, x*16, y*16)
          elseif self.right.expandStep ~= 0 or self.bottom.expandStep ~= 0 then
            -- Don't draw anything
          else
            love.graphics.draw(self.assets.bottomRight, x*16, y*16)
          end
        elseif ox == 15-(self.right.wall + self.left.wall) and oy == 0 then
          -- Top right
          if self.right.shrinkStep ~= 0 then
            love.graphics.draw(self.assets.top, x*16, y*16)
          elseif self.top.shrinkStep ~= 0 then
            love.graphics.draw(self.assets.right, x*16, y*16)
          elseif self.right.expandStep ~= 0 or self.top.expandStep ~= 0 then
            -- Don't draw anything
          else
            love.graphics.draw(self.assets.topRight, x*16, y*16)
          end
        elseif ox == 0 and oy == 8-(self.bottom.wall + self.top.wall) then
          -- Bottom left
          if self.left.shrinkStep ~= 0 then
            love.graphics.draw(self.assets.bottom, x*16, y*16)
          elseif self.bottom.shrinkStep ~= 0 then
            love.graphics.draw(self.assets.left, x*16, y*16)
          elseif self.left.expandStep ~= 0 or self.bottom.expandStep ~= 0 then
            -- Don't draw anything
          else
            love.graphics.draw(self.assets.bottomLeft, x*16, y*16)
          end
        elseif ox == 0 then
          -- Left
          if self.left.shrinkStep ~= 0 then
            love.graphics.draw(self.assets.center, x*16, y*16)
          elseif self.left.expandStep ~= 0 then
            -- Don't draw anything
          else
            love.graphics.draw(self.assets.left, x*16, y*16)
          end
        elseif oy == 0 then
          -- Top
          if self.top.shrinkStep ~= 0 then
            love.graphics.draw(self.assets.center, x*16, y*16)
          elseif self.top.expandStep ~= 0 then
            -- Don't draw anything
          else
            love.graphics.draw(self.assets.top, x*16, y*16)
          end
        elseif ox == 15-(self.right.wall + self.left.wall) then
          -- Right
          if self.right.shrinkStep ~= 0 then
            love.graphics.draw(self.assets.center, x*16, y*16)
          elseif self.right.expandStep ~= 0 then
            -- Don't draw anything
          else
            love.graphics.draw(self.assets.right, x*16, y*16)
          end
        elseif oy == 8-(self.bottom.wall + self.top.wall) then
          -- Bottom
          if self.bottom.shrinkStep ~= 0 then
            love.graphics.draw(self.assets.center, x*16, y*16)
          elseif self.bottom.expandStep ~= 0 then
            -- Don't draw anything
          else
            love.graphics.draw(self.assets.bottom, x*16, y*16)
          end
        else
          love.graphics.draw(self.assets.center, x*16, y*16)
        end
      end
    end

    -- Second pass
    for x = 0+self.left.wall, 15-self.right.wall do
      for y = 0+self.top.wall, 8-self.bottom.wall do
        local ox, oy = x-self.left.wall, y-self.top.wall
        if ox == 0 and oy == 0 then
          -- Top Left
          love.graphics.draw(self.assets.topLeft, (x - self.left.shrinkStep - self.left.expandStep)*16, (y - self.top.shrinkStep - self.top.expandStep)*16)
        elseif ox == 15-(self.right.wall + self.left.wall) and oy == 8-(self.bottom.wall + self.top.wall) then
          -- Bottom Right
          love.graphics.draw(self.assets.bottomRight, (x + self.right.shrinkStep + self.right.expandStep)*16, (y + self.bottom.shrinkStep + self.bottom.expandStep)*16)
        elseif ox == 15-(self.right.wall + self.left.wall) and oy == 0 then
          -- Top right
          love.graphics.draw(self.assets.topRight, (x + self.right.shrinkStep + self.right.expandStep)*16, (y - self.top.shrinkStep - self.top.expandStep)*16)
        elseif ox == 0 and oy == 8-(self.bottom.wall + self.top.wall) then
          -- Bottom left
          love.graphics.draw(self.assets.bottomLeft, (x - self.left.shrinkStep - self.left.expandStep)*16, (y + self.bottom.shrinkStep + self.bottom.expandStep)*16)
        elseif ox == 0 then
          -- Left
          love.graphics.draw(self.assets.left, (x - self.left.shrinkStep - self.left.expandStep)*16, y*16)
        elseif oy == 0 then
          -- Top
          love.graphics.draw(self.assets.top, x*16, (y - self.top.shrinkStep - self.top.expandStep)*16)
        elseif ox == 15-(self.right.wall + self.left.wall) then
          -- Right
          love.graphics.draw(self.assets.right, (x + self.right.shrinkStep + self.right.expandStep)*16, y*16)
        elseif oy == 8-(self.bottom.wall + self.top.wall) then
          -- Bottom
          love.graphics.draw(self.assets.bottom, x*16, (y + self.bottom.shrinkStep + self.bottom.expandStep)*16)
        end
      end
    end

    for i, entity in ipairs(state.entities) do
      if entity.type == "blood" then
        -- Draw blood
        love.graphics.setColor(255, 255, 255, entity.opacity)
        love.graphics.draw(state.assets.blood, entity.body:getX(), entity.body:getY(), 0, entity.sx, entity.sy, 8, 8)
        love.graphics.setColor(255, 255, 255, 255)
      end
      if entity.type == "afterExplosion" then
        -- Draw afterExplosion
        love.graphics.setColor(255, 255, 255, entity.opacity)
        love.graphics.draw(state.assets.afterexplosion, entity.body:getX(), entity.body:getY(), 0, entity.sx, entity.sy, 8, 8)
        love.graphics.setColor(255, 255, 255, 255)
      end
      if entity.type == "bomb" then
        -- Draw bombs
        love.graphics.draw(state.assets.bomb1, entity.body:getX(), entity.body:getY(), 0, entity.sx, entity.sy, 8, 8)
        love.graphics.setColor(255, 255, 255, entity.opacity)
        love.graphics.draw(state.assets.bomb2, entity.body:getX(), entity.body:getY(), 0, entity.sx, entity.sy, 8, 8)
        love.graphics.setColor(255, 255, 255, 255)
      end
      if entity.type == "enemy" then
        -- Draw enemies
        love.graphics.draw(state.assets.enemy, entity.body:getX(), entity.body:getY(), 0, entity.sx, entity.sy, 8, 8)
      end
    end

    for i, bullet in ipairs(state.player.bullets) do
      love.graphics.draw(state.assets.bullet, bullet.body:getX(), bullet.body:getY(), math.rad(bullet.body:getAngle()), 1, 1, 8, 8)
    end
    -- Draw player
    if state.player.health > 0 then
      love.graphics.draw(self.player.image, self.player.body:getX(), self.player.body:getY(), 0, 1, 1, 8, 8)
    else
      love.graphics.draw(state.assets.blood, self.player.body:getX(), self.player.body:getY(), 0, 1, 1, 8, 8)
    end

    -- Draw hud
    love.graphics.setFont(state.assets.smallfont)
    love.graphics.print(math.floor(state.time*100)/100 .. " s", 4, 9)
    love.graphics.draw(state.assets.healthbar[state.player.health], 2, 2)

    local function printCentered(text, x, y, r, sx, sy)
      local width = love.graphics.getFont():getWidth(text)
      local height = love.graphics.getFont():getHeight(text)
      love.graphics.print(text, x, y, r, sx, sy, math.floor(width/2), math.floor(height/2))
    end

    if state.gameover then
      love.graphics.setFont(state.assets.bigfont)
      love.graphics.setColor(172, 50, 50, 255)
      printCentered("GG", gameWidth/2, gameHeight/2 - 12, 0, state.ggText.sx, state.ggText.sy)

      love.graphics.setFont(state.assets.smallfont)
      printCentered("Time: " .. math.floor(state.time*1000) / 1000 .. " s", gameWidth/2, gameHeight/2 + 16, 0, 1, 1)
      love.graphics.setColor(200, 200, 200, 255)
      printCentered("Press R to try again", gameWidth/2, gameHeight/2 + 32, 0, 1, 1)
    end
  end

  function state:keypressed(key, scancode, isRepeat)
    if not isRepeat then
      if key == "r" then
        switchState(mainstate:new())
      end
      if key == "right" then
        state.player:shoot("right")
      end
      if key == "left" then
        state.player:shoot("left")
      end
      if key == "up" then
        state.player:shoot("top")
      end
      if key == "down" then
        state.player:shoot("bottom")
      end
      if key == "escape" then
        switchState(menustate:new())
      end
    end
  end

  local tweenTime = 0.2

  function state:queueWall(command, direction)
    local item = {command = command, direction = direction}
    table.insert(state.queue, item)
  end

  function state:shrinkWall(side)
    local wall = state[side]
    if side == "right" or side == "left" then
      if ((gameWidth/16)-1)-state.left.wall-state.right.wall <= 1 then
        return
      end
    end

    if side == "top" or side == "bottom" then
      if ((gameHeight/16)-1)-state.top.wall-state.bottom.wall <= 1 then
        return
      end
    end

    if self.can then
      screen:setShake(10)

      state.assets.wallSound:stop()
      state.assets.wallSound:play()

      self.can = false
      wall.shrinkStep = 1
      wall.wall = wall.wall + 1
      local pos = {
        x = wall.body:getX(),
        y = wall.body:getY()
      }
      flux.to(wall, tweenTime, {shrinkStep = 0}):oncomplete(function() self.can = true end):ease("expoout")
      local function tweenUpdate()
        local dx, dy = pos.x - wall.body:getX(), pos.y - wall.body:getY()
        wall.body:setPosition(pos.x, pos.y)
        for i, entity in ipairs(state.entities) do
          if side == "right" or side == "left" then
            if math.abs(entity.body:getX() - pos.x) < 8 then
              entity.body:setX(entity.body:getX() + dx)
            end
          end
          if side == "top" or side == "bottom" then
            if math.abs(entity.body:getY() - pos.y) < 8 then
              entity.body:setY(entity.body:getY() + dy)
            end
          end
        end
      end
      if side == "left" then
        flux.to(pos, tweenTime, {x = pos.x+16 }):onupdate(tweenUpdate):ease("expoout")
      elseif side == "right" then
        flux.to(pos, tweenTime, {x = pos.x-16 }):onupdate(tweenUpdate):ease("expoout")
      elseif side == "top" then
        flux.to(pos, tweenTime, {y = pos.y+16 }):onupdate(tweenUpdate):ease("expoout")
      elseif side == "bottom" then
        flux.to(pos, tweenTime, {y = pos.y-16 }):onupdate(tweenUpdate):ease("expoout")
      end
    end
  end

  function state:expandWall(side)
    local wall = state[side]
    if wall.wall <= 0 then
      return
    end
    if self.can then
      screen:setShake(10)

      state.assets.wallSound:stop()
      state.assets.wallSound:play()

      self.can = false
      wall.expandStep = -1
      wall.wall = wall.wall - 1
      flux.to(wall, tweenTime, {expandStep = 0}):oncomplete(function() self.can = true end):ease("expoout")
      local pos = {
        x = wall.body:getX(),
        y = wall.body:getY()
      }
      local function tweenUpdate()
        local dx, dy = pos.x - wall.body:getX(), pos.y - wall.body:getY()
        wall.body:setPosition(pos.x, pos.y)
      end

      if side == "left" then
        flux.to(pos, tweenTime, {x = pos.x-16 }):onupdate(tweenUpdate):ease("expoout")
      elseif side == "right" then
        flux.to(pos, tweenTime, {x = pos.x+16 }):onupdate(tweenUpdate):ease("expoout")
      elseif side == "top" then
        flux.to(pos, tweenTime, {y = pos.y-16 }):onupdate(tweenUpdate):ease("expoout")
      elseif side == "bottom" then
        flux.to(pos, tweenTime, {y = pos.y+16 }):onupdate(tweenUpdate):ease("expoout")
      end
    end
  end

  function state:quit()
    state.assets.music:stop()
  end

  return state
end

return mainstate
