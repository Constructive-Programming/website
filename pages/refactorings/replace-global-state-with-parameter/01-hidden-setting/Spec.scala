//> using scala 3.3.4
//> using dep qa.hedgehog::hedgehog-core:0.14.0
//> using dep qa.hedgehog::hedgehog-runner:0.14.0
import hedgehog.*, hedgehog.core.*, hedgehog.runner.*

object Props extends Properties:
  def tests: List[Test] = List(
    property("total: Before == After", totalAgrees),
    property("the fee parameter controls the whole fee",
      feeIsParametric),
  )

  val genLines: Gen[List[Int]] =
    Gen.int(Range.linear(-100, 100)).list(Range.linear(0, 10))

  def totalAgrees: Property =
    for lines <- genLines.forAll
    yield Before.total(lines) ==== After.total(lines)

  // The parameter has taken over the global's job: at subtotal 0 the
  // result is exactly the fee handed in, for any fee in the range.
  def feeIsParametric: Property =
    for f <- Gen.int(Range.linear(0, 1000)).forAll
    yield After.fee(f, 0) ==== f

@main def spec(): Unit =
  val results = Props.tests.map { t =>
    val r = Property.check(
      t.withConfig(PropertyConfig.default),
      t.result,
      Seed.fromTime(),
    )
    println(Test.renderReport("Props", t, r,
      ansiCodesSupported = false))
    r.status
  }
  if !results.forall(_ == Status.ok) then sys.exit(1)
