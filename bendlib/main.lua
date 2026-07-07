vanilla_model.PLAYER:setVisible(false)
vanilla_model.ARMOR:setVisible(false)

function events.render()
   local rot = vanilla_model.HEAD:getOriginRot()
   models.model.group.cube:setRot(rot)
end