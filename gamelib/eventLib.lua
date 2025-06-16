-- variables
local lib = {}

---@class auria.event
local eventMt = {__type = "Event"}
eventMt.__index = eventMt
local eventsTblMt = {__index = {}}

---creates event
---@return auria.event
function lib.newEvent()
   return setmetatable({_registered = {}}, eventMt)
end
lib.new = lib.newEvent

---makes table allow registering new events by adding functions to it
---@param tbl table?
---@return table
function lib.table(tbl)
   return setmetatable({_table = tbl or {}}, eventsTblMt)
end

---Registers an event
---@param func function
---@param name string?
function eventMt:register(func, name)
   table.insert(self._registered, {func = func, name = name})
end

---Clears all event
function eventMt:clear()
   self._registered = {}
end

---Removes an event with the given name.
---@param match string
---@return integer
function eventMt:remove(match)
   local count = 0
   for i = #self._registered, 1, -1 do
      local tbl = self._registered[i]
      if tbl.func == match or tbl.name == match then
         table.remove(self._registered, i)
         count = count + 1
      end
   end
   return count
end

---Returns how much listerners there are.
---@param name string
---@return integer
function eventMt:getRegisteredCount(name)
   local count = 0
   for _, data in pairs(self._registered) do
      if data.name == name then
         count = count + 1
      end
   end
   return count
end

function eventMt:__call(...)
   local returnValue = {}
   for _, data in pairs(self._registered) do
      table.insert(returnValue, {data.func(...)})
   end
   return returnValue
end

function eventMt:invoke(...)
   local returnValue = {}
   for _, data in pairs(self._registered) do
      table.insert(returnValue, {data.func(...)})
   end
   return returnValue
end

function eventMt:__len()
   return #self._registered
end

-- events table
function eventsTblMt.__index(t, i)
   return t._table[i] or (type(i) == "string" and type(t._table[i:upper()]) == 'Event' and t._table[i:upper()] or nil)
end

function eventsTblMt.__newindex(t, i, v)
   if type(i) == "string" and type(v) == "function" and t._table[i:upper()] and type(t._table[i:upper()]) == 'Event' then
      t._table[i:upper()]:register(v)
   else
      t._table[i] = v
   end
end

function eventsTblMt.__ipairs(t)
   return ipairs(t._table)
end
function eventsTblMt.__pairs(t)
   return pairs(t._table)
end

-- return library
return lib