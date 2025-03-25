local trailTail = require('trail_tail')

trailTail.new({
   models.model.tail1,
   models.model.tail2,
   models.model.tail3,
   models.model.tail4,
   models.model.tail5,
   models.model.tail6,
   models.model.tail7,
})

-- hide legs
vanilla_model.LEFT_LEG:setVisible(false)
vanilla_model.RIGHT_LEG:setVisible(false)
vanilla_model.LEFT_PANTS:setVisible(false)
vanilla_model.RIGHT_PANTS:setVisible(false)

-- hide armor and elytra when not flying
vanilla_model.ARMOR:setVisible(false)

function events.tick()
   vanilla_model.ELYTRA:setVisible(player:getPose() == 'FALL_FLYING')
end