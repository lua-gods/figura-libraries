-- dependencies
local Spring = require("lib.GNSpring")

--────  CONFIG  ────────────────────────────────────────────────────────--

-- Customize these values
local MY_SPRING = Spring.newVec3(
	0.5, -- Response Speed
	0.1, -- Damping Coeficient
	0 -- Initial Response Strength
)
:setGravity(vec(0, -9.8, 0)) -- constant force being applied
:setGuardrailRadius(2) -- maximum distance of the spring

--────  USELESS DISPLAY CODE  ────────────────────────────────────────────────────────--
local SCALE = 0.5
local LOOP_COUNT = 20
local MODEL = models.spring.Spring

local modelhead = models:newPart("hed", "WORLD")
modelhead:newBlock("block"):block("minecraft:diamond_block")

MODEL:setVisible(false)
local modelSpring = models:newPart("spring", "WORLD")
local finalLength = LOOP_COUNT * 2.42
for i = 1, LOOP_COUNT, 1 do
	local part = MODEL:copy("spring" .. i)
		 :scale(SCALE)
		 :setVisible(true)
		 :moveTo(modelSpring)
		 :pos(0, 0, 2.42 * i)
end


---@param dirVec Vector3
---@return Vector3
local function dirToEular(dirVec)
	local yaw = math.atan2(dirVec.x, dirVec.z)
	local pitch = math.atan2(dirVec.y, dirVec.xz:length())
	return vec(-math.deg(pitch), math.deg(yaw), 0)
end



events.ENTITY_INIT:register(function()
	local pos = player:getPos()
	MY_SPRING
		 :setPos(pos)
		 :setTarget(pos)
end)


events.WORLD_RENDER:register(function(delta)
	if not player:isLoaded() then return end
	MY_SPRING.target = player:getPos(delta):add(0, 4, 0)

	local from = MY_SPRING.target
	local to = MY_SPRING:samplePos(delta)
	local dir = to - from
	local rot = dirToEular(dir)

	modelSpring
		 :setPos(from * 16)
		 :setRot(rot)
		 :scale(1, 1, dir:length() / finalLength * 16)

	modelhead:setPos((to - 0.5) * 16)
end)
