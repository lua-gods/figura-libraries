local earsPhysics = {} -- made by Auriafoxgirl
---@class auria.earsPhysics
---@field config auria.earsPhysics.config
---@field leftEar ModelPart
---@field rightEar ModelPart
local ears = {}
local updatingEars = {}
ears.__index = ears
local oldPlayerRot

---creates new ears physics
---@param leftEar ModelPart
---@param rightEar ModelPart
---@return auria.earsPhysics
function earsPhysics.new(leftEar, rightEar)
   -- check types
   if type(leftEar) ~= 'ModelPart' then
      error('bad argument: ModelPart expected, got '..type(leftEar), 2)
   end
   if type(rightEar) ~= 'ModelPart' then
      error('bad argument: ModelPart expected, got '..type(rightEar), 2)
   end
   --
   local obj = setmetatable({}, ears)
   ---@class (partial) auria.earsPhysics.config
   obj.config = { -- default config, please use ears:setConfig to set config, dont edit this table
      ---@type number|Vector3
      velocityStrength = 1, -- velocity strength
      headRotStrength = 0.4, -- how much ears should rotate when head moved up or down

      bounce = 0.2, -- how bouncy ears are
      stiff = 0.3, -- how stiff ears are
      extraMovingStiff = 0.2, -- extra stiff when moving
      movingStiffStrength = 0.25,

      extraAngle = 15, -- rotates ears by this angle when crouching
      ---@type {[any]: boolean}
      useExtraAngle = {}, -- if any of variables in this table is true extraAngle will be used even when not crouching
      ---@type {[any]: number}
      addAngle = {}, -- adds angle to ear rotation

      earsFlick = true, -- set if ears should flick
      flickChance = 400, -- chance of ear flick per tick
      flickDelay = 40, -- minimum delay between ear flicks
      flickStrength = 30, -- how much ears should flick

      rotMin = vec(-12, -10, -4), -- rotation limit
      rotMax = vec(12, 10, 6), -- rotation limit

      headRotMin = -90, -- minimum rotation for head rotation
      headRotMax = 90, -- maximum rotation for head rotation

      extraYRot = 0,
   }
   -- model
   obj.leftEar = leftEar
   obj.rightEar = rightEar
   -- other
   obj.rot = vec(0, 0, 0, 0)
   obj.oldRot = obj.rot
   obj.vel = vec(0, 0, 0, 0)
   obj.flickTime = 0
   -- finish
   updatingEars[obj] = obj
   return obj
end

---merge new config with current config, returns self for chaining
---@param tbl auria.earsPhysics.config
---@return self
function ears:setConfig(tbl)
   for i, v in pairs(tbl) do
      self.config[i] = v
   end
   return self
end

---set if ears should update, returns self for chaining
---@param x boolean
---@return self
function ears:setUpdate(x)
   updatingEars[self] = x and self or nil
   return self
end

---remove ears physics from ears
---@param keepRot? boolean
function ears:remove(keepRot)
   if not keepRot then
      self.leftEar:setOffsetRot()
      self.rightEar:setOffsetRot()
   end
   updatingEars[self] = nil
end

---@overload fun(obj: auria.earsPhysics, playerVel: Vector3, playerRotVel: Vector2, isCrouching: boolean, playerRot: Vector2)
local function tickEars(obj, playerVel, playerRotVel, isCrouching, playerRot)
   -- set oldRot
   obj.oldRot = obj.rot
   -- set target rotation
   local targetRotZW = 0
   if isCrouching then
      targetRotZW = obj.config.extraAngle
   else
      for _, v in pairs(obj.config.useExtraAngle) do
         if v then
            targetRotZW = obj.config.extraAngle
            break
         end
      end
   end
   for _, v in pairs(obj.config.addAngle) do
      targetRotZW = targetRotZW + v
   end
   local targetRot = vec(
      math.clamp(obj.config.headRotStrength * -playerRot.x, obj.config.headRotMin, obj.config.headRotMax),
      0,
      targetRotZW,
      -targetRotZW
   )
   -- player velocity
   playerVel = playerVel * obj.config.velocityStrength * 20
   playerRotVel = playerRotVel * obj.config.velocityStrength
   local clampedVel = vec(
      math.clamp(playerVel.z + playerRotVel.x, obj.config.rotMin.x, obj.config.rotMax.x),
      math.clamp(playerVel.x, obj.config.rotMin.y, obj.config.rotMax.y),
      math.clamp(playerVel.y * 0.25, obj.config.rotMin.z, obj.config.rotMax.z)
   )
   local acc = vec(clampedVel.x, -clampedVel.y * obj.config.extraYRot, -clampedVel.y + clampedVel.z, -clampedVel.y - clampedVel.z)
   -- update velocity and rotation
   local stiff = 1 - math.lerp(
      obj.config.stiff,
      math.min(obj.config.stiff + obj.config.extraMovingStiff, 1),
      (acc * obj.config.movingStiffStrength):applyFunc(math.abs):applyFunc(function(v) return v > 1 and 1 or v end)
   )
   obj.vel = obj.vel * stiff + (targetRot - obj.rot) * obj.config.bounce

   obj.vel = obj.vel + acc

   obj.rot = obj.rot + obj.vel
   -- ears flick
   obj.flickTime = math.max(obj.flickTime - 1, 0)
   obj.flickTime = math.max(obj.flickTime - 1, 0)
   if obj.config.earsFlick and obj.flickTime == 0 and math.random(math.max(obj.config.flickChance, 1)) == 1 then
      obj.flickTime = obj.config.flickDelay
      if math.random() > 0.5 then
         obj.vel.z = obj.vel.z + obj.config.flickStrength
      else
         obj.vel.w = obj.vel.w - obj.config.flickStrength
      end
   end
end

function events.tick()
   if not next(updatingEars) then return end
   -- velocity and stuff
   local playerRot = player:getRot()
   if not oldPlayerRot then
      oldPlayerRot = playerRot
   end
   local playerRotVel = (playerRot - oldPlayerRot) * 0.75
   oldPlayerRot = playerRot
   local playerVel = player:getVelocity()
   playerVel = vectors.rotateAroundAxis(playerRot.y, playerVel, vec(0, 1, 0))
   playerVel = vectors.rotateAroundAxis(-playerRot.x, playerVel, vec(1, 0, 0))
   local isCrouching = player:getPose() == "CROUCHING"
   -- update ears
   for _, obj in pairs(updatingEars) do
      tickEars(obj, playerVel, playerRotVel, isCrouching, playerRot)
   end
end

function events.render(delta)
   for _, obj in pairs(updatingEars) do
      local rot = math.lerp(obj.oldRot, obj.rot, delta)
      obj.leftEar:setOffsetRot(rot.xyz) ---@diagnostic disable-line: undefined-field
      obj.rightEar:setOffsetRot(rot.xyw) ---@diagnostic disable-line: undefined-field
   end
end

return earsPhysics