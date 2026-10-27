#!/usr/bin/env bash
# Point git at the repo's shared hooks. Run once after cloning.
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"
chmod +x githooks/*
git config core.hooksPath githooks
echo "Git hooks installed from githooks/ (pre-commit, commit-msg, and their git am equivalents)."
