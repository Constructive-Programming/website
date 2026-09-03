// Uppercase the variable of one Var node: a hand-written match
// that rebuilds the hit branch and lets every other shape pass.
object Before:
  case class Var(name: String, ref: Int)
  enum Expr:
    case EVar(v: Var)
    case EApp(f: Expr, x: Expr)
    case ELam(bind: String, body: Expr)

  import Expr.*

  def upperVarName(e: Expr): Expr = e match
    case EVar(v) => EVar(v.copy(name = v.name.toUpperCase))
    case other   => other
