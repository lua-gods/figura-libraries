# GN Spring Library
This library implements Springs, it supports numbers, vectors

example code
```lua
local mySpring = Spring.newVec3(
	0.5, -- Response Speed
	0.1, -- Damping Coeficient
	0 -- Initial Response Strength
)
:setGravity(vec(0, -9.8, 0)) -- constant force being applied
:setGuardrailRadius(2) -- maximum distance of the spring
```

> this project is an implementation from this video, but tweaked a whole lot to take advantage of Figura and Sumneko Lua's horrific annotation  
> https://www.youtube.com/watch?v=KPoeNZZ6H4s
>
> I highly recommend watching it, it explains the common problems with spring implementation and edge cases

ive had this library for years now, and only now im releasing it because ive polished it enough to be in the standard I release my libraries in

License: MPL 2.0  
-# Last Updated: 3/9/2026  