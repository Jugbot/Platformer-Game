local Room = {}

Room.gateLookup = {
  ['N']={},
  ['E']={},
  ['S']={},
  ['W']={}
}

function Room:loadMap(path)
  local c, n = love.filesystem.read(path)
  local f = csv.openstring(c)
  -- parse file
  local map = {}
  for fields in f:lines() do
    for i=1, #fields do
      fields[i] = tonumber(fields[i])
    end
    table.insert(map, fields)
  end

  -- gate marker parser
  local function makeGate(dir, x, y)
    local n = map[y][x]
    if dir == 'N' or dir == 'S' then
      for i=x, #map[1] do
        local isGate = (map[y][i] == n)
        map[y][i] = -1 
        if not isGate or i == #map[y] then
          return { -- gate
            dir=dir,
            x=x,
            y=y,
            size=i-x
          }
        end
      end
    end
    
    if dir == 'E' or dir == 'W' then
      for j=y, #map do
        local isGate = (map[j][x] == n)
        map[j][x] = -1 
        if not isGate or j == #map then
          return { -- gate
            dir=dir,
            x=x,
            y=y,
            size=j-y
          }
        end
      end
    end
  end

  -- process special tiles
  for j=1, #map do
    for i=1, #map[j] do
      local v = map[j][i]
      if v == 56 then
        table.insert(self.spawn_points, {x=i, y=j})
        map[j][i] = -1
      elseif v == 48 then
        map[j][i] = -1
      elseif v == 46 then
        table.insert(self.gates, makeGate('N', i, j))
      elseif v == 55 then
        table.insert(self.gates, makeGate('E', i, j))
      elseif v == 64 then
        table.insert(self.gates, makeGate('S', i, j))
      elseif v == 53 then
        table.insert(self.gates, makeGate('W', i, j))
      end
    end
  end

  for _, gate in ipairs(self.gates) do
    self.gateLookup[gate.dir][gate.size] = self.gateLookup[gate.dir][gate.size] or {}
    table.insert(self.gateLookup[gate.dir][gate.size], self)
  end

  self.map = map
end

function Room:new(path)
  local o = {
    gates = {},
    fixtures = {},
    spawn_points = {},
    map = nil
  }
  setmetatable(o, self)
  self.__index = self
  o:loadMap(path)
  return o
end

function Room:getGates(dir, size)
  local results = {}
  for _, gate in ipairs(self.gates) do
    if gate.dir == dir and gate.size == size then
      table.insert(results, gate)
    end
  end
  return results
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
    local s = love.physics.newRectangleShape(unpack(bb))
    local f = love.physics.newFixture(b, s)
    f:setSensor(sensor)
    f:setUserData(id)
    table.insert(self.fixtures, f)
    return f
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
      end
    end
  end

  return makeTile(#map[1]/2, #map/2, "bounds", {#map[1], #map}, true) -- room bounds
end

function Room:destroy()

end

function Room:generate()

end

return Room