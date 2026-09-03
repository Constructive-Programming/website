-- Closing balance after a run of transactions; `step` is extracted from
-- the fold lambda and stays nested, capturing `limit` and `fee`.
module After where

import Data.List (foldl')

settle :: Int -> Int -> Int -> [Int] -> Int
settle opening limit fee =
  foldl' step opening
  where
    step balance tx =
      let next = balance + tx
      in if tx < 0 && next < negate limit then next - fee else next
