local RoomNode = require "roomnode"

local game = {}

local fixtures = {}
local player = nil
local spawn_points = {}

local function makePlayer(x, y)
  local b = love.physics.newBody(world, x, y, "dynamic")
  local s = love.physics.newRectangleShape(0.5, 1)
  local f = love.physics.newFixture(b, s)
  f:setUserData("player")
  player = f
end 

local function reset()
  player:getBody():setPosition(room.spawn_points[1].x, room.spawn_points[1].y)
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
  local Room = require "room"
  room = Room:new("assets/rooms/" .. mapname .. ".csv")
  RoomNode:new(world, 0, 0, room)
  room:create(world, 0, 0)
  local spawn = room.spawn_points[1]
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
    
    room:draw(0,0)

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