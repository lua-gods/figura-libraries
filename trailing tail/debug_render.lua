local tail = require('main')

local debugRender = false

local hud = models:newPart('debug renderer', 'Hud')
local whitePixel = textures.whitePixel or textures:newTexture('whitePixel', 1, 1):setPixel(0, 0, 1, 1, 1)

local toggleKeybind = keybinds:of('toggle debug render', 'key.keyboard.g')
toggleKeybind.press = function()
   debugRender = not debugRender
   hud:removeTask()
end

local toHud = client.getScaledWindowSize() * -0.5
local taskI = 0
---@param a Vector3
---@param b Vector3
---@param color Vector3
local function drawLine(a, b, color)
   local screenA = vectors.worldToScreenSpace(a)
   local screenB = vectors.worldToScreenSpace(b)
   local hudA = screenA.xy * toHud + toHud
   local hudB = screenB.xy * toHud + toHud

   if screenA.z < 1 or screenB.z < 1 then
      return
   end

   local offset = hudA - hudB
   local dist = offset:length()
   local angle = math.deg(math.atan2(offset.y, offset.x))

   taskI = taskI + 1
   hud:newSprite('a'..taskI)
      :setTexture(whitePixel, 1, 2)
      :setLight(15, 15)
      :setPos(hudA.x, hudA.y)
      :setScale(dist, 1, 1)
      :setColor(color)
      :setRot(0, 0, angle)

   hud:newSprite('b'..taskI)
      :setTexture(whitePixel, 2, 2)
      :setLight(15, 15)
      :setPos(hudA.x, hudA.y, -1)
      :setColor(1, 1, 1)
      :setRot(0, 0, angle)

   hud:newSprite('c'..taskI)
      :setTexture(whitePixel, 2, 2)
      :setLight(15, 15)
      :setPos(hudB.x, hudB.y, -1)
      :setColor(1, 1, 1)
      :setRot(0, 0, angle)
end

hud.preRender = function(delta)
   if not debugRender then
      return
   end
   hud:removeTask()
   taskI = 0

   toHud = client.getScaledWindowSize() * -0.5

   local pos = math.lerp(tail.oldPoints[0], tail.points[0], delta) --[[@as Vector3]]
   for i = 1, #tail.models do
      local nextPos = math.lerp(tail.oldPoints[i], tail.points[i], delta)  --[[@as Vector3]]

      drawLine(pos, nextPos, vec(1, 0, 1))

      drawLine(nextPos, nextPos + (tail.config.collisionOffsets[i] or vec(0, 0, 0)) / 16, vec(0, 1, 0))

      pos = nextPos
   end
end