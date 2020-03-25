local RoomNode = require "roomnode"

local game = {}

local player = nil
local spawn = {}

local function makePlayer(x, y)
  local b = love.physics.newBody(world, x, y, "dynamic")
  local s = love.physics.newRectangleShape(0.5, 0.9)
  local f = love.physics.newFixture(b, s)
  f:setUserData("player")
  player = f
end 

local function reset()
  player:getBody():setPosition(spawn.x, spawn.y)
  player:getBody():setLinearVelocity(0, 0)
end

local function killPlayer()
  reset()
end

local MIN_GOAL_DISTANCE = 10

function game:enter(previous)
  world = love.physics.newWorld(0, GRAVITY * love.physics.getMeter(), true)
  local Room = require "room"
  root = RoomNode:new(world, 0, 0, Room:new("assets/rooms/" .. "start" .. ".csv")) -- FIXME: doing this twice?
  local i = 1
  local blacklist = {["door"]=true}
  while true do
    if i > #root.all then i = i % #root.all end
    local node = root.all[#root.all-i+1]
    if vector.dist(node.position.x, node.position.y, root.position.x, root.position.y) > MIN_GOAL_DISTANCE then 
      blacklist = nil
      if node.room:has(5) then break end
    end
    node:generate(blacklist)
    i = i + 1
  end
  for _, node in ipairs(root.all) do
    node:plug()
  end
  spawn = root.room.spawn_points[1]
  makePlayer(spawn.x, spawn.y)
  reset()
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

  local function jump()
    local vx, vy = pbody:getLinearVelocity()
    pbody:setLinearVelocity(vx, -GRAVITY * 1.5)
  end

  -- check collisions below player
  local tx, ty = pbody:getWorldPoint(0, 0.5)
  world:queryBoundingBox(tx, ty, tx, ty, function ( fixture )
    local obj_t = fixture:getUserData()
    if fixture ~= player and (not fixture:isSensor() or obj_t == "ladder") then
      local vx, vy = pbody:getLinearVelocity()
      if obj_t == "bouncepad" and (love.keyboard.isDown("w") or love.keyboard.isDown("space")) then 
        jump()
      elseif obj_t == "bouncepad" then
        pbody:setLinearVelocity(vx, -GRAVITY)
      elseif love.keyboard.isDown("w") or love.keyboard.isDown("space") then
        pbody:setLinearVelocity(vx, -GRAVITY)
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

  local function ladderControls()
    local vx, vy = 0, 0
    local LADDER_SPEED = 2
    if love.keyboard.isDown("w") then
      vy = vy - LADDER_SPEED
    end
    if love.keyboard.isDown("s") then
      vy = vy + LADDER_SPEED
    end
    if love.keyboard.isDown("d") then --press the right arrow key to push the ball to the right
      vx = vx + LADDER_SPEED
    end
    if love.keyboard.isDown("a") then --press the left arrow key to push the ball to the left
      vx = vx - LADDER_SPEED
    end
    pbody:setLinearVelocity(vx, vy)
  end

  -- special collision events
  for _, contact in ipairs(pbody:getContacts()) do
    if contact:isTouching() then
      local f1, f2 = contact:getFixtures()
      local fixture
      if f1 ~= player then fixture = f1 else fixture = f2 end
      local obj_t = fixture:getUserData()
      if obj_t == "hazard" then
        killPlayer()
      elseif obj_t == "goal" then

      elseif obj_t == "ladder" then
        ladderControls()
      elseif obj_t and obj_t.room then
        -- obj_t:generate()
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
  -- debug graphics
  love.graphics.setWireframe(DEBUG)
  -- background
  love.graphics.setShader(shader)
  camera:attach()
  local origin = {love.graphics.transformPoint(-0.5, -0.5)}
  local meter = {love.graphics.transformPoint(0.5, 0.5)}
  camera:detach()
  shader:send("origin", origin)
  shader:send("meter", meter)
  love.graphics.draw(background_image, screen_quad, 0, 0)
  love.graphics.setShader()
  -- entities and tiles
  camera:attach()
    -- entities
    local px, py = player:getBody():getPosition()
    love.graphics.draw(player_image, entity_quad, px - 0.25, py - 0.5)
    -- tiles
    for i, r in ipairs(root.all) do
      r:draw()
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