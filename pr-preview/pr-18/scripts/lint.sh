#!/usr/bin/env bash
# Run the full lint suite against every tracked file. This is the exact same
# configuration that runs locally on commit (bundle exec overcommit --install);
# CI calls this script, so local and CI can't drift.
set -euo pipefail
cd "$(dirname "$0")/.."
# OVERCOMMIT_NO_VERIFY: overcommit records hook signatures in the local
# git config, which a fresh checkout (CI) never has, so skip that check.
# (verify_signatures is already off in .overcommit.yml; this makes the very
# first run work without an interactive `overcommit --sign`.)
export OVERCOMMIT_NO_VERIFY=1
export GIT_AUTHOR_NAME="${GIT_AUTHOR_NAME:-CI}"
export GIT_AUTHOR_EMAIL="${GIT_AUTHOR_EMAIL:-ci@example.com}"
exec bundle exec overcommit --run
