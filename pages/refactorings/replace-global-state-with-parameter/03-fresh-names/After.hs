-- Number every variable in an expression tree, pre-order, with a
-- fresh-number supply.
module After where

data Expr = Var String | Lit Int | Add Expr Expr
  deriving (Eq, Show)

number :: Expr -> Expr
number e = fst (go e 0)

go :: Expr -> Int -> (Expr, Int)
go (Var name) n = (Var (name ++ show n), n + 1)
go e@(Lit _) n = (e, n)
go (Add l r) n =
  let (l', n') = go l n
      (r', n'') = go r n'
  in (Add l' r', n'')
