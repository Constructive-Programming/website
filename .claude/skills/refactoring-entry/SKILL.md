---
name: refactoring-entry
description: Add one entry to the Constructive Programming refactoring catalogue at /refactorings/ — research with verified citations, 3 Before/After examples in Scala 3 and Haskell, hedgehog property-based proof of equivalence, diagrams, page, PR. Use when asked to "do the next refactoring", "add <name> to the catalogue", or "write the <name> entry".
---

# Refactoring catalogue entry

One entry = one refactoring from `_data/refactorings.yml`, read as an equation between programs
and *checked* with property-based tests. The reference implementation is `/refactorings/extract-method/`
(page `pages/refactorings/extract-method.md`, sources `pages/refactorings/extract-method/`).
Copy its shape; do not redesign it.

Each entry is written **with its dual**: the refactoring and its inverse are one equation, and the
page presents both directions ("Extract / Inline", "Replace X with Y / Replace Y with X"). The list name
in `_data/refactorings.yml` carries both sides, e.g. `Extract / Inline method`.

## 0. Read the lessons first

Read `LESSONS.md` in this directory, top to bottom. It is the memory of every previous entry: what
the reviewer caught, what broke, what the calibration table says. Anything marked **rule** there
overrides the defaults below. If a lesson has become permanent, it has already been folded into
the steps below and the `workflow.js` prompts; if you find one that has not, fold it in now.

## 1. Set up

1. Branch from `master`: `refactoring/<slug>`.
2. Pick the entry: the first item in `_data/refactorings.yml` without a `slug`, unless the user
   names one. Add `slug: <slug>` to it (that is what links it on the index page).
3. Toolchain check (the agents assume these work):
   - `scala-cli --version` (hedgehog `qa.hedgehog::hedgehog-core:0.14.0` + `hedgehog-runner:0.14.0`).
   - `docker image inspect cp-hedgehog` — if missing, `sh pages/refactorings/extract-method/run.sh`
     builds it (about 2.5 minutes). GHC is not installed here; nix is read-only.
4. Write the brief to the scratchpad: copy `brief.md` from this directory, fill the `<...>` fields.
   The agents that build the entry read the brief, not this file.

## 2. Run the workflow (research ∥ examples → review → diagrams)

This skill describes a *workflow*, not a Claude-specific runner. The phases below are mandatory;
how you parallelise them depends on your agent runtime:

- **Research** — with verified citations (one skeptic pass per reference), and
- **Examples** — build + run the 3 Before/After/Spec pairs in both languages, then
- **Review** — mutation-check + adversarial probes; fix, up to 3 rounds, then
- **Diagrams** — inline SVG koan + one per example.

If your runtime provides a batch/orchestration runner (e.g. `workflow.js` in this directory is a
Claude Code `Workflow` script that runs both tracks in parallel and resumes crashed agents from
`journal.jsonl`), use it with `slug/name/number/total/brief/scratch/repo/seeds/examples` args — but
any agent can run the phases itself in order (research → citation checks → examples → review →
diagrams), which is exactly what `workflow.js` does under the hood. While research runs, write
`pages/refactorings/<slug>.md` from the extract-method page (next step) and build the site in a
scratch copy with stub SVGs to catch Liquid errors early.

## 3. Assemble the page

Start from `pages/refactorings/extract-method.md`. Keep: front matter shape (`layout: page`,
`subtitle` carries the koan and names both directions, `permalink: /refactorings/<slug>/`, `tags`,
`hide: true` so entry pages stay out of the top-right nav), the crumb line, the
section order (Motivation · The move · To and from + koan figure ·
Three examples · Pitfalls + a collapsible "The functional reading" footnote ·
Verification · References) — **Motivation is always
the first section, before The move** — the `rf-pair` /
`rf-figure` / `rf-spec` markup, and the `run.sh` instructions. Replace the prose with
`<scratch>/research.md` (after its citation fix-up) and write one paragraph per example from
the examples agent's `what_changes` notes.

Motivation states why you would move in either direction: what smell drives the move, and
what smell drives its inverse. Extract-style motivators include duplication and methods that
have grown too long; inline-style motivators include speculative generality and coupling
through a seam's implementation rather than its contract. Two short paragraphs, one per
direction, before any mechanics — the reader should know when to reach for the move before
how to perform it.

Rules that came from review, keep them:
- In-text citations are links: write `[[n](#ref-n)]` (render → [<a href="#ref-n">n</a>]);
  each reference list item is raw HTML `<li id="ref-N">…</li>` inside a plain `<ol>`, with
  markdown inline formatting hand-rendered to `<em>` and `<a href>` (Kramdown will not process
  markdown inside raw block HTML, and IALs on numbered items break the list).
- Source lines ≤ 72 characters or the pane scrolls horizontally on a 1280px screen.
- No `{{` `}}` `{%` `%}` in any included source (Liquid runs before highlighting).
- Copy `run.sh` from extract-method unchanged into the new sources directory (then adjust it only
  if the entry has a real reason to, e.g. a `shared/` module — see next bullet).
- Add the new sources directory to `exclude:` in `_config.yml` (sources are included via
  `include_relative`, not published as static files).
- **Setup shared across examples lives in `shared/` and is never shown on the page.** If the entry
  needs shared machinery (an optic library, a hedgehog spec runner, a common data type), put it in
  `pages/refactorings/<slug>/shared/` and have `run.sh` compile it (`scala-cli run "$d" … "$SHARED"`
  for Scala, `-i"$SHARED"` for Haskell) — but do NOT `include_relative` it. Each Example
  `Before/After/Spec` on the page is then the *move itself*, with a one-line note in the page that
  the shared setup is hidden. The reviewer considers inline setup (e.g. redefining a Lens type in
  every After) accidental complexity that buries the motivation.
- **Never hand-write intermediate helpers in an example.** If the example needs a walk over a
  recursive type, a fold, or a traversal builder, do not define it in the example's `After` —
  add it to `shared/` (e.g. a `Plated` class with `descend`/`everywhere`, as in eo's "visit
  across whole trees" recipe) or use a library, and have the example declare only the instance
  (`which fields recurse`). A hand-rolled `everywhere` in an example buries the motivation: the
  optic is the reusable thing, not the helper. This is the same rule as the `shared/` bullet
  above — shared machinery stays off the page — extended to any intermediate helper the
  example needs.
- Do not claim totality or purity the code does not have (e.g. `Int` `div` overflow).

## 4. Verify before the PR

1. `sh pages/refactorings/<slug>/run.sh` ends with `all properties passed` — run it yourself, do
   not trust the agent's report alone.
2. `bundle exec jekyll build --destination <scratch>/site` exits 0; open the page over
   `python3 -m http.server` and screenshot at 1280 and 390 wide; no horizontal page scroll,
   diagrams legible in light and dark.
3. Re-read the reviewer's last report; every **blocking** item is fixed, every optional item is
   either applied or deliberately declined in the PR description.

## 5. Ship

Commit sources + page + data + config on the branch; push (SSH remote works; if `gh auth status`
fails ask the user to run `! gh auth login -h github.com -p ssh -w` — or use whichever GitHub
tool your environment provides); open the PR with the
reviewer's mutation table and probe summary in the body. The PR preview URL is
`https://www.constructive.dev/pr-preview/pr-<N>/refactorings/<slug>/`.

## 6. Improve the skill (mandatory, last)

Append a dated entry to `LESSONS.md` with: reviewer findings (blocking and optional), toolchain
failures and their fixes, wall-clock and agent count from the workflow result, anything the
prose reviewers (citation skeptics) refuted, and any generator/test-count calibration that
changed. Then act on it: if a lesson is a rule, edit the rule into this file or into the prompts
in `workflow.js` so the next run does not have to rediscover it; if a lesson retires an older one,
delete the older one. Commit the skill change in the same PR.
