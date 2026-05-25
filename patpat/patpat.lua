-- config
local conf = {
   patParticle = "minecraft:heart", -- particle that will be used when patting
   patpatKey = "key.mouse.right", -- keybind that will be used for patpat

   requireEmptyOffHand = false,
   patDelay = 3, -- delay between pats when holding patpat key in ticks
   holdFor = 10, -- amount of ticks before patting stops, if this value is smaller than patDelay it might cause issues

   patpatBlocks = { -- list of blocks that can be patted
      "minecraft:player_head", "minecraft:player_wall_head"
   },
   disabledEntities = { -- list of entites that will be ignored when trying to pat them
      "minecraft:boat", "minecraft:chest_boat", "minecraft:minecart",
   },
   ignoredEntities = { -- entities you can patpat through
      "minecraft:area_effect_cloud", "minecraft:interaction",
   },
   noPats = false,
   noHearts = false,
   complicatedPlayerHeadEvents = false, -- when disabled only oncePat for player heads will work 

   selfPat = false, -- for debugging
}

-- events
local playerEvents = { -- list of tables containing functions that get called when specific thing happens
   onPat = { -- runs when you start being petted
      --function() end
   },
   onUnpat = { -- runs when you stop being petted
      --function() end
   },
   togglePat = { -- runs when you start or stop being petted, isPetted - boolean that is true when someone starts
      --function(isPetted) end
   },
   whilePat = { -- runs every tick while being patted, patters - list of people patting you
      --function(patters) end
   },
   oncePat = { -- every time someone pats you, entity - entity that is petting you, can return 2 booleans, noSwing, noHearts
      --function(entity) end
   },
   patting = { -- called every time you are patting someone, you can return true to stop particles
      --function(entity) end
   }
}

local headEvents = { -- this table works like playerEvents table but instead of player its for player heads and every event have extra argument that is position of player head
   onPat = {},
   onUnpat = {},
   togglePat = {},
   whilePat = {},
   oncePat = {},
   patting = {}
}

-- some useful variables
if conf.noPats then avatar:store("patpat.noPats", true) end
if conf.noHearts then avatar:store("patpat.noHearts", true) end
local vector3Index = figuraMetatables.Vector3.__index
local myUuid = avatar:getUUID()

-- events handler
playerEvents.player = playerEvents -- backwards compatibility
playerEvents.head = headEvents

local eventError
local function callEvent(group, eventName, ...)
   local output = {}
   for _, func in ipairs(playerEvents[group][eventName]) do
      table.insert(output, {func(...)})
   end
   return output
end

local function callEventPcalled(group, eventName, ...)
   local ok, output = pcall(callEvent, group, eventName, ...)
   if ok then
      return output
   end
   eventError = 'from patpat event:\n'..output..''
   return {}
end

local myPatters = {player = {}, head = {}}

function events.tick()
   if eventError then
      error(eventError)
   end
   local patted = false
   for uuid, time in pairs(myPatters.player) do
      if time <= 0 then
         callEvent("player", "onUnpat")
         callEvent("player", "togglePat", false)
         myPatters.player[uuid] = nil
      else
         myPatters.player[uuid] = time - 1
         patted = true
      end
   end
   if patted then
      callEvent("player", "whilePat", myPatters.player)
   end
end

if conf.complicatedPlayerHeadEvents then
   function events.world_tick()
      for i, headPatters in pairs(myPatters.head) do
         local patted = false
         local pos = headPatters.pos
         for uuid, time in pairs(headPatters.list) do
            if time <= 0 then
               callEvent("head", "onUnpat", pos)
               callEvent("head", "togglePat", false, pos)
               headPatters.list[uuid] = nil
            else
               headPatters.list[uuid] = time - 1
               patted = true
            end
         end
         if patted then
            callEvent("head", "whilePat", headPatters.list, pos)
         else
            myPatters.head[i] = nil
         end
      end
   end
end

avatar:store("petpet", function(uuid, time)
   local entity = world.getEntity(uuid)
   if not entity then return true, true end -- no entity
   time = math.min(time or 10, 40)
   if not myPatters.player[uuid] then
      callEventPcalled("player", "onPat")
      callEventPcalled("player", "togglePat", true)
   end
   myPatters.player[uuid] = time
   local output = callEventPcalled("player", "oncePat", entity)
   local noPats, noHearts = false, false
   for _, v in ipairs(output) do
      noPats, noHearts = noPats or v[1], noHearts or v[2]
   end
   return noPats, noHearts
end)

avatar:store("petpet.playerHead", function(uuid, time, x, y, z)
   local entity = world.getEntity(uuid)
   if not entity then return true, true end -- no entity
   time = math.min(time or 10, 40) -- math.min and vec does type checking
   local pos = vec(x, y, z)
   local i = tostring(pos)
   if conf.complicatedPlayerHeadEvents then
      local patters = myPatters.head[i]
      if not patters then
         patters = {}
         myPatters.head[i] = {list = patters, pos = pos}
      end

      if not patters[uuid] then
         callEventPcalled("head", "onPat", pos)
         callEventPcalled("head", "togglePat", true, pos)
      end
      patters[uuid] = time
   end
   local output = callEventPcalled("head", "oncePat", entity, pos)
   local noPats, noHearts = false, false
   for _, v in ipairs(output) do
      noPats, noHearts = noPats or v[1], noHearts or v[2]
   end
   return noPats, noHearts
end)

---@overload fun(uuid: string): string
local function packUuid(uuid)
   uuid = uuid:gsub("-", "")
   local newUuid = ""
   for i = 1, 32, 2 do
      newUuid = newUuid..string.char(tonumber(uuid:sub(i, i + 1), 16))
   end
   return newUuid
end

local uuidDashes = {[4] = true, [6] = true, [8] = true, [10] = true}
---@overload fun(uuid: string): string
local function unpackUuid(uuid)
   local newUuid = ""
   for i = 1, 16 do
      newUuid = newUuid..string.format("%02x", string.byte(uuid:sub(i, i)))
      if uuidDashes[i] then newUuid = newUuid.."-" end
   end
   return newUuid
end

---@param block BlockState
---@return table?
local function getAvatarVarsFromBlock(block)
   if block.id == "minecraft:player_head" or block.id == "minecraft:player_wall_head" then
      local entityData = block:getEntityData()
      if entityData then
         local skullOwner = entityData.SkullOwner and entityData.SkullOwner.Id and client.intUUIDToString(table.unpack(entityData.SkullOwner.Id))
         if skullOwner then
            return world.avatarVars()[skullOwner] or {}
         end
      end
   end
end

---@param vars table
---@return boolean
local function canPat(vars)
   if vars["patpat.noPats"] then
      return false
   end
   if vars["petpet"] or vars["patpat.yesPats"] then
      return true
   end
   return false
end

-- pings
local function patpatPing(a, b, c)
   if not player:isLoaded() then return end
   local vars, pos, boundingBox, pattingOutput
   local petpetSuccess, noPats, noHearts
   if b then -- block
      -- decode position
      local receivedPos = vec(a, b, c)
      local playerPos = player:getPos()
      local offset = (receivedPos / 64):floor()
      local blockPos = (playerPos / 64 + offset * 0.5):floor() * 64
      blockPos = blockPos + receivedPos % 64 - 32 * offset
      local block = world.getBlockState(blockPos)
      -- set position for particles
      pos = blockPos + vec(0.5, 0, 0.5)
      boundingBox = vec(0.8, 0.8, 0.8)
      -- call petpet function
      vars = getAvatarVarsFromBlock(block) or {}
      petpetSuccess, noPats, noHearts = pcall(vars["petpet.playerHead"], myUuid, conf.holdFor, blockPos.x, blockPos.y, blockPos.z)
      pattingOutput = callEvent("head", "patting", blockPos)
   else -- entity
      local entity = world.getEntity(unpackUuid(a))
      if not entity then return end
      vars = entity:getVariable()
      -- get position and safely get patpat.boundingBox and fallback to normal boundingBox
      pos = entity:getPos()
      local success
      success, boundingBox = pcall(vector3Index, vars['patpat.boundingBox'], 'xyz')
      if not success then
         boundingBox = entity:getBoundingBox()
      end
      -- call petpet function
      petpetSuccess, noPats, noHearts = pcall(vars["petpet"], myUuid, conf.holdFor)
      pattingOutput = callEvent("player", "patting", entity)
   end
   -- swing
   if host:isHost() and not (petpetSuccess and rawequal(noPats, true)) then
      host:swingArm()
   end
   -- spawn particles
   -- cancel patpat particles when returned true in patting event
   for _, v in pairs(pattingOutput) do
      if v[1] then
         return
      end
   end
   noHearts = petpetSuccess and rawequal(noHearts, true) or vars['patpat.noHearts']
   if noHearts then return end
   pos = pos - boundingBox.x_z * 0.5 + vec(
      math.random(),
      math.random(),
      math.random()
   ) * boundingBox
   particles[conf.patParticle]:pos(pos):size(1):spawn()
end

function pings.patpat(a, b, c)
   if host:isHost() then return end
   patpatPing(a, b, c)
end

-- host only
if not host:isHost() then return playerEvents end

---@overload fun(tbl: table): table
local function toLookupTable(tbl)
   local new = {}
   for _, v in ipairs(tbl) do
      new[v] = true
   end
   return new
end
local allowedBlocks = toLookupTable(conf.patpatBlocks)
local disabledEntities = toLookupTable(conf.disabledEntities)
local ignoredEntities = toLookupTable(conf.ignoredEntities)

local function entityPredicate(entity)
   return entity ~= player and not ignoredEntities[entity:getType()]
end

local function patPat()
   if player:getItem(1).id ~= "minecraft:air" then return end
   if conf.requireEmptyOffHand and player:getItem(2).id ~= "minecraft:air" then return end

   local myPos = player:getPos():add(0, player:getEyeHeight(), 0)
   local eyeOffset = renderer:getEyeOffset()
   if eyeOffset then myPos = myPos + eyeOffset end

   local reachDistance = math.min(host:getReachDistance(), 20)
   local targetPos = myPos + player:getLookDir() * reachDistance

   local block, blockPos = raycast:block(myPos, targetPos)
   if not block then
      block = world.newBlock("air")
      blockPos = vec(0, 0, 0)
   end

   local dist = (myPos - blockPos):length()
   local isEntity = false

   local entity, entityPos = raycast:entity(myPos, targetPos, entityPredicate)

   if conf.selfPat and not entity then
      entity = player
      entityPos = entity:getPos()
   end

   if entity then
      local newDist = (myPos - entityPos):length()
      if newDist < dist then
         isEntity = true
      end
   end

   if isEntity then
      if entity:hasContainer() then return end
      local entityType = entity:getType()
      if disabledEntities[entityType] then return end
      local vars = entity:getVariable()
      if entity:isPlayer() and not canPat(vars) then return end

      local uuid = packUuid(entity:getUUID())
      pings.patpat(uuid)
      patpatPing(uuid)
   else
      if not allowedBlocks[block.id] then return end
      local vars = getAvatarVarsFromBlock(block)
      if vars then
         if not canPat(vars) then return end
      end
      -- encode position
      local pos = block:getPos()
      local playerPos = player:getPos()
      local playerOffset = vec(
         math.abs(playerPos.x % 64 - 32) > 16 and 1 or 0,
         math.abs(playerPos.y % 64 - 32) > 16 and 1 or 0,
         math.abs(playerPos.z % 64 - 32) > 16 and 1 or 0
      )
      local finalPos = (pos + playerOffset * 32) % 64 + playerOffset * 64
      pings.patpat(finalPos:unpack())
      patpatPing(finalPos:unpack())
   end
end

local patting = false
local patTime = 0
local key = keybinds:newKeybind("patpat", conf.patpatKey)

key.press = function()
   if not host:getScreen() and
      not action_wheel:isEnabled() and
      player:isLoaded() and
      player:isSneaking() then
      patting = true
      patPat()
   end
end
key.release = function() patting = false patTime = 0 end

function events.tick()
   if not patting then return end

   patTime = patTime + 1
   if patTime % conf.patDelay == 0 then
      patPat()
   end
end

-- return, made by Auria
return playerEvents