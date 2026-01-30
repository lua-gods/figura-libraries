--[[ info

Script made by Auria and GNamimates

features:
stacking - placing plushie on top of another plushie makes it bigger
snap to floor - placing plushie above blocks like carpet, cauldron, slab will make plushie snap to floor
sit on stairs - makes plushie sit on stairs 

there might be issues with stacking if pivot point of model group is not at 0 0 0

this variant allows plushies to be squished, requires patpat script

]]-- config
local model = models.plushie.Skull -- model part for plushie
local headOffset = 6 -- how high should plushie move when entity have it on helmet slot
local sitOffset = vec(0, -8, -2) -- where should plushie move when its placed on stairs

-- basic variables
local offset = vec(0, 1, 0)
local vec3 = vec(1, 1, 1)
local vec2Half = vec(0.5, 0.5)
local myUuid = avatar:getUUID()

local tickTimer = 0
local squishData = {}
local squishDataI = nil

-- patpat squish
local patpat = require("patpat") -- path to patpat script

table.insert(patpat.head.oncePat, function(_, pos)
   squishData[tostring(pos)] = tickTimer
   sounds['entity.axolotl.idle_air']:pos(pos + 0.5):pitch(2):play()
end)

-- check for head
local function myHead(bl)
   local data = bl:getEntityData()
   return data and data.SkullOwner and data.SkullOwner.Id and client.intUUIDToString(table.unpack(data.SkullOwner.Id)) == myUuid
end

-- skull render event
function events.skull_render(delta, block, item, entity, mode)
   if not block then
      model:setScale(vec3)
      if entity and mode == "HEAD" then
         model:setPos(0, headOffset, 0)
      else
         model:setPos(0, 0, 0)
      end
      return
   end
   -- get pos and floor
   local pos = block:getPos()
   local floor = world.getBlockState(pos - offset)
   -- dont render when part of stack
   if myHead(floor) then
      return true
   end
   --stack
   local size = 1
   while myHead(world.getBlockState(pos + offset * size)) do
      size = size + 1
   end
   -- squish
   local squish = vec(1, 1, 1)
   local posStr = tostring(pos)
   if squishData[posStr] then
      local squishTime = (tickTimer + delta - squishData[posStr]) / 8
      if squishTime > 1 then
         squishTime = 1
         squishData[posStr] = nil
      end
      squish.y = 1 - math.sin(squishTime * 9.5) * 2 ^ (-9 * squishTime) * 0.9
      squish.x = 1 / squish.y
      squish.z = squish.x
   end
   -- scale
   model:setScale(squish * size)
   -- move to floor
   if block.id ~= "minecraft:player_head" then
      model:setPos(0, 0, 0)
      return
   end
   if floor.id:match("stairs") and floor.properties and floor.properties.half == "bottom" then
      model:setPos(sitOffset)
      return
   end
   local y = 0
   local shape = floor:getOutlineShape()
   for _, v in ipairs(shape) do
      if v[1].xz <= vec2Half and v[2].xz >= vec2Half then
         y = math.max(y, v[2].y)
      end
   end
   if #shape >= 1 then
      model:setPos(0, y * 16 - 16, 0)
   else
      model:setPos(0, 0, 0)
   end
end

-- clean up squish data
function events.world_tick()
   tickTimer = tickTimer + 1
   local timeLimit = tickTimer - 10 -- limit before it is removed in ticks
   for _ = 1, 2 do
     squishDataI = next(squishData, squishData[squishDataI] and squishDataI or nil)
     if squishDataI then
       if squishData[squishDataI] < timeLimit then
         squishData[squishDataI] = nil
       end
     end
   end
end