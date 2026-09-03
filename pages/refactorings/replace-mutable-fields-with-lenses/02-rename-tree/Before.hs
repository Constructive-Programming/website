-- Uppercase the variable of every Var node: a recursive walk that
-- rebuilds each hit by hand.
module Before where

import Data.Char (toUpper)

data Var  = Var  { vName :: String, vRef :: Int }
  deriving (Eq, Show)
data Expr = EVar Var | EApp Expr Expr | ELam String Expr
  deriving (Eq, Show)

renameAll :: Expr -> Expr
renameAll (EVar v)     = EVar v { vName = map toUpper (vName v) }
renameAll (EApp f x)   = EApp (renameAll f) (renameAll x)
renameAll (ELam b bd)  = ELam b (renameAll bd)
