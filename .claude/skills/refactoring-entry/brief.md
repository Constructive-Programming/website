# Brief: "<Name>" — entry <n> of the Constructive Programming refactoring catalogue

## Context
- Repo: <repo root> (Jekyll site for www.constructive.dev), branch `refactoring/<slug>`.
- Section: /refactorings/ (index at pages/refactorings.md, list in _data/refactorings.yml). This entry lives at
  /refactorings/<slug>/ (page pages/refactorings/<slug>.md, sources pages/refactorings/<slug>/).
- Reference entry, copy its shape exactly: pages/refactorings/extract-method.md and pages/refactorings/extract-method/.
- Methodology framing (pages/about.md): Constructive Programming = restrictions that make code easier to reason about:
  referential transparency, totality, termination; Curry–Howard–Lambek. Refactorings are read as *equivalences between
  programs* that you can state and CHECK — hence property-based tests proving before == after.
- Audience: senior engineers and CTOs who know OO refactoring (Fowler) and want the typed-FP reading of it.
- Every entry is presented "to & from": the move AND its inverse (<Name> <-> <inverse name>). The catalogue name
  carries both sides ("Extract / Inline method"), so does the page title and subtitle; the two directions are
  one equation.

## This refactoring
Every entry carries the structure: Motivation first, then the move, the
functional reading (a collapsible footnote inside Pitfalls), to & from,
examples, pitfalls, verification, references. Fill the fields below; omit one
when it does not apply.
- OO reading: <one paragraph: what the OO/imperative world calls it, where it is catalogued — ONLY when
  one exists; many moves (higher-order, higher-kinded, dependent-typed) have no OO counterpart, and for
  those the OO reading is dropped entirely>
- FP reading: <one paragraph: what it is in a referentially transparent language; which papers/transformations>
- Dual: <the reverse move — ALWAYS present. Every refactoring is presented as a pair: extract / inline
  method, introduce / eliminate generics, ... The catalogue name, page title and subtitle carry both
  sides; the two directions are one equation>
- Motivation (page section 1, before any mechanics): <why go in each direction — the smell that drives the move,
  the smell that drives its inverse (e.g. duplication / long methods vs speculative generality / coupling)>
- Known anchors to verify and cite (find more; verify all): <list>
- References render as raw HTML: each item is `<li id="ref-N">…</li>` inside a plain `<ol>` (Kramdown
  won't run markdown inside raw block HTML, so inline `*em*` → `<em>` and `<url>` → `<a href>` by hand).
  In-text citations are the links `[[n](#ref-n)]`.
- Example ideas (adjust if you find better, keep the progression simple → free variables/effects → recursion/laziness):
  1. <...>
  2. <...>
  3. <...>

## Code layout (examples agent writes these; reviewer runs them)
pages/refactorings/<slug>/
  run.sh                      # copied unchanged from extract-method; runs every NN-*/ dir in both languages
  NN-<ex>/Before.scala        # object Before { ... }   the pre-refactoring program
  NN-<ex>/After.scala         # object After  { ... }   the refactored version (same public entry point signature)
  NN-<ex>/Spec.scala          # hedgehog property: forAll generated inputs, Before.f(x) ==== After.f(x). `@main def spec()`.
  NN-<ex>/Before.hs           # module Before where ...
  NN-<ex>/After.hs            # module After  where ...
  NN-<ex>/Spec.hs             # hedgehog property, main :: IO (); exit non-zero on failure
- The web page `include_relative`s these files verbatim into highlighted panes, so:
  * every file self-contained, readable, SHORT (Before/After 8–25 lines each); lines ≤ 72 characters;
  * NO `{{`, `}}`, `{%`, `%}` sequences anywhere (Liquid would eat them);
  * one-line comment at the top of Before/After saying what the program does; no essay comments;
  * the Scala and Haskell Befores must be parallel (same shape: if Scala has an inline lambda, so does Haskell).
- Scala: Scala 3.3.x, directives at the top of Spec.scala only:
    //> using scala 3.3.4
    //> using dep qa.hedgehog::hedgehog-core:0.14.0
    //> using dep qa.hedgehog::hedgehog-runner:0.14.0
  Run: `scala-cli run pages/refactorings/<slug>/NN-ex --main-class spec`  (Properties has its own main; name ours `spec`)
  Known-good hedgehog 0.14.0 runner (renderReport's 4th param is `ansiCodesSupported`):
    import hedgehog.*, hedgehog.core.*, hedgehog.runner.*
    object Props extends Properties:
      def tests: List[Test] = List(property("name", prop))
      def prop: Property = for x <- Gen.int(Range.linear(-100, 100)).forAll yield Before.f(x) ==== After.f(x)
    @main def spec(): Unit =
      val results = Props.tests.map { t =>
        val r = Property.check(t.withConfig(PropertyConfig.default), t.result, Seed.fromTime())
        println(Test.renderReport("Props", t, r, ansiCodesSupported = false)); r.status }
      if !results.forall(_ == Status.ok) then sys.exit(1)
  `.withTests(500)` on a property raises its count.
- Haskell: GHC 9.8.4 + hedgehog. No ghc on this machine; docker image `cp-hedgehog` (run.sh builds it if missing):
    docker run --rm -v "$PWD/pages/refactorings/<slug>:/w" -w /w cp-hedgehog runghc -iNN-ex NN-ex/Spec.hs
  (from the repo root). Spec.hs: `main = do ok <- checkParallel (Group "Props" [...]); unless ok exitFailure`.
  `withTests 500 $ property $ do ...` raises the count. Prefer `foldl'` over `foldl` for strict accumulators.
- Run everything at once: `sh pages/refactorings/<slug>/run.sh` (from anywhere).

## Generators (from LESSONS.md — the reviewer will mutation-test them)
- Design generators around the program's boundaries (equality tests, zero, empty, sign changes): small ranges
  (e.g. -30..30) hit boundaries far more often than wide ones; exclude values that make a branch invisible
  (e.g. fee = 0). Use 500 tests when a boundary matters.
- A second property per example is expected when natural (the extracted piece on its own; a law it obeys).
- In Haskell probe laziness/strictness with `undefined` where the refactoring could change what is forced;
  in Scala reason about evaluation count (def vs val, by-name) and say so in a comment when it matters.

## Style
- Site prose: crisp, editorial, no hype; sentences, not bullets, in body text (the caveats section may use a list).
- Claims about tools and papers must be modest and literally supported by the cited source.
- Code: idiomatic, set in a very common domain subject matter, and just enough code to get the point
  across — no accidental complexity, no clever tricks; the refactoring must be the only difference
  between Before and After.
