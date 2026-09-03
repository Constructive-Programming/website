#!/usr/bin/env bash
# Refactoring sample sources must stay within the 72-char pane width
# (see .claude/skills/refactoring-entry/LESSONS.md "pane width").
# Invoked by pre-commit with the changed sample files as arguments.
set -u

status=0
for f in "$@"; do
  [ -f "$f" ] || continue
  line_no=0
  while IFS= read -r line; do
    if [ "${#line}" -gt 72 ]; then
      printf '%s: line %s is %s chars (> 72)\n' "$f" "$((line_no + 1))" "${#line}"
      status=1
    fi
    line_no=$((line_no + 1))
  done < "$f"
done
exit "$status"
