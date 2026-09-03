{-# LANGUAGE OverloadedStrings #-}
module Main where

import Control.Monad (unless)
import System.Exit (exitFailure)
import Hedgehog
import qualified Hedgehog.Gen as Gen
import qualified Hedgehog.Range as Range
import qualified Before
import qualified After

genExpr :: Gen Before.Expr
genExpr = Gen.recursive Gen.choice
  [ Before.Lit <$> Gen.int (Range.linear (-20) 20) ]
  [ Gen.subterm2 genExpr genExpr Before.Add
  , Gen.subterm2 genExpr genExpr Before.Mul
  , Gen.subterm2 genExpr genExpr Before.Div
  ]

toAfter :: Before.Expr -> After.Expr
toAfter (Before.Lit n)   = After.Lit n
toAfter (Before.Add l r) = After.Add (toAfter l) (toAfter r)
toAfter (Before.Mul l r) = After.Mul (toAfter l) (toAfter r)
toAfter (Before.Div l r) = After.Div (toAfter l) (toAfter r)

prop_eval_agrees :: Property
prop_eval_agrees = property $ do
  e <- forAll genExpr
  Before.eval e === After.eval (toAfter e)

-- A left operand without a value short-circuits: the right operand is never
-- forced, before and after. (Division by zero has no value, so it does not throw here.)
prop_short_circuit_preserved :: Property
prop_short_circuit_preserved = property $ do
  e <- forAll genExpr
  Before.eval (Before.Add (Before.Div e (Before.Lit 0)) undefined) === Nothing
  After.eval (After.Add (After.Div (toAfter e) (After.Lit 0)) undefined) === Nothing

main :: IO ()
main = do
  ok <- checkParallel $ Group "Props"
    [ ("eval: Before == After", prop_eval_agrees)
    , ("short-circuit on a valueless left operand is preserved", prop_short_circuit_preserved)
    ]
  unless ok exitFailure
