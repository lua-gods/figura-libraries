--[[______   __
  / ____/ | / / Name: GN EVENTS LIBRARY v1.1.1
 / / __/  |/ /  Desc: acts the same way as Figura events, but as instantiatable objects
/ /_/ / /|  / Author: GNanimates | https://gnon.top | @gn68s
\____/_/ |_/ License: Mozilla Public License Version 2.0 ]]

---A Event is a list of functions that can be invoked.
---@class GN.Event : Event
local Events = {}
Events.__index = Events

---@alias GN.EventGroup table<string, GN.Event>

---@return GN.Event
function Events.new() return setmetatable({}, Events) end

---@return GN.EventGroup
function Events.newGroup()
	local group = {}
	setmetatable(group, {
		__newindex = function(t, k, v)
			k = k:upper()
			if not rawget(t, k) then rawset(t, k, Events.new()) end
			rawget(t, k):register(v)
		end,
		__index = function(t, k)
			k = k:upper()
			if not rawget(t, k) then rawset(t, k, Events.new()) end
			return rawget(t, k)
		end,
	})
	return group
end

Events.newEvent = Events.new

---Registers a function as a listener to the event when it triggers.
---@param func function
---@param name any
function Events:register(func, name) self[#self + 1] = { name or func, func } end

---Clears all the registered listeners.
function Events:clear() for key in pairs(self) do self[key] = nil end end

---Removes the listener with the given name.
---@param name any|function
function Events:remove(name) for id, value in pairs(self) do if value[1] == name then self[id] = nil end end end

---Returns the amount of events with the given name.
---@param name any
---@return integer
function Events:getRegisteredCount(name)
	local c = 0
	if not name then return #self end
	for id, value in pairs(self) do if value[1] == name then c = c + 1 end end
	return c
end

function Events:__call(...)
	local flush = {}
	for _, func in pairs(self) do flush[#flush + 1] = { func[2](...) } end
	return flush
end

---@type fun(self: GN.Event, ...: any): string[]
Events.invoke = Events.__call

function Events.__index(t, i) return rawget(t, i) or rawget(t, i:upper()) or Events[i] end

function Events.__newindex(t, i, v) rawset(t, type(i) == "string" and t[i:upper()] or i, v) end

return Events
