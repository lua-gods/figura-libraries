local mod = {}
---@type {model: ModelPart, rotMat: Matrix3, len: number, yaw: number}[]
local arms = {}

local myUuid = avatar:getUUID()

---uuid of person to hold hands with
---@type string?
mod.target = nil
local lastArm = nil

---sets person to hold hands with
---@param target Entity.any|string|nil
function mod.setTarget(target)
   if not target then
      mod.target = nil
      avatar:store('simpleHandHolding.target', nil)
      avatar:store('simpleHandHolding.pos', nil)
      avatar:store('simpleHandHolding.len', nil)
      return
   end
   if type(target) == "string" then
      mod.target = target
   else
      mod.target = target:getUUID()
   end
   avatar:store('simpleHandHolding.target', mod.target)
end

---snippet by @kitcat962
---@param dirVec Vector3
---@return Vector3
local function directionToEuler(dirVec)
   local yaw = math.atan2(dirVec.x, dirVec.z)
   local pitch = math.atan2(dirVec.y, dirVec.xz:length())
   return vec(-math.deg(pitch), math.deg(yaw), 0)
end


---snippet by @PenguinEncounter
---@param mat Matrix4|Matrix3
---@return Vector3
local function mat2eulerZYX(mat)
	---@type number, number, number
	local x, y, z
	local query = mat.v31 -- are we in Gimbal Lock?
	if math.abs(query) < 0.9999 then
		y = math.asin(-mat.v31)
		z = math.atan2(mat.v21, mat.v11)
		x = math.atan2(mat.v32, mat.v33)
	elseif query < 0 then -- approx -1, gimbal lock
		y = math.pi / 2
		z = -math.atan2(-mat.v23, mat.v22)
		x = 0
	else -- approx 1, gimbal lock
		y = -math.pi / 2
		z = math.atan2(-mat.v23, mat.v22)
		x = 0
	end
	return vec(x, y, z):toDeg()
end

---adds new arm that you can hand holds with
---@param model ModelPart
---@param offset Vector3
---@param yaw number?
function mod.addArm(model, offset, yaw)
   local rotMat = matrices.mat3()
   local rot = directionToEuler(offset)
   rotMat:rotateX(rot.x - 90)
   rotMat:rotateY(rot.y)

   table.insert(arms, {
      model = model,
      rotMat = rotMat,
      yaw = yaw or 180,
      len = offset:length()
   })
end

---@param pos1 Vector3
---@param pos2 Vector3
---@param r number
---@param r2 number
---@return Vector3
local function sphereIntersectionLowest(pos1, pos2, r, r2)
   local offset = pos2 - pos1
   local d = offset:length()
   local dir = offset:normalize()
   local rot = directionToEuler(dir)

   if d >= r + r2 then
      return pos2 - dir * r2
   end

   local x = (d ^ 2 - r ^ 2 + r2 ^ 2) / (2 * d)
   local a = math.sqrt(4 * d ^ 2 * r2 ^ 2 - (d ^ 2 - r ^ 2 + r2 ^ 2) ^ 2) / (2 * d)

   return pos2 - dir * x - vec(0, a, 0) * matrices.rotation3(rot.x, rot.y, 0)
end


function events.render(delta)
   if #arms == 0 then
      return
   end

   local isHoldingHands = false

   local targetArmPos = nil
   local targetArmLength = nil

   if mod.target then
      local entity = world.getEntity(mod.target)
      if entity then
         if entity:getVariable('simpleHandHolding.target') == myUuid then
            isHoldingHands = true
            local posPacked = entity:getVariable('simpleHandHolding.pos')
            local len = entity:getVariable('simpleHandHolding.len')
            if type(posPacked) == "table" and type(posPacked[1]) == "number" and
               type(posPacked[2]) == "number" and type(posPacked[3]) == "number" and type(len) == "number" then
               targetArmPos = vec(posPacked[1], posPacked[2], posPacked[3])
               targetArmLength = len
            else
               targetArmPos = entity:getPos() + vec(0, 1, 0)
               targetArmLength = 0.7
            end
         end
      end
   end

   if not isHoldingHands then
      avatar:store('simpleHandHolding.pos', nil)
      avatar:store('simpleHandHolding.len', nil)
      if lastArm then
         lastArm.model:setOffsetRot()
         lastArm = nil
      end
      return
   end
   local closestArm = arms[1]
   local dist = math.huge
   for _, arm in pairs(arms) do
      local pos = arm.model:partToWorldMatrix():apply()
      local myDist = (targetArmPos - pos):length()
      if myDist < dist then
         dist = myDist
         closestArm = arm
      end
   end
   if closestArm ~= lastArm then
      if lastArm then
         lastArm.model:setOffsetRot()
      end
      lastArm = closestArm
   end
   local model = closestArm.model
   local toWorld = model:partToWorldMatrix()
   local modelScale = vec(
      toWorld.c1.xyz:length(),
      toWorld.c2.xyz:length(),
      toWorld.c3.xyz:length()
   )
	local rotMat = toWorld:deaugmented():scale(vec(1, 1, 1) / modelScale)
	local myLen = closestArm.len * (modelScale.x + modelScale.y + modelScale.z) / 3
	local pos = toWorld:apply()
	
	avatar:store('simpleHandHolding.pos', {pos.x, pos.y, pos.z})
	avatar:store('simpleHandHolding.len', myLen)

   if not targetArmLength then
      return
   end

   local targetPos = sphereIntersectionLowest(pos, targetArmPos, myLen, targetArmLength)

   local rot = directionToEuler(targetPos - pos)

   rotMat:rotateY(-rot.y)
   rotMat:rotateX(-rot.x + 90)
   rotMat:rotateY(closestArm.yaw)

   rotMat:multiply(closestArm.rotMat)

   rotMat:invert()
   rotMat:rotate(model:getOffsetRot())

   local finalRot = mat2eulerZYX(rotMat)
   if finalRot.x ~= finalRot.x or finalRot.y ~= finalRot.y or finalRot.z ~= finalRot.z then
      finalRot = vec(0, 0, 0)
   end
   model:setOffsetRot(finalRot)
end

return mod