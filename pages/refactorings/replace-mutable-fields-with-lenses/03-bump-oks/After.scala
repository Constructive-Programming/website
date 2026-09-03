// Same, with a small traversal composed with a prism and a lens:
// reach every element, match the succeeded branch, edit its value.
object After:
  import Optics.*

  case class Ok(value: Int)
  enum Result:
    case Succeeded(v: Ok)
    case Failed(msg: String)

  import Result.*

  val succeededP: Prism[Result, Ok] =
    Prism[Result, Ok](
      { case Succeeded(v) => Some(v); case _ => None },
      Succeeded(_),
    )
  val valueL: Lens[Ok, Int] =
    Lens[Ok, Int](_.value, (ok, v) => ok.copy(value = v))
  val okVal: PartialLens[Result, Int] = compose(succeededP, valueL)

  val eachSucceeded: PartialLens[List[Result], Int] = each(okVal)

  def bumpSucceeded(xs: List[Result]): List[Result] =
    over(eachSucceeded, _ + 1)(xs)
