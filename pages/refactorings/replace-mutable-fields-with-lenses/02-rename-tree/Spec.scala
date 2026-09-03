//> using scala 3.3.4
//> using dep qa.hedgehog::hedgehog-core:0.14.0
//> using dep qa.hedgehog::hedgehog-runner:0.14.0
import hedgehog.*, hedgehog.core.*, hedgehog.runner.*

object Props extends Properties:
  def tests: List[Test] = List(
    property("renameAll: Before == After", agrees),
    property("every Var name is uppercased after the walk", allUpper),
  )

  // A neutral tree, so one generated input feeds both Expr types.
  enum T:
    case TVar(name: String, ref: Int)
    case TApp(f: T, x: T)
    case TLam(bind: String, body: T)

  val genName: Gen[String] =
    Gen.alpha.list(Range.linear(0, 4)).map(_.mkString)
  def genT(depth: Int): Gen[T] =
    val leaf =
      for n <- genName; r <- Gen.int(Range.linear(-10, 10))
      yield T.TVar(n, r)
    if depth == 0 then leaf
    else
      Gen.choice1(
        leaf,
        for
          f <- genT(depth - 1)
          x <- genT(depth - 1)
        yield T.TApp(f, x),
        for b <- genName; body <- genT(depth - 1) yield T.TLam(b, body),
      )

  def toBefore(t: T): Before.Expr = t match
    case T.TVar(n, r) => Before.Expr.EVar(Before.Var(n, r))
    case T.TApp(f, x) => Before.Expr.EApp(toBefore(f), toBefore(x))
    case T.TLam(b, e) => Before.Expr.ELam(b, toBefore(e))
  def fromBefore(e: Before.Expr): T = e match
    case Before.Expr.EVar(v)     => T.TVar(v.name, v.ref)
    case Before.Expr.EApp(f, x)  => T.TApp(fromBefore(f), fromBefore(x))
    case Before.Expr.ELam(b, e)  => T.TLam(b, fromBefore(e))
  def toAfter(t: T): After.Expr = t match
    case T.TVar(n, r) => After.Expr.EVar(After.Var(n, r))
    case T.TApp(f, x) => After.Expr.EApp(toAfter(f), toAfter(x))
    case T.TLam(b, e) => After.Expr.ELam(b, toAfter(e))
  def fromAfter(e: After.Expr): T = e match
    case After.Expr.EVar(v)     => T.TVar(v.name, v.ref)
    case After.Expr.EApp(f, x)  => T.TApp(fromAfter(f), fromAfter(x))
    case After.Expr.ELam(b, e)  => T.TLam(b, fromAfter(e))

  def agrees: Property =
    for t <- genT(4).forAll
    yield
      fromBefore(Before.renameAll(toBefore(t)))
        ==== fromAfter(After.renameAll(toAfter(t)))

  def allUpper: Property =
    for t <- genT(4).forAll
    yield
      val renamed = fromAfter(After.renameAll(toAfter(t)))
      (allNamesUpper(renamed) && refsUnchanged(renamed, t)) ==== true

  def allNamesUpper(t: T): Boolean = t match
    case T.TVar(n, _)   => n == n.toUpperCase
    case T.TApp(f, x)   => allNamesUpper(f) && allNamesUpper(x)
    case T.TLam(_, b)   => allNamesUpper(b)
  def refsUnchanged(a: T, b: T): Boolean = (a, b) match
    case (T.TVar(_, r1), T.TVar(_, r2)) => r1 == r2
    case (T.TApp(f1, x1), T.TApp(f2, x2)) =>
      refsUnchanged(f1, f2) && refsUnchanged(x1, x2)
    case (T.TLam(_, b1), T.TLam(_, b2)) => refsUnchanged(b1, b2)
    case _ => false

@main def spec(): Unit =
  val results = Props.tests.map { t =>
    val r = Property.check(t.withConfig(PropertyConfig.default),
      t.result, Seed.fromTime())
    println(Test.renderReport(
      "Props", t, r, ansiCodesSupported = false))
    r.status
  }
  if !results.forall(_ == Status.ok) then sys.exit(1)
