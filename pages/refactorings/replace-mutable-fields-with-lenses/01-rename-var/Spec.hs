{-# LANGUAGE OverloadedStrings #-}
module Main where

import Control.Monad (unless)
import System.Exit (exitFailure)
import Data.Char (toUpper)
import Hedgehog
import qualified Hedgehog.Gen as Gen
import qualified Hedgehog.Range as Range
import qualified Before
import qualified After

-- A neutral tree, so one generated input feeds both Expr types.
data T = TVar String Int | TApp T T | TLam String T
  deriving (Eq, Show)

genName :: Gen String
genName = Gen.string (Range.linear 0 4) Gen.alpha

genT :: Int -> Gen T
genT 0 = TVar <$> genName <*> Gen.int (Range.linear (-10) 10)
genT depth = Gen.choice
  [ TVar <$> genName <*> Gen.int (Range.linear (-10) 10)
  , TApp <$> genT (depth - 1) <*> genT (depth - 1)
  , TLam <$> genName <*> genT (depth - 1)
  ]

toBefore :: T -> Before.Expr
toBefore (TVar n r) = Before.EVar (Before.Var n r)
toBefore (TApp f x) = Before.EApp (toBefore f) (toBefore x)
toBefore (TLam b e) = Before.ELam b (toBefore e)

fromBefore :: Before.Expr -> T
fromBefore (Before.EVar v)  = TVar (Before.vName v) (Before.vRef v)
fromBefore (Before.EApp f x) = TApp (fromBefore f) (fromBefore x)
fromBefore (Before.ELam b e) = TLam b (fromBefore e)

toAfter :: T -> After.Expr
toAfter (TVar n r) = After.EVar (After.Var n r)
toAfter (TApp f x) = After.EApp (toAfter f) (toAfter x)
toAfter (TLam b e) = After.ELam b (toAfter e)

fromAfter :: After.Expr -> T
fromAfter (After.EVar v)   = TVar (After.vName v) (After.vRef v)
fromAfter (After.EApp f x) = TApp (fromAfter f) (fromAfter x)
fromAfter (After.ELam b e) = TLam b (fromAfter e)

prop_agrees :: Property
prop_agrees = property $ do
  t <- forAll (genT 4)
  fromBefore (Before.upperVarName (toBefore t))
    === fromAfter (After.upperVarName (toAfter t))

noVars :: T -> Bool
noVars (TVar _ _) = False
noVars (TApp f x) = noVars f && noVars x
noVars (TLam _ e) = noVars e

prop_hit_and_miss :: Property
prop_hit_and_miss = property $ do
  n <- forAll genName
  t <- forAll (genT 3)
  After.upperVarName (After.EVar (After.Var n 0))
    === After.EVar (After.Var (map toUpper n) 0)
  if noVars t
    then fromAfter (After.upperVarName (toAfter t)) === t
    else success

main :: IO ()
main = do
  ok <- checkParallel $ Group "Props"
    [ ("upperVarName: Before == After", prop_agrees)
    , ("the hit is uppercased, misses pass through", prop_hit_and_miss)
    ]
  unless ok exitFailure
