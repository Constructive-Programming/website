// Move the player inside a game: the nested copy-update touches
// both records at every move.
object Before:
  case class Player(id: String, x: Int, y: Int)
  case class Game(level: Int, player: Player)

  def moveX(g: Game, dx: Int): Game =
    g.copy(player = g.player.copy(x = g.player.x + dx))

  def moveY(g: Game, dy: Int): Game =
    g.copy(player = g.player.copy(y = g.player.y + dy))
