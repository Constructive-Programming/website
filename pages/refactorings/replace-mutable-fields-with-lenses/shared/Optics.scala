// Shared optic building blocks for the examples on this page. Compiled
// by run.sh but not shown, so each example presents only the move.
object Optics:
  case class Lens[S, A](view: S => A, set: (S, A) => S):
    def modify(f: A => A): S => S = s => set(s, f(view(s)))

  case class Prism[S, A](preview: S => Option[A], review: A => S):
    def modify(f: A => A): S => S =
      s => preview(s).map(a => review(f(a))).getOrElse(s)
    def andThen[B](inner: Lens[A, B]): PartialLens[S, B] =
      compose(this, inner)

  case class PartialLens[S, A](preview: S => Option[A],
                               modify: (A => A) => S => S):
    def each: PartialLens[List[S], A] = Optics.each(this)

  def compose[S, M, A](p: Prism[S, M],
                       l: Lens[M, A]): PartialLens[S, A] =
    PartialLens(
      preview = s => p.preview(s).map(l.view),
      modify = f => s => p.preview(s) match
        case Some(m) => p.review(l.modify(f)(m))
        case None    => s,
    )

  def each[S, A](pl: PartialLens[S, A]): PartialLens[List[S], A] =
    PartialLens(
      preview = _.iterator.map(pl.preview).collectFirst {
        case Some(a) => a
      },
      modify = f => _.map(pl.modify(f)),
    )

  def over[S, A](pl: PartialLens[S, A], f: A => A): S => S =
    pl.modify(f)

  trait Plated[S]:
    def descend(f: S => S)(s: S): S
    def everywhere(f: S => S): S => S =
      s => f(descend(everywhere(f))(s))

  object Plated:
    def everywhere[S](f: S => S)(using p: Plated[S]): S => S =
      p.everywhere(f)
