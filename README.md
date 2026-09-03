# website

Source for [www.constructive.dev](https://www.constructive.dev). Jekyll,
built on the [Type-on-Strap](https://github.com/sylhare/Type-on-Strap) remote
theme, deployed to GitHub Pages from the `gh-pages` branch.

- **Build & deploy** (`.github/workflows/build.yml`): on push to `master`,
  builds with `JEKYLL_ENV=production` and force-pushes `_site/` to `gh-pages`.
- **PR previews** (`.github/workflows/preview.yml`): each PR gets a preview at
  `https://www.constructive.dev/pr-preview/pr-<N>/` via
  [rossjrw/pr-preview-action](https://github.com/rossjrw/pr-preview-action).
- **Lint** (`.github/workflows/lint.yml`): runs
  [`scripts/lint.sh`](scripts/lint.sh) — which is exactly
  `bundle exec overcommit --run` — on every PR and push to `master`. The
  same overcommit configuration runs locally on commit; install once, then
  it just happens:

  ```sh
  bundle install
  bundle exec overcommit --install
  # only required for the spell check:
  pip install codespell
  ```

  Rules: Markdown (`mdl`, style in [`.mdlrc`](.mdlrc) +
  [`mdl_style.rb`](mdl_style.rb)), spelling (codespell), hygiene checks
  (trailing whitespace, final newline, YAML/JSON syntax, merge markers,
  case conflicts, executable/shebang consistency) and a 72-char pane-width
  cap on the refactoring sample sources. Run everything at any time with
  `scripts/lint.sh`.

```sh
bundle install
bundle exec jekyll serve
```
