-- Settle transactions: refuse any that would overdraw past the
-- limit, and charge a fee on each one accepted.
module After where

import Data.List (foldl')

data Policy = Policy { limit :: Int, fee :: Int }

policy :: Policy
policy = Policy { limit = 30, fee = 2 }

applyTx :: Policy -> Int -> Int -> Int
applyTx policy balance tx =
  let next = balance + tx
  in if next < -limit policy then balance
     else next - fee policy

settle :: [Int] -> Int
settle = foldl' (applyTx policy) 0
