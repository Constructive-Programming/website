-- Bump only the successes of a batch: a hand-written map carrying
-- the branch test and the rebuild in the same step.
module Before where

data Ok     = Ok     { okValue :: Int }
  deriving (Eq, Show)
data Result = Succeeded Ok | Failed String
  deriving (Eq, Show)

bumpSucceeded :: [Result] -> [Result]
bumpSucceeded = map step
  where
    step (Succeeded ok) = Succeeded ok { okValue = okValue ok + 1 }
    step f@(Failed _)   = f
