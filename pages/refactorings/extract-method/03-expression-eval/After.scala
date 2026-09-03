// Evaluate an arithmetic expression; division by zero has no value.
object After:
  enum Expr:
    case Lit(n: Int)
    case Add(l: Expr, r: Expr)
    case Mul(l: Expr, r: Expr)
    case Div(l: Expr, r: Expr)
  import Expr.*

  def eval(e: Expr): Option[Int] = e match
    case Lit(n)    => Some(n)
    case Add(l, r) => binary(l, r)((a, b) => Some(a + b))
    case Mul(l, r) => binary(l, r)((a, b) => Some(a * b))
    case Div(l, r) => binary(l, r)((a, b) => Option.when(b != 0)(a / b))

  // Takes the operands unevaluated, so the right one is still only evaluated
  // when the left one has a value, exactly as in Before.
  def binary(l: Expr, r: Expr)(op: (Int, Int) => Option[Int]): Option[Int] =
    for a <- eval(l); b <- eval(r); c <- op(a, b) yield c
