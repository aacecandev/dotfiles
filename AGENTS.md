# AGENTS.md

Instructions for AI coding agents working in this repository. `README.md` is
for humans; this file is for agents. Human contributors should follow it too.

**Precedence:** an explicit instruction from the repository owner in the
current session overrides this file. If an `AGENTS.md` is ever added in a
subdirectory, the one closest to the file being edited wins for that subtree.

## Commands

Run these from the repository root.

```sh
# Static gates (lint, format, secret scan) - full suite, run before every commit
pre-commit run --all-files

# Static gates on specific files only - fast loop while iterating
pre-commit run --files <path> [<path> ...]

# One gate only, e.g. shellcheck / markdownlint-cli2 / yamllint / gitleaks-docker
pre-commit run shellcheck --files install.sh

# End-to-end test in a disposable container (never on the host):
# buildx build, then one `docker run -it --rm` with live output: install,
# reinstall + state diff (idempotence), then tests/checks.sh.
# Logs land in logs/<UTC timestamp>/; failures are collected in errors.log.
# Requires GITHUB_TOKEN age-encrypted in mise.local.toml; see docs/github-token.md.
mise exec -- sh tests/run.sh

# Interactive aarch64 Termux shell under QEMU (manual, privileged)
mise run test:arm64

# Inspect a bootstrapped container interactively
docker run -d --name dots dotfiles-test && docker logs -f dots
docker exec -it dots zsh -l
docker rm -f dots

# Format Neovim Lua config (uses .config/nvim/stylua.toml)
stylua .config/nvim
```

A test run passes only when `tests/run.sh` exits with `0`; on failure, read
`errors.log` in the newest `logs/` directory. Every `[dotfiles]` entry is
checked with `mise dot status --missing` and every pinned tool with
`mise ls --missing`, so neither needs its own assertion; what a file or tool
does (templates rendering, plugins loading) still needs explicit checks. When
you add an apt package or other installed artifact, add a matching assertion to `tests/checks.sh` in
the same change.

## What this repository is

Personal dotfiles driven entirely by [mise](https://mise.jdx.dev). A single
`mise bootstrap` turns a clean Ubuntu machine into a configured environment:
apt packages, pinned CLI tools, zsh, Starship, Vim, Neovim (LazyVim), and
Nerd Fonts. Every managed file is deployed into `$HOME` as a **symlink** back
into this checkout. The exception is a file that needs machine-private
values: it is rendered from a template into a regular file (today only
`~/.config/git/config`).

**`main` is production.** Machines bootstrap straight from `main`, either
from a clone or with `mise bootstrap --from <repo-url>`. There is no release
process or staging branch, so anything merged to `main` reaches the next
machine that bootstraps, and any machine with a checkout changes as soon as it
pulls.

## Architecture

| Path | Owns |
| --- | --- |
| `mise.toml` | Bootstrap: `[dotfiles]` entries, `[vars]` defaults, `[bootstrap.packages]`, hooks, login shell |
| `.config/mise/config.toml` | Pinned tool versions (`[tools]`) |
| `.config/zsh/` | Shell startup (`.zshenv`, `.zprofile`, `.zshrc`), completion, keybindings and functions (`*.zsh`), deployed to `~/.config/zsh` (`ZDOTDIR`) |
| `.config/sheldon/plugins.toml` | Zsh plugins (sheldon), pinned to release tags |
| `.config/starship/starship.toml` | Prompt theme |
| `.config/vim/.vimrc` | Vim config (vim-plug) |
| `.config/nvim/` | Neovim config (LazyVim), plugin lock in `lazy-lock.json` |
| `.config/git/config.tera` | Git config template rendered to `~/.config/git/config` |
| `.config/git/ignore` | Global gitignore, symlinked to `~/.config/git/ignore` |
| `install.sh` | POSIX entry point: prerequisites, mise, `mise bootstrap` |
| `Dockerfile` | Disposable Ubuntu 26.04 image (pinned by digest) used to test the bootstrap |
| `tests/` | `run.sh` (host-side runner), `container.sh` (in-container steps and idempotence diff), `checks.sh` (in-container assertions) |
| `docs/` | Guides: `private-settings.md` (required `mise.local.toml` vars), `github-token.md` (test setup), `renovate.md` (version updates, GitHub App setup), `neovim-shortcuts.md` (custom Neovim keymaps) |
| `mise.local.toml` | Git-ignored, machine-local: private `[vars]` and the encrypted `GITHUB_TOKEN`. Never commit it; only the owner writes it |
| `mise.local.toml.example` | Tracked, commented template for `mise.local.toml`; lists every private var with a placeholder |
| `logs/` | Test run logs and `errors.log`; git-ignored, never commit its contents |
| `.pre-commit-config.yaml` | Lint, format, and secret-scanning gates |

Each kind of change belongs in one place:

- **OS packages** go only in `[bootstrap.packages]` in `mise.toml`.
  `install.sh` and the `Dockerfile` install only what is needed to download
  mise (curl, CA roots, sudo). Do not add packages there.
- **Developer tools** go only in `.config/mise/config.toml`.
- **New config files** go under `.config/<tool>/` and are deployed by adding
  a `[dotfiles]` entry in `mise.toml`. Do not drop new files at the repository
  root.
- **Shell functions** go in `.config/zsh/functions.zsh` (fzf helpers in
  `functions_fzf.zsh`), not inline in `.zshrc`. A new `.config/zsh/*.zsh`
  file needs its own `[dotfiles]` symlink entry in `mise.toml`.
- **Post-install steps** (downloads, plugin installs) go in
  `[bootstrap.hooks.*]` in `mise.toml`, not in `install.sh`.
- **Machine-private values** (name, email, signing keys, employer hosts) go
  in `[vars]` of the git-ignored `mise.local.toml`. Render them from a
  `mode = "template"` source (see `.config/git/config.tera`). Never hardcode
  them in tracked files. The full list of variables and what each one
  renders is in [docs/private-settings.md](docs/private-settings.md).
  **Every time a private variable is added, renamed, removed, or changes what
  it renders, update `docs/private-settings.md` and `mise.local.toml.example`
  in the same commit** (the guide's Variables table, plus "What happens
  without them" if the effect of a missing value changes). Users read the
  guide and copy the example to fill in `mise.local.toml`. A variable missing
  from either is a bug, even if the tests pass. To add a variable, do all of
  the following in the same change:
  - declare it with an empty default under `[vars]` in `mise.toml`;
  - render it under `{% if vars.<name> %}` so an empty value renders nothing;
  - add its row to the Variables table in `docs/private-settings.md`;
  - add it with a placeholder value and a one-line comment to
    `mise.local.toml.example` (commented out if optional);
  - assert it in `tests/checks.sh` with a dummy value, as the existing
    `git_*` checks do.

Follow the existing files as reference: `mise.toml` shows how dotfiles,
packages, and hooks are declared, and `.config/zsh/.zshrc` shows how optional
tools are guarded.

## Code style

| Language | Files | Rules |
| --- | --- | --- |
| POSIX `sh` | `install.sh` | `set -eu`; no bash/zsh syntax; must pass ShellCheck |
| zsh | `.config/zsh/*` | zsh features allowed; ShellCheck skips `.zshrc` and `.config/zsh/*.zsh`, so review by hand; `.zshenv` and `.zprofile` stay bash-compatible (`# shellcheck shell=bash`) |
| Lua | `.config/nvim/**` | StyLua: 2 spaces, 120 columns (`.config/nvim/stylua.toml`) |
| TOML | `mise.toml`, `.config/mise/config.toml` | Comment every non-obvious entry with its purpose and a docs link |
| YAML | `*.yaml`, `*.yml` | yamllint, relaxed profile, 500-column limit |
| Markdown | `*.md` | markdownlint (`.markdownlint-cli2.jsonc`); links must resolve |

All files use LF line endings, end with a single newline, and have no trailing
whitespace (enforced by pre-commit). Executable scripts need a shebang, and
scripts with a shebang must be executable.

## Hard rules

Each rule gives the alternative to use instead.

1. **No secrets, ever.** Never commit tokens, API keys, passwords, private
   keys, SSH or GPG material, auth files, shell history, hostnames, or
   machine-specific identifiers. This repository is public.
   *Instead:* read secrets at runtime from environment variables or a
   secrets manager, and keep machine-local overrides in untracked files
   that the shell sources only if they exist. For values a deployed config
   needs, use `[vars]` in `mise.local.toml` (see
   [docs/private-settings.md](docs/private-settings.md)).
2. **Never run the bootstrap on the host.** `install.sh` and
   `mise bootstrap` install packages with `sudo`, change the login shell,
   move existing configs to `*.bak`, and overwrite files in `$HOME`.
   *Instead:* use the Docker commands in [Commands](#commands).
3. **Never edit the real `$HOME` from this repo.** Do not create, delete, or
   rewrite files under `~` directly.
   *Instead:* change the source file here and let `mise bootstrap` deploy it.
4. **Keep the mise activation markers intact.** Never edit the lines between
   `# >>> mise:activate >>>` and `# <<< mise:activate <<<` in
   `.config/zsh/.zshrc`.
   *Instead:* add your lines above or below the block.
5. **Pin everything.** Tools, hook downloads (vim-plug, Nerd Fonts), and
   pre-commit `rev:` values use exact versions. Never use `latest`, a branch
   name, or an unpinned URL. The only exception is apt packages, which
   follow the distro.
   *Instead:* look up the current stable release and pin that exact version.
6. **Hooks must be idempotent and non-destructive.** Running
   `mise bootstrap` twice must leave the system unchanged and never destroy
   user data.
   *Instead:* guard every destructive step, as the `pre-dotfiles` hook does
   ("only if it exists and is not already a symlink"), and back up instead of
   deleting.
7. **Do not weaken the gates.** Do not remove pre-commit hooks, add broad
   `exclude:` patterns, disable lint rules, or commit with `--no-verify`.
   *Instead:* fix the cause. If a rule is truly wrong for one file, ask the
   owner and add the narrowest possible exclusion with a comment saying why.
8. **Do not leave a broken `[dotfiles]` entry.** Every `source` in
   `mise.toml` must exist in the repository. A missing source aborts the
   whole bootstrap with `mise ERROR files: sources do not exist`.
   *Instead:* when you move or rename a file, update its `source` in the
   same change and re-run the bootstrap test.

## Changing dotfiles safely

- If the `Dockerfile` must see a new top-level path, add it to the `COPY`
  lines too. Everything under `.config/` is already copied.
- zsh reads its startup files from `ZDOTDIR` (`~/.config/zsh`, set in
  `.config/zsh/.zshenv`), never from `~`: deploy new zsh files there and
  refer to them as `${ZDOTDIR}/<file>`. mise's
  `[bootstrap.mise_shell_activate]` is off because it ignores `ZDOTDIR`;
  `.zprofile` and `.zshrc` carry the activation lines themselves.
- Startup files must not fail when an optional tool is missing. Guard calls
  with `(type <tool> &>/dev/null) &&` or `[ -f <file> ] && source <file>`.
- Keep shell startup fast. `.zshrc` prints its load time. Do not add network
  access or slow `eval "$(<tool> init)"` calls without measuring the
  difference in the container.
- Keep `.config/nvim/lazy-lock.json` in sync with plugin changes. Do not bump
  plugins you were not asked to bump.
- **Every time a Neovim plugin or keymap is added, removed, or changed,
  update [docs/neovim-shortcuts.md](docs/neovim-shortcuts.md) in the same
  commit.** A keymap missing from that guide is a bug, even if the tests
  pass.
- Keep changes cross-platform where it is cheap.
- A `mode = "template"` target is a regular file that every apply
  overwrites. Edit the `.tera` source, never the target, and keep plain
  `mode = "symlink"` for any file that holds no private values. Template
  sources must not contain literal `{{`, `{%`, or `{#` outside Tera tags.
- To read git config the way git does, query without a scope from outside a
  repository (`git -C "$HOME" config --get <key>`). `git config --global`
  reads only `~/.gitconfig` once that file exists, so it misses the rendered
  `~/.config/git/config`.

## Security

- `gitleaks`, `detect-private-key`, and `check-added-large-files` run on
  every commit and push. A finding blocks the commit. Never silence it.
- Before adding a package, tool, plugin, or download, check that it comes
  from the official upstream (the GitHub release or the distro archive), that
  it has no known unpatched CVEs, and that its license allows use in a public
  repository.
- Fetch over HTTPS from pinned release URLs only. Never pipe a script into a
  shell inside hooks, except for the documented `mise.run` installer in
  `install.sh`.
- Do not widen `sudo` usage. Only mise's apt installer and `install.sh`'s
  prerequisite step run as root.

## Continuous integration

`pre-commit` runs locally at both the `pre-commit` and `pre-push` stages (see
`default_stages`). The Docker test runs as the local `bootstrap-test` hook at
the `pre-commit` stage only, for commits that touch `mise.toml`, `install.sh`,
the `Dockerfile`, `.config/` or `tests/`: such a commit needs a passing image
build and `tests/checks.sh`. No CI job runs the gates; never bypass them.

GitHub Actions (`.github/workflows/ci.yml`) runs no tests. On every push to
`main` it tags the commit with the next semantic version derived from the
Conventional Commits since the last `v*` tag (breaking change: major, `feat`:
minor, `fix`/`perf`: patch, anything else: no tag). Commit types therefore
decide versions; pick them deliberately. Actions are pinned to commit SHAs
with the release tag in a trailing comment (`uses: owner/action@<sha> # vX.Y.Z`),
which Renovate updates together. Keep it that way.

Renovate (`.github/workflows/renovate.yml`, config in `.github/renovate.json`)
runs weekly and opens `chore(mise):`, `chore(pre-commit):`,
`chore(sheldon):` and `chore(actions):` PRs that bump the versions pinned in
`.config/mise/config.toml`, `.pre-commit-config.yaml`,
`.config/sheldon/plugins.toml` and `.github/workflows/`. It authenticates as a private GitHub App
(repository variable `RENOVATE_APP_CLIENT_ID`, secret
`RENOVATE_APP_PRIVATE_KEY`); the App setup and
permissions are in [docs/renovate.md](docs/renovate.md). Keep each sheldon
plugin's `tag =` line right after its `github =` line, or Renovate will not
see it. Review and merge them like any other tool upgrade.

## Commits, review, and delivery

- Use [Conventional Commits](https://www.conventionalcommits.org/)
  (`feat:`, `fix:`, `chore:`, `docs:`, ...). Keep the subject line at 72
  characters or fewer.
- Commit with `git commit -s` so every commit carries a `Signed-off-by`
  trailer.
- Never mention AI tools in commits: no AI attribution, no
  `Co-Authored-By` trailers for AI tools, and no tool or model names in the
  subject or body. The same applies to pull request titles and
  descriptions.
- Agent-made changes meet the same bar as any other change: small diffs, one
  logical change per commit, and proof that the gates and the bootstrap test
  passed.
- Update `README.md` and this file in the same commit whenever behavior,
  layout, or commands change. Update `docs/private-settings.md` and
  `mise.local.toml.example` in the same commit whenever a private `[vars]`
  entry changes (see
  [Architecture](#architecture)).
- Work on a branch, never directly on `main`. Pushing, opening pull requests,
  and merging are the owner's decisions.
- Preserve uncommitted work you did not make. Never use `git reset --hard`,
  `git clean`, force-push, or history rewrites without explicit approval.

## Human approval required

Stop and get explicit approval from the owner before you:

- add, remove, or upgrade any apt package, mise tool, Neovim or Vim plugin,
  pre-commit hook, or downloaded asset, and confirm its license;
- change `install.sh`, the `Dockerfile`, `.pre-commit-config.yaml`, or any
  `[bootstrap.hooks.*]` entry (these are the delivery pipeline);
- change the login shell, `[bootstrap.user]`, or anything that runs with
  `sudo`;
- delete, move, or overwrite user data in a hook;
- change a file's deploy mode or target path in `[dotfiles]`;
- add or change license, copyright, or other legal text;
- make any change you cannot verify in the Docker image.

## Keeping this file current

This file is living documentation. When you find it wrong or incomplete, fix
it in the same change. When the owner gives an agent the same instruction
twice, add it here. Prefer commands over prose, and pair every restriction
with the alternative to use.
