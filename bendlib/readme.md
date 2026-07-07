# Bend lib
Simple library to bend modelparts, supports blockbench animations

Simply require library
```lua
local bendLib = require("bend")
```
and call `bendLib.new` with modelpart you want to bend
```lua
bendLib.new(models.path.to.model)
```
now rotating that part by other script or animation will bend it instead

by default it will stop moving vertices of model or model's children if its group

but you can define it manually
```lua
bendLib.new(models.model.group, {models.model.group.cube1, models.model.group.cube2})
```
if you want even more control you can define which vertices shouldn't move manually
```lua
bendLib.new(
   models.path.to.model,
   nil,
   function(pos)
      return pos.y > 4 -- vertices above y 4 will not move
   end
)
```