//> using scala 3.3.4
//> using dep qa.hedgehog::hedgehog-core:0.14.0
//> using dep qa.hedgehog::hedgehog-runner:0.14.0
import hedgehog.*, hedgehog.core.*, hedgehog.runner.*

object Props extends Properties:
  def tests: List[Test] = List(
    property("replay: Before == After", replayAgrees),
    property("toList is natural in A", toListIsNatural),
  )

  // A script as raw data: Some(text) is an edit, None an undo, so
  // one generated script feeds Before.Cmd and After.Cmd alike.
  // Short scripts with frequent undos hit the empty history often.
  val genScript: Gen[List[Option[String]]] =
    Gen.choice1(
      Gen.string(Gen.alpha, Range.linear(0, 6)).map(Some(_)),
      Gen.constant(Option.empty[String]),
    ).list(Range.linear(0, 20))

  def beforeCmd(c: Option[String]): Before.Cmd =
    c.fold(Before.Cmd.Undo)(Before.Cmd.Edit(_))

  def afterCmd(c: Option[String]): After.Cmd =
    c.fold(After.Cmd.Undo)(After.Cmd.Edit(_))

  def replayAgrees: Property =
    for s <- genScript.forAll
    yield Before.replay(s.map(beforeCmd)) ====
      After.replay(s.map(afterCmd))

  def toListIsNatural: Property =
    for s <- genScript.forAll
    yield
      val stack = After.build(s.map(afterCmd))
      stack.map(_.length).toList ==== stack.toList.map(_.length)

@main def spec(): Unit =
  val results = Props.tests.map { t =>
    val r = Property.check(
      t.withConfig(PropertyConfig.default), t.result, Seed.fromTime())
    println(
      Test.renderReport("Props", t, r, ansiCodesSupported = false))
    r.status
  }
  if !results.forall(_ == Status.ok) then sys.exit(1)
