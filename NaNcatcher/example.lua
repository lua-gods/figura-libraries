require('nancatcher')

local a = vec(1, 2, 3)
local b = vec(2, 4, 6)

local c = b / 2

local d = (a - c):normalize()

local e = vectors.rotateAroundAxis(45, vec(0, 0, 1), d)