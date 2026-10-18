local patpat = require("libraries.patpat")

local myUuid = avatar:getUUID()

local function spawnParticle(pos, bBox)
   pos = pos + vec(
      math.random() - 0.5,
      math.random(),
      math.random() - 0.5
   ) * bBox
   particles[patpat.particle or "minecraft:heart"]
      :pos(pos)
      :scale(1)
      :spawn()
end

patpat.patHandlers.add(function(value, uuid, vars)
   local noPats = true
   local ok = patpat.safePcall(function()
      if vars["patpat.noPats"] then
         return false
      end
      if not (vars["petpet"] or vars["patpat.yesPats"]) then
         return false
      end
      if type(value) == "Vector3" then
         noPats = vars["petpet.playerHead"](myUuid, 15, value:unpack())
      else
         noPats = vars["petpet"](myUuid, 15)
      end
   end)
   if not ok or noPats then
      return false
   end
   if type(value) == "Vector3" then
      spawnParticle(value + vec(0.5, 0, 0.5), vec(0.75, 0.75, 0.75))
   else
      spawnParticle(value:getPos(), value:getBoundingBox())
   end
   return true
end)