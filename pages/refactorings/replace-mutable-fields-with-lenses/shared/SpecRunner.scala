// Shared runner body for every example's hedgehog suite. Each example
// ends with `@main def spec(): Unit = SpecRunner.run(Props.tests)`;
// this file holds the boilerplate so the page does not show it.
import hedgehog.*, hedgehog.core.*, hedgehog.runner.*

object SpecRunner:
  def run(tests: List[Test]): Unit =
    val results = tests.map { t =>
      val r = Property.check(t.withConfig(PropertyConfig.default),
        t.result, Seed.fromTime())
      println(Test.renderReport(
        "Props", t, r, ansiCodesSupported = false))
      r.status
    }
    if !results.forall(_ == Status.ok) then sys.exit(1)
