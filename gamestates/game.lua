local game = {}

local map = {}
local fixtures = {}
local player = nil
local spawn_points = {}

-- DELETE
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

local function newMap(map)
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
end
-- END DELETE

local function reset()
  player:getBody():setPosition(spawn_points[player].x, spawn_points[player].y)
  player:getBody():setLinearVelocity(0, 0)
end

local function killPlayer()
  reset()
end

function game:init()


end

function game:enter(previous, mapname)
  LEVELS[#LEVELS] = nil
  world = love.physics.newWorld(0, GRAVITY * love.physics.getMeter(), true)
  -- DELETE
  local c, n = love.filesystem.read("assets/" .. mapname .. ".csv")
  local f = csv.openstring(c)
  map = {}
  fixtures = {}
  for fields in f:lines() do
    table.insert(map, fields)
  end
  -- physics objects
  newMap(map)
  -- for good measure
  reset()
  -- END DELETE
end

function game:leave()
  world:destroy()
end

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
  
  -- check collisions below player
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

  -- player controls
  if love.keyboard.isDown("s") then
    pbody:applyForce(0, GRAVITY / 4)
  end
  if love.keyboard.isDown("d") then --press the right arrow key to push the ball to the right
    pbody:applyForce(1, 0)
  elseif love.keyboard.isDown("a") then --press the left arrow key to push the ball to the left
    pbody:applyForce(-1, 0)
  end

  -- generic collisions
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
  camera:attach()
    -- background
    love.graphics.setShader(shader)
    local origin = {love.graphics.transformPoint(-0.5, -0.5)}
    local meter = {love.graphics.transformPoint(0.5, 0.5)}
    shader:send("origin", origin)
    shader:send("meter", meter)
    love.graphics.draw(background_image, screen_quad, -love.graphics.getWidth()/2, -love.graphics.getHeight()/2)
    love.graphics.setShader()
    -- love.graphics.draw(background_image, screen_quad, 0, 0)
    -- objects
    local px, py = player:getBody():getPosition()
    love.graphics.draw(player_image, entity_quad, px - 0.25, py - 0.5)
    -- DELETE
    local rowIndex
    for rowIndex=1, #map do
      local row = map[rowIndex]
      for columnIndex=1, #row do
        local n = row[columnIndex]
        if n ~= -1 then
          love.graphics.draw(atlas_image, quads[n], (columnIndex)-0.5, (rowIndex)-0.5)
        end
      end
    end
    -- END DELETE
    
    -- debug physics
    if DEBUG then
      for _, f in ipairs(fixtures) do
        renderRect("line", f)
      end
    end
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