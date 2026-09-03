// Same, as one composed optic: the prism matches the Var branch,
// the lens edits its name, every other shape passes through.
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

  def upperVarName(e: Expr): Expr = over(varName, _.toUpperCase)(e)
