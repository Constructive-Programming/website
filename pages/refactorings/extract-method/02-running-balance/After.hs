-- Closing balance after a run of transactions; each debit that leaves the
-- account below its overdraft limit is charged a fee.
module After where

import Data.List (foldl')

settle :: Int -> Int -> Int -> [Int] -> Int
settle opening limit fee = foldl' (step limit fee) opening

step :: Int -> Int -> Int -> Int -> Int
step limit fee balance tx =
  let next = balance + tx
  in if tx < 0 && next < negate limit then next - fee else next
