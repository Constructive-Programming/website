{-# LANGUAGE OverloadedStrings #-}
module Main where

import Control.Monad (unless)
import System.Exit (exitFailure)
import Hedgehog
import qualified Hedgehog.Gen as Gen
import qualified Hedgehog.Range as Range
import qualified Before
import qualified After

-- A neutral list element, so one generated input feeds both types.
data R = Succeeded Int | Failed String
  deriving (Eq, Show)

genValue :: Gen Int
genValue = Gen.int (Range.linear (-100) 100)

genMsg :: Gen String
genMsg = Gen.string (Range.linear 0 6) Gen.alpha

genR :: Gen R
genR = Gen.choice
  [ Succeeded <$> genValue
  , Failed <$> genMsg
  ]

toBefore :: R -> Before.Result
toBefore (Succeeded v) = Before.Succeeded (Before.Ok v)
toBefore (Failed m)    = Before.Failed m

fromBefore :: Before.Result -> R
fromBefore (Before.Succeeded ok) = Succeeded (Before.okValue ok)
fromBefore (Before.Failed m)     = Failed m

toAfter :: R -> After.Result
toAfter (Succeeded v) = After.Succeeded (After.Ok v)
toAfter (Failed m)    = After.Failed m

fromAfter :: After.Result -> R
fromAfter (After.Succeeded ok) = Succeeded (After.okValue ok)
fromAfter (After.Failed m)     = Failed m

prop_agrees :: Property
prop_agrees = property $ do
  xs <- forAll (Gen.list (Range.linear 0 10) genR)
  map fromBefore (Before.bumpSucceeded (map toBefore xs))
    === map fromAfter (After.bumpSucceeded (map toAfter xs))

prop_only_succeeded :: Property
prop_only_succeeded = property $ do
  xs <- forAll (Gen.list (Range.linear 0 10) genR)
  let bumped = map fromAfter (After.bumpSucceeded (map toAfter xs))
  and (zipWith check bumped xs) === True
  where
    check (Succeeded v1) (Succeeded v0) = v1 == v0 + 1
    check (Failed m1)    (Failed m0)    = m1 == m0
    check _ _                           = False

main :: IO ()
main = do
  ok <- checkParallel $ Group "Props"
    [ ("bumpSucceeded: Before == After", prop_agrees)
    , ("only successes bumped, messages pass through",
      prop_only_succeeded)
    ]
  unless ok exitFailure
