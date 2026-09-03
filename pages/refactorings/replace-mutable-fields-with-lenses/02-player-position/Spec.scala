//> using scala 3.3.4
//> using dep qa.hedgehog::hedgehog-core:0.14.0
//> using dep qa.hedgehog::hedgehog-runner:0.14.0
import hedgehog.*, hedgehog.core.*, hedgehog.runner.*

object Props extends Properties:
  def tests: List[Test] = List(
    property("moveX: Before == After", agreesX),
    property("moveY: Before == After", agreesY),
    property("the composed path lens player.x obeys the laws", laws),
  )

  // Raw values, so the same input feeds both Game types.
  val genInt: Gen[Int] = Gen.int(Range.linear(-30, 30))
  val genId: Gen[String] =
    for n <- Gen.int(Range.linear(0, 9)) yield "p" + n.toString

  def agreesX: Property =
    for
      id <- genId.forAll
      lv <- genInt.forAll
      px <- genInt.forAll
      py <- genInt.forAll
      dx <- genInt.forAll
    yield
      val b =
        Before.moveX(Before.Game(lv, Before.Player(id, px, py)), dx)
      val a = After.moveX(After.Game(lv, After.Player(id, px, py)), dx)
      (b.level, b.player.id, b.player.x, b.player.y)
        ==== (a.level, a.player.id, a.player.x, a.player.y)

  def agreesY: Property =
    for
      id <- genId.forAll
      lv <- genInt.forAll
      px <- genInt.forAll
      py <- genInt.forAll
      dy <- genInt.forAll
    yield
      val b =
        Before.moveY(Before.Game(lv, Before.Player(id, px, py)), dy)
      val a = After.moveY(After.Game(lv, After.Player(id, px, py)), dy)
      (b.level, b.player.id, b.player.x, b.player.y)
        ==== (a.level, a.player.id, a.player.x, a.player.y)

  def laws: Property =
    for
      id <- genId.forAll
      lv <- genInt.forAll
      px <- genInt.forAll
      py <- genInt.forAll
      v1 <- genInt.forAll
      v2 <- genInt.forAll
    yield
      val g  = After.Game(lv, After.Player(id, px, py))
      val l  = After.playerX
      l.get(l.set(v1)(g)) ==== v1 and
        l.set(l.get(g))(g) ==== g and
        l.set(v2)(l.set(v1)(g)) ==== l.set(v2)(g)

@main def spec(): Unit =
  val results = Props.tests.map { t =>
    val r = Property.check(t.withConfig(PropertyConfig.default),
      t.result, Seed.fromTime())
    println(Test.renderReport(
      "Props", t, r, ansiCodesSupported = false))
    r.status
  }
  if !results.forall(_ == Status.ok) then sys.exit(1)
