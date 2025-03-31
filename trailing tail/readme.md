# Trailing tail library
Figura library that adds simple physics to long tails/snake tails/lamia tails.<br>
Suport blockbench animations (rotation, position)

## Setup
- Make sure your tail in blockbench is chained (tail2 is in tail1, tail3 is in tail2, etc)
- Check if your groups pivots are correct in blockbench
- Download library [trail_tail.lua](trail_tail.lua)
- Require the script:
```lua
local trailTail = require('trail_tail')
```
- Setup tail something like this:
```lua
local tail = trailTail.new(models.your_model_name.tail_model_path)
```
- Save your script
- Done!

## Config
You can set config with `tail:setConfig`
```lua
tail:setConfig({
   floorFriction = 0.1,
   partToWorldDelay = 0.5,
})
```
Or you can edit config table directly
```lua
tail.config.physicsStrength = 0.5
```

## Extra info
Uses `modelPart:partToWorldMatrix()`<br>
No visible delay <br>
Doesn't use `WORLD` parent type <br>
Renders only when player is rendered. Use first person model mod if you want it to render in first person. <br>
Should run fine under figura default permission level <br>
You can use `physicsStrength` config to control strength of physics, setting it to 0 will disable it