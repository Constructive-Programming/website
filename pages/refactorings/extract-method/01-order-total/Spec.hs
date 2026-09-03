{-# LANGUAGE OverloadedStrings #-}
module Main where

import Control.Monad (unless)
import System.Exit (exitFailure)
import Hedgehog
import qualified Hedgehog.Gen as Gen
import qualified Hedgehog.Range as Range
import qualified Before
import qualified After

-- Raw values, so the same input can be fed to both Before.Order and After.Order.
genLine :: Gen (Int, Int)
genLine = (,) <$> Gen.int (Range.linear (-100) 1000) <*> Gen.int (Range.linear 0 20)

genOrder :: Gen ([(Int, Int)], Int, Int)
genOrder = (,,) <$> Gen.list (Range.linear 0 10) genLine
                <*> Gen.int (Range.linear 0 100)
                <*> Gen.int (Range.linear 0 30)

prop_total_agrees :: Property
prop_total_agrees = property $ do
  (items, d, t) <- forAll genOrder
  Before.total (Before.Order (map (uncurry Before.Line) items) d t)
    === After.total (After.Order (map (uncurry After.Line) items) d t)

prop_plain_total_is_subtotal :: Property
prop_plain_total_is_subtotal = property $ do
  items <- forAll (Gen.list (Range.linear 0 10) genLine)
  let ls = map (uncurry After.Line) items
  After.total (After.Order ls 0 0) === After.subtotal ls

main :: IO ()
main = do
  ok <- checkParallel $ Group "Props"
    [ ("total: Before == After", prop_total_agrees)
    , ("no discount, no tax: total == subtotal", prop_plain_total_is_subtotal)
    ]
  unless ok exitFailure
