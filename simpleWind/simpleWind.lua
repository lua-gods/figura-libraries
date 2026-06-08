local mod = {}

-- config
-- edits player:getVelocity() so it works with libraries that dont support it
-- may cause issues with animation libraries
local editGetVelocity = false

-- code
local windDir = vec(0, 0, 1)
local windStrength = 0
local playerWind = vec(0, 0, 0)

local ignoreGetVelocity = false

local time = world.getTime()

---@param seed number
local function getRandom(seed)
   local v = math.sin(seed * 12.9898) * 43758.5453
   return v - math.floor(v)
end

---@param x number
---@param offset number
---@param isRotation boolean?
local function smoothRandom(x, offset, isRotation)
   local y = math.floor(x) + offset
   local a, b, t = getRandom(y), getRandom(y + 1), x % 1
   t = 3 * t * t - 2 * t * t * t
   if isRotation then
      return math.lerpAngle(a * 360, b * 360, t)
   end
   return math.lerp(a, b, t)
end

---returns wind at specific position
---@param pos Vector3
---@return Vector3
function mod.getWind(pos)
   local min = 0
   local max = 0.25

   local rain = world.getRainGradient() * (world.isThundering() and 1.5 or 1)
   min, max = min + rain * 0.15, max + rain * 0.25

   local height = math.clamp((pos.y - 70) * 0.008, 0, 1)
   min, max = min + height * 0.5, max + height

   local skyLight = world.getSkyLightLevel(pos) / 15
   skyLight = skyLight ^ 3

   min = min * skyLight
   max = max * skyLight

   return windDir * math.lerp(min, max, windStrength)
end

---returns wind where player is
---@param ignoreOverride boolean? # if true and editGetVelocity is set to true, next player:getVelocity() call will not include wind
---@return Vector3
function mod.getPlayerWind(ignoreOverride)
   ignoreGetVelocity = ignoreOverride
   return playerWind
end

if editGetVelocity then
   local function getWind(self)
      if ignoreGetVelocity or self ~= player then
         ignoreGetVelocity = false
         return vec(0, 0, 0)
      end
      return playerWind
   end

   local playerApi = figuraMetatables.PlayerAPI.__index
   if type(playerApi) == "function" then
      ---@param self Player
      ---@return Vector3
      local function getVelocity(self)
         return playerApi(self, "getVelocity")(self) + getWind(self)
      end
      figuraMetatables.PlayerAPI.__index = function(t, i)
         return i == "getVelocity" and getVelocity or playerApi(t, i)
      end
   else
      local getVel = playerApi.getVelocity
      function playerApi:getVelocity()
         return getVel(self) + getWind(self)
      end
   end
end

function events.tick()
   local worldTime = world.getTime()
   time = math.clamp(time - worldTime, -100, 100) + worldTime
   time = math.lerp(time + 1, worldTime, 0.1)

   local windRot = smoothRandom(time / 2400, 0, true) -- 4 minutes
   windRot = windRot + math.cos(time * 0.05) * 10

   local windRad = math.rad(windRot)
   windDir = vec(math.cos(windRad), 0, math.sin(windRad))

   windStrength = smoothRandom(time * 0.05, 0.25)
   windStrength = windStrength * math.lerp(0.25, math.cos(time * 0.2) * 0.5 + 0.5, math.cos(time * 0.05) * 0.25 + 0.75)

   playerWind = mod.getWind(player:getPos():add(0, player:getBoundingBox().y * 0.5))
end

return mod