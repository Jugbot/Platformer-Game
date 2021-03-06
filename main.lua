Camera = require "lib.camera"
Gamestate = require "lib.gamestate"
vector = require "lib.vector-light"
tiny = require "lib.tiny"
inspect = require "lib.inspect"
tween = require "lib.tween"
csv = require "lib.csv"
deque = require 'lib.deque'

require "constants"
local Room = require "room"
game = require "gamestates/game"
home = require "gamestates/home"

mainFont = love.graphics.newFont("assets/font.ttf", 20) 
camera = Camera(0, 0)

function math.clamp(low, n, high) return math.min(math.max(n, low), high) end

function loadAssets()
  shader = love.graphics.newShader("shader.glsl")
  breakSound = love.audio.newSource("assets/audio/270310__littlerobotsoundfactory__explosion-04.wav", "static")
  splash_image = love.graphics.newImage("assets/splash.png")
  player_image = love.graphics.newImage("assets/player.png")
  atlas_image = love.graphics.newImage("assets/atlas.png")
  background_image = love.graphics.newImage("assets/background.png")
  background_image:setWrap("repeat", "repeat")
  local w, h = love.graphics.getDimensions()
  screen_quad = love.graphics.newQuad(0, 0, w, h, w, h)
  entity_quad = love.graphics.newQuad(0, 0, 0.5, 1, 0.5, 1)
  quads = {}
  local px, py
  local tx, ty = atlas_image:getWidth() / TILE_SIZE, atlas_image:getHeight() / TILE_SIZE
  for py = 0, ty do
    for px = 0, tx do
      quads[px+py*tx] = love.graphics.newQuad(px, py, 1, 1, atlas_image:getWidth()/TILE_SIZE, atlas_image:getHeight()/TILE_SIZE)
    end
  end
end

function loadRooms()
  local files = love.filesystem.getDirectoryItems("assets/rooms")
  local ext = ".csv"

  -- files = {"room5.csv", "plugE.csv"}
  -- Room:new("assets/rooms/" .. "plugN" .. ".csv")
  -- if true then return end

  for _, file in ipairs(files) do
    if file:sub(-#ext) == ext then
      print("loadeding " .. file) 
      local r = Room:new("assets/rooms/" .. file)
      print("loaded " .. r.name) 
    end
  end
end

function love.load()
  print(_VERSION)
  math.randomseed(os.time())
  math.random()
  camera:zoomTo(30)
  love.graphics.setFont(mainFont)
  love.graphics.setLineWidth(0.1)
  love.graphics.setDefaultFilter("nearest")
  love.physics.setMeter(2)
  loadAssets()
  loadRooms()
  Gamestate.registerEvents()
  Gamestate.switch(home, game)
end

function love.resize(w, h)
  screen_quad = love.graphics.newQuad(0, 0, w, h, w, h)
end

