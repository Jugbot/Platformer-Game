Camera = require "lib.camera"
Gamestate = require "lib.gamestate"
vector = require "lib.vector-light"
tiny = require "lib.tiny"
inspect = require "lib.inspect"
tween = require "lib.tween"
csv = require "lib.csv"
deque = require 'lib.deque'

require "constants"
local game = require "gamestates/game"
LEVELS = {"m1", "m4", "m3", "m2"}

mainFont = love.graphics.newFont("assets/NovaMono-Regular.ttf", 20) 
camera = Camera(0, 0)

function math.clamp(low, n, high) return math.min(math.max(n, low), high) end

function loadAssets()
  shader = love.graphics.newShader("shader.glsl")
  breakSound = love.audio.newSource("assets/audio/270310__littlerobotsoundfactory__explosion-04.wav", "static")
  player_image = love.graphics.newImage("assets/player.png")
  atlas_image = love.graphics.newImage("assets/atlas.png")
  background_image = love.graphics.newImage("assets/background.png")
  local w, h = love.graphics.getDimensions()
  screen_quad = love.graphics.newQuad(0, 0, w, h, w, h)
  entity_quad = love.graphics.newQuad(0, 0, 0.5, 1, 0.5, 1)
  quads = {}
  local px, py
  local tx, ty = atlas_image:getWidth() / TILE_SIZE, atlas_image:getHeight() / TILE_SIZE
  for py = 0, ty do
    for px = 0, tx do
      print(px+py*tx)
      quads[px+py*tx] = love.graphics.newQuad(px, py, 1, 1, atlas_image:getWidth()/TILE_SIZE, atlas_image:getHeight()/TILE_SIZE)
    end
  end
end

function love.load()
  print(_VERSION)
  camera:zoomTo(30)
  love.graphics.setFont(mainFont)
  love.graphics.setLineWidth(0.1)
  love.graphics.setDefaultFilter("nearest")
  love.physics.setMeter(2)
  loadAssets()
  Gamestate.registerEvents()
  Gamestate.switch(game, LEVELS[#LEVELS])
end

