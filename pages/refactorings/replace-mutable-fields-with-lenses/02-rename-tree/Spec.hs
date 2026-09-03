{-# LANGUAGE OverloadedStrings #-}
module Main where

import Control.Monad (unless)
import System.Exit (exitFailure)
import Data.Char (isUpper)
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
genT depth =
  let leaf = TVar <$> genName <*> Gen.int (Range.linear (-10) 10)
  in if depth == 0 then leaf
     else Gen.choice
       [ leaf
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
fromAfter (After.EVar v)  = TVar (After.vName v) (After.vRef v)
fromAfter (After.EApp f x) = TApp (fromAfter f) (fromAfter x)
fromAfter (After.ELam b e) = TLam b (fromAfter e)

prop_agrees :: Property
prop_agrees = property $ do
  t <- forAll (genT 4)
  fromBefore (Before.renameAll (toBefore t))
    === fromAfter (After.renameAll (toAfter t))

allNamesUpper :: T -> Bool
allNamesUpper (TVar n _) = all isUpper n
allNamesUpper (TApp f x) = allNamesUpper f && allNamesUpper x
allNamesUpper (TLam _ b) = allNamesUpper b

refsUnchanged :: T -> T -> Bool
refsUnchanged (TVar _ r1) (TVar _ r2) = r1 == r2
refsUnchanged (TApp f1 x1) (TApp f2 x2) =
  refsUnchanged f1 f2 && refsUnchanged x1 x2
refsUnchanged (TLam _ b1) (TLam _ b2) = refsUnchanged b1 b2
refsUnchanged _ _ = False

prop_all_upper :: Property
prop_all_upper = property $ do
  t <- forAll (genT 4)
  let renamed = fromAfter (After.renameAll (toAfter t))
  allNamesUpper renamed === True
  refsUnchanged renamed t === True

main :: IO ()
main = do
  ok <- checkParallel $ Group "Props"
    [ ("renameAll: Before == After", prop_agrees)
    , ("every Var name is uppercased, refs unchanged", prop_all_upper)
    ]
  unless ok exitFailure
