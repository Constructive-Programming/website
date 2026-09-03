# frozen_string_literal: true

module Overcommit::Hook::PreCommit
  # Runs spellr (the Ruby spell checker) on the files being committed.
  # spellr splits camelCase and snake_case identifiers, skips URLs and
  # hex-like strings via heuristics, obeys .gitignore, and consults
  # .spellr.yml plus the wordlists in .spellr_wordlists/. It runs from
  # the repo root so the config is found wherever the hook triggers.
  class Spellr < Base
    def run
      return :pass if applicable_files.empty?

      result = execute(%w[bundle exec spellr], args: applicable_files)

      return :pass if result.success?

      [:fail, (result.stdout + result.stderr).chomp]
    end
  end
end
