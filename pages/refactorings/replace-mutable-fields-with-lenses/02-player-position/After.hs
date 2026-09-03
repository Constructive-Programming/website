-- Same, with a composed path: player . x and player . y reach the
-- nested field in one step, no copy chain.
module After where

data Player = Player { pid :: String, px :: Int, py :: Int }
  deriving (Eq, Show)
data Game   = Game   { level :: Int, gplayer :: Player }
  deriving (Eq, Show)

data Lens s a = Lens { get :: s -> a, set :: a -> s -> s }

modify :: Lens s a -> (a -> a) -> s -> s
modify l f s = set l (f (get l s)) s

compose :: Lens s m -> Lens m a -> Lens s a
compose outer inner = Lens
  { get = get inner . get outer
  , set = \a s -> set outer (set inner a (get outer s)) s
  }

player :: Lens Game Player
player = Lens { get = gplayer, set = \p g -> g { gplayer = p } }

x :: Lens Player Int
x = Lens { get = px, set = \v p -> p { px = v } }

y :: Lens Player Int
y = Lens { get = py, set = \v p -> p { py = v } }

playerX :: Lens Game Int
playerX = compose player x

playerY :: Lens Game Int
playerY = compose player y

moveX :: Game -> Int -> Game
moveX g dx = modify playerX (+ dx) g

moveY :: Game -> Int -> Game
moveY g dy = modify playerY (+ dy) g
