-- Same, as one composed optic: the prism matches the Var branch,
-- the lens edits its name, every other shape passes through.
module After where

import Data.Char (toUpper)
import Optics (Lens(..), Prism(..), PartialLens(..), andThen, over)

data Var   = Var   { vName :: String, vRef :: Int }
  deriving (Eq, Show)
data Expr  = EVar Var | EApp Expr Expr | ELam String Expr
  deriving (Eq, Show)

varP :: Prism Expr Var
varP = Prism
  { preview = \e -> case e of EVar v -> Just v; _ -> Nothing
  , review  = EVar
  }

nameL :: Lens Var String
nameL = Lens { view = vName, set = \(v, n) -> v { vName = n } }

varName :: PartialLens Expr String
varName = varP `andThen` nameL

upperVarName :: Expr -> Expr
upperVarName = over varName (map toUpper)
