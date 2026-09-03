// Closing balance after a run of transactions; each debit that leaves the
// account below its overdraft limit is charged a fee.
object Before:
  def settle(opening: Int, limit: Int, fee: Int, txs: List[Int]): Int =
    txs.foldLeft(opening) { (balance, tx) =>
      val next = balance + tx
      if tx < 0 && next < -limit then next - fee else next
    }
