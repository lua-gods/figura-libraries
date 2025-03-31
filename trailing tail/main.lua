local trailTail = require('trail_tail')

local tail = trailTail.new({
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


local state = 0
local oldState = 0
local target = 0
page:newAction()
   :setItem('glass_pane')
   :setHoverColor(0, 0, 0)
   :onScroll(function (dir, self)
      target = math.clamp(target + dir * 0.1, 0, 1)
      self:setColor(target, target, target)
      self:setHoverColor(target, target, target)
   end)
   :onLeftClick(function (self)
      target = target > 0.5 and 0 or 1
      self:setColor(target, target, target)
      self:setHoverColor(target, target, target)
   end)

function events.tick()
   oldState = state
   state = math.lerp(state, target, 0.2)
end

function events.render(delta)
   local x = math.lerp(oldState, state, delta)
   animations.model.awa:setPlaying(x > 0.01):blend(x)
   tail.config.physicsStrength = 1 - x
end