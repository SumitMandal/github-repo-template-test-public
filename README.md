# Project Name

One sentence on what this project does and who it is for.

[![CI](https://github.com/SumitMandal/YOUR-REPO/actions/workflows/ci.yml/badge.svg?branch=develop)](https://github.com/SumitMandal/YOUR-REPO/actions/workflows/ci.yml)

## Getting started

### Prerequisites

- List the tools and versions needed (for example Node.js 22, Python 3.12)

### Install

```bash
git clone https://github.com/SumitMandal/YOUR-REPO.git
cd YOUR-REPO
./scripts/install-hooks.sh
# install dependencies here
```

### Run

```bash
# how to start the project locally
```

### Test

```bash
# how to run the test suite
```

## Branch model

Code is promoted one branch at a time, always through a pull request:

```
feature/*  ->  develop  ->  stage  ->  release/x.y.z  ->  main
                  ^                         |              |
                  +----- back-merge --------+--------------+
hotfix/*  ->  main  (then into develop and any open release/*)
```

| Branch | Purpose | Created from | Merges into | Deploys to |
| --- | --- | --- | --- | --- |
| `main` | Production, every merge tagged `vX.Y.Z` | — | — | Production |
| `release/x.y.z` | Version freeze, bug fixes only; cut by maintainers, not a PR | `stage` | `main`, then `develop` | Pre-production |
| `stage` | QA and acceptance testing | — | Cut into `release/*` | Staging |
| `develop` | Integration of finished work (default branch) | — | `stage` | Dev |
| `feature/<name>` | One task or ticket | `develop` | `develop` | — |
| `bugfix/<name>` | Fix found in QA (via `develop`) or on a release | `develop` or `release/*` | Its source branch | — |
| `hotfix/<name>` | Urgent production fix | `main` | `main`, then `develop` and any open `release/*` | — |
| `backmerge/<name>` | Resolving back-merge conflicts | `develop` or `release/*` | Its source branch | — |

Merges between long-lived branches always use merge commits; only short-lived `feature/*` and `bugfix/*` PRs are squashed. See [CONTRIBUTING.md](CONTRIBUTING.md) for the promotion steps and commit and pull request conventions.

### What the rulesets enforce

| Rule | `main` | `release/*` | `stage` | `develop` |
| --- | --- | --- | --- | --- |
| Approvals | 1 | 1 | 1 | 1 |
| Code owner approval for owned paths (`.github/`, `githooks/`, `scripts/`) | Yes | Yes | Yes | Yes |
| Merge methods | Merge commit | Merge commit, squash | Merge commit | Squash, merge commit |
| Required checks | build-and-test, branch-policy, pr-title, commit-messages | same | same | same |
| Signed commits | Yes | Yes | Yes | No |
| No force push | Yes | Yes | Yes | Yes |
| No deletion | Yes | Admins only | Yes | Yes |
| Admin emergency merge (PRs only) | Yes | Yes | Yes | Yes |

`release/*` branches and `v*` tags can only be created by maintainers and admins, and tags can't be moved or deleted. Checks aren't required to be "up to date" with the base branch: with merge-commit promotion, a long-lived source branch can never be. After each merge into `develop`, a `merge-guard` workflow flags the two mistakes rulesets can't prevent, and comments on the PR: a back-merge that was squashed, and a feature PR merged with a merge commit that carried unsigned commits in.

**Cutting a release branch works with a plain push.** Tested live: `git push origin origin/stage:refs/heads/release/x.y.z` by an admin was blocked only by the `release-create` rule, which admins and maintainers bypass. The `release` ruleset's pull-request and signing rules don't apply to creating the branch.

**The git hooks only run on developers' machines.** Branches and commits made in GitHub's web interface (or any client without the hooks) skip them, and GitHub's rules for branch names and commit messages need GitHub Enterprise. So the same rules are enforced again when a pull request is opened: `branch-policy` checks the branch name, `pr-title` the PR title, and `commit-messages` every commit on a `feature/`, `bugfix/` or `hotfix/` branch. A badly named branch or commit can be created, but it can't be merged.

**Several open PRs from one branch share their check results.** GitHub attaches checks to the head commit, so `branch-policy`, `pr-title` and `commit-messages` check every open PR on that commit and fail if any breaks the rules. Fix or close the PR the check names, then re-run the check on the others.

**Automating back-merges:** a PR opened by a workflow using the built-in `GITHUB_TOKEN` doesn't trigger other workflows, so its required checks never report. Use a GitHub App token or a fine-grained personal access token for any bot that opens back-merge PRs.

**Finishing a release is manual:** tag `main` and update `CHANGELOG.md` yourself, or add a tool such as release-please to do both.

## Using this template

1. Click **Use this template → Create a new repository** on GitHub.
2. Clone the new repository and run the one-time setup (requires the [GitHub CLI](https://cli.github.com/) and repo admin rights):

   ```bash
   ./scripts/setup-repo.sh SumitMandal/YOUR-REPO
   ```

   It creates `main`, `develop` and `stage` (whichever are missing), makes `develop` the default branch, makes merge commit subjects use the PR title, creates labels, applies the branch and tag rulesets in `.github/rulesets/`, and turns on Dependabot, secret scanning and push protection.

   Rulesets need a public repository or a paid plan (GitHub Pro, Team or Enterprise) for private ones. Without one, the script warns, skips them and finishes the rest of the setup, but nothing on GitHub enforces the branch model.
3. Replace `YOUR-REPO` with the new repository's name (`grep -rn "YOUR-REPO" .`), and check that `.github/CODEOWNERS` lists the right people.
4. Fill in this README, choose a license in `LICENSE`, and check `.github/workflows/ci.yml` runs your build and tests. In `.github/dependabot.yml`, uncomment the entry for your package ecosystem.
5. Turn on CodeQL: **Settings → Code security → Code scanning → Default setup**.

## License

See [LICENSE](LICENSE).
