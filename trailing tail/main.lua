local trailTail = require('trail_tail')

trailTail.new({
   models.model.tail1,
   models.model.tail1.tail2,
   models.model.tail1.tail2.tail3,
   models.model.tail1.tail2.tail3.tail4,
   models.model.tail1.tail2.tail3.tail4.tail5,
   models.model.tail1.tail2.tail3.tail4.tail5.tail6,
   models.model.tail1.tail2.tail3.tail4.tail5.tail6.tail7,
})

-- trailTail.new({
--    models.model.testtail,
--    models.model.testtail.testtail2,
--    models.model.testtail.testtail2.testtail3,
--    models.model.testtail.testtail2.testtail3.testtail4,
--    models.model.testtail.testtail2.testtail3.testtail4.testtail5,
--    models.model.testtail.testtail2.testtail3.testtail4.testtail5.testtail6,
--    models.model.testtail.testtail2.testtail3.testtail4.testtail5.testtail6.testtail7,
--    models.model.testtail.testtail2.testtail3.testtail4.testtail5.testtail6.testtail7.testtail8,
-- })

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

local page = action_wheel:newPage()
action_wheel:setPage(page)

page:newAction()
   :setItem('glass_pane')
   :setOnToggle(function(state)
      animations.model.awa:setPlaying(state)
   end)