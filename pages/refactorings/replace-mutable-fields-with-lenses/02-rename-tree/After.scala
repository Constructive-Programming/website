// Same, with the single varName optic applied at every node of the
// tree: how to reach the name is defined once, and the walk only
// decides where it applies.
object After:
  import Optics.*

  case class Var(name: String, ref: Int)
  enum Expr:
    case EVar(v: Var)
    case EApp(f: Expr, x: Expr)
    case ELam(bind: String, body: Expr)

  import Expr.*

  val varP: Prism[Expr, Var] =
    Prism[Expr, Var](
      { case EVar(v) => Some(v); case _ => None },
      EVar(_),
    )
  val nameL: Lens[Var, String] =
    Lens[Var, String](_.name, (v, n) => v.copy(name = n))
  val varName: PartialLens[Expr, String] = compose(varP, nameL)

  // Bottom-up: apply the rewrite at every node, descending first.
  def everywhere(f: Expr => Expr)(e: Expr): Expr = e match
    case EVar(_)     => f(e)
    case EApp(a, b)  => f(EApp(everywhere(f)(a), everywhere(f)(b)))
    case ELam(b, bd) => f(ELam(b, everywhere(f)(bd)))

  def renameAll(e: Expr): Expr =
    everywhere(over(varName, _.toUpperCase))(e)
