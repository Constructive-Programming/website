// Number every variable in an expression tree, pre-order, with a
// fresh-number supply.
object Before:
  enum Expr:
    case Var(name: String)
    case Lit(value: Int)
    case Add(lhs: Expr, rhs: Expr)

  var supply = 0 // global fresh-number supply

  def number(e: Expr): Expr =
    supply = 0
    go(e)

  private def go(e: Expr): Expr = e match
    case Expr.Var(name) =>
      val n = supply
      supply += 1
      Expr.Var(name + n)
    case Expr.Lit(_) => e
    case Expr.Add(l, r) => Expr.Add(go(l), go(r))
