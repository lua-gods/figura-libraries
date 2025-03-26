local trailTail = require('trail_tail')

trailTail.new({
   models.model.tail.tail1,
   models.model.tail.tail2,
   models.model.tail.tail3,
   models.model.tail.tail4,
   models.model.tail.tail5,
   models.model.tail.tail6,
   models.model.tail.tail7,
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