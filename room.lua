local weights = require "roomweights"

local Room = {}

Room.gateLookup = {
  ['N']={},
  ['E']={},
  ['S']={},
  ['W']={}
}

function Room:weight()
  return weights[self.name] or 1.0
end

function Room:processMap(map)
  -- gate marker parser
  local function makeGate(dir, x, y)
    -- correct placement of gate flags
    local n = map[y][x]
    local px, py = x, y
    if dir == 'S' then py = y - 1 end
    if dir == 'E' then px = x - 1 end
    local gate = {
      dir=dir,
      x=px,
      y=py,
      size=nil
    }
    -- horizontal size
    if dir == 'N' or dir == 'S' then
      local i=x
      while i <= #map[1] do
        if map[y][i] == n then
          map[y][i] = -1 
        else
          break
        end
        i = i + 1
      end
      gate.size=i-x
    end
    -- vertical size
    if dir == 'E' or dir == 'W' then
      local j=y
      while j <= #map do
        if map[j][x] == n then
          map[j][x] = -1 
        else
          break
        end
        j = j + 1
      end
      gate.size=j-y
    end
    assert(gate.size)
    return gate
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
      elseif v == 62 then
        table.insert(self.gates, makeGate('S', i, j))
      elseif v == 53 then
        table.insert(self.gates, makeGate('W', i, j))
      end
      self.content_flags[v] = true
    end
  end

  -- add to class gate lookup library for procedural generation purposes
  for _, gate in ipairs(self.gates) do
    self.gateLookup[gate.dir][gate.size] = self.gateLookup[gate.dir][gate.size] or {}
    table.insert(self.gateLookup[gate.dir][gate.size], self)
  end
end

function Room:loadMap(path)
  assert(love.filesystem.getInfo(path))
  local c, n = love.filesystem.read(path)
  local csv_table = csv.openstring(c)
  -- beware folders with '.' characters *shrug*
  self.name = path:match('[^/]*%f[%.]')
  -- parse file
  local map = {}
  for fields in csv_table:lines() do
    for i=1, #fields do
      fields[i] = tonumber(fields[i])
    end
    table.insert(map, fields)
  end

  self:processMap(map)

  -- set map
  self.map = map
end

function Room:new(path)
  local o = {
    gates = {},
    spawn_points = {},
    map = nil,
    content_flags = {}
  }
  setmetatable(o, self)
  self.__index = self
  o:loadMap(path)
  return o
end

function Room:width()
  return #self.map[1]
end

function Room:height()
  return #self.map
end

function Room.intersects(room_a, room_b, offset_x, offset_y)
  -- aabb room_a
  tlx1 = 0
  tly1 = 0
  brx1 = room_a:width()
  bry1 = room_a:height()
  -- aabb room_b with offset
  tlx2 = offset_x
  tly2 = offset_y
  brx2 = offset_x + room_b:width()
  bry2 = offset_y + room_b:height()
  -- aabb intersection
  tlx3 = math.max(tlx1, tlx2)
  tly3 = math.max(tly1, tly2)
  brx3 = math.min(brx1, brx2)
  bry3 = math.min(bry1, bry2)
  -- compare overlap
  if bry3-tly3 > 2 and brx3-tlx3 > 2 then return true end -- simple
  for j=tly3+1, bry3 do
    for i=tlx3+1, brx3 do
      if (room_a.map[j][i] ~= -1) and (room_b.map[j-offset_y][i-offset_x] ~= -1) then
        return true
      end
    end
  end
  return false
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
      if n > 0 then
        love.graphics.draw(atlas_image, quads[n], off_x + i - 0.5, off_y + j - 0.5)
      end
    end
  end
end

function Room:has(tile_id)
  return self.content_flags[tile_id] or false
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
    self.content_flags[id] = true
    return f
  end
  
  for j=1, #self.map do
    for i=1, #self.map[j] do
      local v = self.map[j][i]
      if v == 9 or v == 16 or v == 18 or v == 19 or v == 20 or v == 27 then
        makeTile(i, j, "terrain")
      elseif v == 8 then
        makeTile(i, j, "terrain", {0, 0.25, 1, 0.5})
      elseif v == 24 then
        makeTile(i, j, "terrain", {0, -0.25, 1, 0.5})
      elseif v == 3 or v == 12 or v == 11 then
        makeTile(i, j, "hazard", {1, 1}, true)
      elseif v == 4 then
        makeTile(i, j, "hazard", {-0.25, 0.25, 0.5, 0.5}, true)
      elseif v == 10 then
        makeTile(i, j, "treasure", {1, 1}, true)
      elseif v == 5 or v == 6 or v == 13 or v == 14 then
        makeTile(i, j, "goal", {1, 1}, true)
      elseif v == 17 then
        makeTile(i, j, "ladder", {1, 1}, true)
      elseif v == 2 then
        makeTile(i, j, "bouncepad", {0, 0.25, 1, 0.5})
      end
    end
  end

  return makeTile(#self.map[1]/2, #self.map/2, "bounds", {#self.map[1], #self.map}, true) -- room bounds
end

function Room:destroy()

end

return Room