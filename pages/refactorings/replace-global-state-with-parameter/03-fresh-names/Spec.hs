{-# LANGUAGE OverloadedStrings #-}
module Main where

import Control.Monad (unless)
import Control.Monad.IO.Class (liftIO)
import System.Exit (exitFailure)
import Hedgehog
import qualified Hedgehog.Gen as Gen
import qualified Hedgehog.Range as Range
import qualified Before
import qualified After

-- A neutral tree, so one input feeds both Expr types. Names are
-- always "x": the supply numbers occurrences, not names.
data T = TVar | TLit Int | TAdd T T
  deriving (Eq, Show)

genT :: Int -> Gen T
genT depth =
  let leaf = Gen.choice
        [ pure TVar
        , TLit <$> Gen.int (Range.linear (-30) 30)
        ]
  in if depth == 0 then leaf
     else Gen.choice
       [ leaf
       , TAdd <$> genT (depth - 1) <*> genT (depth - 1)
       ]

toBefore :: T -> Before.Expr
toBefore TVar = Before.Var "x"
toBefore (TLit v) = Before.Lit v
toBefore (TAdd l r) = Before.Add (toBefore l) (toBefore r)

toAfter :: T -> After.Expr
toAfter TVar = After.Var "x"
toAfter (TLit v) = After.Lit v
toAfter (TAdd l r) = After.Add (toAfter l) (toAfter r)

-- The walk, as the list of variable labels in pre-order. Forces
-- the spine and the labels only, never a Lit's payload.
labelsBefore :: Before.Expr -> [String]
labelsBefore (Before.Var n) = [n]
labelsBefore (Before.Lit _) = []
labelsBefore (Before.Add l r) =
  labelsBefore l ++ labelsBefore r

labelsAfter :: After.Expr -> [String]
labelsAfter (After.Var n) = [n]
labelsAfter (After.Lit _) = []
labelsAfter (After.Add l r) = labelsAfter l ++ labelsAfter r

-- Reading and incrementing the supply is the whole of the state,
-- so equal label lists mean equal reads in equal order.
prop_agrees :: Property
prop_agrees = property $ do
  t <- forAll (genT 4)
  b <- liftIO (Before.number (toBefore t))
  labelsBefore b === labelsAfter (After.number (toAfter t))

-- Whatever the tree holds, its labels must be exactly x0, x1, ...
-- in visit order: no skips, no repeats, no reordering.
prop_labels_run :: Property
prop_labels_run = property $ do
  t <- forAll (genT 4)
  let ls = labelsAfter (After.number (toAfter t))
  let expected =
        take (length ls) (map (\i -> "x" ++ show i) [0 :: Int ..])
  ls === expected

-- The Lit payload is never forced: an undefined there survives the
-- numbering in both versions, because labels touches only the spine.
prop_lazy_probe :: Property
prop_lazy_probe = property $ do
  let probe = Before.Add (Before.Var "x") (Before.Lit undefined)
  b <- liftIO (Before.number probe)
  labelsBefore b === ["x0"]
  let probe' = After.Add (After.Var "x") (After.Lit undefined)
  labelsAfter (After.number probe') === ["x0"]

main :: IO ()
main = do
  -- checkSequential: the properties share Before's top-level supply.
  ok <- checkSequential $ Group "Props"
    [ ("number: Before == After", prop_agrees)
    , ("labels run x0, x1, ... in pre-order", prop_labels_run)
    , ("a Lit payload is never forced", prop_lazy_probe)
    ]
  unless ok exitFailure
