//> using scala 3.3.4
//> using dep qa.hedgehog::hedgehog-core:0.14.0
//> using dep qa.hedgehog::hedgehog-runner:0.14.0
import hedgehog.*, hedgehog.core.*, hedgehog.runner.*

object Props extends Properties:
  def tests: List[Test] = List(
    property("settle: Before == After", settleAgrees)
      .withTests(500),
    property("settings as parameter: fee 0, wide limit sums",
      neutralSettings),
  )

  // Narrow range, so the overdraft boundary (next == -limit) is hit
  // often.
  val genTxs: Gen[List[Int]] =
    Gen.int(Range.linear(-30, 30)).list(Range.linear(0, 20))

  def settleAgrees: Property =
    for txs <- genTxs.forAll
    yield Before.settle(txs) ==== After.settle(txs)

  // The record is now an argument, so other policies are testable:
  // with no fee and a limit out of reach, the step is plain addition.
  def neutralSettings: Property =
    for
      b <- Gen.int(Range.linear(-30, 30)).forAll
      t <- Gen.int(Range.linear(-30, 30)).forAll
    yield
      After.applyTx(After.Policy(10000, 0), b, t) ==== b + t

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
