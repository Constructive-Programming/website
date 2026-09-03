# website

Source for [www.constructive.dev](https://www.constructive.dev). Jekyll,
built on the [Type-on-Strap](https://github.com/sylhare/Type-on-Strap) remote
theme, deployed to GitHub Pages from the `gh-pages` branch.

- **Build & deploy** (`.github/workflows/build.yml`): on push to `master`,
  builds with `JEKYLL_ENV=production` and force-pushes `_site/` to `gh-pages`.
- **PR previews** (`.github/workflows/preview.yml`): each PR gets a preview at
  `https://www.constructive.dev/pr-preview/pr-<N>/` via
  [rossjrw/pr-preview-action](https://github.com/rossjrw/pr-preview-action).
- **Lint** (`.github/workflows/lint.yml`): runs `pre-commit` on every PR. The
  same config also runs locally on commit — install once, then it just
  happens:

  ```sh
  pip install pre-commit
  pre-commit install
  ```

  Rules: Markdown (`markdownlint-cli2`, config in `.markdownlint-cli2.yaml`),
  spelling (codespell), plus `pre-commit-hooks` hygiene checks and a 72-char
  pane-width cap on the refactoring sample sources (`scripts/check-sample-width.sh`).
  Run everything at any time with `pre-commit run --all-files`.

```sh
bundle install
bundle exec jekyll serve
```
