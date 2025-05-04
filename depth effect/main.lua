vanilla_model.ALL:setVisible(false)

local camAnim = false
local camTime = 0

keybinds:of('toggle cam anim', 'key.keyboard.g').press = function()
   camAnim = not camAnim
   if camAnim then
      renderer:setOffsetCameraPivot(0, -0.5, 0)
      renderer:setFOV(50 / client.getFOV())
      renderer:setCameraPos(0, 0, -1)
   else
      renderer:setOffsetCameraPivot()
      renderer:setOffsetCameraRot()
      renderer:setFOV()
      renderer:setCameraPos()
   end
end

function events.tick()
   if camAnim then
      camTime = (camTime + 1) % 80
      host:setActionbar(tostring(camTime))
   end
end

function events.render(delta)
   if not camAnim then
      return
   end
   local time = camTime + delta
   time = time / 80
   time = time * math.pi * 2

   renderer:setOffsetCameraRot(
      math.sin(time) * 10,
      math.cos(time) * 30 + 180,
      0
   )
end