local patpat = require("./patpat") ---@type auria.patpat

local myUuid = avatar:getUUID()

patpat.patHandlers.add(function(value, uuid, vars)
   local canPat = false
   local ok = patpat.safePcall(function()
      if type(value) == "Vector3" then
         canPat = vars.FOXPat.skull_pat(myUuid, value:unpack())
      else
         canPat = vars.FOXPat.entity_pat(myUuid)
      end
   end)
   if ok and canPat then
      return true
   end
   return false
end)