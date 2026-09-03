-- Total of an order: the lines summed, less a percentage discount, plus tax.
module Before where

data Line  = Line  { unitPrice :: Int, quantity :: Int }
data Order = Order { items :: [Line], discountPct :: Int, taxPct :: Int }

total :: Order -> Int
total o = discounted + discounted * taxPct o `div` 100
  where
    subtotal   = sum [unitPrice l * quantity l | l <- items o]
    discounted = subtotal - subtotal * discountPct o `div` 100
