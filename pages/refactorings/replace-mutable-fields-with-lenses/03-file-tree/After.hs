-- Same, with a lens on the size field: the write goes through the
-- lens; the recursion over children is unchanged.
module After where

data Node = Node { name :: String, size :: Int, children :: [Node] }
  deriving (Eq, Show)

data Lens s a = Lens { get :: s -> a, set :: a -> s -> s }

modify :: Lens s a -> (a -> a) -> s -> s
modify l f s = set l (f (get l s)) s

sizeLens :: Lens Node Int
sizeLens = Lens { get = size, set = \v n -> n { size = v } }

bumpSizes :: Node -> Int -> Node
bumpSizes n by =
  modify sizeLens (+ by)
    (n { children = map (`bumpSizes` by) (children n) })
