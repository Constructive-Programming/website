# frozen_string_literal: true

module Overcommit::Hook::PreCommit
  # Any tracked file with the executable bit set must start with a shebang
  # (previously pre-commit's check-executables-have-shebangs and
  # check-shebang-scripts-are-executable, combined).
  class CheckExecutableShebangs < Base
    def run
      errors = []

      `git ls-files -sz`.split("\0").each do |entry|
        mode_part, path = entry.split("\t", 2)
        mode = mode_part.split(' ').first.to_i(8) & 0o111
        next if mode.zero?

        next unless File.exist?(path) && !File.directory?(path)

        first = File.open(path) { |f| f.readline } rescue ''
        if !first.start_with?('#!')
          errors << "#{path}: executable file is missing a shebang"
        elsif (File.stat(path).mode & 0o111).zero?
          errors << "#{path}: script starts with a shebang but is not executable"
        end
      end

      return :pass if errors.empty?

      [:fail, errors.join("\n")]
    end
  end
end
