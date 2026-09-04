// Number every variable in an expression tree, pre-order, with a
// fresh-number supply.
object After:
  enum Expr:
    case Var(name: String)
    case Lit(value: Int)
    case Add(lhs: Expr, rhs: Expr)

  def number(e: Expr): Expr = go(e, 0)._1

  private def go(e: Expr, n: Int): (Expr, Int) = e match
    case Expr.Var(name) => (Expr.Var(name + n), n + 1)
    case Expr.Lit(_)    => (e, n)
    case Expr.Add(l, r) =>
      val (l1, n1) = go(l, n)
      val (r1, n2) = go(r, n1)
      (Expr.Add(l1, r1), n2)
