-- Move the player inside a game: the nested copy-update touches
-- both records at every move.
module Before where

data Player = Player { pid :: String, px :: Int, py :: Int }
data Game   = Game   { level :: Int, gplayer :: Player }

moveX :: Game -> Int -> Game
moveX g dx = g { gplayer = (gplayer g) { px = px (gplayer g) + dx } }

moveY :: Game -> Int -> Game
moveY g dy = g { gplayer = (gplayer g) { py = py (gplayer g) + dy } }
