-- Shared optic building blocks for the examples on this page. Compiled
-- by run.sh but not shown, so each example presents only the move.
module Optics
  ( Lens(..), Prism(..), PartialLens(..), Plated(..)
  , andThen, each, over, modify, everywhere
  ) where

data Lens s a = Lens { view :: s -> a, set :: (s, a) -> s }

modify :: Lens s a -> (a -> a) -> s -> s
modify l f s = set l (s, f (view l s))

data Prism s a = Prism
  { preview :: s -> Maybe a
  , review  :: a -> s
  }

data PartialLens s a = PartialLens
  { plPreview :: s -> Maybe a
  , plModify  :: (a -> a) -> s -> s
  }

andThen :: Prism s m -> Lens m a -> PartialLens s a
andThen p l = PartialLens
  (\s -> view l <$> preview p s)
  (\f s -> case preview p s of
      Nothing -> s
      Just m  -> review p (modify l f m))

each :: PartialLens s a -> PartialLens [s] a
each pl = PartialLens (firstFocus . map (plPreview pl))
                      (\f -> map (plModify pl f))
  where
    firstFocus []             = Nothing
    firstFocus (Just a : _)   = Just a
    firstFocus (Nothing : xs) = firstFocus xs

over :: PartialLens s a -> (a -> a) -> s -> s
over pl = plModify pl

class Plated s where
  descend :: (s -> s) -> s -> s

everywhere :: Plated s => (s -> s) -> s -> s
everywhere f s = f (descend (everywhere f) s)
