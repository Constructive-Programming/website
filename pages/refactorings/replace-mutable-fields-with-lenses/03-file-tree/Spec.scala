//> using scala 3.3.4
//> using dep qa.hedgehog::hedgehog-core:0.14.0
//> using dep qa.hedgehog::hedgehog-runner:0.14.0
import hedgehog.*, hedgehog.core.*, hedgehog.runner.*

object Props extends Properties:
  def tests: List[Test] = List(
    property("bumpSizes: Before == After", agrees),
    property("the size lens obeys get-put, put-get, put-put", laws),
  )

  val genName: Gen[String] =
    for n <- Gen.int(Range.linear(0, 9)) yield "n" + n.toString
  val genSize: Gen[Int] = Gen.int(Range.linear(-20, 20))

  def genNode(depth: Int): Gen[Before.Node] =
    val leaf =
      for n <- genName; s <- genSize yield Before.Node(n, s, Nil)
    if depth == 0 then leaf
    else
      Gen.choice1(
        leaf,
        for
          n  <- genName
          s  <- genSize
          cs <- genNode(depth - 1).list(Range.linear(0, 3))
        yield Before.Node(n, s, cs)
        ,
      )

  def toAfter(n: Before.Node): After.Node = n match
    case Before.Node(nm, s, cs) => After.Node(nm, s, cs.map(toAfter))

  def same(b: Before.Node, a: After.Node): Boolean = (b, a) match
    case (Before.Node(n1, s1, c1), After.Node(n2, s2, c2)) =>
      n1 == n2 && s1 == s2 && c1.size == c2.size &&
        c1.zip(c2).forall((x, y) => same(x, y))

  def agrees: Property =
    for
      n  <- genNode(3).forAll
      by <- genSize.forAll
    yield
      val b = Before.bumpSizes(n, by)
      val a = After.bumpSizes(toAfter(n), by)
      same(b, a) ==== true

  def laws: Property =
    for
      n  <- genNode(1).forAll
      v1 <- genSize.forAll
      v2 <- genSize.forAll
    yield
      val l = After.size
      val m = toAfter(n)
      l.get(l.set(v1)(m)) ==== v1 and
        l.set(l.get(m))(m) ==== m and
        l.set(v2)(l.set(v1)(m)) ==== l.set(v2)(m)

@main def spec(): Unit =
  val results = Props.tests.map { t =>
    val r = Property.check(t.withConfig(PropertyConfig.default),
      t.result, Seed.fromTime())
    println(Test.renderReport(
      "Props", t, r, ansiCodesSupported = false))
    r.status
  }
  if !results.forall(_ == Status.ok) then sys.exit(1)
