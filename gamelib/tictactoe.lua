local gamelib = require("gamelib")

local tictactoe = gamelib.register("tictactoe")

tictactoe.minPlayers = 2
tictactoe.maxPlayers = 2

tictactoe.syncData = {
   board = '_________',
   turn = false
}

-- tictactoe.server.PACKET:register(function(game, clientId, packet, data)
--    if packet == 'board' and game.syncData.turn ~= (clientId == 1) then
--       game.syncdata.board = -- update board
--       game:sync()
--       if gameFinished then
--          game:stop()
--       end
--    end
-- end)

tictactoe.client.TICK:register(function(game, clientId)
   if game.syncData.turn ~= (clientId == 1) then
      return
   end
   local selectedSpot = 0
   -- ui stuff?
   if selectedSpot ~= 0 and userClickedOrSomething then
      game:send('board', selectedSpot)
   end
end)