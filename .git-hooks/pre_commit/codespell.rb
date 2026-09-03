# frozen_string_literal: true

module Overcommit::Hook::PreCommit
  # Runs `codespell` on the files being committed.
  class Codespell < Base
    def run
      result = execute(
        %w[codespell --ignore-words-list=Claus,Technik --skip=_site,.git,node_modules],
        args: applicable_files,
      )
      return :pass if result.success?

      [:fail, (result.stdout + result.stderr).chomp]
    end
  end
end
