local trailTail = require('trail_tail')

local tail = trailTail.new(models.model.tail1)

tail.config.collisionOffsets = {
   [1] = vec(0, -4, 0),
   [2] = vec(0, -3.5, 0),
   [3] = vec(0, -3, 0),
   [4] = vec(0, -2.5, 0),
   [5] = vec(0, -2, 0),
   [6] = vec(0, -1.5, 0),
   [7] = vec(0, -1, 0),
}

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

-- testing stuff
local page = action_wheel:newPage()
action_wheel:setPage(page)

local anims = {
   animations.model.awa,
   animations.model.meow,
}

local animsStates = {}

for i = 1, #anims do
   local state = 0
   local oldState = 0
   local target = 0
   page:newAction()
      :setItem('glass_pane')
      :setTitle(anims[i]:getName())
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

   animsStates[i] = function(delta)
      return math.lerp(oldState, state, delta)
   end
end

function events.render(delta)
   tail.physicsStrength = 1
   local strength = 1
   for i, anim in pairs(anims) do
      local state = animsStates[i](delta)
      anim:setPlaying(state > 0.01):blend(state)
      strength = strength * (1 - state)
   end
   tail.config.physicsStrength = strength
end

return tail