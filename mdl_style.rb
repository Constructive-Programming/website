# mdl style for the site (loaded from .mdlrc). Start from mdl's default
# style and adjust for the site's actual content conventions.

all

# Fenced code blocks may omit a language tag where it adds nothing.
exclude_rule 'fenced-code-language'

# Pages start with a heading only after their front matter (which mdl skips
# entirely), and Liquid-driven pages have no heading at all.
exclude_rule 'first-line-h1'

# The refactoring pages carry citations and koans as raw HTML blocks (the
# refactoring skill writes them that way because kramdown won't process
# markdown inside raw block HTML). Inline HTML is fine here by design.
exclude_rule 'no-inline-html'

# The refactorings post steps are numbered 1., 2., 3., ...; require a
# consistent ordered sequence instead of mdl's default "one" style.
rule 'MD029', :style => :ordered

# Headings may end in '?' (e.g. '## Not a fit?') — markdownlint's MD026
# default punctuation (".,;:!") is what this site always used.
rule 'MD026', :punctuation => '.,;:!'

# Prose wraps at 80 chars. Code blocks, tables and headings carry their own
# width rules (the refactoring panes are capped at 72 chars by
# scripts/check-sample-width.sh), so exempt them here.
rule 'MD013', :line_length => 80, :ignore_code_blocks => true,
              :tables => false, :headings => false
