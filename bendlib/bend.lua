local mod = {}

local matrices_rotation4 = matrices.rotation4

---@param mainModel ModelPart # main modelpart which will be rotated
---@param modelparts? ModelPart[] # list of moderlparts whose vertices will be used
---@param checkFunc? fun(pos: Vector3): boolean # function to choose which vertices should not rotate
function mod.new(mainModel, modelparts, checkFunc)
   assert(mainModel ~= mod, "Use dot (.) instead of colon (:) to call this function")
   assert(mainModel, "ModelPart expected, got nil")
   if not modelparts then
      if mainModel:getType() == "GROUP" then
         modelparts = mainModel:getChildren()
      else
         modelparts = {mainModel}
      end
   end
   local vertexCount = 0
   local posSum = vec(0, 0, 0)
   if not checkFunc then
      checkFunc = function(p)
         posSum = posSum + p
         vertexCount = vertexCount + 1
         return true
      end
   end
   local vertices = {}
   local pivot = mainModel:getPivot()
   for _, model in pairs(modelparts) do
      for _, vertexGroup in pairs(model:getAllVertices()) do
         for _, vertex in pairs(vertexGroup) do
            local pos = vertex:getPos()
            if checkFunc(pos) then
               local id = tostring(pos)
               if vertices[id] then
                  table.insert(vertices[id][2], vertex)
               else
                  vertices[id] = {pos - pivot, {vertex} }
               end
            end
         end
      end
   end
   if vertexCount >= 1 then
      local offset = posSum / vertexCount - pivot
      local dir = offset:normalize()
      for i, group in pairs(vertices) do
         if (group[1] - offset):dot(dir) > 0 then
            vertices[i] = nil
         end
      end
   end
   local rotMat = matrices.rotation3(mainModel:getRot())
   for _, group in pairs(vertices) do
      group[1] = group[1] * rotMat
   end
   local function update()
      local mat = matrices_rotation4(mainModel:getTrueRot()):invert():translate(pivot)
      for _, group in pairs(vertices) do
         local pos = mat:apply(group[1])
         for _, vertex in pairs(group[2]) do
            vertex:setPos(pos)
         end
      end
   end
   local preRender = mainModel.preRender
   if preRender then
      mainModel.preRender = function(...)
         update()
         return preRender(...)
      end
   else
      mainModel.preRender = update
   end
end

return mod