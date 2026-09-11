// Editor history: apply edits and undos, then list the survivors
// oldest-first. Stack owns its discipline; toList is the arrow out.
object After:
  final case class Stack[A](private val repr: List[A]):
    def push(a: A): Stack[A]        = Stack(repr :+ a)
    def undo: Stack[A]              = Stack(repr.dropRight(1))
    def map[B](f: A => B): Stack[B] = Stack(repr.map(f))
    def toList: List[A]             = repr // natural in A

  object Stack:
    def empty[A]: Stack[A] = Stack(Nil)

  enum Cmd:
    case Edit(text: String)
    case Undo

  def build(cmds: List[Cmd]): Stack[String] =
    cmds.foldLeft(Stack.empty[String]) {
      case (s, Cmd.Edit(t)) => s.push(t)
      case (s, Cmd.Undo)    => s.undo
    }

  def replay(cmds: List[Cmd]): List[String] =
    build(cmds).toList // build(cmds) alone does not compile now
