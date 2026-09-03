//> using scala 3.3.4
//> using dep qa.hedgehog::hedgehog-core:0.14.0
//> using dep qa.hedgehog::hedgehog-runner:0.14.0
import hedgehog.*, hedgehog.core.*, hedgehog.runner.*

object Props extends Properties:
  def tests: List[Test] = List(
    property("withdraw: Before == After", agrees),
    property("the balance lens obeys get-put, put-get, put-put", laws),
  )

  // Raw values, so the same input feeds both Account types.
  val genInt: Gen[Int] = Gen.int(Range.linear(-30, 30))

  def agrees: Property =
    for
      b  <- genInt.forAll
      bn <- genInt.forAll
      am <- genInt.forAll
    yield
      val before = Before.withdraw(Before.Account(b, bn), am)
      val after  = After.withdraw(After.Account(b, bn), am)
      (before.balance, before.bonus) ==== (after.balance, after.bonus)

  def laws: Property =
    for
      b  <- genInt.forAll
      bn <- genInt.forAll
      v1 <- genInt.forAll
      v2 <- genInt.forAll
    yield
      val a = After.Account(b, bn)
      val l = After.balance
      l.get(l.set(v1)(a)) ==== v1 and
        l.set(l.get(a))(a) ==== a and
        l.set(v2)(l.set(v1)(a)) ==== l.set(v2)(a)

@main def spec(): Unit =
  val results = Props.tests.map { t =>
    val r = Property.check(t.withConfig(PropertyConfig.default),
      t.result, Seed.fromTime())
    println(Test.renderReport(
      "Props", t, r, ansiCodesSupported = false))
    r.status
  }
  if !results.forall(_ == Status.ok) then sys.exit(1)
