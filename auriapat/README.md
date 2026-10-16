# Auria pat
Patpat script with new simple protocol designed to support whitelist,
supporting players, player heads and entities

## whitelist
You can whitelist people by adding them into filters in config
```lua
...
player = {
   players = {
      ["your cool friend"] = true, -- can be either name or uuid, remember its case sensitive
   },
   isBlacklist = false,
},
...
```
## events
Auriapat provides many events to make your avatar react to patting or have custom patting animation

by default script provides some basic events (just below the config!) for swinging arm and spawning particles when someone pets you

you can add events either by editing patpat script directly or by adding it in other script

For example you can edit default `patting` event to play custom animation
```lua
-- if you are adding event to other script, use "patpat" instead of mod and make sure to require it
table.insert(mod.events.patting, function(target)
   animations["model_name_here"]["animation_name"]:play()
end)
```