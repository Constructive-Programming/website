//> using scala 3.3.4
//> using dep qa.hedgehog::hedgehog-core:0.14.0
//> using dep qa.hedgehog::hedgehog-runner:0.14.0
import hedgehog.*, hedgehog.core.*, hedgehog.runner.*

object Props extends Properties:
  def tests: List[Test] = List(
    property("settle: Before == After", settleAgrees).withTests(500),
  )

  val genAmount: Gen[Int] = Gen.int(Range.linear(-30, 30))
  val genLimit: Gen[Int]  = Gen.int(Range.linear(0, 20))
  val genFee: Gen[Int]    = Gen.int(Range.linear(1, 20))

  def settleAgrees: Property =
    for
      opening <- genAmount.forAll
      limit   <- genLimit.forAll
      fee     <- genFee.forAll
      txs     <- genAmount.list(Range.linear(0, 20)).forAll
    yield Before.settle(opening, limit, fee, txs) ====
      After.settle(opening, limit, fee, txs)

@main def spec(): Unit =
  val results = Props.tests.map { t =>
    val r = Property.check(t.withConfig(PropertyConfig.default),
      t.result, Seed.fromTime())
    println(Test.renderReport("Props", t, r,
      ansiCodesSupported = false))
    r.status
  }
  if !results.forall(_ == Status.ok) then sys.exit(1)
