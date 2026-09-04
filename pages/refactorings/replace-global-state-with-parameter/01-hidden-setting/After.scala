// Total of an order: the lines summed, plus a fixed service fee.
object After:
  val serviceFee = 300 // cents; still the program's default

  def fee(serviceFee: Int, subtotal: Int): Int =
    subtotal + serviceFee

  def total(lines: List[Int]): Int = fee(serviceFee, lines.sum)
