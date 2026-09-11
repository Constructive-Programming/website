//> using scala 3.3.4
//> using dep qa.hedgehog::hedgehog-core:0.14.0
//> using dep qa.hedgehog::hedgehog-runner:0.14.0
import hedgehog.*, hedgehog.core.*, hedgehog.runner.*

object Props extends Properties:
  def tests: List[Test] = List(
    property("quantity: Before == After", quantityAgrees),
    property("toOption is natural in A", toOptionIsNatural),
  )

  // Numerals around zero hit both error branches; letter noise
  // covers the unparsable, digit runs the plain positives.
  val genRaw: Gen[String] =
    Gen.choice1(
      Gen.int(Range.linear(-20, 20)).map(_.toString),
      Gen.string(Gen.alpha, Range.linear(0, 4)),
      Gen.string(Gen.digit, Range.linear(1, 4)),
    )

  def quantityAgrees: Property =
    for raw <- genRaw.forAll
    yield Before.quantity(raw) ==== After.quantity(raw)

  def toOptionIsNatural: Property =
    for raw <- genRaw.forAll
    yield
      val e = After.parse(raw)
      After.toOption(e.map(_ * 2)) ====
        After.toOption(e).map(_ * 2)

@main def spec(): Unit =
  val results = Props.tests.map { t =>
    val r = Property.check(
      t.withConfig(PropertyConfig.default), t.result, Seed.fromTime())
    println(
      Test.renderReport("Props", t, r, ansiCodesSupported = false))
    r.status
  }
  if !results.forall(_ == Status.ok) then sys.exit(1)
