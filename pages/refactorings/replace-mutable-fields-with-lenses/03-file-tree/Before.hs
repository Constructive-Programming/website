-- Grow the size of every node of a file tree by the same amount.
module Before where

data Node = Node { name :: String, size :: Int, children :: [Node] }
  deriving (Eq, Show)

bumpSizes :: Node -> Int -> Node
bumpSizes n by =
  n { size = size n + by
    , children = map (`bumpSizes` by) (children n)
    }
