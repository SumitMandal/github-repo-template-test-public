#!/usr/bin/env bash
# One-time setup for a repository created from this template.
# Requires the GitHub CLI (gh), logged in with admin rights on the repo.
#
#   ./scripts/setup-repo.sh SumitMandal/YOUR-REPO
set -euo pipefail

repo=${1:?usage: setup-repo.sh OWNER/REPO}
cd "$(git rev-parse --show-toplevel)"

step() { printf '\n== %s\n' "$*"; }

step "Creating main, develop and stage"
# "Use this template" copies only the template's default branch, so main may be missing.
default=$(gh api "repos/$repo" --jq .default_branch)
base_sha=$(gh api "repos/$repo/git/ref/heads/$default" --jq .object.sha)
for b in main develop stage; do
  if gh api "repos/$repo/git/ref/heads/$b" >/dev/null 2>&1; then
    echo "$b already exists"
  else
    gh api "repos/$repo/git/refs" -f ref="refs/heads/$b" -f sha="$base_sha" >/dev/null
    echo "created $b from $default"
  fi
done

step "Repository settings"
gh repo edit "$repo" \
  --default-branch develop \
  --enable-merge-commit \
  --enable-squash-merge \
  --enable-rebase-merge=false \
  --delete-branch-on-merge \
  --enable-auto-merge=false \
  --enable-wiki=false
# Squash and merge commits take the PR title, which the pr-title check keeps conventional.
# (The default uses a single-commit PR's own commit message instead.)
gh api "repos/$repo" --method PATCH \
  -f squash_merge_commit_title=PR_TITLE -f squash_merge_commit_message=COMMIT_MESSAGES \
  -f merge_commit_title=PR_TITLE -f merge_commit_message=PR_BODY >/dev/null
echo "default branch: develop; merge + squash only; commit subjects from PR titles; head branches auto-deleted"

step "Labels"
while IFS='|' read -r name color desc; do
  gh label create "$name" --repo "$repo" --color "$color" --description "$desc" --force >/dev/null
  echo "label: $name"
done <<'LABELS'
type: bug|d73a4a|Something is broken
type: feature|0e8a16|New functionality
type: docs|0075ca|Documentation only
type: chore|cfd3d7|Maintenance, tooling, dependencies
priority: high|b60205|Fix first
priority: medium|fbca04|Normal priority
priority: low|c2e0c6|When there is time
status: needs-triage|ededed|Not yet reviewed by a maintainer
status: blocked|000000|Waiting on something else
breaking-change|b60205|Changes public behaviour or APIs
dependencies|0366d6|Dependency updates
skip-changelog|ffffff|Leave out of release notes
good first issue|7057ff|Good for newcomers
help wanted|008672|Extra attention is needed
LABELS

step "Rulesets"
# Rulesets need a public repository or a paid plan (GitHub Pro, Team or Enterprise)
# for private ones. Without them, warn and carry on with the rest of the setup.
rulesets_skipped=0
if ! existing=$(gh api --paginate "repos/$repo/rulesets?includes_parents=false" --jq '.[].name' 2>"${TMPDIR:-/tmp}/rulesets-err.$$"); then
  rulesets_skipped=1
  echo "WARNING: rulesets aren't available on this repository: $(head -n1 "${TMPDIR:-/tmp}/rulesets-err.$$")"
  echo "         Private repositories need GitHub Pro, Team or Enterprise for rulesets."
  echo "         Branch protection, required checks and signing are NOT enforced. Re-run this"
  echo "         script after upgrading or making the repository public."
else
  for f in .github/rulesets/*.json; do
    name=$(sed -n 's/^  "name": "\(.*\)",$/\1/p' "$f" | head -n1)
    if grep -qxF "$name" <<<"$existing"; then
      echo "ruleset '$name' already exists, skipped (edit it in Settings -> Rules)"
    elif gh api "repos/$repo/rulesets" --method POST --input "$f" >/dev/null 2>"${TMPDIR:-/tmp}/rulesets-err.$$"; then
      echo "ruleset '$name' created"
    else
      rulesets_skipped=1
      echo "WARNING: ruleset '$name' was not created: $(head -n1 "${TMPDIR:-/tmp}/rulesets-err.$$")"
    fi
  done
fi
rm -f "${TMPDIR:-/tmp}/rulesets-err.$$"

step "Security features"
gh api "repos/$repo/vulnerability-alerts" --method PUT >/dev/null && echo "Dependabot alerts on"
gh api "repos/$repo/automated-security-fixes" --method PUT >/dev/null && echo "Dependabot security updates on"
gh api "repos/$repo/private-vulnerability-reporting" --method PUT >/dev/null 2>&1 \
  && echo "private vulnerability reporting on" \
  || echo "private vulnerability reporting: enable it in Settings -> Code security"
gh api "repos/$repo" --method PATCH --input - >/dev/null 2>&1 <<'JSON' \
  && echo "secret scanning and push protection on" \
  || echo "secret scanning: not available on this plan or repo visibility; enable it in Settings -> Code security"
{"security_and_analysis": {"secret_scanning": {"status": "enabled"}, "secret_scanning_push_protection": {"status": "enabled"}}}
JSON

step "Placeholders"
if grep -rqs "YOUR-" .github/CODEOWNERS; then
  echo "WARNING: .github/CODEOWNERS still has placeholder owners. Until you replace them,"
  echo "         GitHub ignores owners that don't exist, so code owner review isn't enforced,"
  echo "         and a PR could edit the branch-policy workflow without a maintainer's approval."
fi

step "Local git hooks"
./scripts/install-hooks.sh

if (( rulesets_skipped )); then
  echo
  echo "WARNING: some rulesets were not applied (see above). The branch model is not enforced yet."
fi

cat <<'DONE'

Setup complete. Remaining manual steps:
  1. Settings -> Code security -> Code scanning -> enable CodeQL "Default setup".
  2. Settings -> Environments -> create production, pre-production and staging
     with required reviewers and their own secrets.
  3. Replace YOUR-REPO with this repository's name (grep -rn YOUR-REPO .) and commit via a PR.
DONE
