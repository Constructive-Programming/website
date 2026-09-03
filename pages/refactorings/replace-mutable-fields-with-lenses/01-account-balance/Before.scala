// Withdraw from an account: the balance changes, the bonus does not.
object Before:
  case class Account(balance: Int, bonus: Int)

  def withdraw(a: Account, amount: Int): Account =
    a.copy(balance = a.balance - amount)
