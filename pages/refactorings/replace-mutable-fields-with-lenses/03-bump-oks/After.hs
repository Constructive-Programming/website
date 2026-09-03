-- Same, with a small traversal composed with a prism and a lens:
-- reach every element, match the succeeded branch, edit its value.
module After where

import Optics
  ( Lens(..), Prism(..), PartialLens(..)
  , andThen, each, over
  )

data Ok     = Ok     { okValue :: Int }
  deriving (Eq, Show)
data Result = Succeeded Ok | Failed String
  deriving (Eq, Show)

succeededP :: Prism Result Ok
succeededP = Prism
  { preview = \r -> case r of Succeeded ok -> Just ok; _ -> Nothing
  , review  = Succeeded
  }

valueL :: Lens Ok Int
valueL = Lens { view = okValue, set = \(ok, v) -> ok { okValue = v } }

eachSucceeded :: PartialLens [Result] Int
eachSucceeded = each (succeededP `andThen` valueL)

bumpSucceeded :: [Result] -> [Result]
bumpSucceeded = over eachSucceeded (+ 1)
