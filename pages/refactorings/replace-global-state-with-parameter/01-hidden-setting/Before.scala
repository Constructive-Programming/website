// Total of an order: the lines summed, plus a fixed service fee.
object Before:
  val serviceFee = 300 // cents; a global setting

  def fee(subtotal: Int): Int = subtotal + serviceFee

  def total(lines: List[Int]): Int = fee(lines.sum)
