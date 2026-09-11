// Order quantity from a raw form field. One result class is-a
// two views at once: the diagnosis and the presence. Every caller
// of either view is coupled to the class that owns both.
object Before:
  trait Diagnosed { def err: Option[String] }
  trait Present   { def value: Option[Int]  }

  enum Result extends Diagnosed, Present:
    case Bad(why: String)
    case Ok(n: Int)

    def err: Option[String] = this match
      case Bad(why) => Some(why)
      case Ok(_)    => None

    def value: Option[Int] = this match
      case Bad(_) => None
      case Ok(n)  => Some(n)

  def parse(raw: String): Result =
    raw.toIntOption match
      case Some(n) if n > 0 => Result.Ok(n)
      case Some(_)          => Result.Bad("not positive")
      case None             => Result.Bad("not a number")

  def quantity(raw: String): Option[Int] =
    parse(raw).value
