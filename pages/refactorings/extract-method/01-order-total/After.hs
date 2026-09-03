-- Total of an order: the lines summed, less a percentage discount, plus tax.
module After where

data Line  = Line  { unitPrice :: Int, quantity :: Int }
data Order = Order { items :: [Line], discountPct :: Int, taxPct :: Int }

total :: Order -> Int
total o = discounted + percent (taxPct o) discounted
  where
    net        = subtotal (items o)
    discounted = net - percent (discountPct o) net

subtotal :: [Line] -> Int
subtotal ls = sum [unitPrice l * quantity l | l <- ls]

percent :: Int -> Int -> Int
percent pct amount = amount * pct `div` 100
