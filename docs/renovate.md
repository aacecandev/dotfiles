# Renovate

[Renovate](https://docs.renovatebot.com) keeps the tool versions pinned in
`.config/mise/config.toml` up to date. It runs as a GitHub Actions workflow
and opens one pull request per tool update.

| File | Purpose |
| --- | --- |
| `.github/workflows/renovate.yml` | Runs Renovate every Monday at 04:00 UTC, on demand, and when a Dependency Dashboard checkbox is ticked |
| `.github/renovate.json` | Renovate config: only the `mise` manager, only `.config/mise/config.toml` |

Pull requests use `chore(mise): ...` commit messages, so merging them never
creates a new version tag (see "Continuous integration" in
[AGENTS.md](../AGENTS.md#continuous-integration)). Tools that Renovate cannot
resolve are skipped and listed on the Dependency Dashboard.

There is no hourly PR limit (`prHourlyLimit: 0`) and no Renovate-side time
window: the workflow's cron decides when Renovate runs. At most 10 Renovate
pull requests are open at once (`prConcurrentLimit`); the rest wait on the
dashboard until one is merged or closed.

## Token setup

The workflow authenticates with a repository secret named `RENOVATE_TOKEN`.
It must be a personal access token, not the automatic `GITHUB_TOKEN`: pull
requests opened with `GITHUB_TOKEN` do not trigger other workflows, so the
`ci` checks would never run on Renovate's pull requests.

1. Open GitHub **Settings > Developer settings > Personal access tokens >
   Fine-grained tokens > Generate new token**.
2. **Resource owner:** the account that owns this repository.
3. **Expiration:** pick a date and put a reminder to rotate it before then.
   An expired token makes the workflow fail.
4. **Repository access:** *Only select repositories*, and select this
   repository only.
5. **Repository permissions:**

   | Permission | Access | Why |
   | --- | --- | --- |
   | Contents | Read and write | Push update branches and commits |
   | Pull requests | Read and write | Open, update, and close pull requests |
   | Issues | Read and write | Maintain the Dependency Dashboard issue |
   | Workflows | Read and write | Allow pushes to branches that touch `.github/workflows/` |
   | Metadata | Read-only | Required by GitHub; selected automatically |

   Leave every other permission at *No access*.
6. Generate the token and copy it.
7. In the repository, open **Settings > Secrets and variables > Actions >
   New repository secret**, name it `RENOVATE_TOKEN`, and paste the token.

Reference: [Renovate GitHub Action token docs](https://github.com/renovatebot/github-action#token)
and [GitHub fine-grained token permissions](https://docs.github.com/en/rest/authentication/permissions-required-for-fine-grained-personal-access-tokens).

## Running it

- Automatically: every Monday at 04:00 UTC.
- Manually: **Actions > renovate > Run workflow**, or
  `gh workflow run renovate.yml`.
- From the Dependency Dashboard: ticking any checkbox edits the issue, which
  starts the workflow.

Review a Renovate pull request like any other tool upgrade: check the
release notes and let the `ci` workflow (pre-commit and the bootstrap test)
pass before merging.

## Dependency Dashboard

Renovate keeps one open issue titled **Dependency Dashboard** (label
`dependencies`) with the state of every tool in `.config/mise/config.toml`.
See the [Renovate dashboard docs](https://docs.renovatebot.com/key-concepts/dashboard/).

| Section | Meaning | Checkbox |
| --- | --- | --- |
| Pending Approval | Major upgrades; they never get a PR on their own | Creates the PR |
| Rate-Limited | Updates held back by the 10 open PRs limit | Creates the PR now |
| Open | Renovate PRs currently open | Rebases or retries that PR |
| Ignored or Blocked | Updates whose PR you closed without merging | Recreates the PR |
| Detected dependencies | Every tool Renovate found, with its current version | None |
| Vulnerabilities | Known OSV advisories for the pinned versions | None |

Ticking a box only records the request; the workflow run it triggers does
the work, and Renovate unticks the box when it rewrites the issue. The
workflow ignores edits to any other issue and dashboard edits with no ticked
box, so Renovate's own rewrites do not start new runs.

Closing a Renovate PR without merging tells Renovate to skip that version;
it moves to "Ignored or Blocked" until you tick it again.
