{-# LANGUAGE OverloadedStrings #-}
module Main where

import Control.Monad (unless)
import System.Exit (exitFailure)
import Hedgehog
import qualified Hedgehog.Gen as Gen
import qualified Hedgehog.Range as Range
import qualified Before
import qualified After

-- Narrow range, so the overdraft boundary (next == -limit) is hit
-- often.
genTxs :: Gen [Int]
genTxs =
  Gen.list (Range.linear 0 20) (Gen.int (Range.linear (-30) 30))

prop_settle_agrees :: Property
prop_settle_agrees = withTests 500 $ property $ do
  txs <- forAll genTxs
  Before.settle txs === After.settle txs

-- The record is now an argument, so other policies are testable:
-- with no fee and a limit out of reach, the step is plain addition.
prop_neutral_settings :: Property
prop_neutral_settings = property $ do
  b <- forAll (Gen.int (Range.linear (-30) 30))
  t <- forAll (Gen.int (Range.linear (-30) 30))
  After.applyTx (After.Policy 10000 0) b t === b + t

main :: IO ()
main = do
  ok <- checkParallel $ Group "Props"
    [ ("settle: Before == After", prop_settle_agrees)
    , ( "settings as parameter: fee 0, wide limit sums"
      , prop_neutral_settings )
    ]
  unless ok exitFailure
