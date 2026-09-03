-- Uppercase the variable of one Var node: a hand-written match
-- that rebuilds the hit branch and lets every other shape pass.
module Before where

import Data.Char (toUpper)

data Var   = Var   { vName :: String, vRef :: Int }
  deriving (Eq, Show)
data Expr  = EVar Var | EApp Expr Expr | ELam String Expr
  deriving (Eq, Show)

upperVarName :: Expr -> Expr
upperVarName (EVar v) = EVar v { vName = map toUpper (vName v) }
upperVarName e        = e
