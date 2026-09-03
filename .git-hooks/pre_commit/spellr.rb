# frozen_string_literal: true

module Overcommit::Hook::PreCommit
  # Runs spellr (the Ruby spell checker) on the files being committed.
  # spellr splits camelCase and snake_case identifiers, skips URLs and
  # hex-like strings via heuristics, obeys .gitignore, and consults
  # .spellr.yml plus the wordlists in .spellr_wordlists/. It runs from
  # the repo root so the config is found wherever the hook triggers.
  #
  # NOTE: spellr applies .spellr.yml excludes only when given a directory
  # or nothing; explicit file arguments bypass them. Overcommit passes
  # files, so re-apply the same excludes here.
  class Spellr < Base
    EXCLUDES = [
      # match on the repo-relative path and the bare basename, because
      # overcommit passes absolute paths in --run mode
      lambda do |path|
        rel = path.sub(%r{#{Regexp.escape(Overcommit::Utils.repo_root)}/?}, '')
        rel =~ %r{^\.claude/} ||
          rel =~ %r{\.(scala|hs|js)$} ||
          rel == 'run.sh' ||
          rel =~ %r{^pages/refactorings/} ||
          rel == '.gitignore' ||
          File.basename(rel).start_with?('.')
      end
    ].freeze

    def run
      files = applicable_files.reject { |f| EXCLUDES.any? { |re| re.call(f) } }
      return :pass if files.empty?

      result = execute(%w[bundle exec spellr], args: files)
      return :pass if result.success?

      [:fail, (result.stdout + result.stderr).chomp]
    end
  end
end
