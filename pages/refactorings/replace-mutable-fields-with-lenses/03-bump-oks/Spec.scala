//> using scala 3.3.4
//> using dep qa.hedgehog::hedgehog-core:0.14.0
//> using dep qa.hedgehog::hedgehog-runner:0.14.0
import hedgehog.*, hedgehog.core.*, hedgehog.runner.*

object Props extends Properties:
  def tests: List[Test] = List(
    property("bumpSucceeded: Before == After", agrees),
    property("only successes are bumped, messages pass through",
      onlySucceeded),
  )

  // A neutral list, so one generated input feeds both Result types.
  enum R:
    case Succeeded(value: Int)
    case Failed(msg: String)

  val genValue: Gen[Int] = Gen.int(Range.linear(-100, 100))
  val genMsg: Gen[String] =
    Gen.alpha.list(Range.linear(0, 6)).map(_.mkString)
  def genR: Gen[R] =
    Gen.choice1(
      genValue.map(R.Succeeded(_)),
      genMsg.map(R.Failed(_)),
    )

  def toBefore(r: R): Before.Result = r match
    case R.Succeeded(v) => Before.Result.Succeeded(Before.Ok(v))
    case R.Failed(m)    => Before.Result.Failed(m)
  def fromBefore(r: Before.Result): R = r match
    case Before.Result.Succeeded(ok) => R.Succeeded(ok.value)
    case Before.Result.Failed(m)     => R.Failed(m)
  def toAfter(r: R): After.Result = r match
    case R.Succeeded(v) => After.Result.Succeeded(After.Ok(v))
    case R.Failed(m)    => After.Result.Failed(m)
  def fromAfter(r: After.Result): R = r match
    case After.Result.Succeeded(ok) => R.Succeeded(ok.value)
    case After.Result.Failed(m)     => R.Failed(m)

  def agrees: Property =
    for xs <- genR.list(Range.linear(0, 10)).forAll
    yield
      Before.bumpSucceeded(xs.map(toBefore)).map(fromBefore)
        ==== After.bumpSucceeded(xs.map(toAfter)).map(fromAfter)

  def onlySucceeded: Property =
    for xs <- genR.list(Range.linear(0, 10)).forAll
    yield
      val bumped =
        After.bumpSucceeded(xs.map(toAfter)).map(fromAfter)
      bumped.zip(xs).forall {
        case (R.Succeeded(v1), R.Succeeded(v0)) => v1 == v0 + 1
        case (R.Failed(m1), R.Failed(m0))       => m1 == m0
        case _                                  => false
      } ==== true

@main def spec(): Unit =
  val results = Props.tests.map { t =>
    val r = Property.check(t.withConfig(PropertyConfig.default),
      t.result, Seed.fromTime())
    println(Test.renderReport(
      "Props", t, r, ansiCodesSupported = false))
    r.status
  }
  if !results.forall(_ == Status.ok) then sys.exit(1)
