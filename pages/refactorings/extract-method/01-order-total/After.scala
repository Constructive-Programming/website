// Total of an order: the lines summed, less a percentage discount, plus tax.
object After:
  case class Line(unitPrice: Int, quantity: Int)
  case class Order(items: List[Line], discountPct: Int, taxPct: Int)

  def total(o: Order): Int =
    val net        = subtotal(o.items)
    val discounted = net - percent(o.discountPct, net)
    discounted + percent(o.taxPct, discounted)

  def subtotal(items: List[Line]): Int =
    items.map(l => l.unitPrice * l.quantity).sum

  def percent(pct: Int, amount: Int): Int =
    amount * pct / 100
