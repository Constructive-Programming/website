// Closing balance after a run of transactions; each debit that leaves the
// account below its overdraft limit is charged a fee.
object After:
  def settle(opening: Int, limit: Int, fee: Int, txs: List[Int]): Int =
    txs.foldLeft(opening)(step(limit, fee))

  def step(limit: Int, fee: Int)(balance: Int, tx: Int): Int =
    val next = balance + tx
    if tx < 0 && next < -limit then next - fee else next
