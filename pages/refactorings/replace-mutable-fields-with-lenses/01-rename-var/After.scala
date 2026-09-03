// Same, as one composed optic: the prism matches the Var branch,
// the lens edits its name, every other shape passes through.
object After:
  case class Var(name: String, ref: Int)
  enum Expr:
    case EVar(v: Var)
    case EApp(f: Expr, x: Expr)
    case ELam(bind: String, body: Expr)

  import Expr.*

  case class Lens[S, A](view: S => A, set: (S, A) => S):
    def modify(f: A => A): S => S = s => set(s, f(view(s)))

  case class Prism[S, A](preview: S => Option[A], review: A => S):
    def modify(f: A => A): S => S =
      s => preview(s).map(a => review(f(a))).getOrElse(s)
  // A prism followed by a lens: hit → edit the field;
  // miss → pass through.
  case class PartialLens[S, A](preview: S => Option[A],
                               modify: (A => A) => S => S)

  def compose[S, M, A](p: Prism[S, M],
                     l: Lens[M, A]): PartialLens[S, A] =
    PartialLens(
      preview = s => p.preview(s).map(l.view),
      modify  = f => s => p.preview(s) match
        case Some(m) => p.review(l.modify(f)(m))
        case None    => s,
    )

  def over[S, A](pl: PartialLens[S, A], f: A => A): S => S =
    pl.modify(f)

  val varP: Prism[Expr, Var] =
    Prism[Expr, Var](
      { case EVar(v) => Some(v); case _ => None },
      EVar(_),
    )
  val nameL: Lens[Var, String] =
    Lens[Var, String](_.name, (v, n) => v.copy(name = n))

  val varName: PartialLens[Expr, String] = compose(varP, nameL)

  def upperVarName(e: Expr): Expr = over(varName, _.toUpperCase)(e)
