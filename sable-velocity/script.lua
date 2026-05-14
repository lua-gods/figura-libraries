local sabelSubLevelOffset = vec(0, 10000, 0)
---@param pos Vector3
---@return Vector3
local function sableSublevelToWorld(pos)
   local pos1 = pos + sabelSubLevelOffset
   local pos2 = pos - sabelSubLevelOffset
   local _, hitPos1 = raycast:block(pos1, pos1)
   local _, hitPos2 = raycast:block(pos2, pos2)
   return (hitPos1 + hitPos2) * 0.5
end

local playerVel = vec(0, 0, 0)
local oldPos, pos = vec(0, 0, 0), vec(0, 0, 0)
local wasOnSublevel
function events.tick()
   oldPos = pos
   pos = player:getPos() + vec(0, 0.05, 0)
   local _, hitPos = raycast:block(pos, pos - vec(0, 1, 0))
   local hitWorldPos = sableSublevelToWorld(hitPos)
   local dist = math.min((hitWorldPos - pos):length(), 1)
   local onSublevel = (hitPos - pos):length() > 2
   if onSublevel then
      pos = hitPos + vec(0, dist, 0)
   end
   if wasOnSublevel ~= onSublevel then
      oldPos = pos
      wasOnSublevel = onSublevel
   end
   playerVel = pos - oldPos
end
-- patch player:getVelocity
local playerApi = figuraMetatables.PlayerAPI.__index
local getVel = playerApi.getVelocity
function playerApi:getVelocity()
    return player == self and playerVel or getVel(self)
end
