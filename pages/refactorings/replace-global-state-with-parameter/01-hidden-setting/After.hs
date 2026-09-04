-- Total of an order: the lines summed, plus a fixed service fee.
module After where

serviceFee :: Int
serviceFee = 300 -- cents; still the program's default

fee :: Int -> Int -> Int
fee serviceFee subtotal = subtotal + serviceFee

total :: [Int] -> Int
total lines = fee serviceFee (sum lines)
