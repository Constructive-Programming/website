// Same, with a lens on the balance: the getter and the pure setter
// packed as one value.
object After:
  case class Account(balance: Int, bonus: Int)

  case class Lens[S, A](get: S => A, set: A => S => S):
    def modify(f: A => A): S => S = s => set(f(get(s)))(s)

  val balance: Lens[Account, Int] =
    Lens[Account, Int](_.balance, b => a => a.copy(balance = b))

  def withdraw(a: Account, amount: Int): Account =
    balance.modify(_ - amount)(a)
