-- Evaluate an arithmetic expression; division by zero has no value.
module Before where

data Expr = Lit Int | Add Expr Expr | Mul Expr Expr | Div Expr Expr
  deriving Show

eval :: Expr -> Maybe Int
eval (Lit n)   = Just n
eval (Add l r) = do
  a <- eval l
  b <- eval r
  Just (a + b)
eval (Mul l r) = do
  a <- eval l
  b <- eval r
  Just (a * b)
eval (Div l r) = do
  a <- eval l
  b <- eval r
  if b == 0 then Nothing else Just (a `div` b)
