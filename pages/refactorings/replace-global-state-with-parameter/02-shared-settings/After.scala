// Settle transactions: refuse any that would overdraw past the
// limit, and charge a fee on each one accepted.
object After:
  case class Policy(limit: Int, fee: Int)
  val policy = Policy(limit = 30, fee = 2)

  def applyTx(policy: Policy, balance: Int, tx: Int): Int =
    val next = balance + tx
    if next < -policy.limit then balance
    else next - policy.fee

  def settle(txs: List[Int]): Int =
    txs.foldLeft(0)(applyTx(policy, _, _))
