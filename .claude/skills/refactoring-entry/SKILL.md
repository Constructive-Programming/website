---
name: refactoring-entry
description: Add one entry to the Constructive Programming refactoring catalogue at /refactorings/ — research with verified citations, 3 Before/After examples in Scala 3 and Haskell, hedgehog property-based proof of equivalence, diagrams, page, PR. Use when asked to "do the next refactoring", "add <name> to the catalogue", or "write the <name> entry".
---

# Refactoring catalogue entry

One entry = one refactoring from `_data/refactorings.yml`, read as an equation between programs
and *checked* with property-based tests. The reference implementation is `/refactorings/extract-method/`
(page `pages/refactorings/extract-method.md`, sources `pages/refactorings/extract-method/`).
Copy its shape; do not redesign it.

## 0. Read the lessons first

Read `LESSONS.md` in this directory, top to bottom. It is the memory of every previous entry: what
the reviewer caught, what broke, what the calibration table says. Anything marked **rule** there
overrides the defaults below. If a lesson has become permanent, it has already been folded into
the steps below and the `workflow.js` prompts; if you find one that has not, fold it in now.

## 1. Set up

1. Branch from `master`: `refactoring/<slug>`.
2. Pick the entry: the first item in `_data/refactorings.yml` without a `slug`, unless the user
   names one. Add `slug: <slug>` to it (that is what links it on the index page).
3. Toolchain check (the workflow agents assume these work):
   - `scala-cli --version` (hedgehog `qa.hedgehog::hedgehog-core:0.14.0` + `hedgehog-runner:0.14.0`).
   - `docker image inspect cp-hedgehog` — if missing, `sh pages/refactorings/extract-method/run.sh`
     builds it (about 2.5 minutes). GHC is not installed on the host; nix is read-only.
4. Write the brief to the scratchpad: copy `brief.md` from this directory, fill the `<...>` fields.
   The workflow agents read the brief, not this file.

## 2. Run the workflow (research ∥ examples → verify loop → diagrams)

```
Workflow({
  scriptPath: ".claude/skills/refactoring-entry/workflow.js",
  args: {
    slug: "<slug>", name: "<Name>", number: <n>, total: 35,
    brief: "<abs path to brief.md>", scratch: "<abs scratchpad dir>",
    repo: "<abs repo root>",
    seeds: ["<paper or tool that anchors the OO side>", "<the FP-side paper>", ...],
    examples: ["<example 1 idea>", "<example 2 idea>", "<example 3 idea>"]
  }
})
```

- The script runs two tracks in parallel: **research → per-citation skeptics → fix-up**, and
  **examples → reviewer (mutation + adversarial probes) → fix, up to 3 rounds → diagrams**.
- If an agent dies (session limit, API error), relaunch with `resumeFromRunId`; finished agents replay
  from cache. Read `journal.jsonl` before assuming a result is empty.
- While it runs: write `pages/refactorings/<slug>.md` from the extract-method page (next step), and
  build the site in a scratch copy with stub SVGs to catch Liquid errors early.

## 3. Assemble the page

Start from `pages/refactorings/extract-method.md`. Keep: front matter shape (`layout: page`,
`subtitle` carries the koan, `permalink: /refactorings/<slug>/`, `tags`), the crumb line, the
section order (intro · The move · The functional reading · To and from + koan figure ·
Three examples · When it is not an equivalence · Checking it · References), the `rf-pair` /
`rf-figure` / `rf-spec` markup, and the `run.sh` instructions. Replace the prose with
`<scratch>/research.md` (after its citation fix-up) and write one paragraph per example from
the examples agent's `what_changes` notes.

Rules that came from review, keep them:
- Source lines ≤ 72 characters or the pane scrolls horizontally on a 1280px screen.
- No `{{` `}}` `{%` `%}` in any included source (Liquid runs before highlighting).
- Copy `run.sh` from extract-method unchanged into the new sources directory.
- Add the new sources directory to `exclude:` in `_config.yml` (sources are included via
  `include_relative`, not published as static files).
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
fails ask the user to run `! gh auth login -h github.com -p ssh -w`); open the PR with the
reviewer's mutation table and probe summary in the body. The PR preview URL is
`https://www.constructive.dev/pr-preview/pr-<N>/refactorings/<slug>/`.

## 6. Improve the skill (mandatory, last)

Append a dated entry to `LESSONS.md` with: reviewer findings (blocking and optional), toolchain
failures and their fixes, wall-clock and agent count from the workflow result, anything the
prose reviewers (citation skeptics) refuted, and any generator/test-count calibration that
changed. Then act on it: if a lesson is a rule, edit the rule into this file or into the prompts
in `workflow.js` so the next run does not have to rediscover it; if a lesson retires an older one,
delete the older one. Commit the skill change in the same PR.
