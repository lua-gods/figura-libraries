do return end -- prevent code from running

local screenUv = require("screen_uv")

screenUv.applyAll(models.model)

models.model:setPrimaryRenderType("EMISSIVE_SOLID")

-- use uv matrix to fix aspect ratio
function events.render(delta)
   local size = client.getWindowSize()
   local mat = matrices.mat3()
   -- pos
   local pos = player:getPos(delta) + vec(0, 1, 0)
   -- fancy math
   local offset = vectors.worldToScreenSpace(pos).xy
   local depth = math.abs(vectors.toCameraSpace(pos).z)
   offset = offset * 0.5 + 0.5
   local scale = depth
   -- translate
   mat:translate(-offset)
   mat:scale(scale, scale, 1)
   -- aspect ratio
   mat:translate(-0.5, -0.5)
   if size.x > size.y then
      mat:scale(size.x / size.y, 1, 1)
   else
      mat:scale(1, size.y / size.x, 1)
   end
   mat:translate(0.5, 0.5)
   -- apply
   models.model:setUVMatrix(mat)
end