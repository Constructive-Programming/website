-- Shared optic building blocks for the examples on this page: a Lens,
-- a Prism, a composed PartialLens, and a traversal `each`. Compiled by
-- run.sh but not shown on the page, so each example is the move itself.
module Optics (Lens(..), Prism(..), PartialLens(..), Plated(..), everywhere, composeO, each, over, modify) where

import Data.Maybe (listToMaybe)

data Lens s a = Lens { view :: s -> a, set :: (s, a) -> s }

modify :: Lens s a -> (a -> a) -> s -> s
modify l f s = set l (s, f (view l s))

data Prism s a = Prism
  { preview :: s -> Maybe a
  , review  :: a -> s
  }

-- A prism followed by a lens: hit -> edit the field; miss -> pass through.
data PartialLens s a = PartialLens
  { plPreview :: s -> Maybe a
  , plModify  :: (a -> a) -> s -> s
  }

composeO :: Prism s m -> Lens m a -> PartialLens s a
composeO p l = PartialLens
  ( \s -> view l <$> preview p s
  ) ( \f s -> case preview p s of
        Nothing -> s
        Just m  -> review p (modify l f m)
  )

-- A traversal: reach every element, apply the partial lens to each.
each :: PartialLens s a -> PartialLens [s] a
each pl = PartialLens
  (\xs -> listToMaybe xs >>= plPreview pl)
  (\f xs -> map (plModify pl f) xs)

over :: PartialLens s a -> (a -> a) -> s -> s
over pl = plModify pl

-- Plated: the recursion of a recursive type, as a value. An instance
-- says which fields are the sub-terms (the "plate"); `everywhere`
-- then applies a rewrite at every node, bottom-up.
class Plated s where
  descend :: (s -> s) -> s -> s

everywhere :: Plated s => (s -> s) -> s -> s
everywhere f s = descend (everywhere f) (f s)

