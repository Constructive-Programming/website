-- Same, with a small traversal composed with a prism and a lens:
-- reach every element, match the succeeded branch, edit its value.
module After where

import Data.Maybe (listToMaybe)

data Ok     = Ok     { okValue :: Int }
  deriving (Eq, Show)
data Result = Succeeded Ok | Failed String
  deriving (Eq, Show)

data Lens s a = Lens { view :: s -> a, set :: (s, a) -> s }

modifyL :: Lens s a -> (a -> a) -> s -> s
modifyL l f s = set l (s, f (view l s))

data Prism s a = Prism
  { preview :: s -> Maybe a
  , review  :: a -> s
  }

data PartialLens s a = PartialLens
  { plPreview :: s -> Maybe a
  , plModify  :: (a -> a) -> s -> s
  }

composeO :: Prism s m -> Lens m a -> PartialLens s a
composeO p l = PartialLens
  { plPreview = \s -> view l <$> preview p s
  , plModify  = \f s -> case preview p s of
      Nothing -> s
      Just m  -> review p (modifyL l f m)
  }

-- Traversal: reach every element, and within it apply the
-- partial lens (hits edit, misses pass through).
each :: PartialLens s a -> PartialLens [s] a
each pl = PartialLens
  (\xs -> listToMaybe xs >>= plPreview pl)
  (\g xs -> map (plModify pl g) xs)

over :: PartialLens s a -> (a -> a) -> s -> s
over pl = plModify pl

succeededP :: Prism Result Ok
succeededP = Prism
  { preview = \r -> case r of Succeeded ok -> Just ok; _ -> Nothing
  , review  = Succeeded
  }

valueL :: Lens Ok Int
valueL = Lens { view = okValue, set = \(ok, v) -> ok { okValue = v } }

okVal :: PartialLens Result Int
okVal = composeO succeededP valueL

eachSucceeded :: PartialLens [Result] Int
eachSucceeded = each okVal

bumpSucceeded :: [Result] -> [Result]
bumpSucceeded = over eachSucceeded (+ 1)
