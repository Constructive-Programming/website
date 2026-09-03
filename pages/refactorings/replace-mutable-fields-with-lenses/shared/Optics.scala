// Shared optic building blocks for the examples on this page: a Lens,
// a Prism, a composed PartialLens, and a traversal `each`. Compiled by
// run.sh but not shown on the page, so each example is the move itself.
object Optics:
  case class Lens[S, A](view: S => A, set: (S, A) => S):
    def modify(f: A => A): S => S = s => set(s, f(view(s)))

  case class Prism[S, A](preview: S => Option[A], review: A => S):
    def modify(f: A => A): S => S =
      s => preview(s).map(a => review(f(a))).getOrElse(s)

  // A prism followed by a lens: hit -> edit the field; miss -> pass through.
  case class PartialLens[S, A](preview: S => Option[A],
                               modify: (A => A) => S => S)

  def compose[S, M, A](p: Prism[S, M], l: Lens[M, A]): PartialLens[S, A] =
    PartialLens(
      preview = s => p.preview(s).map(l.view),
      modify  = f => s => p.preview(s) match
        case Some(m) => p.review(l.modify(f)(m))
        case None    => s,
    )

  // A traversal: reach every element, apply the partial lens to each.
  def each[S, A](pl: PartialLens[S, A]): PartialLens[List[S], A] =
    PartialLens(
      preview = _.headOption.flatMap(pl.preview),
      modify  = f => _.map(pl.modify(f)),
    )

  def over[S, A](pl: PartialLens[S, A], f: A => A): S => S =
    pl.modify(f)

  // Plated: the recursion of a recursive type, as a value. An instance
  // says which fields are the sub-terms (the "plate"); `everywhere`
  // then applies a rewrite at every node, bottom-up, without the type
  // knowing how to walk itself.
  trait Plated[S]:
    def descend(f: S => S)(s: S): S
    def everywhere(f: S => S): S => S =
      s => descend(everywhere(f))(f(s))

