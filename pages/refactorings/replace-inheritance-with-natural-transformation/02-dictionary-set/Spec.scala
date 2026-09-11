//> using scala 3.3.4
//> using dep qa.hedgehog::hedgehog-core:0.14.0
//> using dep qa.hedgehog::hedgehog-runner:0.14.0
import hedgehog.*, hedgehog.core.*, hedgehog.runner.*

object Props extends Properties:
  def tests: List[Test] = List(
    property("common: Before == After", commonAgrees),
    property("entries is natural in V", entriesIsNatural),
  )

  // Five names and ten numbers, so books collide on keys often and
  // later-wins is exercised with equal and unequal values.
  val genBook: Gen[List[(String, Int)]] =
    (for
      k <- Gen.element1("ann", "bo", "cy", "dee", "ed")
      v <- Gen.int(Range.linear(0, 9))
    yield (k, v)).list(Range.linear(0, 12))

  def commonAgrees: Property =
    for
      xs <- genBook.forAll
      ys <- genBook.forAll
    yield Before.common(xs, ys) ==== After.common(xs, ys)

  def entriesIsNatural: Property =
    for xs <- genBook.forAll
    yield
      val m = After.fill(xs)
      val f = (v: Int) => v % 3 // not injective, on purpose
      After.entries(m.map((k, v) => (k, f(v)))) ====
        After.entries(m).map((k, v) => (k, f(v)))

@main def spec(): Unit =
  val results = Props.tests.map { t =>
    val r = Property.check(
      t.withConfig(PropertyConfig.default), t.result, Seed.fromTime())
    println(
      Test.renderReport("Props", t, r, ansiCodesSupported = false))
    r.status
  }
  if !results.forall(_ == Status.ok) then sys.exit(1)
