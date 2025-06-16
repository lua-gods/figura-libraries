local mainPage = action_wheel:newPage()

if not host:isHost() then
   return mainPage
end

local gamelib = require('gamelib')

function events.entity_init()
   if not action_wheel:getCurrentPage() then
      action_wheel:setPage(mainPage)
   end
end

local goBackAction = action_wheel:newAction()
   :item('barrier')
   :title('go back')
   :onLeftClick(function() action_wheel:setPage(mainPage) end)

local hostServerAction = mainPage:newAction()
   :title('host server')
   :item('oak_sapling')

hostServerAction:onLeftClick(function()
   local page = action_wheel:newPage()
   page:setAction(-1, goBackAction)
   action_wheel:setPage(page)
   local games = gamelib.getGames()
   for name, game in pairs(games) do
      page:newAction()
         :title(name)
         :item('minecraft:pink_glazed_terracotta')
         :onLeftClick(function()
            local hostPage = action_wheel:newPage()
            action_wheel:setPage(hostPage)

            game:hostGame()

            hostPage:newAction()
               :title('stop')
               :item('barrier')
               :onLeftClick(function()
                  action_wheel:setPage(mainPage)
                  gamelib.stopHostedGame()
               end)
         end)
   end
end)

local findGamesAction = mainPage:newAction()
   :title('find games')
   :item('oak_leaves')

findGamesAction:onLeftClick(function()
   local page = action_wheel:newPage()
   page:setAction(-1, goBackAction)

   local games = gamelib.getGames()
   for _, v in pairs(gamelib.findGames()) do
      local game = games[v.game]
      local action = page:newAction()
         :title(v.game..'\n'..v.host:getName())
         :item('player_head{SkullOwner:'..v.host:getName()..'}')

      if game then
         action:onLeftClick(function()
            print("JOIN GAME")
         end)
      else
         action:setColor(0.2, 0.2, 0.2)
            :setHoverColor(0.2, 0.2, 0.2)
      end
   end

   action_wheel:setPage(page)
end)

return mainPage