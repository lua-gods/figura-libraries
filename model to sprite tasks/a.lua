---@param model ModelPart
---@param subdivide number?
---@param worldModel ModelPart?
---@param spriteTaskId {[0]: number}?
---@param depth number?
---@param color Vector4?
---@param uvMat Matrix3?
---@return ModelPart
local function generateSpriteTasks(model, subdivide, worldModel, spriteTaskId, depth, color, uvMat)
   if not worldModel then
      worldModel = models:newPart('meow', 'World')
   end
   subdivide = subdivide or 1
   spriteTaskId = (spriteTaskId or {0})
   depth = (depth or 0) + 1
   color = color or vec(1, 1, 1, 1)
   color = color * model:getColor():augmented(model:getOpacity())
   uvMat = (uvMat or matrices.mat3()) * model:getUVMatrix()

   if model:getVisible() == false then return worldModel end

   for _, child in pairs(model:getChildren()) do
      generateSpriteTasks(child, subdivide, worldModel, spriteTaskId, depth, color, uvMat)
   end

   local toWorldMat = model:partToWorldMatrix()
   local pivot = model:getTruePivot()
   local positionScale = vec(-16, -16, 16)
   local primaryTextureType, primaryTexture = model:getPrimaryTexture() --[[@as Texture]]
   local textureOverride = primaryTextureType == 'CUSTOM' and textures[figuraMetatables.Texture.__index(primaryTexture, 'getName')(primaryTexture)]
   local normalMatrix = matrices.mat3()
   normalMatrix = normalMatrix * toWorldMat:deaugmented()
   normalMatrix:scale(-16, -16, 16)
   for textureName, vertexGroup in pairs(model:getAllVertices()) do
      local orginalTexture = textures[textureName]
      local texture = textureOverride or orginalTexture
      local spriteUvMat = uvMat * matrices.scale3(vec(1, 1, 1) / orginalTexture:getDimensions():augmented(1))
      for i = 1, #vertexGroup, 4 do
         local posList, normalList, uvList = {}, {}, {}
         for k = 1, 4 do
            local orginal = vertexGroup[i + k - 1]
            posList[k] = toWorldMat:apply(orginal:getPos() - pivot) * positionScale
            normalList[k] = normalMatrix * orginal:getNormal():normalize()
            uvList[k] = spriteUvMat:apply(orginal:getUV())
         end
         for subX = 0, subdivide - 1 do
            local tX, tX2 = subX / subdivide, (subX + 1) / subdivide
            for subY = 0, subdivide - 1 do
               local tY, tY2 = subY / subdivide, (subY + 1) / subdivide
               spriteTaskId[1] = spriteTaskId[1] + 1
               local sprite = worldModel:newSprite(tostring(spriteTaskId[1]))
               sprite:texture(texture, 1, 1):color(color)
               local spriteVertices = sprite:getVertices()
               for a = 0, 1 do
                  local t1 = a == 1 and tY2 or tY
                  for b = 0, 1 do
                     local t2 = b == a and tX2 or tX
                     local k = a * 2 + b + 1
                     spriteVertices[k]:setPos(
                           math.lerp(
                              math.lerp(posList[1], posList[4], t1),
                              math.lerp(posList[2], posList[3], t1),
                              t2
                           )
                        ):setUV(
                           math.lerp(
                              math.lerp(uvList[1], uvList[4], t1),
                              math.lerp(uvList[2], uvList[3], t1),
                              t2
                           )
                        ):setNormal(
                           math.lerp(
                              math.lerp(normalList[1], normalList[4], t1),
                              math.lerp(normalList[2], normalList[3], t1),
                              t2
                           )
                        )
                  end
               end
            end
         end
      end
   end

   return worldModel
end