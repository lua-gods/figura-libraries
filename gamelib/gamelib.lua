local eventlib = require('./eventLib')

---@class luagods.gamelib
local mod = {}

---@class luagods.gamelib.gameTemplate
---@field name string
---@field minPlayers number minimum players for this game
---@field maxPlayers number maximum players for this game
---@field syncData table data at start of game that will be synced
---@field client luagods.gamelib.client
---@field server luagods.gamelib.server
local gameTemplateClass = {}
gameTemplateClass.__index = gameTemplateClass

---@class luagods.gamelib.game
---@field name string
local gameClass = {}
gameClass.__index = gameClass

---@type {[string]: luagods.gamelib.gameTemplate}
local registeredGames = {}

---@type luagods.gamelib.game
local hostedGame
local hostedGameId = 0
local hostedTick = 0

---registers game
---@param name string
---@return luagods.gamelib.gameTemplate
function mod.register(name)
   ---@class luagods.gamelib.client
   local gameClient = {
      ---@class luagods.gamelib.client.tick_event : auria.event
      ---@field register fun(self: self, func: fun(game: luagods.gamelib.game), name: string?)
      TICK = eventlib.newEvent(),
   }
   ---@class luagods.gamelib.server
   local gameServer = {
      ---@class luagods.gamelib.server.tick_event : auria.event
      ---@field register fun(self: self, func: fun(game: luagods.gamelib.game), name: string?)
      TICK = eventlib.newEvent(),
   }
   local obj = {
      name = name,
      minPlayers = 2,
      maxPlayers = math.huge,
      syncData = {},
      client = eventlib.table(gameClient),
      server = eventlib.table(gameServer),
   }
   registeredGames[name] = obj
   setmetatable(obj, gameTemplateClass)
   return obj
end

---returns all registered games
---@return {[string]: luagods.gamelib.gameTemplate}
function mod.getGames()
   return registeredGames
end

---finds and returns all hosted games
---@return {game: string, host: Player}[]
function mod.findGames()
   local tbl = {}
   local minTime = client.getSystemTime() - 20000 -- 20 seconds
   for _, entity in pairs(world.getPlayers()) do
      local vars = entity:getVariable()
      if vars['gamelib.server'] then
         local ok, hostTime = pcall(tonumber, vars['gamelib.server.time'])
         if ok and hostTime > minTime then
            table.insert(tbl, {
               game = vars['gamelib.server'],
               host = entity
            })
         end
      end
   end
   return tbl
end

local function serverTick()
   if not hostedGame then
      events.TICK:remove(serverTick)
      pings.gamelib_server()
      return
   end
   hostedTick = hostedTick + 1
   if hostedTick % 100 == 1 then
      pings.gamelib_server(hostedGame.name, hostedGameId)
   end
end

---creates game object, used internally by library
---@return luagods.gamelib.game
function gameTemplateClass:newGameObj()
   return {
      name = self.name
   }
end

---starts hosting game, returns game object
---@return luagods.gamelib.game
function gameTemplateClass:hostGame()
   if hostedGame then
      mod.stopHostedGame()
   end
   events.TICK:register(serverTick)
   hostedTick = 0
   hostedGameId = client.generateUUID()
   hostedGame = self:newGameObj()
   return hostedGame
end

function mod.stopHostedGame()
   hostedGame = nil
end

function pings.gamelib_server(name, id)
   avatar:store('gamelib.server', name)
   avatar:store('gamelib.server.id', id)
   avatar:store('gamelib.server.time', client.getSystemTime())
end

return mod