local game = {}

local map = {}
local fixtures = {}
local player = nil
local spawn_points = {}

local GRAVITY = 9.81

local function reset()
  player:getBody():setPosition(spawn_points[player].x, spawn_points[player].y)
  player:getBody():setLinearVelocity(0, 0)
end

local function killPlayer()
  reset()
end

function game:init()
  player_image = love.graphics.newImage("assets/player.png")
  entity_quad = love.graphics.newQuad(0, 0, 0.5, 1, 0.5, 1)
  local w, h = love.graphics.getDimensions()
  screen_quad = love.graphics.newQuad(0, 0, w, h, w, h)

  atlas_image = love.graphics.newImage("assets/atlas.png")

  shader = love.graphics.newShader("shader.glsl")
end

local function makeTerrain(x, y)
  local b = love.physics.newBody(world, x, y, "static")
  local s = love.physics.newRectangleShape(1, 1)
  local f = love.physics.newFixture(b, s)
  f:setUserData("terrain")
  table.insert(fixtures, f)
end 

local function makeGoal(x, y)
  local b = love.physics.newBody(world, x, y, "static")
  local s = love.physics.newRectangleShape(1, 1)
  local f = love.physics.newFixture(b, s)
  f:setSensor(true)
  f:setUserData("goal")
  table.insert(fixtures, f)
end 

local function makeHazard(x, y)
  local b = love.physics.newBody(world, x, y, "static")
  local s = love.physics.newRectangleShape(1, 1)
  local f = love.physics.newFixture(b, s)
  f:setSensor(true)
  f:setUserData("hazard")
  table.insert(fixtures, f)
end 

local function makeBouncepad(x, y)
  local b = love.physics.newBody(world, x, y, "static")
  local s = love.physics.newRectangleShape(0, 0.25, 1, 0.5)
  local f = love.physics.newFixture(b, s)
  f:setUserData("bouncepad")
  -- f:setRestitution(1.0)
  table.insert(fixtures, f)
end 

local function makePlayer(x, y)
  local b = love.physics.newBody(world, x, y, "dynamic")
  local s = love.physics.newRectangleShape(0.5, 1)
  local f = love.physics.newFixture(b, s)
  f:setUserData("player")
  spawn_points[f] = {x=x, y=y}
  player = f
  table.insert(fixtures, f)
end 

function game:enter(previous, map)
  LEVELS[#LEVELS] = nil
  world = love.physics.newWorld(0, GRAVITY * love.physics.getMeter(), true)
  maptest_image = love.graphics.newImage("assets/" .. map .. ".png")
  local c, n = love.filesystem.read("assets/" .. map .. ".csv")
  local f = csv.openstring(c)
  map = {}
  fixtures = {}
  for fields in f:lines() do
    table.insert(map, fields)
  end
  for j, y in ipairs(map) do
    for i, x in ipairs(y) do
      local v = tonumber(x)
      map[j][i] = v
      if v == 8 or v == 9 or v == 16 or v == 24 then
        makeTerrain(i, j)
      elseif v == 3 or v == 4 or v == 12 or v == 13 then
        makeHazard(i, j)
      elseif v == 10 then
        makeGoal(i, j)
      elseif v == 2 then
        makeBouncepad(i, j)
      elseif v == 56 then
        makePlayer(i, j)
        map[j][i] = -1
      elseif v == 48 then
        makeEnemy(i, j)
        map[j][i] = -1
      end
    end
  end
  
  map_quad = love.graphics.newQuad(0, 0, #map[1], #map, #map[1], #map)
  -- print(inspect(map))
  reset()
end

function game:leave()
  world:destroy()
end

local breakSound = love.audio.newSource("assets/audio/270310__littlerobotsoundfactory__explosion-04.wav", "static")

local SPEED_LIMIT = 100.0

function game:update(dt)
  DEBUG = love.keyboard.isDown("g")
  if love.keyboard.isDown("r") then
    reset()
  -- elseif won() or lost() then
  --   return
  end
  world:update(dt)
  camera:lockPosition(player:getBody():getPosition())

  local pbody = player:getBody()
  pbody:setAngle(0)
  
  local tx, ty = pbody:getWorldPoint(0, 0.5)
  world:queryBoundingBox(tx, ty, tx, ty, function ( fixture )
    if fixture ~= player and not fixture:isSensor() then
      local vx, vy = pbody:getLinearVelocity()
      if fixture:getUserData() == "bouncepad" and (love.keyboard.isDown("w") or love.keyboard.isDown("space")) then 
        pbody:setLinearVelocity(vx, -GRAVITY * 1.5)
      elseif fixture:getUserData() == "bouncepad" then
        pbody:setLinearVelocity(vx, -GRAVITY)
      elseif love.keyboard.isDown("w") or love.keyboard.isDown("space") then
        pbody:setLinearVelocity(vx, -GRAVITY/4*3)
      end
      -- pbody:applyLinearImpulse(0, -0.1)
      return false
    end
    return true
  end)
  if love.keyboard.isDown("s") then
    pbody:applyForce(0, GRAVITY / 4)
  end
  if love.keyboard.isDown("d") then --press the right arrow key to push the ball to the right
    pbody:applyForce(1, 0)
  elseif love.keyboard.isDown("a") then --press the left arrow key to push the ball to the left
    pbody:applyForce(-1, 0)
  end

  for _, contact in ipairs(pbody:getContacts()) do
    if contact:isTouching() then
      local f1, f2 = contact:getFixtures()
      local fixture
      if f1 ~= player then fixture = f1 else fixture = f2 end
      local obj_t = fixture:getUserData()
      if obj_t == "hazard" then
        killPlayer()
      elseif obj_t == "goal" and #LEVELS > 0 then
        Gamestate.switch(game, LEVELS[#LEVELS])
        return
      end
    end
  end
end

local function renderRect(t, fixture) 
  local shape = fixture:getShape()
  local body = fixture:getBody()
  love.graphics.polygon(t, body:getWorldPoints(shape:getPoints()))
end


local red = {1.0, 0.5, 0.5} 
local blue = {0.5, 0.5, 1.0}
local green = {0.5, 1.0, 0.5}
local white = {1.0, 1.0, 1.0}

function game:draw(dt)
  -- objects
  camera:attach()
    local px, py = player:getBody():getPosition()
    love.graphics.draw(maptest_image, map_quad, 0.5, 0.5)
    love.graphics.draw(player_image, entity_quad, px - 0.25, py - 0.5)
    if DEBUG then
      for _, f in ipairs(fixtures) do
        renderRect("line", f)
      end
    end
    -- love.graphics.setShader(shader)
    -- love.graphics.draw(maptest_image, screen_quad, 0, 0)
    -- love.graphics.setShader()
  camera:detach()
  -- text
  -- love.graphics.setColor(white, 0.7)
  -- love.graphics.printf(time, 0, 0, love.graphics.getWidth(), "left")
  -- love.graphics.printf(lives - drops .. " lives", 0, 0, love.graphics.getWidth(), "right")
  -- if won() then
  --   love.graphics.setColor(0,0,0,0.5)
  --   love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
  --   love.graphics.setColor(green, 0.7)
  --   love.graphics.printf("GREAT\nSUCCESS", 0, love.graphics.getHeight()/4, love.graphics.getWidth()/2, "center", 0, 2)
  --   love.graphics.printf("(press 'R')", 0, love.graphics.getHeight()/2, love.graphics.getWidth(), "center")
  -- elseif lost() then
  --   love.graphics.setColor(0,0,0,0.5)
  --   love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
  --   love.graphics.setColor(red, 0.7)
  --   love.graphics.printf("OOPS", 0, love.graphics.getHeight()/4, love.graphics.getWidth()/2, "center", 0, 2)
  --   love.graphics.printf("(press 'R')", 0, love.graphics.getHeight()/2, love.graphics.getWidth(), "center")
  -- end
end

return game