local home = {}

function home:enter(previous)
end

function home:update()
  if love.keyboard.isDown("w") then
    Gamestate.switch(game)
  end
end

function home:draw(dt)
  love.graphics.setShader(shader)
  camera:attach()
  local origin = {love.graphics.transformPoint(-0.5, -0.5)}
  local meter = {love.graphics.transformPoint(0.5, 0.5)}
  camera:detach()
  shader:send("origin", origin)
  shader:send("meter", meter)
  love.graphics.draw(background_image, screen_quad, 0, 0)
  love.graphics.setShader()
  love.graphics.draw(splash_image, screen_quad)
end

return home