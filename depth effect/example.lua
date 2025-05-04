local depthEffect = require("depth_effect")

depthEffect.apply(models.model.layer1, 64)
depthEffect.apply(models.model.layer2, 32)
depthEffect.apply(models.model.layer3, 16)
depthEffect.apply(models.model.layer4, 4)

local depthObj = depthEffect.apply(models.model.layer5, -4)

models.model.layer1:setPrimaryRenderType("CUTOUT_EMISSIVE_SOLID"):color(0.5, 0.5, 0.5)
models.model.layer2:setPrimaryRenderType("CUTOUT_EMISSIVE_SOLID"):color(0.75, 0.75, 0.75)
models.model.layer3:setPrimaryRenderType("CUTOUT_EMISSIVE_SOLID")
models.model.layer4:setPrimaryRenderType("CUTOUT_EMISSIVE_SOLID")
models.model.layer5:setPrimaryRenderType("CUTOUT_EMISSIVE_SOLID")

local time = 0

function events.tick()
   time = time + 1
end

function events.render(delta)
   local depth = math.cos((time + delta) * 0.1) * 4
   depthObj:setDepth(depth)
end