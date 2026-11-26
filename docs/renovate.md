# Renovate

[Renovate](https://docs.renovatebot.com) keeps the pinned versions up to
date. It runs as a GitHub Actions workflow, authenticated as a private GitHub
App, and opens one pull request per update.

| Pinned in | Renovate manager | Commit prefix |
| --- | --- | --- |
| `.config/mise/config.toml` (tools) | [`mise`](https://docs.renovatebot.com/modules/manager/mise/) | `chore(mise):` |
| `.pre-commit-config.yaml` (hook `rev:`) | [`pre-commit`](https://docs.renovatebot.com/modules/manager/pre-commit/), enabled explicitly (off by default) | `chore(pre-commit):` |
| `.config/sheldon/plugins.toml` (plugin `tag`) | [custom regex](https://docs.renovatebot.com/modules/manager/regex/) on `github = "owner/repo"` + `tag = "..."`, GitHub tags | `chore(sheldon):` |

| File | Purpose |
| --- | --- |
| `.github/workflows/renovate.yml` | Runs Renovate every Monday at 04:00 UTC, on demand, and when a Dependency Dashboard checkbox is ticked |
| `.github/renovate.json` | Renovate config: the three managers above, nothing else |

A sheldon plugin is only detected when its `tag =` line comes right after its
`github =` line, as in the existing entries.

Pull requests use `chore(...)` commit messages, so merging them never
creates a new version tag (see "Continuous integration" in
[AGENTS.md](../AGENTS.md#continuous-integration)). Tools that Renovate cannot
resolve are skipped and listed on the Dependency Dashboard.

There is no hourly PR limit (`prHourlyLimit: 0`) and no Renovate-side time
window: the workflow's cron decides when Renovate runs. At most 10 Renovate
pull requests are open at once (`prConcurrentLimit`); the rest wait on the
dashboard until one is merged or closed.

## GitHub App setup

The workflow authenticates as a private GitHub App. Each run exchanges the
App's private key for an installation token that expires after one hour,
scoped to this repository only, with
[`actions/create-github-app-token`](https://github.com/actions/create-github-app-token).
The automatic `GITHUB_TOKEN` is not an option: pull requests opened with it
do not trigger other workflows, so the `ci` checks would never run on
Renovate's pull requests.

1. Open GitHub **Settings > Developer settings > GitHub Apps > New GitHub
   App**, under the account that owns this repository.
2. **GitHub App name:** any unique name, for example `<owner>-renovate`. Its
   bot user (`<name>[bot]`) authors Renovate's commits.
3. **Homepage URL:** this repository's URL.
4. **Webhook:** untick *Active*. The workflow polls; it needs no webhook.
5. **Repository permissions:**

   | Permission | Access | Why |
   | --- | --- | --- |
   | Contents | Read and write | Push update branches and commits |
   | Pull requests | Read and write | Open, update, and close pull requests |
   | Issues | Read and write | Maintain the Dependency Dashboard issue |
   | Workflows | Read and write | Allow pushes to branches that touch `.github/workflows/` |
   | Metadata | Read-only | Required by GitHub; selected automatically |

   Leave every other permission at *No access*, and every account
   permission too.
6. **Where can this GitHub App be installed?** *Only on this account*.
7. Click **Create GitHub App**. On the App's page, copy the **Client ID**.
8. Under **Private keys**, click **Generate a private key**. A `.pem` file
   downloads.
9. In the left menu, **Install App** > **Install** on your account >
   *Only select repositories* > this repository.
10. In this repository, open **Settings > Secrets and variables > Actions**:
    - **Variables > New repository variable:** name
      `RENOVATE_APP_CLIENT_ID`, value the Client ID.
    - **Secrets > New repository secret:** name `RENOVATE_APP_PRIVATE_KEY`,
      value the whole contents of the `.pem` file, including the
      `BEGIN`/`END` lines.
11. Delete the downloaded `.pem` file, and delete the old `RENOVATE_TOKEN`
    secret and its fine-grained token: the workflow no longer reads them.

The private key does not expire. To rotate it, generate a new key, update
the secret, then delete the old key on the App's page.

Commits are created through the GitHub API (`platformCommit`) and authored
as the App's bot user, so GitHub shows them as Verified.

Reference: [Renovate GitHub App authentication](https://docs.renovatebot.com/modules/platform/github/#running-as-a-github-app)
and [registering a GitHub App](https://docs.github.com/en/apps/creating-github-apps/registering-a-github-app/registering-a-github-app).

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
`dependencies`) with the state of every dependency in the three files above.
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
