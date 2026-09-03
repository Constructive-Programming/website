// Same, with a composed path: player . x and player . y reach the
// nested field in one step, no copy chain.
object After:
  case class Player(id: String, x: Int, y: Int)
  case class Game(level: Int, player: Player)

  case class Lens[S, A](get: S => A, set: A => S => S):
    def modify(f: A => A): S => S = s => set(f(get(s)))(s)

  def compose[S, M, A](outer: Lens[S, M],
                       inner: Lens[M, A]): Lens[S, A] =
    Lens[S, A](s => inner.get(outer.get(s)),
      a => s => outer.set(inner.set(a)(outer.get(s)))(s))

  val player: Lens[Game, Player] =
    Lens[Game, Player](_.player, p => g => g.copy(player = p))

  val x: Lens[Player, Int] =
    Lens[Player, Int](_.x, v => p => p.copy(x = v))
  val y: Lens[Player, Int] =
    Lens[Player, Int](_.y, v => p => p.copy(y = v))

  val playerX: Lens[Game, Int] = compose(player, x)
  val playerY: Lens[Game, Int] = compose(player, y)

  def moveX(g: Game, dx: Int): Game = playerX.modify(_ + dx)(g)
  def moveY(g: Game, dy: Int): Game = playerY.modify(_ + dy)(g)
