
local RoomNode = {}

function RoomNode:new(x, y, room_from, room)
  local o = {}
  setmetatable(o, self)
  self.__index = self
  return o
end

function RoomNode:generate()
  for _, connection in ipairs(room) do

  end
end

return RoomNode