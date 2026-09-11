-- Two phone books built by inserting entries in order (later
-- numbers win), then the entries both books agree on. A Dict is-a
-- Set of pairs, so one-value-per-key is re-imposed at every put.
module Before where

import Data.List (foldl')
import Data.Set (Set)
import qualified Data.Set as Set

type Dict k v = Set (k, v)

-- Ord v: the set orders values, which a map would never need.
put :: (Ord k, Ord v) => k -> v -> Dict k v -> Dict k v
put k v d = Set.insert (k, v) (Set.filter ((/= k) . fst) d)

fill :: [(String, Int)] -> Dict String Int
fill = foldl' (\d (k, v) -> put k v d) Set.empty

common :: [(String, Int)] -> [(String, Int)] -> Set (String, Int)
common xs ys = Set.intersection (fill xs) (fill ys)
