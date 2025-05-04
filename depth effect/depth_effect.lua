---@class auria.depth_effect
local mod = {}

---@class auria.depth_effect.obj
---@field depth number
---@field model ModelPart
---@field modelFaces {vertices: {[1]: Vertex, [2]: Vector3, [3]: Vector2}[], rotMat: Matrix4, uvMat: Matrix3}[]
local depthObj = {}
local depthObjMt = {__index = depthObj}

---@type {[ModelPart]: auria.depth_effect.obj}
local appliedDepthEffect = {}

local function midRender(delta, ctx, model)
   local me = appliedDepthEffect[model]
   local depth = me.depth

   local toModelMat = model:partToWorldMatrix():invert()

   local worldCamPos = client.getCameraPos()
   local camPos = toModelMat:apply(worldCamPos)

   for i, face in pairs(me.modelFaces) do
      local mat = matrices.mat3()
      local localPos = face.rotMat:apply(camPos)

      local size = (1 / (localPos.z)) * depth + 1

      mat:multiply(face.uvMat)
      mat:translate(-localPos.xy)
      mat:scale(size, size, 1)
      mat:translate(localPos.xy)
      mat:multiply(face.uvMat:inverted())

      for _, vertexData in pairs(face.vertices) do
         vertexData[1]:setUV(mat:apply(vertexData[3]))
      end
   end
end

---applies depth effect to modelpart
---@param model ModelPart
---@param depth number
---@return auria.depth_effect.obj
function mod.apply(model, depth)
   local modelPivot = model:getPivot()
   local modelFaces = {}

   for textureName, vertexGroup in pairs(model:getAllVertices()) do
      local texture = textures[textureName]
      local textureSize = texture:getDimensions()
      for i = 1, #vertexGroup, 4 do
         local vertices = {}
         local uvMin, uvMax = textureSize * 2, -textureSize
         for k = 0, 3 do
            local vertex = vertexGroup[i + k]
            local pos = vertex:getPos() - modelPivot
            local uv = vertex:getUV()
            uvMin = vec(math.min(uvMin.x, uv.x), math.min(uvMin.y, uv.y)) ---@type Vector2
            uvMax = vec(math.max(uvMax.x, uv.x), math.max(uvMax.y, uv.y)) ---@type Vector2
            vertices[k + 1] = {vertex, pos, uv}
         end
         -- uv mat
         local uvMat = matrices.mat3()
         uvMat:translate(-uvMin)
         uvMat:scale((vec(1, 1) / (uvMax - uvMin)):augmented())
         -- matrix magic, thanks limits
         local a = vertices[1][2]
         local b = vertices[2][2]
         local c = vertices[4][2]
         local normal = (b - a):cross(c - a):normalize()
         local inverseRotMat = matrices.mat4((b-a).xyz_, (c-a).xyz_, normal.xyz_, vec(a.x, a.y, a.z, 1))
         local rotMat = inverseRotMat:inverted()
         -- extra flips because uv weird
         if vertices[1][3].x > vertices[2][3].x then
            rotMat:scale(-1, 1, 1):translate(1, 0, 0)
         end
         if vertices[2][3].y > vertices[3][3].y then
            rotMat:scale(1, -1, 1):translate(0, 1, 0)
         end
         -- add to list
         table.insert(modelFaces, {
            vertices = vertices,
            rotMat = rotMat,
            uvMat = uvMat,
         })
      end
   end

   local obj = {
      model = model,
      depth = depth,
      modelFaces = modelFaces
   }
   setmetatable(obj, depthObjMt)

   if #modelFaces ~= 0 then
      appliedDepthEffect[model] = obj
      model.midRender = midRender
   end

   return obj
end

---applies depth effect to modelpart and its children
---@param model ModelPart
---@param depth number
function mod.applyAll(model, depth)
   for _, v in pairs(model:getChildren()) do
      mod.applyAll(v, depth)
   end
   mod.apply(model, depth)
end

---returns depth effect obj from modelpart, returns nil if not registered
---@param model ModelPart
---@return auria.depth_effect.obj[]
function mod.get(model)
   return appliedDepthEffect[model]
end

---sets depth
---@param depth number
---@return self
function depthObj:setDepth(depth)
   self.depth = depth
   return self
end

---removes depth effect
function depthObj:remove()
   for i, face in pairs(self.modelFaces) do
      for _, vertexData in pairs(face.vertices) do
         vertexData[1]:setUV(vertexData[3])
      end
   end
   self.model.midRender = nil
   appliedDepthEffect[self.model] = nil
end

return mod