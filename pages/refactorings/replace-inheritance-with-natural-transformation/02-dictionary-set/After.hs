-- The same phone books as a Map, which owns one-value-per-key;
-- entries is the arrow back into the world of sets.
module After where

import Data.List (foldl')
import Data.Map (Map)
import Data.Set (Set)
import qualified Data.Map as Map
import qualified Data.Set as Set

entries :: Map k v -> Set (k, v) -- natural in v
entries = Set.fromList . Map.toList

fill :: [(String, Int)] -> Map String Int
fill = foldl' (\m (k, v) -> Map.insert k v m) Map.empty

common :: [(String, Int)] -> [(String, Int)] -> Set (String, Int)
common xs ys =
  Set.intersection (entries (fill xs)) (entries (fill ys))
