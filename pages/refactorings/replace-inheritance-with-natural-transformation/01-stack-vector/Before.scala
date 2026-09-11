// Editor history: apply edits and undos, then list the survivors
// oldest-first. A Stack is-a List, so the whole List API is the
// history's API: undo is list surgery like any other operation.
object Before:
  type Stack[A] = List[A]

  enum Cmd:
    case Edit(text: String)
    case Undo

  def build(cmds: List[Cmd]): Stack[String] =
    cmds.foldLeft(Nil: Stack[String]) {
      case (h, Cmd.Edit(t)) => h :+ t
      case (h, Cmd.Undo)    => h.dropRight(1)
    }

  def replay(cmds: List[Cmd]): List[String] =
    build(cmds) // compiles only because a Stack *is* the List
