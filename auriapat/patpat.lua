-- config
local mod = {
   keybind = "key.mouse.right", -- keybind that will be used for patpat
   patDelay = 3, -- delay between pats when holding patpat key in ticks
   requireEmptyOffHand = false,
   sneakToPat = true,

   -- particle that will be used when patted/patting entity
   -- can be changed in code below too
   particle = "minecraft:heart",

   minPatDelay = 1, -- minimum delay between pats
   maxPatRange = 8, -- max blocks for petting

   ---whitelist/blacklist for default filterPlayer function
   ---each filter has:
   ---players table with name or uuid indexes and true values, names are case sensitive
   ---isBlacklist toggles between whitelist or blacklist mode
   ---filter can also be string that points it to use other filter
   ---@type {[string]: {players: {[string]: true}, isBlacklist: boolean}|string}
   filters = {
      player = {
         players = {
            -- ["someone"] = true,
            -- ["some uuid"] = true,
         },
         isBlacklist = false,
      },
      skull = "player", -- switch it to table to seperate whitelist
   },

   patpatBlocks = { -- list of blocks that can be patted
      "minecraft:player_head", "minecraft:player_wall_head"
   },
   disabledEntities = { -- list of entites that will be ignored when trying to pat them
      "minecraft:boat", "minecraft:chest_boat", "minecraft:minecart",
   },
   ignoredEntities = { -- entities you can patpat through
      "minecraft:area_effect_cloud", "minecraft:interaction",
   },

   selfPat = false, -- for debugging
}

mod.events = {
   ---@type fun(entity: Entity)[]
   oncePat = {},
   ---@type function[]
   whilePat = {},
   ---@type fun(state: boolean, entity?: Entity)[]
   togglePat = {},
   ---@type fun(pos: Vector3, entity: Entity)[]
   skullOncePat = {},
   ---@type fun(target: Entity|Vector3)[]
   patting = {},
   ---@type fun(target: Entity)[]
   pattingEntity = {},
}

-- default events, you can change these if you want
table.insert(mod.events.patting, function(target)
   host:swingArm()
end)

table.insert(mod.events.oncePat, function(entity)
   local pos = player:getPos()
   local bBox = player:getBoundingBox()
   pos = pos + vec(
      math.random() - 0.5,
      math.random(),
      math.random() - 0.5
   ) * bBox
   particles[mod.particle]
      :pos(pos)
      :scale(1)
      :spawn()
end)

table.insert(mod.events.skullOncePat, function(pos, entity)
   pos = pos + vec(
      math.random() - 0.5,
      math.random(),
      math.random() - 0.5
   ) * 0.75 + vec(0.5, 0, 0.5)
   particles[mod.particle]
      :pos(pos)
      :scale(1)
      :spawn()
end)

table.insert(mod.events.pattingEntity, function(target)
   local pos = target:getPos()
   local bBox = target:getBoundingBox()
   pos = pos + vec(
      math.random() - 0.5,
      math.random(),
      math.random() - 0.5
   ) * bBox
   particles[mod.particle]
      :pos(pos)
      :scale(1)
      :spawn()
end)

---@param entity Entity
---@param isSkull boolean
---@return boolean?
function mod.filterPlayer(entity, isSkull)
   local filter = mod.filters[isSkull and "skull" or "player"]
   if type(filter) == "string" then
      filter = mod.filters[filter]
   end
   local onList = filter.players and filter.players[entity:getUUID()]
   if not onList and entity:isPlayer() then
      onList = filter.players[entity:getName()]
   end
   if filter.isBlacklist then
      return not onList
   end
   return onList
end

--{ code }--
local myUuid = avatar:getUUID()

local eventError
local function callEvent(eventName, ...)
   local output = {}
   for _, func in ipairs(mod.events[eventName]) do
      table.insert(output, {func(...)})
   end
   return output
end

local function callEventPcalled(eventName, ...)
   local ok, output = pcall(callEvent, eventName, ...)
   if ok then
      return output
   end
   eventError = 'from patpat event "'..eventName..'":\n'..output
   return {}
end

local pattedTime = 0
local pattedDelay = 0

function events.tick()
   if eventError then
      error(eventError)
   end
   pattedDelay = math.max(pattedDelay - 1, 0)
   if pattedTime <= 0 then
      return
   end
   pattedTime = pattedTime - 1
   callEvent("whilePat")
   if pattedTime == 0 then
      callEvent("togglePat", false)
   end
end

---@param entity Entity
---@param mode number
---@param pos Vector3?
---@return boolean?
function mod.receivePats(entity, mode, pos)
   -- rate limit
   if pattedDelay >= 1 then
      return
   end
   pattedDelay = mod.minPatDelay
   local myPos
   if mode == 2 then
      myPos = pos
   elseif mode == 1 then
      myPos = player:getPos()
   end
   if (entity:getPos() - myPos):length() > mod.maxPatRange then
      return
   end
   -- check if petting allowed
   if not mod.filterPlayer(entity, mode == 2) then
      return
   end
   -- call events
   if mode == 2 then
      callEventPcalled("skullOncePat", pos:copy(), entity)
   elseif mode == 1 then
      if not player:isLoaded() then
         return
      end
      callEventPcalled("oncePat", entity)
      if pattedTime == 0 then
         callEvent("togglePat", true, entity)
      end
      pattedTime = 15
   end
   return true
end

local patTarget = nil

local patpatAvatarVars = {}

function patpatAvatarVars.confirm()
   local target = patTarget
   patTarget = nil
   return target
end

function patpatAvatarVars.pat(uuid, mode, x, y, z)
   local entity = world.getEntity(uuid)
   if not entity then return end -- no entity
   -- verify uuid
   local targetUuid = entity:getVariable("catpat").confirm()
   if myUuid ~= targetUuid then
      return
   end
   if mode == 2 then
      local pos = vec(x, y, z):floor()
      return mod.receivePats(entity, 2, pos)
   elseif mode == 1 then
      return mod.receivePats(entity, 1)
   end
end

avatar:store("catpat", patpatAvatarVars)

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
---@return string?
local function getUuidFromBlock(block)
   if block.id == "minecraft:player_head" or block.id == "minecraft:player_wall_head" then
      local entityData = block:getEntityData()
      if entityData then
         local skullOwner = entityData.SkullOwner and entityData.SkullOwner.Id
         if skullOwner then
            return client.intUUIDToString(table.unpack(skullOwner))
         end
      end
   end
end

---pcall that prevents stack overflows by making java function call lua function
---found out by bitslayn
---@param func function
---@return boolean
function mod.safePcall(func)
   local v = vec(1, 2)
   local ok = pcall(v.applyFunc, v, function(i)
      if i == 1 then
         func()
      end
      return i
   end)
   return ok
end

mod.patHandlers = {}
-- stupid language server, doesnt accept table.insert

---@param func (fun(value: Entity|Vector3, uuid: string, vars: table): boolean)
function mod.patHandlers.add(func)
   table.insert(mod.patHandlers, func)
end

mod.patHandlers.add(function(value, uuid, vars)
   local patsAllowed = false
   patTarget = uuid
   local ok = mod.safePcall(function()
      if type(value) == "Vector3" then
         if vars.catpat.pat(myUuid, 2, value:unpack()) then
            patsAllowed = true
         end
      else
         if vars.catpat.pat(myUuid, 1) then
            patsAllowed = true
         end
      end
   end)
   patTarget = nil
   if ok and patsAllowed then
      return true
   end
   return false
end)

---@param a string|number
---@param b number?
---@param c number?
---@return boolean
local function patpat(a, b, c)
   if not player:isLoaded() then return false end
   local blockPos, entity
   if b then -- block
      -- decode position
      ---@diagnostic disable-next-line: param-type-mismatch
      local receivedPos = vec(a, b, c)
      local playerPos = player:getPos()
      local offset = (receivedPos / 64):floor()
      blockPos = (playerPos / 64 + offset * 0.5):floor() * 64
      blockPos = blockPos + receivedPos % 64 - 32 * offset
      local block = world.getBlockState(blockPos)
      -- call petpet function
      local uuid, avatarVars
      local ok = mod.safePcall(function()
         uuid = getUuidFromBlock(block)
         avatarVars = world.avatarVars()[uuid]
      end)
      if not ok then
         return false
      end
      local pos = block:getPos()
      for i, v in ipairs(mod.patHandlers) do
         if v(pos, uuid, avatarVars) then
            callEvent("patting", blockPos)
            return true
         end
      end
      return false
   end
   -- entity
   ---@diagnostic disable-next-line: param-type-mismatch
   entity = world.getEntity(unpackUuid(a))
   if not entity then return false end
   if not entity:isPlayer() then
      callEvent("pattingEntity", entity)
      callEvent("patting", entity)
      return true
   end
   local uuid = entity:getUUID()
   local avatarVars
   local ok = mod.safePcall(function()
      avatarVars = entity:getVariable()
   end)
   if not ok then
      return false
   end
   for i, v in ipairs(mod.patHandlers) do
      if v(entity, uuid, avatarVars) then
         callEvent("patting", entity)
         return true
      end
   end
   return false
end

function pings.patpat(a, b, c)
   if host:isHost() then return end
   patpat(a, b, c)
end

-- host only
if not host:isHost() then return mod end

---@overload fun(tbl: table): table
local function toLookupTable(tbl)
   local new = {}
   for _, v in ipairs(tbl) do
      new[v] = true
   end
   return new
end

local allowedBlocks = toLookupTable(mod.patpatBlocks)
local disabledEntities = toLookupTable(mod.disabledEntities)
local ignoredEntities = toLookupTable(mod.ignoredEntities)

local function entityPredicate(entity)
   return entity ~= player and not ignoredEntities[entity:getType()]
end

---@return boolean?
local function patTargeted()
   if player:getItem(1).id ~= "minecraft:air" then return end
   if mod.requireEmptyOffHand and player:getItem(2).id ~= "minecraft:air" then return end

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

   if mod.selfPat and not entity then
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
      local uuid = packUuid(entity:getUUID())
      if patpat(uuid) then
         pings.patpat(uuid)
         return true
      end
      return
   end
   if not allowedBlocks[block.id] then return end
   -- encode position
   local pos = block:getPos()
   local playerPos = player:getPos()
   local playerOffset = vec(
      math.abs(playerPos.x % 64 - 32) > 16 and 1 or 0,
      math.abs(playerPos.y % 64 - 32) > 16 and 1 or 0,
      math.abs(playerPos.z % 64 - 32) > 16 and 1 or 0
   )
   local finalPos = (pos + playerOffset * 32) % 64 + playerOffset * 64
   if patpat(finalPos:unpack()) then
      pings.patpat(finalPos:unpack())
      return true
   end
end

local patting = false
local patTime = 0
local keybind = keybinds:newKeybind("patpat", mod.keybind)

keybind.press = function()
   if not host:getScreen() and
      not action_wheel:isEnabled() and
      player:isLoaded() and
      (not mod.sneakToPat or player:isSneaking()) then
      patTime = 0
      patting = patTargeted() or false
   end
end

keybind.release = function()
   patting = false
end

function events.tick()
   if not patting then return end

   patTime = patTime + 1
   if patTime % mod.patDelay == 0 then
      patTargeted()
   end
end

return mod