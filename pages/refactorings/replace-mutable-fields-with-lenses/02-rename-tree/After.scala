// Same, with the single varName optic applied at every node of the
// tree: how to reach the name is defined once, and the walk only
// decides where it applies.
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

  // Bottom-up: apply the rewrite at every node, descending first.
  def everywhere(f: Expr => Expr)(e: Expr): Expr = e match
    case EVar(_)     => f(e)
    case EApp(a, b)  => f(EApp(everywhere(f)(a), everywhere(f)(b)))
    case ELam(b, bd) => f(ELam(b, everywhere(f)(bd)))

  def renameAll(e: Expr): Expr =
    everywhere(over(varName, _.toUpperCase))(e)
