
local Room = require "room"

local RoomNode = {}

RoomNode.all = {}

function RoomNode:new(world, x, y, room, from_room, to_gate)
  assert(not (from_room and not to_gate), "need to specify connection")
  local o = {
    generated = false
  }
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
  o.bounds:setUserData(o)
  table.insert(self.all, o)
  return o
end

function RoomNode:draw()
  self.room:draw(self.position.x, self.position.y)
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
        table.insert(stack, other_node)
      end
    end
    -- return or try again
    if ret then return ret else return dfs() end
  end

  return dfs
end

function RoomNode:intersects(tlx, tly, brx, bry)
  tlx2 = self.position.x
  tly2 = self.position.y
  brx2 = self.position.x + self.room:width()
  bry2 = self.position.y + self.room:height()
  tlx3 = math.max(tlx, tlx2)
  tly3 = math.max(tly, tly2)
  brx3 = math.min(brx, brx2)
  bry3 = math.min(bry, bry2)
  
end

local function weigthed_shuffle(items)
  local shuffle_vals = {}
  -- https://softwareengineering.stackexchange.com/questions/233541/how-to-implement-a-weighted-shuffle
  local function shuffle_val(item)
    return -math.pow(math.random(), (1.0 / item:weight()))
  end
  for i=1, #items do
    shuffle_vals[items[i]] = shuffle_val(items[i]) 
  end
  local order = table.sort(items, function (a, b) 
    return shuffle_vals[a] < shuffle_vals[b]
  end)
end

function RoomNode:plug()
  ONE_BLOCK_ROOM = ONE_BLOCK_ROOM or Room:new("assets/rooms/special/block.csv")

  local function plugGate(gate)
    local px, py = gate.x, gate.y
    if dir == 'S' then py = y + 1 end
    if dir == 'E' then px = x + 1 end
    for i=1, gate.size do
      if dir == 'N' or dir == 'S' then
        print("plug")
        RoomNode:new(self.world, px + i - 1, py, ONE_BLOCK_ROOM)
      elseif dir == 'E' or dir == 'W' then
        RoomNode:new(self.world, px, py + i - 1, ONE_BLOCK_ROOM)
      end
    end
  end

  for _, gate in ipairs(self.room.gates) do
    plugGate(gate)
  end
end

function RoomNode:generate(blackList)
  if self.generated then return end
  self.generated = true
  blackList = blackList or {}

  local opposite = {
    ['N']='S',
    ['E']='W',
    ['S']='N',
    ['W']='E'
  }

  local function openGate(gate)
    -- print("starting search on gate ", inspect(gate))
    -- dont open connected gates
    if self.gates[gate] then return end
    -- get corresponding gate
    local target_dir = opposite[gate.dir]
    local candidates = self.room.gateLookup[target_dir][gate.size] or {}
    weigthed_shuffle(candidates)
    -- print('\tcandidates: ', #self.room.gateLookup)
    for _, candidate_room in ipairs(candidates) do
      if not blackList[candidate_room.name] then
        local candidate_gates = candidate_room:getGates(target_dir, gate.size)
        -- print('\t\tpotential gates', #candidate_gates)
        for i, candidate_gate in ipairs(candidate_gates) do
          local off_x = gate.x - candidate_gate.x
          local off_y = gate.y - candidate_gate.y 
          local px = self.position.x + off_x
          local py = self.position.y + off_y
          local invalid = false
          for _, node in ipairs(self.all) do
            if node ~= self then
              invalid = node.room:intersects(candidate_room, px - node.position.x, py - node.position.y)
              -- print("ok", not invalid)
              if invalid then break end
            end
          end

          if not invalid then
            print("adding ", candidate_room.name, px, py)
            local r = RoomNode:new(self.world, px, py, candidate_room, self.room, candidate_gate)
            return
          end
        end
      end
    end
  end

  -- print("generating from " .. self.room.name)
  for _, gate in ipairs(self.room.gates) do
    openGate(gate)
  end
end

if not pcall(debug.getlocal, 4, 1) then
  print("running tests")
  local Room = require "room"
  local r1 = Room:new("assets/rooms/room1.csv")
  local r2 = Room:new("assets/rooms/plugE.csv")
  r1:intersects(r2, 0, 0)
end

return RoomNode