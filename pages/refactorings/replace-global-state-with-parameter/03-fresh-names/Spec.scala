//> using scala 3.3.4
//> using dep qa.hedgehog::hedgehog-core:0.14.0
//> using dep qa.hedgehog::hedgehog-runner:0.14.0
import hedgehog.*, hedgehog.core.*, hedgehog.runner.*

object Props extends Properties:
  def tests: List[Test] = List(
    property("number: Before == After", agrees),
    property("labels run x0, x1, ... in pre-order", labelsRun),
  )

  // A neutral tree, so one input feeds both Expr types. Names are
  // always "x": the supply numbers occurrences, not names.
  enum T:
    case TVar
    case TLit(value: Int)
    case TAdd(lhs: T, rhs: T)

  def genT(depth: Int): Gen[T] =
    val leaf = Gen.choice1(
      Gen.constant(T.TVar),
      Gen.int(Range.linear(-30, 30)).map(T.TLit(_)),
    )
    if depth == 0 then leaf
    else Gen.choice1(leaf,
      for l <- genT(depth - 1); r <- genT(depth - 1)
      yield T.TAdd(l, r))

  def toBefore(t: T): Before.Expr = t match
    case T.TVar       => Before.Expr.Var("x")
    case T.TLit(v)    => Before.Expr.Lit(v)
    case T.TAdd(l, r) =>
      Before.Expr.Add(toBefore(l), toBefore(r))

  def toAfter(t: T): After.Expr = t match
    case T.TVar       => After.Expr.Var("x")
    case T.TLit(v)    => After.Expr.Lit(v)
    case T.TAdd(l, r) => After.Expr.Add(toAfter(l), toAfter(r))

  // The walk, as the list of variable labels in pre-order.
  def labelsBefore(e: Before.Expr): List[String] = e match
    case Before.Expr.Var(name) => List(name)
    case Before.Expr.Lit(_)    => Nil
    case Before.Expr.Add(l, r) =>
      labelsBefore(l) ++ labelsBefore(r)
  def labelsAfter(e: After.Expr): List[String] = e match
    case After.Expr.Var(name) => List(name)
    case After.Expr.Lit(_)    => Nil
    case After.Expr.Add(l, r) =>
      labelsAfter(l) ++ labelsAfter(r)

  // Reading and incrementing the supply is the whole of the state,
  // so equal label lists mean equal reads in equal order.
  def agrees: Property =
    for t <- genT(4).forAll
    yield
      labelsBefore(Before.number(toBefore(t)))
        ==== labelsAfter(After.number(toAfter(t)))

  // Whatever the tree holds, its labels must be exactly x0, x1, ...
  // in visit order: no skips, no repeats, no reordering.
  def labelsRun: Property =
    for t <- genT(4).forAll
    yield
      val ls = labelsAfter(After.number(toAfter(t)))
      ls ==== ls.indices.map(i => "x" + i).toList

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
