-- Evaluate an arithmetic expression; division by zero has no value.
module After where

data Expr = Lit Int | Add Expr Expr | Mul Expr Expr | Div Expr Expr
  deriving Show

eval :: Expr -> Maybe Int
eval (Lit n)   = Just n
eval (Add l r) = binary (\a b -> Just (a + b)) l r
eval (Mul l r) = binary (\a b -> Just (a * b)) l r
eval (Div l r) = binary (\a b -> if b == 0 then Nothing else Just (a `div` b)) l r

-- Takes the operands unevaluated, so the right one is still only forced
-- when the left one has a value, exactly as in Before.
binary :: (Int -> Int -> Maybe Int) -> Expr -> Expr -> Maybe Int
binary op l r = do
  a <- eval l
  b <- eval r
  op a b
