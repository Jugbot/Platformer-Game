local Room = {}

local gate = {
  dir='N',
  offset=0,
  size=1
}

local ConnectionTable = {}

Room.gates = {}

local function loadMap(path)
  local c, n = love.filesystem.read(path)
  local f = csv.openstring(c)
  map = {}
  for fields in f:lines() do
    for i=1, #fields do
      fields[i] = tonumber(fields[i])
    end
    table.insert(map, fields)
  end
  return map
end

function Room:new(path)
  local o = {}
  setmetatable(o, self)
  self.__index = self
  o.map = loadMap(path)
  return o
end


function Room:draw(off_x, off_y)
  for j=1, #self.map do
    for i=1, #self.map[j] do
      local n = self.map[j][i]
      if n ~= -1 then
        love.graphics.draw(atlas_image, quads[n], off_x + i - 0.5, off_y + j - 0.5)
      end
    end
  end
end

function Room:create(world, off_x, off_y)
  local function makeTile(x, y, id, bb, sensor)
    if not sensor then sensor = false end
    if not bb then bb = {1, 1} end
    local b = love.physics.newBody(world, off_x + x, off_y + y, "static")
    local s = love.physics.newRectangleShape(bb)
    local f = love.physics.newFixture(b, s)
    f:setSensor(sensor)
    f:setUserData(id)
    table.insert(self.fixtures, f)
    return f
  end
  
  local function makePlayer(x, y)
    table.insert(self.spawn_points, {x=x, y=y})
  end 
  
  for j=1, #self.map do
    for i=1, #self.map[j] do
      local v = self.map[j][i]
      if v == 8 or v == 9 or v == 16 or v == 24 then
        makeTile(i, j, "terrain")
      elseif v == 3 or v == 4 or v == 12 or v == 13 then
        makeTile(i, j, "hazard", {1, 1}, true)
      elseif v == 10 then
        makeTile(i, j, "goal", {1, 1}, true)
      elseif v == 2 then
        makeTile(i, j, "bouncepad", {0, 0.25, 1, 0.5})
      elseif v == 56 then
        makePlayer(i, j)
        self.map[j][i] = -1
      elseif v == 48 then
        makeEnemy(i, j)
        self.map[j][i] = -1
      end
    end
  end
end

function Room:destroy()

end

function Room:generate()

end

return Room