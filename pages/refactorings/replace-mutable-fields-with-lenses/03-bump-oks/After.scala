// Same, with a small traversal composed with a prism and a lens:
// reach every element, match the succeeded branch, edit its value.
object After:
  case class Ok(value: Int)
  enum Result:
    case Succeeded(v: Ok)
    case Failed(msg: String)

  import Result.*

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
  // Traversal: reach every element, and within it apply the
  // partial lens (hits edit, misses pass through).
  def each[S, A](pl: PartialLens[S, A]): PartialLens[List[S], A] =
    PartialLens(
      preview = _.headOption.flatMap(pl.preview),
      modify  = f => _.map(pl.modify(f)),
    )

  def over[S, A](pl: PartialLens[S, A], f: A => A): S => S =
    pl.modify(f)

  val succeededP: Prism[Result, Ok] =
    Prism[Result, Ok](
      { case Succeeded(v) => Some(v); case _ => None },
      Succeeded(_),
    )
  val valueL: Lens[Ok, Int] =
    Lens[Ok, Int](_.value, (ok, v) => ok.copy(value = v))
  val okValue: PartialLens[Result, Int] = compose(succeededP, valueL)

  val eachSucceeded: PartialLens[List[Result], Int] =
    each(okValue)

  def bumpSucceeded(xs: List[Result]): List[Result] =
    over(eachSucceeded, _ + 1)(xs)
