local screenUv = require("screen_uv")

screenUv.applyAll(models.model)

models.model:setPrimaryRenderType("EMISSIVE_SOLID")

-- use uv matrix to fix aspect ratio
function events.tick()
   local size = client.getWindowSize()
   local mat = matrices.mat3()

   mat:translate(-0.5, -0.5)
   if size.x > size.y then
      mat:scale(size.x / size.y, 1, 1)
   else
      mat:scale(1, size.y / size.x, 1)
   end
   mat:translate(0.5, 0.5)

   models.model:setUVMatrix(mat)
end