// Total of an order: the lines summed, less a percentage discount, plus tax.
object Before:
  case class Line(unitPrice: Int, quantity: Int)
  case class Order(items: List[Line], discountPct: Int, taxPct: Int)

  def total(o: Order): Int =
    val subtotal   = o.items.map(l => l.unitPrice * l.quantity).sum
    val discounted = subtotal - subtotal * o.discountPct / 100
    discounted + discounted * o.taxPct / 100
