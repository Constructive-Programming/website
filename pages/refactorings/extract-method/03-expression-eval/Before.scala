// Evaluate an arithmetic expression; division by zero has no value.
object Before:
  enum Expr:
    case Lit(n: Int)
    case Add(l: Expr, r: Expr)
    case Mul(l: Expr, r: Expr)
    case Div(l: Expr, r: Expr)
  import Expr.*

  def eval(e: Expr): Option[Int] = e match
    case Lit(n)    => Some(n)
    case Add(l, r) => for a <- eval(l); b <- eval(r) yield a + b
    case Mul(l, r) => for a <- eval(l); b <- eval(r) yield a * b
    case Div(l, r) => for a <- eval(l); b <- eval(r); if b != 0 yield a / b
