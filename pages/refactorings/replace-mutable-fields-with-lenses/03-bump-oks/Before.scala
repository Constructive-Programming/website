// Bump only the successes of a batch: a hand-written map carrying
// the branch test and the rebuild in the same step.
object Before:
  case class Ok(value: Int)
  enum Result:
    case Succeeded(v: Ok)
    case Failed(msg: String)

  import Result.*

  def bumpSucceeded(xs: List[Result]): List[Result] =
    xs.map {
      case Succeeded(ok) => Succeeded(ok.copy(value = ok.value + 1))
      case f @ Failed(_) => f
    }
