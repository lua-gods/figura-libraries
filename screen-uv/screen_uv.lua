local mod = {}

---@class auria.screen_uv.obj
---@field model ModelPart
---@field modelFaces {vertices: {[1]: Vertex, [2]: Vector3, [3]: Vector2, [4]: Vector3, [5]: number}[], textureSize: Vector2}[]
local screenUVObj = {}
local screenUVMt = {__index = screenUVObj}

local vectors_toCameraSpace = vectors.toCameraSpace
local vectors_worldToScreenSpace = vectors.worldToScreenSpace
local math_max = math.max

---@type {[ModelPart]: auria.screen_uv.obj}
local appliedEffect = {}

---@param delta number
---@param ctx Event.Render.context
---@param model ModelPart
local function midRender(delta, ctx, model)
   local me = appliedEffect[model]

   -- completly breaks in these contexts
   if ctx == "FIGURA_GUI" or ctx == "FIRST_PERSON" or ctx == "MINECRAFT_GUI" then
      for i, face in pairs(me.modelFaces) do
         for _, vertexData in pairs(face.vertices) do
            vertexData[1]:setPos(vertexData[2])
               :setUV(vertexData[3])
         end
      end
      return
   end

   local pivot = model:getPivot()

   local toWorldMat = model:partToWorldMatrix()
   toWorldMat:rightMultiply(matrices.translate4(-pivot))
   local toModelMat = toWorldMat:inverted()

   local camPos = client.getCameraPos()
   local camDir = client.getCameraDir()

   for i, face in pairs(me.modelFaces) do
      local depth = 0
      local textureSize = face.textureSize
      local onScreen = true

      for _, vertexData in pairs(face.vertices) do
         vertexData[4] = toWorldMat:apply(vertexData[2])
         vertexData[5] = vectors_toCameraSpace(vertexData[4]).z
         depth = depth + vertexData[5]
         if vertexData[5] < 0 then -- behind camera, ignore
            onScreen = false
            break
         end
      end

      if onScreen then
         depth = depth * 0.25

         for _, vertexData in pairs(face.vertices) do
            local pos = vertexData[4]
            local dir = (pos - camPos):normalize()
            dir = dir / math_max(dir:dot(camDir), 0.01)
            pos = pos + (depth - vertexData[5]) * dir
            local camP = vectors_worldToScreenSpace(pos)
            vertexData[1]:setPos(toModelMat:apply(pos))
               :setUV(camP.xy * textureSize + textureSize)
         end
      end
   end
end

---applies screen uv effect to modelpart
---@param model ModelPart
---@return auria.screen_uv.obj
function mod.apply(model)
   local modelFaces = {}

   for textureName, vertexGroup in pairs(model:getAllVertices()) do
      local texture = textures[textureName]
      local textureSize = texture:getDimensions()
      for i = 1, #vertexGroup, 4 do
         local vertices = {}
         for k = 0, 3 do
            local vertex = vertexGroup[i + k]
            local pos = vertex:getPos()
            vertices[k + 1] = {vertex, pos, vertex:getUV(), vec(0, 0, 0), 0}
         end
         -- add to list
         table.insert(modelFaces, {
            vertices = vertices,
            textureSize = textureSize * 0.5,
         })
      end
   end

   local obj = {
      model = model,
      modelFaces = modelFaces
   }
   setmetatable(obj, screenUVMt)

   if #modelFaces ~= 0 then
      appliedEffect[model] = obj
      model.midRender = midRender
   end

   return obj
end

---applies screen uv effect to modelpart and its children
---@param model ModelPart
function mod.applyAll(model)
   for _, v in pairs(model:getChildren()) do
      mod.applyAll(v)
   end
   mod.apply(model)
end

return mod