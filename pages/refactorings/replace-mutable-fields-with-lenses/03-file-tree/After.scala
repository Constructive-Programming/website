// Same, with a lens on the size field: the write goes through the
// lens; the recursion over children is unchanged.
object After:
  case class Node(name: String, size: Int, children: List[Node])

  case class Lens[S, A](get: S => A, set: A => S => S):
    def modify(f: A => A): S => S = s => set(f(get(s)))(s)

  val size: Lens[Node, Int] =
    Lens[Node, Int](_.size, v => n => n.copy(size = v))

  def bumpSizes(n: Node, by: Int): Node =
    size.modify(_ + by)(
      n.copy(children = n.children.map(bumpSizes(_, by))))
