// Grow the size of every node of a file tree by the same amount.
object Before:
  case class Node(name: String, size: Int, children: List[Node])

  def bumpSizes(n: Node, by: Int): Node =
    n.copy(
      size = n.size + by,
      children = n.children.map(bumpSizes(_, by)))
