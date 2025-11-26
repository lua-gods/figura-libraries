local handHolding = require("handholding")

-- add arms
handHolding.addArm(models.model.root.LeftArm, vec(0, -12, 0))
handHolding.addArm(models.model.root.RightArm, vec(0, -12, 0))

-- simple hand holding keybind
local key = keybinds:of('hand holding toggle', 'key.keyboard.g')

function pings.handholding(uuid)
   handHolding.setTarget(uuid)
end

key.press = function()
	if not player:isLoaded() then return end
	local entity = player:getTargetedEntity(5)
	if entity and not entity:isPlayer() then
   	entity = nil
	end
	if entity and entity:getUUID() == handHolding.target then
      entity = nil
	end
	if entity then
   	host:setActionbar('Holding hands with '..entity:getName())
   	pings.handholding(entity:getUUID())
	else
   	host:setActionbar('No longer holding hands')
   	pings.handholding()
	end
end