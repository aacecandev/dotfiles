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
# build, install, reinstall (idempotence), then tests/checks.sh.
# Logs land in logs/<UTC timestamp>/; failures are collected in errors.log.
sh tests/run.sh

# Inspect a bootstrapped container interactively
docker run -d --name dots dotfiles-test && docker logs -f dots
docker exec -it dots zsh -l
docker rm -f dots

# Format Neovim Lua config (uses .config/nvim/stylua.toml)
stylua .config/nvim
```

A test run passes only when `tests/run.sh` exits with `0`; on failure, read
`errors.log` in the newest `logs/` directory. `[dotfiles]` symlinks are
checked automatically from `mise.toml`. When you add a tool, package, or
other installed artifact, add a matching assertion to `tests/checks.sh` in
the same change.

## What this repository is

Personal dotfiles driven entirely by [mise](https://mise.jdx.dev). A single
`mise bootstrap` turns a clean Ubuntu machine into a configured environment:
apt packages, pinned CLI tools, zsh, Starship, Vim, Neovim (LazyVim), and
Nerd Fonts. Every managed file is deployed into `$HOME` as a **symlink** back
into this checkout.

**`main` is production.** Machines bootstrap straight from `main`, either
from a clone or with `mise bootstrap --from <repo-url>`. There is no release
process or staging branch, so anything merged to `main` reaches the next
machine that bootstraps, and any machine with a checkout changes as soon as it
pulls.

## Architecture

| Path | Owns |
| --- | --- |
| `mise.toml` | Bootstrap: `[dotfiles]` symlinks, `[bootstrap.packages]`, hooks, login shell |
| `.config/mise/config.toml` | Pinned tool versions (`[tools]`) |
| `.config/zsh/` | Shell startup (`.zshrc`) and custom functions (`.functions_custom`) |
| `.config/starship/starship.toml` | Prompt theme |
| `.config/vim/.vimrc` | Vim config (vim-plug) |
| `.config/nvim/` | Neovim config (LazyVim), plugin lock in `lazy-lock.json` |
| `install.sh` | POSIX entry point: prerequisites, mise, `mise bootstrap` |
| `Dockerfile` | Disposable Ubuntu 26.04 image used to test the bootstrap |
| `tests/` | `run.sh` (host-side runner) and `checks.sh` (in-container assertions) |
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
- **Shell functions** go in `.config/zsh/.functions_custom`, not inline in
  `.zshrc`.
- **Post-install steps** (downloads, plugin installs) go in
  `[bootstrap.hooks.*]` in `mise.toml`, not in `install.sh`.

Follow the existing files as reference: `mise.toml` shows how dotfiles,
packages, and hooks are declared, and `.config/zsh/.zshrc` shows how optional
tools are guarded.

## Code style

| Language | Files | Rules |
| --- | --- | --- |
| POSIX `sh` | `install.sh` | `set -eu`; no bash/zsh syntax; must pass ShellCheck |
| zsh | `.config/zsh/*` | zsh features allowed; ShellCheck skips `.zshrc`, so review by hand |
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
   that the shell sources only if they exist.
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
- Startup files must not fail when an optional tool is missing. Guard calls
  with `(type <tool> &>/dev/null) &&` or `[ -f <file> ] && source <file>`.
- Keep shell startup fast. `.zshrc` prints its load time. Do not add network
  access or slow `eval "$(<tool> init)"` calls without measuring the
  difference in the container.
- Keep `.config/nvim/lazy-lock.json` in sync with plugin changes. Do not bump
  plugins you were not asked to bump.
- Keep changes cross-platform where it is cheap. `.zshrc` already handles
  macOS (`gdate`), so do not remove that.

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
`default_stages`), and the Docker test is the integration check. Run both
before you hand off work.

GitHub Actions (`.github/workflows/ci.yml`) runs the same two commands from
[Commands](#commands) on every pull request and push to `main`. On `main`, a
green run tags the commit with the next semantic version derived from the
Conventional Commits since the last `v*` tag (breaking change: major, `feat`:
minor, `fix`/`perf`: patch, anything else: no tag). Commit types therefore
decide versions; pick them deliberately. Actions are pinned to commit SHAs
with the release tag in a comment. Keep it that way.

## Commits, review, and delivery

- Use [Conventional Commits](https://www.conventionalcommits.org/)
  (`feat:`, `fix:`, `chore:`, `docs:`, ...). Keep the subject line at 72
  characters or fewer.
- Do not add AI attribution or `Co-Authored-By` trailers.
- Agent-made changes meet the same bar as any other change: small diffs, one
  logical change per commit, and proof that the gates and the bootstrap test
  passed.
- Update `README.md` and this file in the same commit whenever behavior,
  layout, or commands change.
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
