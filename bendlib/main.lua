vanilla_model.PLAYER:setVisible(false)
vanilla_model.ARMOR:setVisible(false)

local bendLib = require("bend")

function events.render()
   local rot = vanilla_model.HEAD:getOriginRot()
   models.model.group.cube:setRot(rot)
end

local model = models.model.Skull
model:setScale(0.5)
for i = 1, 8 do
   model = model["part"..i]

   bendLib.new(model)

   local y = 180/8
   model:setRot(0, y, 0)
end