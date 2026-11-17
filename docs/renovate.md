# Renovate

[Renovate](https://docs.renovatebot.com) keeps the tool versions pinned in
`.config/mise/config.toml` up to date. It runs as a GitHub Actions workflow
and opens one pull request per tool update.

| File | Purpose |
| --- | --- |
| `.github/workflows/renovate.yml` | Runs Renovate every Monday at 04:00 UTC, or on demand |
| `.github/renovate.json` | Renovate config: only the `mise` manager, only `.config/mise/config.toml` |

Pull requests use `chore(mise): ...` commit messages, so merging them never
creates a new version tag (see "Continuous integration" in
[AGENTS.md](../AGENTS.md#continuous-integration)). Tools that Renovate cannot
resolve are skipped, not reported as errors.

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

Review a Renovate pull request like any other tool upgrade: check the
release notes and let the `ci` workflow (pre-commit and the bootstrap test)
pass before merging.
