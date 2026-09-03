//> using scala 3.3.4
//> using dep qa.hedgehog::hedgehog-core:0.14.0
//> using dep qa.hedgehog::hedgehog-runner:0.14.0
import hedgehog.*, hedgehog.core.*, hedgehog.runner.*

object Props extends Properties:
  def tests: List[Test] = List(
    property("eval: Before == After", evalAgrees),
    property("dividing by zero has no value, never throws", divByZeroIsNone),
  )

  import Before.Expr, Before.Expr.*

  val genLit: Gen[Expr] = Gen.int(Range.linear(-20, 20)).map(Lit(_))
  def genExpr(depth: Int): Gen[Expr] =
    if depth == 0 then genLit
    else
      val sub = genExpr(depth - 1)
      Gen.choice1(
        genLit,
        for l <- sub; r <- sub yield Add(l, r),
        for l <- sub; r <- sub yield Mul(l, r),
        for l <- sub; r <- sub yield Div(l, r),
      )

  def toAfter(e: Expr): After.Expr = e match
    case Lit(n)    => After.Expr.Lit(n)
    case Add(l, r) => After.Expr.Add(toAfter(l), toAfter(r))
    case Mul(l, r) => After.Expr.Mul(toAfter(l), toAfter(r))
    case Div(l, r) => After.Expr.Div(toAfter(l), toAfter(r))

  def evalAgrees: Property =
    for e <- genExpr(4).forAll
    yield Before.eval(e) ==== After.eval(toAfter(e))

  def divByZeroIsNone: Property =
    for e <- genExpr(3).forAll
    yield Before.eval(Div(e, Lit(0))) ==== None and After.eval(toAfter(Div(e, Lit(0)))) ==== None

@main def spec(): Unit =
  val results = Props.tests.map { t =>
    val r = Property.check(t.withConfig(PropertyConfig.default), t.result, Seed.fromTime())
    println(Test.renderReport("Props", t, r, ansiCodesSupported = false))
    r.status
  }
  if !results.forall(_ == Status.ok) then sys.exit(1)
