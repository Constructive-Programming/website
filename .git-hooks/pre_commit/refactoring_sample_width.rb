# frozen_string_literal: true

module Overcommit::Hook::PreCommit
  # Enforces the 72-char pane width on refactoring sample sources
  # (see the refactoring skill's LESSONS.md 'pane width').
  class RefactoringSampleWidth < Base
    MAX_WIDTH = 72

    def run
      errors = []

      applicable_files.each do |file|
        next unless File.exist?(file)

        File.foreach(file).with_index(1) do |line, line_no|
          content = line.chomp
          next if content.length <= MAX_WIDTH

          errors << "#{file}: line #{line_no} is #{content.length} chars " \
                    "(> #{MAX_WIDTH})"
        end
      end

      return :pass if errors.empty?

      [:fail, errors.join("\n")]
    end
  end
end
