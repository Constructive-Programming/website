-- Total of an order: the lines summed, plus a fixed service fee.
module Before where

serviceFee :: Int
serviceFee = 300 -- cents; a global setting

fee :: Int -> Int
fee subtotal = subtotal + serviceFee

total :: [Int] -> Int
total lines = fee (sum lines)
