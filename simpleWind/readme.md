# simple wind
Script that adds basic wind effect synced across avatars and clients based on things like weather, altitude

This script doesn't do anything on its own (unless `editGetVelocity` is enabled) and is intended to be integrated with other scripts like physics libraries

this is not physically accurate wind

## adding support
### require script
you can require script normally
```lua
local windLib = require("./simpleWind")
```
or if you want it optional and only care about wind near player you can use this snippet below which makes local getWind function that returns wind direction or empty vector when no wind library is found
```lua
local windLibPath = "./simpleWind"

local getWind = function(a) return vec(0, 0, 0) end

if pcall(require, windLibPath) then
   local windLib = require(windLibPath)
   getWind = windLib.getPlayerWind
end
```
### library methods
you can use `windLib.getPlayerWind()` to get wind direction near player, giving `true` as argument makes `player:getVelocity()` return without wind when `editGetVelocity` is true

for wind farther from player you can use
`windLib.getWind(pos)` which takes `Vector3` as argument and returns wind direction

## download
[wind.lua](wind.lua)