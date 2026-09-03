# website

Source for [www.constructive.dev](https://www.constructive.dev). Jekyll, built on the [Type-on-Strap](https://github.com/sylhare/Type-on-Strap) remote theme, deployed to GitHub Pages from the `gh-pages` branch.

- **Build & deploy** (`.github/workflows/build.yml`): on push to `master`, builds with `JEKYLL_ENV=production` and force-pushes `_site/` to `gh-pages`.
- **PR previews** (`.github/workflows/preview.yml`): each PR gets a preview at `https://www.constructive.dev/pr-preview/pr-<N>/` via [rossjrw/pr-preview-action](https://github.com/rossjrw/pr-preview-action).

```sh
bundle install
bundle exec jekyll serve
```
