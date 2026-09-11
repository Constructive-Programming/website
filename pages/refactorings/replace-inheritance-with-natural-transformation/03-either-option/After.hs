-- Order quantity from a raw form field. One canonical type at
-- the boundary; each view is an arrow, not a superclass.
module After where

import Text.Read (readMaybe)

parse :: String -> Either String Int
parse raw = case readMaybe raw of
  Just n | n > 0 -> Right n
  Just _         -> Left "not positive"
  Nothing        -> Left "not a number"

toMaybe :: Either e a -> Maybe a -- natural in a
toMaybe = either (const Nothing) Just

quantity :: String -> Maybe Int
quantity raw = toMaybe (parse raw)
