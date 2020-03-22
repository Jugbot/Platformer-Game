
local RoomNode = {}

function RoomNode:new(world, x, y, room, from_room, to_gate)
  assert(not (from_room and not to_gate), "need to specify connection")
  local o = {}
  setmetatable(o, self)
  self.__index = self
  o.gates = {}
  o.world = world
  o.room = room
  o.position = {x=x, y=y}
  for _, gate in ipairs(room.gates) do
    o.gates[gate] = nil
  end
  if from_room then
    o.gates[to_gate] = from_room
  end
  o.bounds = room:create(world, x, y)
  return o
end

function RoomNode:draw()
  self.room.draw(self.position.x, self.position.y)
end

function RoomNode:walk()
  local visited = {}
  local stack = { self }

  local function dfs()
    -- base case
    if #stack == 0 then return nil end
    -- pop stack
    local node = table.remove(stack)
    local ret = nil
    -- mark for return if new
    if not visited[node] then
      visited[node] = true
      ret = node
    end
    -- add children if new
    for gate, other_node in pairs(node.gates) do
      if other_node and not visited[other_node] then
        table.insert(other_node)
      end
    end
    -- return or try again
    if ret then return ret else return dfs() end
  end

  return dfs
end

function RoomNode:intersects(tlx, tly, brx, bry)
  tlx2, tly2, brx2, bry2 = self.bounds:getBoundingBox()
  return false -- TODO
end

function RoomNode:generate()
  local opposite = {
    ['N']='S',
    ['E']='W',
    ['S']='N',
    ['W']='E'
  }

  for _, gate in ipairs(self.room.gates) do
    local lookup = self.room.gateLookup
    local dir = opposite[gate.dir]
    local candidates = lookup[dir][gate.size] or {}
    local useable = {}
    for _, candidate_room in ipairs(candidates) do
      local candidate_gates = candidate_room:getGates(dir, gate.size)
      for _, candidate_gate in ipairs(candidate_gates) do
        local tlx = self.position.x - candidate_gate.x
        local tly = self.position.y - candidate_gate.y 
        local brx = self.position.x - candidate_gate.x + w
        local bry = self.position.y - candidate_gate.y + h
        local invalid = false
        for node in self:walk() do
          invalid = node:intersects(tlx, tly, brx, bry)
          if invalid then break end
        end

        if not invalid then
          RoomNode:new(self.world, tlx, tly, candidate_room, self.room, candidate_gate)
          return
        end
      end
    end
  end
end

return RoomNode