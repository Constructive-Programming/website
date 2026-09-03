#!/usr/bin/env bash
# Run the full lint suite against every tracked file. This is the exact same
# configuration that runs locally on commit (bundle exec overcommit --install);
# CI calls this script, so local and CI can't drift.
set -euo pipefail
cd "$(dirname "$0")/.."
exec bundle exec overcommit --run
