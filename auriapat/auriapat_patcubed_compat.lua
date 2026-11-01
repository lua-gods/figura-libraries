local patpat = require("./patpat") ---@type auria.patpat

local myUuid = avatar:getUUID()
local patCubedVars = {
   protocol = 1,
}

local acceptedFuncs
local canAcceptFuncs = false
function patCubedVars.acceptor(tbl, validate)
   if canAcceptFuncs then
      acceptedFuncs = tbl
      canAcceptFuncs = false
   end
end

local id = client.intUUIDToString(client.generateUUID())
patCubedVars.session_id = id
local function validateSession()
   return world.avatarVars()[myUuid].PatCubed.session_id == id
end
patCubedVars.validate = validateSession

local function prompter(uuid)
   local vars = world.avatarVars()[uuid].PatCubed
   if vars.protocol ~= 1 then
      return
   end
   local entity = world.getEntity(uuid)
   local playerFilter = patpat.filterPlayer(entity, false)
   local skullFilter = patpat.filterPlayer(entity, true)
   if not playerFilter and not skullFilter then
      return
   end
   vars.acceptor({
      player = playerFilter and function(time)
         if not validateSession() then
            return false
         end
         local e = world.getEntity(uuid)
         local ok = patpat.receivePats(e, 1, nil, time)
         return ok or false
      end or nil,
      skull = skullFilter and function(time, x, y, z)
         if not validateSession() then
            return false
         end
         local e = world.getEntity(uuid)
         local ok = patpat.receivePats(e, 2, vec(x, y, z), time)
         return ok or false
      end or nil,
   }, validateSession)
end

function patCubedVars.prompter(uuid)
   if uuid then
      prompter(uuid)
   else
      for _, v in pairs(world.getPlayers()) do
         prompter(v:getUUID())
      end
   end
end

avatar:store("PatCubed", patCubedVars)

patpat.patHandlers.add(function(value, uuid, vars)
   local canPat
   local ok = patpat.safePcall(function()
      canAcceptFuncs = true
      vars.PatCubed.prompter(myUuid)
      if type(value) == "Vector3" then
         canPat = acceptedFuncs.skull(patpat.holdFor, value:unpack())
      else
         canPat = acceptedFuncs.player(patpat.holdFor)
      end
   end)
   acceptedFuncs = nil
   if ok and canPat ~= false then
      return true
   end
   return false
end)