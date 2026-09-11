// Order quantity from a raw form field. One canonical type at
// the boundary; each view is an arrow, not a superclass.
object After:
  def parse(raw: String): Either[String, Int] =
    raw.toIntOption match
      case Some(n) if n > 0 => Right(n)
      case Some(_)          => Left("not positive")
      case None             => Left("not a number")

  def toOption[E, A](e: Either[E, A]): Option[A] = // natural in A
    e.fold(_ => None, Some(_))

  def quantity(raw: String): Option[Int] =
    toOption(parse(raw))
