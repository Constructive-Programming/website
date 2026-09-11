-- Order quantity from a raw form field. One result type carries
-- two views at once: the diagnosis and the presence. Every caller
-- of either view is coupled to the type that owns both.
module Before where

import Text.Read (readMaybe)

data Result = Bad String | Ok Int

err :: Result -> Maybe String -- the diagnosis view
err (Bad why) = Just why
err (Ok _)    = Nothing

value :: Result -> Maybe Int -- the presence view
value (Bad _) = Nothing
value (Ok n)  = Just n

parse :: String -> Result
parse raw = case readMaybe raw of
  Just n | n > 0 -> Ok n
  Just _         -> Bad "not positive"
  Nothing        -> Bad "not a number"

quantity :: String -> Maybe Int
quantity raw = value (parse raw)
