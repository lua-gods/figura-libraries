local mod = {}

function mod.sphere(pos, r, color)
   for _ = 1, 32 do
      particles['end_rod']
         :pos(pos + (vec(math.random(), math.random(), math.random()) - 0.5):normalize() * r)
         :scale(0.1)
         :lifetime(10)
         :gravity(0)
         :color(color or vec(1, 1, 1))
         :spawn()
   end
end

function mod.point(pos, color)
   particles['end_rod']
      :pos(pos)
      :scale(0.5)
      :color(color or vec(1, 1, 1))
      :lifetime(4)
      :gravity(0)
      :spawn()
end

function mod.line(pos, pos2, color)
   for t = 0, 1, 0.05 do
      particles['end_rod']
         :pos(math.lerp(pos, pos2, t))
         :scale(0.5)
         :color(color or vec(1, 1, 1))
         :lifetime(4)
         :gravity(0)
         :spawn()
   end
end

function mod.circle(pos, r, mat, color)
   for t = 0, math.pi * 2, math.pi / 10 do
      particles['end_rod']
         :pos(pos + vec(math.cos(t), math.sin(t), 0) * r * mat)
         :scale(0.4)
         :color(color or vec(1, 1, 1))
         :lifetime(4)
         :gravity(0)
         :spawn()
   end
end

--[[
require("debugShapes").circle(pos2 - dir * x, a, matrices.rotation3(rot.x, rot.y, 0))


require("debugShapes").sphere(targetArmPos, targetArmLength, vec(1, 0.6, 0.6))
require("debugShapes").sphere(pos, myLen, vec(1, 1, 0.6))
require("debugShapes").point(targetPos, vec(0, 1, 0))
--]]

return mod