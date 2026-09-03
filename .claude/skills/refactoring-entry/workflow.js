export const meta = {
  name: 'refactoring-entry',
  description: 'Research, build, and PBT-verify one refactoring catalogue entry (Scala 3 + Haskell hedgehog)',
  phases: [
    { title: 'Research', detail: 'text + references, to & from direction' },
    { title: 'Citations', detail: 'adversarially verify every reference' },
    { title: 'Examples', detail: '3 examples, Before/After/Spec in both languages' },
    { title: 'Verify', detail: 'reviewer runs hedgehog, mutation-tests the specs' },
    { title: 'Diagrams', detail: 'inline SVG per example + koan' },
  ],
}

// args: { slug, name, number, total, brief, scratch, repo, seeds: [...], examples: [...] }
const A = args
const BRIEF = A.brief
const SCRATCH = A.scratch
const REPO = A.repo
const EX = `${REPO}/pages/refactorings/${A.slug}`
const SEEDS = (A.seeds || []).map(s => `- ${s}`).join('\n') || '- (none given; find the primary sources yourself)'
const EXAMPLE_IDEAS = (A.examples || []).map((e, i) => `  0${i + 1}: ${e}`).join('\n')

const REF = {
  type: 'object',
  required: ['id', 'title', 'authors', 'year', 'venue', 'url', 'claim'],
  properties: {
    id: { type: 'string' }, title: { type: 'string' }, authors: { type: 'string' },
    year: { type: 'string' }, venue: { type: 'string' }, url: { type: 'string' },
    claim: { type: 'string', description: 'what the text attributes to this reference' },
  },
}
const RESEARCH_SCHEMA = {
  type: 'object', required: ['file', 'references', 'summary'],
  properties: { file: { type: 'string' }, references: { type: 'array', items: REF }, summary: { type: 'string' } },
}
const CITE_SCHEMA = {
  type: 'object', required: ['id', 'ok', 'note'],
  properties: { id: { type: 'string' }, ok: { type: 'boolean' }, note: { type: 'string' }, fixed_url: { type: 'string' }, fixed_citation: { type: 'string' } },
}
const EXAMPLES_SCHEMA = {
  type: 'object', required: ['examples', 'notes'],
  properties: {
    examples: { type: 'array', items: { type: 'object', required: ['dir', 'title', 'what_changes', 'scala_ok', 'haskell_ok', 'output_tail'],
      properties: { dir: { type: 'string' }, title: { type: 'string' }, what_changes: { type: 'string' }, scala_ok: { type: 'boolean' }, haskell_ok: { type: 'boolean' }, output_tail: { type: 'string' } } } },
    notes: { type: 'string' },
  },
}
const VERIFY_SCHEMA = {
  type: 'object', required: ['passed', 'examples', 'adversarial_findings', 'report_file'],
  properties: {
    passed: { type: 'boolean' },
    examples: { type: 'array', items: { type: 'object', required: ['dir', 'scala_passed', 'haskell_passed', 'mutation_detected', 'equivalent', 'issues'],
      properties: { dir: { type: 'string' }, scala_passed: { type: 'boolean' }, haskell_passed: { type: 'boolean' }, mutation_detected: { type: 'boolean' }, equivalent: { type: 'boolean' }, issues: { type: 'array', items: { type: 'string' } } } } },
    adversarial_findings: { type: 'array', items: { type: 'string' } },
    report_file: { type: 'string' },
  },
}
const DIAGRAM_SCHEMA = { type: 'object', required: ['files', 'notes'], properties: { files: { type: 'array', items: { type: 'string' } }, notes: { type: 'string' } } }

const common = `Read ${BRIEF} first; it has the repo layout, toolchain commands, and constraints. Also read ${REPO}/.claude/skills/refactoring-entry/LESSONS.md: it lists what went wrong on previous entries. Work in the repo at ${REPO} (branch refactoring/${A.slug}). Do not commit.`

// ---------------------------------------------------------------- Track A: research → verify citations → fix-up
const trackA = async () => {
  const research = await agent(`${common}

You are the RESEARCH agent for catalogue entry ${A.number} of ${A.total}: "${A.name}", read as a Constructive/functional-programming refactoring, always presented WITH ITS DUAL (the inverse move: the two directions are one equation).
Write ${SCRATCH}/research.md — the prose for the web page at /refactorings/${A.slug}/ — with these exact H2 headings, in this exact order; the first section is always Motivation. Match the reference page ${REPO}/pages/refactorings/extract-method.md in tone and depth (read it first):

## Motivation
The FIRST section, before any mechanics. Why reach for either direction, two short paragraphs: the smells that drive the move (duplication, long methods, ...) and the smells that drive its inverse (speculative generality, coupling through a seam's implementation rather than its contract, ...). The reader should know when to use the move before how to perform it.

## The move
The refactoring as the OO / imperative world catalogues it (Fowler, Kerievsky, Opdyke, the IDE menu, GoF where relevant): mechanics, preconditions, why they are needed there.

## The functional reading
What the move IS in a referentially transparent, typed language; which transformation systems and papers it is an instance of; how tools (HaRe, compilers, Scala refactoring library) perform it or its inverse. Explain what the constructive criteria (referential transparency, totality, termination) buy: the OO precondition becomes an equation or a type.

## To and from
The two directions as a pair. State the equation or the isomorphism. Say what each direction is *for*.

## When it is not an equivalence
Concrete caveats, each one sentence + why: effects and evaluation order; sharing and evaluation count (Scala def/val, Haskell let/CAF, full laziness); strictness and bottom; exceptions and non-termination; name capture or type-inference changes; anything specific to this move.

## Checking it
How the property-based test states the equivalence (forAll x. before x == after x), hedgehog both sides, and one paragraph on mutation-checking the spec.

## References
A numbered list. EVERY reference must be real. Use WebSearch/WebFetch to confirm title, authors, year, venue, and a working URL (DOI, ACM DL, author's page, or arXiv) for each one BEFORE including it. If you cannot verify an item, leave it out. Prefer primary sources. Aim for 10–14 references. Anchors to start from (verify them too):
${SEEDS}
Always include: Fowler (Refactoring, 1999 and/or 2018), Claessen & Hughes QuickCheck ICFP 2000, hedgehog (GitHub), and Thompson's "Refactoring functional programs" (AFP 2004, LNCS 3622) or HaRe where the move exists there.
Cite in-text as [n]. Prose: tight, editorial, 900–1500 words, sentences not bullets (the caveats section may use a short list). Claims about what a tool or paper does must be modest and literally supported by it. Do not write code. No Liquid-looking sequences ({{ or {%).

Return the file path, the references array (id = the [n] number, plus title/authors/year/venue/url/claim), and a 3-sentence summary.`,
    { label: `research:${A.slug}`, phase: 'Research', schema: RESEARCH_SCHEMA, effort: 'high' })
  if (!research) return { research: null }
  log(`research done: ${research.references.length} references`)

  const verdicts = (await parallel(research.references.map(r => () =>
    agent(`You are a citation SKEPTIC. Try to REFUTE this reference; default to ok=false if you cannot confirm it.
Reference [${r.id}]: "${r.title}" — ${r.authors} (${r.year}), ${r.venue}. URL: ${r.url}
Claim the text attributes to it: ${r.claim}

Use WebFetch on the URL (and WebSearch if needed) and check: (1) the URL resolves and is about this work; (2) title, authors, year, venue are correct (small formatting differences are fine; wrong year/venue/author list is not); (3) the attributed claim is something this work actually says or does — an overstatement ("spends most of its effort", "proves", "always") counts as a failure. If the URL is dead but the work exists, find a working URL and return it as fixed_url. If a detail is wrong but the work exists, return the corrected citation line as fixed_citation. Return ok=true only when all three checks pass (possibly after your fix). Put what you checked in note (1–3 sentences).`,
      { label: `cite:${r.id}`, phase: 'Citations', schema: CITE_SCHEMA })
  ))).filter(Boolean)

  const bad = verdicts.filter(v => !v.ok)
  const fixes = verdicts.filter(v => v.ok && (v.fixed_url || v.fixed_citation))
  log(`citations: ${verdicts.length - bad.length}/${verdicts.length} confirmed, ${bad.length} refuted, ${fixes.length} corrected`)

  let fixup = 'no fix-up needed'
  if (bad.length || fixes.length) {
    fixup = await agent(`${common}
Edit ${SCRATCH}/research.md in place. Independent skeptics checked every reference. Apply these results exactly:

REFUTED (remove the reference, or replace it with a verified alternative you confirm yourself via WebFetch; rewrite any sentence that leaned on it so the text stays true and the numbering stays contiguous; if only the claim was overstated, tone the sentence down to what the source supports and keep the reference):
${bad.map(v => `- [${v.id}] ${v.note}`).join('\n') || '- none'}

CORRECTIONS (apply the corrected URL/citation line):
${fixes.map(v => `- [${v.id}] ${v.fixed_citation || ''} ${v.fixed_url ? 'URL: ' + v.fixed_url : ''} — ${v.note}`).join('\n') || '- none'}

Keep the section headings and length. Return a 2–3 sentence description of what changed and the final reference count.`,
      { label: 'research:fixup', phase: 'Citations' })
  }
  return { research, verdicts, fixup }
}

// ---------------------------------------------------------------- Track B: examples → verify (loop) → diagrams
const trackB = async () => {
  const buildPrompt = `${common}

You are the EXAMPLES agent. Build THREE examples of "${A.name}" as a functional refactoring, each in BOTH Scala 3 and Haskell, under ${EX}/NN-<ex>/ exactly as the brief's code layout describes (Before/After/Spec × .scala/.hs). Copy ${REPO}/pages/refactorings/extract-method/run.sh into ${EX}/run.sh unchanged. Suggested set — adjust if you find a better trio, but keep the progression simple → closes over context/effects → recursion or laziness matters:
${EXAMPLE_IDEAS}
Rules:
- Before and After expose the SAME entry point (same name, same signature) so Spec can compare them; After differs from Before ONLY by the refactoring. Keep every file short and idiomatic (Scala 3 syntax, braces-free is fine; Haskell 2010 + common extensions only). Lines ≤ 72 characters. The Scala and Haskell Befores must have the same shape.
- Spec generates meaningful inputs with hedgehog, designed around the program's boundaries (see the Generators section of the brief), and asserts before == after; add a second property per example when there is a natural one.
- Scala Spec must be runnable with: scala-cli run ${EX}/NN-ex --main-class spec   (exit 1 on failure). Haskell Spec with the docker command in the brief.
- RUN every spec in both languages yourself and only report scala_ok/haskell_ok=true when you saw it pass. Then run sh ${EX}/run.sh once from the repo root and confirm it ends with "all properties passed". Paste the last lines of output per example in output_tail.
- Mutation-check your own specs once before returning: break After in a copy under ${SCRATCH}/mut/, confirm each property fails, restore. The reviewer will do this again with different mutants.
- Do not create files outside ${EX}/ and ${SCRATCH}/. Leave no build artefacts outside .scala-build/ (gitignored).
Return the examples array and notes (design choices, anything the page text should mention).`

  let examples = await agent(buildPrompt, { label: 'examples:build', phase: 'Examples', schema: EXAMPLES_SCHEMA, effort: 'high' })
  if (!examples) return { examples: null }
  log(`examples built: ${examples.examples.map(e => e.dir).join(', ')}`)

  const reviewPrompt = (round) => `${common}

You are the REVIEWER. Independently confirm that each example under ${EX}/NN-*/ is a genuine equivalence, using the property-based tests, and try hard to break it. Round ${round}.
Steps, all mandatory:
1. Run sh ${EX}/run.sh from the repo root. Record per-example pass/fail for Scala and Haskell.
2. Mutation check of each Spec, both languages: make a small semantic change to After (off-by-one, dropped case, swapped operands, boundary < vs <=) in a COPY (cp -r the example dir into ${SCRATCH}/mut/NN-ex, edit the copy, run the copy's spec with the same commands, paths adjusted). The property MUST fail on the mutant, reliably (run flaky catches 5 times); if it survives, the generator or property is too weak — report the exact generator change and test count that fixes it, measured. Never leave a mutation in the real files (git -C ${REPO} status --short pages/refactorings).
3. Adversarial probes (throwaway specs in ${SCRATCH}/mut/, not in the repo): stronger generators (empty, negative, Int boundaries, deep ADTs); in Haskell, laziness/strictness — does After force something Before did not (undefined in lazily-unused positions, seq)? in Scala, evaluation count — does the refactoring change how many times something is evaluated (def vs val, by-name)? Totality: any partial function / non-exhaustive match introduced?
4. Read Before vs After in each language: is the refactoring the ONLY difference? Same entry-point signature? Are the Scala and Haskell Befores parallel? Short and idiomatic enough for a public page? Lines ≤ 72 chars? Any {{ or {% sequences (forbidden)? Any comment that overclaims (e.g. "never throws" where Int arithmetic can)?
Write a report to ${SCRATCH}/review-round${round}.md with a mutation table and a probe summary (the PR description quotes them). Return passed=true only if every example passes in both languages, every mutant was caught reliably, and no adversarial probe found a semantic difference. List concrete, actionable issues per example (file + what to change) — the examples agent will act on them verbatim.`

  let verdict = null
  for (let round = 1; round <= 3; round++) {
    verdict = await agent(reviewPrompt(round), { label: `verify:round${round}`, phase: 'Verify', schema: VERIFY_SCHEMA, effort: 'high' })
    if (!verdict) break
    log(`verify round ${round}: ${verdict.passed ? 'PASSED' : 'issues: ' + verdict.examples.flatMap(e => e.issues).length}`)
    if (verdict.passed) break
    examples = await agent(`${common}

You are the EXAMPLES agent again. The reviewer found problems in round ${round} (report: ${verdict.report_file}). Fix them in ${EX}/, keeping the same layout and rules as before. Issues:
${verdict.examples.map(e => `- ${e.dir}: ${e.issues.join(' | ') || 'ok'}`).join('\n')}
Adversarial findings: ${verdict.adversarial_findings.join(' | ') || 'none'}
Re-run every spec in both languages and sh ${EX}/run.sh; re-run the reviewer's mutants against your fix; report only what you saw pass.`,
      { label: `examples:fix${round}`, phase: 'Examples', schema: EXAMPLES_SCHEMA, effort: 'high' })
    if (!examples) break
  }

  let diagrams = null
  if (verdict && verdict.passed) {
    diagrams = await agent(`${common}

You are the DIAGRAM agent. Produce small inline-SVG diagrams for the page /refactorings/${A.slug}/, saved under ${EX}/. Read ${REPO}/pages/refactorings/extract-method/diagrams/koan.svg and one of its NN-*/diagram.svg first and match their visual language exactly (same stroke widths, fonts, arrow style, dashed region convention).
- diagrams/koan.svg — the "to and from" pair for this refactoring: left = before-shape, right = after-shape, top arrow labelled with the move pointing right, bottom arrow labelled with the inverse pointing left. Use the terms from ${SCRATCH}/research.md's "To and from" section.
- NN-<ex>/diagram.svg for each example directory present (read Before/After in that dir first): left = Before with the affected region drawn as a dashed inner rectangle; right = After with the new structure and the relationship (call, instance, parameter) named on the arrow. Use the real names from the code.
Rules: viewBox-based, no fixed width/height; all strokes and text use currentColor so it works in light and dark themes; fills only rgba with low alpha or none; font-family: inherit; font-size 12–14 viewBox units; <title> for accessibility; role="img"; no external resources, no scripts, no site CSS classes; each file under 6 KB; NO {{ or {% sequences. Render-check each SVG with the chrome-devtools MCP tools (ToolSearch for mcp__chrome-devtools__new_page / take_screenshot; file:// URLs work) at 1000px and 360px wide and fix overlaps or clipped text. Return the list of files written and notes.`,
      { label: 'diagrams', phase: 'Diagrams', schema: DIAGRAM_SCHEMA })
  }
  return { examples, verdict, diagrams }
}

const [a, b] = await parallel([trackA, trackB])
return { research: a, examples: b }
