---@diagnostic disable: param-type-mismatch, assign-type-mismatch
--[[______   __
  / ____/ | / / Name: GN SPRING LIBRARY v1.1.0
 / / __/  |/ /  Desc: an implementation of a 2nd-order spring system
/ /_/ / /|  / Author: GNanimates | https://gnon.top | @gn68s
\____/_/ |_/ License: Mozilla Public License Version 2.0 ]]
-- 2nd-order system spring library
-- this library is a reimplementation of: https://www.youtube.com/watch?v=KPoeNZZ6H4s


---@class SpringAPI
local SpringAPI = {}


---@class GN.Spring<T>
---@field id integer
---@field target T
---@field gravity T
---
---@field vel T
---
---@field pos T
---@field accel T
---
---@field lpos T
---@field ltarget T
---
---@field responseSpeed T
---@field dampingCoeficient T
---@field initialResponseStrength T
---
---@field guardrailRadius T
local Spring = {}
Spring.__index = Spring



local springs = {}

local TAU = math.pi * 2
local PI = math.pi


---@generic T
---@param responseSpeed T?
---@param dampingCoeficient T?
---@param initialResponseStrength T?
---@param zero T?
---@return GN.Spring<T>
function SpringAPI.new(responseSpeed, dampingCoeficient, initialResponseStrength, zero)
	zero = zero or 0
	local s = {
		pos = zero,
		vel = zero,
		responseSpeed = responseSpeed or 1,
		dampingCoeficient = dampingCoeficient or 0.05,
		initialResponseStrength = initialResponseStrength or 0,
		target = zero,
		ltarget = zero,
		accel = zero,
		gravity = zero
	}
	-- compute constraints
	s.k1 = s.dampingCoeficient / (PI * s.responseSpeed)
	s.k2 = 1 / ((2 * PI * s.responseSpeed) * (TAU * s.responseSpeed))
	s.k3 = s.initialResponseStrength * s.dampingCoeficient / (TAU * s.responseSpeed)

	setmetatable(s, Spring)
	local id = #springs + 1
	s.id = id
	springs[id] = s
	return s
end

---@param responseSpeed Vector2|number
---@param dampingCoeficient Vector2|number
---@param initialResponseStrength Vector2|number
---@return GN.Spring<Vector2>
function SpringAPI.newVec2(responseSpeed, dampingCoeficient, initialResponseStrength)
	return SpringAPI.new(responseSpeed, dampingCoeficient, initialResponseStrength,vec(0,0))
end


---@param responseSpeed Vector3|number
---@param dampingCoeficient Vector3|number
---@param initialResponseStrength Vector3|number
---@return GN.Spring<Vector3>
function SpringAPI.newVec3(responseSpeed, dampingCoeficient, initialResponseStrength)
	return SpringAPI.new(responseSpeed, dampingCoeficient, initialResponseStrength,vec(0,0,0))
end


---@generic T
---@param self GN.Spring<T>
---@param delta number?
---@return T
function Spring:samplePos(delta)
	return math.lerp(self.lpos or self.pos, self.pos, delta or 1)
end

---@generic T
---@param self GN.Spring<T>
---@param delta number?
---@return T
function Spring:sampleTarget(delta)
	return math.lerp(self.ltarget or self.target, self.target, delta or 1)
end

---@generic T
---@param self GN.Spring<T>
---@param pos T
---@return GN.Spring<T>
function Spring:setPos(pos)
	self.pos = pos
	self.vel = pos * 0
	return self
end

---@generic T
---@param self GN.Spring<T>
---@param pos T
---@return GN.Spring<T>
function Spring:setTarget(pos)
	self.target = pos
	return self
end

---@generic T
---@param self GN.Spring<T>
---@param radius number
---@return GN.Spring<T>
function Spring:setGuardrailRadius(radius)
	self.guardrailRadius = radius
	return self
end


---@generic T
---@param self GN.Spring<T>
---@param gravity T
---@return GN.Spring<T>
function Spring:setGravity(gravity)
	self.gravity = gravity
	return self
end

function Spring:free()
	springs[self.id] = nil
end

---@generic T
---@param self GN.Spring<T>
---@param x T
---@return GN.Spring<T>
function Spring:impulse(x)
	---@cast self GN.Spring<any>
	self.vel = self.vel + x
	return self
end



local DELTA = 0.05
events.TICK:register(function ()
	for i, s in pairs(springs) do
		local taccel = 0
		if not s.ltarget then
			taccel = (s.target - s.ltarget) / DELTA
		end
		s.ltarget = s.target
		s.lpos = s.pos
		s.pos = s.pos + DELTA * s.vel
		local accel = (s.target + s.k3 * taccel - s.pos - 2 * s.k1 * s.vel) / s.k2 + s.gravity
		s.vel = s.vel + DELTA * accel
		
		if s.guardrailRadius then
			local dir = s.pos-s.target
			if type(dir) == "number" then
				s.pos = math.clamp(s.pos,s.target-s.guardrailRadius,s.target+s.guardrailRadius)
			else
---@diagnostic disable-next-line: undefined-field
				s.pos = s.target + dir:clamped(0,s.guardrailRadius)
			end
		end
		
	end
end)

return SpringAPI
