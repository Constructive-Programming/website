# frozen_string_literal: true

module Overcommit::Hook::PreCommit
  # Checks that files end with a single newline (previously pre-commit's
  # end-of-file-fixer, without the auto-fix).
  class FinalNewline < Base
    def run
      errors = []

      applicable_files.each do |file|
        next unless File.exist?(file) && !File.directory?(file)

        content = File.binread(file)
        # Skip binaries and files that are not UTF-8 text (ends-of-files
        # only make sense for text; the previous pre-commit hook ignored
        # binaries too).
        next if content.empty?
        next if content.include?("\0") || !content.valid_encoding?

        unless content.end_with?("\n")
          errors << "#{file}: missing final newline"
        end
      end

      return :pass if errors.empty?

      [:fail, errors.join("\n")]
    end
  end
end
