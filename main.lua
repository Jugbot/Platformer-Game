Camera = require "lib.camera"
Gamestate = require "lib.gamestate"
vector = require "lib.vector-light"
tiny = require "lib.tiny"
inspect = require "lib.inspect"
tween = require "lib.tween"
csv = require "lib.csv"
deque = require 'lib.deque'

local game = require "gamestates/game"
LEVELS = {"m2", "m1"}

mainFont = love.graphics.newFont("assets/NovaMono-Regular.ttf", 20) 
camera = Camera(0, 0)

function math.clamp(low, n, high) return math.min(math.max(n, low), high) end

function love.load()
  print(_VERSION)
  camera:zoomTo(30)
  love.graphics.setFont(mainFont)
  love.graphics.setLineWidth(0.1)
  love.graphics.setDefaultFilter("nearest")
  love.physics.setMeter(2)
  Gamestate.registerEvents()
  Gamestate.switch(game, LEVELS[#LEVELS])
end

