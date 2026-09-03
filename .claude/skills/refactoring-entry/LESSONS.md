# Lessons

Append-only log, newest at the bottom. Each entry: what happened, what it cost, what to do
differently. A line marked **rule** is binding on the next run until it is folded into SKILL.md,
brief.md or workflow.js and deleted here. Keep the calibration table current.

## Calibration

| knob | value | why |
|---|---|---|
| hedgehog (Scala) | `qa.hedgehog::hedgehog-core:0.14.0`, `hedgehog-runner:0.14.0` | 0.13.0 is refused by scala-cli's outdated-dep check |
| Scala | 3.3.4 via scala-cli 1.12.x | matches the site's other Scala |
| Haskell | GHC 9.8.4 + hedgehog, docker image `cp-hedgehog` | no host ghc; nix store is read-only |
| `cp-hedgehog` build | ~2.5 min (cabal update + install --lib hedgehog) | one-off per machine |
| test count | 100 default; **500** when a property has an equality boundary | measured: 100 tests missed `<` vs `<=` mutants 60–90% of the time |
| generator ranges | narrow (−30..30, limits 0..20) for boundary-heavy code; full `Int` only in adversarial probes | narrow ranges hit `next == -limit` often; wide ones almost never |
| pane width | source lines ≤ 72 chars | 77-char comment lines overflowed a 608px pane at 0.78rem mono |
| workflow | 22 agents, ≈ 65 min wall-clock over two runs (12 min to the first crash + 53 min resumed); the reviewer's mutation + probe round is the long pole (≈ 15–20 min) | extract-method, 2026-09-03 |

## 2026-09-03 — 01 Extract method (first entry; the skill was extracted from this run)

- **Toolchain.** No ghc on the host; `nix shell`/`nix-shell` fail (registry needs network config; store is
  read-only). `docker run haskell:9.8-slim` + `cabal install --lib hedgehog` works; baked into `cp-hedgehog`
  and into run.sh's fallback. scala-hedgehog 0.14.0: `Test.renderReport(..., ansiCodesSupported = false)`;
  `object Props extends Properties` brings its own main, so run with `--main-class spec`.
- **Reviewer, round 1 (blocking).** Example 02's generators were too weak: mutants `tx < 0 → tx <= 0` and
  `next < -limit → next <= -limit` survived most runs in both languages. Cause: wide ranges (−500..500)
  rarely hit the equality boundary and `fee = 0` hides the fee branch. Fix: ranges −30..30 / 0..20 / fee
  1..20 and `withTests 500`; both mutants then caught 10/10. → became the generator rules in brief.md.
- **Reviewer, round 1 (optional, applied).** Haskell Before had the step as a `where` binding while Scala
  had an inline lambda; the two Befores were not parallel. Rewritten as an inline lambda. → rule in brief.
- **Reviewer, round 2 (optional, applied).** Comment "never throws" overclaimed: GHC `div` overflows at
  `minBound / -1`. Reworded, and the page says the partiality is preserved, not fixed. `foldl` → `foldl'`.
- **Citation skeptic.** One of 15 references was refuted on its *claim*, not its existence: "spends most of
  its effort on this analysis" about Stocker's Scala refactoring thesis was not supported; softened to
  "must perform exactly this analysis". → skeptic prompt now names overstatement as a failure.
- **Harness.** A session limit killed the reviewer mid-run; `Workflow({scriptPath, resumeFromRunId})`
  replayed the 18 finished agents from cache and re-ran only the reviewer. Cached agents may return empty
  results; read `journal.jsonl` first.
- **Jekyll.** `exclude:` the sources dir in `_config.yml`; `include_relative` still reads excluded files.
  `{% highlight scala %}{% include_relative … %}{% endhighlight %}` works inside raw HTML `<div>`s, so the
  side-by-side panes need no `markdown="1"`. Dot-dirs (`.scala-build`, `.bsp`) are ignored by Jekyll
  automatically. Two 80-column panes do not fit the 68ch prose measure; `.rf-pair` bleeds to
  `min(100vw - 3rem, 1360px)` on ≥1000px viewports.
- **Time.** Research + 15 citation checks ran in parallel with the examples build (both ≈ 10 min); the
  reviewer's two rounds plus the fix took most of the 53-minute resumed run; diagrams with browser
  render-checks ≈ 15 min. Toolchain probing before the workflow cost ≈ 10 min the first time. The main
  agent used the wait to write the page and check the layout in a scratch build — do the same.
- **Browser contention.** The diagram agent and the main agent share one Chrome; resize/reload calls on
  the main agent's tab hang for minutes while the other is screenshotting. Do layout screenshots before
  the Diagrams phase starts, or after it ends.

## 2026-09-03 — 01 Extract method renamed to "Extract / Inline method" (post-PR-12 review round 3)

- **Reviewer (kryptt).** Rename the entry to "Extract / Inline Method" and add a first **Motivation** section
  stating why you would go in either direction: duplication and long methods drive Extract; speculative
  generality and coupling drive Inline. Also (skill-wide): Motivation is always the first section of an entry,
  and every entry shows up with its dual. → folded into SKILL.md §3 (page section order + the always-first
  Motivation section with the two-direction motivators), brief.md, and the workflow.js research prompt
  (Motivation heading, first, with the same motivator guidance). Reference page updated: title, subtitle, intro,
  new Motivation section.

- **Rule.** Prompt-forced page structure in workflow.js: the research prompt now enumerates the exact H2
  headings in order with Motivation first — check that list whenever a section is added or renamed, or the
  assemble-the-page step and the research step will disagree on shape.

## 2026-09-03 — Reference citations are links (post-PR-12 review round 6)

- **Reviewer (kryptt).** In-text `[n]` references must be links that navigate to the reference list.
  Also update the skill with this info. Implemented:
  - In-text citations → `[[n](#ref-n)]`, rendering as [<a href="#ref-n">n</a>].
  - Reference list items → raw HTML `<li id="ref-N">…</li>` inside a plain `<ol>`.
- **Kramdown traps (rule).** Kramdown 1.x will not process markdown inside raw block HTML (`<li>`, even
  with `markdown="1"` — it escapes the inner tags); IALs on numbered list items (`{: #ref-N}` on a line
  after the item) attach to the *enclosing* `<ol>` at a break point and split the list. The working
  pattern is: a single `<ol>` with raw `<li id="ref-N">` items, and hand-render inline markdown to
  `<em>`/`<a>` yourself. Folded into SKILL.md §3, workflow.js research prompt, and brief.md.

## 2026-09-26 — 02 Replace mutable fields with lenses

- **Scala/Haskell Spec must compare *result values*, not the Before/After records.** The two sides carry
  different record types (they must — the point is that After's type can differ). Asserting
  `Before.x(...) ==== After.x(...)` where the tuple/record types differ makes hedgehog upcast to `Any`
  and report structural inequality, or fail to compile without a derived `Eq`. Compare projections:
  `(before.field, ...) ==== (after.field, ...)`. The reference extract-method avoided this by returning
  primitives; lens examples return records, so this bites immediately. → rule in brief.
- **A lens is a focus on one path; composition is for nested paths, not merging sibling fields.** A first
  02 tried `compose(x, y)` on two lenses with the same source to build a pair-lens — that is not a lens
  (no single field focus), and it does not typecheck. The textbook "compose two lenses" example is a
  nested record: `player . x`. When the refactoring is about *every element* (all sizes in a tree), a
  single lens does not fit — that is a traversal; the coherent example uses a total per-node lens inside
  the recursion. → design note for future lens-like entries.
- **A partial lens (entryFile on a sum) forces `error`/`sys.error` in the getter; a reviewer would flag
  it and the property can only test the defined region.** Switched 03 to a total `Lens[Node, Int]` on a
  plain record — partiality is a real pitfall to *write about*, not a good example shape.
- **Mutation-checking discipline.** A wrong-typed mutant is not a valid test; the compose-swap mutant
  was a type error in both languages (itself evidence the lens types are sound). Use sign flips,
  off-by-ones, dropped cases as mutants; drop mutants that fail to compile rather than reporting a pass.
- **Toolchain.** `scala-cli run <dir> --main-class spec` works; `docker run cp-hedgehog runghc -i<dir>
  <dir>/Spec.hs` works. Width rule held at 72 chars for all sources. Time: examples+verify ≈ 45 min;
  mutation+probes ≈ 15 min.
- **Workflow-runner gap.** This environment has no Claude Code `Workflow` batch runner; executed the
  workflow phases directly (research → citation verify → examples → mutate/probes → diagrams). Recorded
  findings here so the skill's workflow prompt matches when the runner is available.

## 2026-09-26 — 02 Replace mutable fields with lenses (post-PR review rework)

- **Reviewer (kryptt) asked for the optics framing, not the lens framing.** The entry should teach
  *optics* (lens · prism · traversal) and the "how to reach vs what to do" separation, mention that
  optics are lawful *by construction* (not per-example law properties in the page), reuse the eo
  cookbook recipes, and justify the inverse by decoupling not paying for itself (no cross-domain
  boundaries). Law-solvers (cats-eo-laws, monocle-law, genvalidity-hspec-optics) belong in
  Verification, not as hand-written law properties.
- **Rule.** Example trios should escalate *nesting* (single node → every tree node → sparse walk over a
  list) so the composed optic's value is visible; the setter-optic encoding (`(a -> a) -> (s -> s)`)
  is compact but reads cryptic next to same-shaped Lens/Prism data types — prefer explicit
  `Lens`/`Prism`/`Traversal` cases with `compose` (prism .andThen lens, each .andThen prism .andThen
  lens) for the page.
- **Rule (spec comparison).** Keep comparing via projected tuples/`from*` converters (Before/After
  have distinct record types), and add a *purpose* second property (hit/miss, only-X-changed) rather
  than also the lens laws — laws are by construction, the purpose property is the page's real check.
- **Generators.** `Gen.unicode` yields control chars (`\NUL`) that `toUpper` leaves alone; for
  "all names uppercased" style invariants use `Gen.alpha` (ASCII letters) or exclude non-letter
  inputs explicitly. `Gen.list/Gen.string` argument order differs between Scala and Haskell hedgehog.
- **Time.** Rework cost ≈ 1h (examples+specs+diagrams+page). The eo cookbook itself is the source of
  truth for optics recipes; reference it with anchors.

## 2026-09-26 — 02 shared/ setup must not appear on the page (post-PR review round 2)

- **Rule (blocking).** Setup shared between examples is *accidental complexity* if shown. A lens
  entry redefining `Lens`/`Prism`/`PartialLens` in every `After` buries the motivation in the
  definition of the tool. Move shared machinery to `pages/refactorings/<slug>/shared/` — compiled
  by `run.sh` (`scala-cli run "$d" --main-class spec "$SHARED"`, `runghc -i"$SHARED"`), never
  `include_relative`'d. Executed in 02: `shared/Optics.scala|.hs` and `shared/SpecRunner.scala`;
  the page says the shared files are hidden, each example is the move itself.
  → folded into SKILL.md §3 and brief.md.
- **Skill must be agent-agnostic.** It lived in `.claude/skills/` and assumed the Claude Code
  `Workflow(...)` runner. Rewrote §2 (the workflow) to describe the phases generically — research ·
  examples · review · diagrams — with the Claude `workflow.js`/`journal.jsonl` as one optional
  orchestrator, and generalized the `gh`/ship steps. The `Workflow` script stays but nothing else
  assumes Claude.
- **Rule (blocking).** Do not hand-write intermediate helper methods in an example — like the
  hand-defined `everywhere` that used to sit in an "across a whole tree" example's After and
  buries the point (the optic is the reusable bit, not the walk). If the example needs shared
  walk machinery, add `Plated`/`everywhere` to `shared/` (a `trait`/`class` with a `descend`
  instance per type; `everywhere f s = descend (everywhere f) (f s)`) and declare the type's
  `Plated` instance in the example — the walk comes from the library, the example only says
  which fields recurse. Same for any helper (a fold over the tree, a traversal builder): it
  belongs in `shared/` or a library, not re-derived in the example.
  → folded into SKILL.md §3 and brief.md ("Never hand-write helpers").
