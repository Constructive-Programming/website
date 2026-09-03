// Uppercase the variable of every Var node: a recursive walk that
// rebuilds each hit by hand.
object Before:
  case class Var(name: String, ref: Int)
  enum Expr:
    case EVar(v: Var)
    case EApp(f: Expr, x: Expr)
    case ELam(bind: String, body: Expr)

  import Expr.*

  def renameAll(e: Expr): Expr = e match
    case EVar(v)     => EVar(v.copy(name = v.name.toUpperCase))
    case EApp(f, x)  => EApp(renameAll(f), renameAll(x))
    case ELam(b, bd) => ELam(b, renameAll(bd))
