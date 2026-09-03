//> using scala 3.3.4
//> using dep qa.hedgehog::hedgehog-core:0.14.0
//> using dep qa.hedgehog::hedgehog-runner:0.14.0
import hedgehog.*, hedgehog.core.*, hedgehog.runner.*

object Props extends Properties:
  def tests: List[Test] = List(
    property("total: Before == After", totalAgrees),
    property("no discount, no tax: total == subtotal", plainTotalIsSubtotal),
  )

  // Raw values, so the same input can be fed to both Before.Order and After.Order.
  val genLine: Gen[(Int, Int)] =
    for p <- Gen.int(Range.linear(-100, 1000)); q <- Gen.int(Range.linear(0, 20)) yield (p, q)
  val genOrder: Gen[(List[(Int, Int)], Int, Int)] =
    for
      items <- genLine.list(Range.linear(0, 10))
      d     <- Gen.int(Range.linear(0, 100))
      t     <- Gen.int(Range.linear(0, 30))
    yield (items, d, t)

  def totalAgrees: Property =
    for o <- genOrder.forAll
    yield
      val (items, d, t) = o
      Before.total(Before.Order(items.map(Before.Line(_, _)), d, t))
        ==== After.total(After.Order(items.map(After.Line(_, _)), d, t))

  def plainTotalIsSubtotal: Property =
    for items <- genLine.list(Range.linear(0, 10)).forAll
    yield
      val lines = items.map(After.Line(_, _))
      After.total(After.Order(lines, 0, 0)) ==== After.subtotal(lines)

@main def spec(): Unit =
  val results = Props.tests.map { t =>
    val r = Property.check(t.withConfig(PropertyConfig.default), t.result, Seed.fromTime())
    println(Test.renderReport("Props", t, r, ansiCodesSupported = false))
    r.status
  }
  if !results.forall(_ == Status.ok) then sys.exit(1)
