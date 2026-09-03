// Closing balance after a run of transactions; `step` is extracted from
// the fold lambda and stays nested, capturing `limit` and `fee`.
object After:
  def settle(opening: Int, limit: Int, fee: Int, txs: List[Int]): Int =
    def step(balance: Int, tx: Int): Int =
      val next = balance + tx
      if tx < 0 && next < -limit then next - fee else next
    txs.foldLeft(opening)(step)
