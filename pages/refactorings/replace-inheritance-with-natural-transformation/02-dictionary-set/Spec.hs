{-# LANGUAGE OverloadedStrings #-}
module Main where

import Control.Monad (unless)
import System.Exit (exitFailure)
import Hedgehog
import qualified Hedgehog.Gen as Gen
import qualified Hedgehog.Range as Range
import qualified Data.Map as Map
import qualified Data.Set as Set
import qualified Before
import qualified After

-- Five names and ten numbers, so books collide on keys often and
-- later-wins is exercised with equal and unequal values.
genBook :: Gen [(String, Int)]
genBook = Gen.list (Range.linear 0 12) $
  (,) <$> Gen.element ["ann", "bo", "cy", "dee", "ed"]
      <*> Gen.int (Range.linear 0 9)

prop_common_agrees :: Property
prop_common_agrees = property $ do
  xs <- forAll genBook
  ys <- forAll genBook
  Before.common xs ys === After.common xs ys

prop_entries_natural :: Property
prop_entries_natural = property $ do
  xs <- forAll genBook
  let m = After.fill xs
      f = (`mod` 3) -- not injective, on purpose
  After.entries (Map.map f m)
    === Set.map (\(k, v) -> (k, f v)) (After.entries m)

main :: IO ()
main = do
  ok <- checkParallel $ Group "Props"
    [ ("common: Before == After", prop_common_agrees)
    , ("entries is natural in v", prop_entries_natural)
    ]
  unless ok exitFailure
