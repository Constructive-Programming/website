// Same, with the single varName optic applied at every node: the walk
// comes from Plated (which fields recurse), not from the example.
object After:
  import Optics.*

  case class Var(name: String, ref: Int)
  enum Expr:
    case EVar(v: Var)
    case EApp(f: Expr, x: Expr)
    case ELam(bind: String, body: Expr)

  import Expr.*

  given Plated[Expr] with
    def descend(f: Expr => Expr)(e: Expr): Expr = e match
      case EApp(a, b)  => EApp(f(a), f(b))
      case ELam(b, bd) => ELam(b, f(bd))
      case e           => e

  val varP: Prism[Expr, Var] =
    Prism[Expr, Var](
      { case EVar(v) => Some(v); case _ => None },
      EVar(_),
    )
  val nameL: Lens[Var, String] =
    Lens[Var, String](_.name, (v, n) => v.copy(name = n))
  val varName: PartialLens[Expr, String] = compose(varP, nameL)

  def renameAll(e: Expr): Expr =
    summon[Plated[Expr]].everywhere(over(varName, _.toUpperCase))(e)
