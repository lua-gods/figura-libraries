local lib = {}
local tails = {} ---@type auria.trail_tail[]
---@class auria.trail_tail
---@field startPos Vector3
---@field oldDir Vector3
---@field points Vector3[]
---@field oldPoints Vector3[]
---@field distances number[]
---@field startDist number[]
---@field vels Vector3[]
---@field modelScale number
---@field models number
---@field posFunc fun(): pos: Vector3?, dir: Vector3?
---@field config {stiff: number, bounce: number, floorFriction: number, gravity: Vector3, maxDist: number, maxAngle: number, partToWorldDelay: number, physicsStrength: number}
local trailingTail = {}

-- from figura code snippets
---@param dirVec Vector3
---@return Vector3
local function directionToEular(dirVec)
   local yaw = math.atan2(dirVec.x, dirVec.z)
   local pitch = math.atan2(dirVec.y, dirVec.xz:length())
   return vec(-math.deg(pitch), math.deg(yaw), 0)
end

---creates new trailing tail
---@param tailModel ModelPart|ModelPart[] # all modelparts will be parented to world
---@return auria.trail_tail
function lib.new(tailModel)
   local tail = {}
   tail.config = {
      bounce = 0.8,
      stiff = 0.5,
      floorFriction = 0.2,
      gravity = vec(0, -0.08, 0),
      maxDist = 1.2,
      maxAngle = 30,
      partToWorldDelay = 0.75,
      physicsStrength = 1
   }
   -- find model parts
   local modelList = tailModel
   if type(tailModel) ~= 'table' then
      modelList = {}
      local model = tailModel
      local name, n = model:getName():match('^(.-)(-?%d*)$')
      n = tonumber(n) or 1
      while model do
         n = n + 1
         table.insert(modelList, model)
         model = model[name..n]
      end
   end
   tail.models = modelList
   -- start part
   local startModel = modelList[1]:getParent():newPart(modelList[1]:getName()..'start')
   startModel:setPivot(modelList[1]:getPivot())
   for _, v in ipairs(modelList) do
      startModel:addChild(v:remove())
   end
   tail.points = {}
   tail.distances = {}
   tail.startPos = vec(0, 0, 0)
   tail.modelScale = math.playerScale
   -- get distances
   local pivotOffsets = {}
   do
      local pivot = modelList[1]:getPivot()
      local offset = vec(0, 0, 0)
      table.insert(pivotOffsets, pivot)
      for i = 2, #modelList do
         local newPivot = modelList[i]:getPivot()
         local dist = (newPivot - pivot):length()
         offset = offset - newPivot + pivot
         pivot = newPivot
         table.insert(pivotOffsets, pivot + offset)
         table.insert(tail.distances, dist / 16)
      end
   end
   table.insert(tail.distances, tail.distances[#tail.distances])
   -- generate data for points
   tail.vels = {}
   tail.points[0] = vec(0, 0, 0)
   tail.oldPoints = {[0] = vec(0, 0, 0)}
   tail.oldDir = vec(0, 0, 1)
   tail.startDist = {}
   for i = 1, #tail.distances do
      tail.vels[i] = vec(0, 0, 0)
      tail.points[i] = vec(0, 0, 0)
      tail.oldPoints[i] = vec(0, 0, 0)
      tail.startDist[i] = (i - 1) / (#modelList - 1)
   end
   -- render
   local tailDir = (modelList[2]:getPivot() - modelList[1]:getPivot()):normalize()
   startModel.midRender = function(delta)
      local toWorld = startModel:partToWorldMatrix()
      if toWorld.v11 ~= toWorld.v11 then -- NaN
         return
      end
      tail.startPos = toWorld:apply()
      tail.oldDir = toWorld:applyDir(tailDir):normalize()

      local modelScale = vec(
         toWorld.c1.xyz:length(),
         toWorld.c2.xyz:length(),
         toWorld.c3.xyz:length()
      )
      local modelWorldScale = (modelScale.x + modelScale.y + modelScale.z) / 3 * 16
      tail.modelScale = modelWorldScale
      
      local worldRotMat = toWorld:deaugmented():augmented()
      local rotMat = matrices.mat3()
      local fromWorld = toWorld:inverted()
      local animMat = matrices.mat4()
      local offset = tail.startPos - math.lerp(tail.oldPoints[0], tail.points[0], delta)
      local pos = math.lerp(tail.oldPoints[0], tail.points[0], delta)
      local renderPos = pos
      local tailStartDir = tail.oldDir
      local physicsStrength = tail.config.physicsStrength
      local partToWorldDelay = tail.config.partToWorldDelay * physicsStrength
      for i = 1, #modelList do
         local model = modelList[i]
         local nextPos = math.lerp(tail.oldPoints[i], tail.points[i], delta)
         local dir = math.lerp(tailStartDir, (nextPos - pos):normalize(), tail.config.physicsStrength):normalize() --[[@as Vector3]]
         if dir:lengthSquared() < 0.1 then dir = vec(0, 0, 1) end -- this one case when dir can be 0 0 0
         -- animation
         local myAnimMat = matrices.mat4()
         myAnimMat = worldRotMat:inverted() * myAnimMat
         myAnimMat:rotate(model:getAnimRot())
         myAnimMat = worldRotMat * myAnimMat
         animMat = animMat * myAnimMat
         -- dir
         dir = animMat:applyDir(dir)
         dir = dir:normalize()
         -- rotation
         rotMat:rightMultiply(matrices.rotation3(directionToEular(rotMat:inverted() * dir)))
         -- all matrix stuff
         local mat = matrices.mat4()
         mat:translate(-model:getPivot())
         mat:multiply(rotMat:augmented())
         mat:scale(modelScale)
         mat:translate(renderPos)
         mat:translate(offset * ( 1 - tail.startDist[i] * partToWorldDelay))
         mat = fromWorld * mat
         mat:translate(pivotOffsets[i])
         modelList[i]:setMatrix(mat)
         -- store for next part
         renderPos = renderPos + dir * tail.distances[i] * modelWorldScale
         pos = nextPos
      end
   end

   -- add tail and return
   local id = #tails + 1
   tails[id] = tail
   return tail
end

---@overload fun(Pos: Vector3): Vector3?
local function isPointInWall(pos)
   local block = world.getBlockState(pos)
   local p = pos - block:getPos()
   for _, col in pairs(block:getCollisionShape()) do
      if p >= col[1] and p <= col[2] then
         return p - (col[1] + col[2]) * 0.5
      end
   end
end

---@overload fun(pos: Vector3, newPos: Vector3): Vector3
local function movePointWithCollision(pos, newPos)
   for axis = 1, 3 do
      local targetPos = pos:copy()
      targetPos[axis] = newPos[axis]
      local _, hitPos = raycast:block(pos, targetPos)
      local offset = hitPos - pos
      pos = pos + offset:clamped(0, math.max(offset:length() - 0.001, 0))
   end
   local push = isPointInWall(pos)
   if push then
      pos = pos + push:normalize() * 0.01
   end
   return pos
end

---@overload fun(tail: auria.trail_tail)
local function tickTail(tail)
   for i, v in pairs(tail.points) do
      tail.oldPoints[i] = v
   end
   
   tail.points[0] = tail.startPos
   local oldDir = tail.oldDir
   for i, pos in ipairs(tail.points) do
      local previous = tail.points[i - 1]
      local dist = tail.distances[i] * tail.modelScale
      local maxDist = tail.distances[i] * tail.config.maxDist
      local offset = pos - previous
      local offsetLength = offset:length()
      local dir = offsetLength > 0.01 and offset / offsetLength or vec(0, 0, 1) -- prevent normalized vector being length 0 when its vec(0, 0, 0)
      -- clamp angle
      local targetDir = dir
      local angle = math.deg(math.acos(math.clamp(dir:dot(oldDir), -1, 1)))
      local maxAngle = tail.config.maxAngle
      if angle > maxAngle then -- clamp angle
         local rotAxis = oldDir:crossed(dir)
         if rotAxis:lengthSquared() > 0.001 then
            targetDir = vectors.rotateAroundAxis(math.min(angle, maxAngle) - angle, dir, rotAxis):normalize()
         end
      end
      local targetPos = previous + targetDir * dist
      -- clamp distance
      offsetLength = math.min(offsetLength, maxDist)
      pos = previous + dir * offsetLength
      -- pull or push to desired length
      local pullPushStrength = offsetLength / dist
      pullPushStrength = math.abs(pullPushStrength - 1)
      pullPushStrength = pullPushStrength + math.max(angle - maxAngle, 0) * 0.1
      pullPushStrength = math.min(pullPushStrength, 1)

      local targetOffset = targetPos - pos
      
      tail.vels[i] = tail.vels[i] * (1 - tail.config.stiff)
      tail.vels[i] = tail.vels[i] + targetOffset * pullPushStrength * tail.config.bounce
      tail.vels[i] = tail.vels[i] + tail.config.gravity
      if isPointInWall(pos - vec(0, 0.02, 0)) then
         tail.vels[i] = tail.vels[i] * tail.config.floorFriction
      end
      
      local newPos = pos + tail.vels[i]:clamped(0, 50)
      
      tail.points[i] = movePointWithCollision(pos, newPos)

      oldDir = dir
   end
end

local lineLib = require('GNLineLib')
local lines = {} ---@type line[][]

---@overload fun(tail: auria.trail_tail, delta: number)
local function renderTail(tail, delta)
   -- debug lines
   -- do return end
   for i, posNew in ipairs(tail.points) do
      local pos = math.lerp(tail.oldPoints[i], posNew, delta) --[[@as Vector3]]
      local oldPos = math.lerp(tail.oldPoints[i - 1], tail.points[i - 1], delta) --[[@as Vector3]]
      if not lines[i] then
         lines[i] = {
            [-1] = lineLib:new(),
            lineLib:new():setWidth(0.08):setDepth(-0.05),
            lineLib:new():setWidth(0.01):setDepth(-0.25),
            lineLib:new():setWidth(0.01):setDepth(-0.5),
            lineLib:new():setWidth(0.01):setDepth(-0.8),
         }
      end
      local distOffset = (pos - oldPos):length()
      local dist = tail.distances[i]
      distOffset = distOffset > dist and (distOffset - dist) / (dist * 0.5) or distOffset / dist - 1
      distOffset = math.clamp(distOffset, -1, 1)
      local color = math.lerp(
         vec(1, 1, 1),
         distOffset > 0 and vec(1, 0, 0) or vec(0, 1, 0),
         math.abs(distOffset)
      )
      for k, v in pairs(lines[i]) do
         v:setA(pos)
         v:setB(oldPos)
         v:setColor(k > 0 and color or color * 0.5)
      end
   end
end

function events.tick()
   if not next(tails) then return end
   for _, tail in pairs(tails) do
      tickTail(tail)
   end
end

function events.render(delta)
   if not next(tails) then return end
   for _, tail in pairs(tails) do
      renderTail(tail, delta)
   end
end

return lib