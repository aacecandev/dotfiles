# dotfiles

Personal dotfiles driven entirely by [mise](https://mise.jdx.dev). A single
`mise bootstrap` turns a clean machine into a fully configured environment:
system packages, pinned CLI tools, shell, prompt, editors, and fonts.

## What it sets up

- **System packages** (apt): `build-essential`, `curl`, `fontconfig`, `git`,
  `unzip`, `zsh`, and TLS roots.
- **Pinned tools** (mise `[tools]`): Neovim, Vim, Starship, Node (which
  provides `npm` and `npx`), Go, and k9s (built from source by mise's `go:`
  backend). Every tool is pinned to an exact version for reproducibility.
- **Shell**: `zsh` with Starship as the prompt (Catppuccin Mocha).
- **Editors**: Vim with vim-plug (plugins installed headlessly) and a LazyVim
  based Neovim config.
- **Git**: shared settings, aliases, delta integration, and a global gitignore.
  The config is rendered from a template, so private values stay out of the
  repo (see [Private git settings](#private-git-settings)).
- **Fonts**: Nerd Fonts (Hack, JetBrainsMono, FiraCode).

All of the above is declared in `mise.toml` (bootstrap) and
`.config/mise/config.toml` (tools), and deployed as symlinks into `$HOME`.
The one exception is `~/.config/git/config`, which mise renders as a regular
file.

## Usage

On a clean machine, clone the repo, add your private settings, and run the
installer:

```sh
git clone https://github.com/aacecandev/dotfiles.git ~/dotfiles
cd ~/dotfiles
cp mise.local.toml.example mise.local.toml   # set git_name and git_email
sh install.sh
```

What to prepare beforehand and where each file lives is in
[docs/private-settings.md](docs/private-settings.md#before-you-install).

`install.sh` installs mise, trusts the config, and runs `mise bootstrap`.
Symlinks point into `~/dotfiles`, so the checkout is the stable home for the
configuration.

### Remote bootstrap (no manual clone)

Alternatively, let mise clone and bootstrap the repo in one step. Starting from
a bare `ubuntu:26.04` container:

```sh
docker run -it ubuntu:26.04 bash

# inside the container:
apt update
apt install -y curl ca-certificates
curl -fsSL https://mise.run | sh
~/.local/bin/mise bootstrap --from https://github.com/aacecandev/dotfiles.git --yes
```

With `--from`, mise clones the repo to its own cache and runs the full
bootstrap from there.

### Private git settings

The repository holds no personal data. Set your git name and email in an
untracked `mise.local.toml` at the root of the checkout, or git refuses to
commit. Start from the commented template:

```sh
cp mise.local.toml.example mise.local.toml   # then fill in your values
mise trust mise.local.toml
mise dot apply ~/.config/git/config
```

For every variable, what happens when one is missing, and how to verify,
see [docs/private-settings.md](docs/private-settings.md).

## Testing

Run the end-to-end test suite (needs Docker and a `GITHUB_TOKEN` stored in
mise):

```sh
mise exec -- sh tests/run.sh
```

`GITHUB_TOKEN` is required: without it the GitHub API rate limit runs out
and `install` fails with `HTTP 403`. Store it age-encrypted in the untracked
`mise.local.toml` with
`mise set --age-encrypt --prompt --file mise.local.toml GITHUB_TOKEN`.
[docs/github-token.md](docs/github-token.md) is the step-by-step guide
(age key, token creation, and why not the tracked `mise.toml`). CI needs no
setup: the workflow passes the automatic `secrets.GITHUB_TOKEN`.

For a manual check on aarch64, `mise run test:arm64` registers QEMU emulation
and opens an interactive Termux shell with this checkout mounted read-only at
`~/dotfiles`. It runs privileged containers and is not part of CI.

It builds the image, runs `install.sh` twice in a fresh container (the second
run checks the bootstrap is idempotent), then runs `tests/checks.sh` inside it:
dotfile symlinks, tools on `PATH`, login shell, clean zsh startup, vim-plug,
and Nerd Fonts. Each run writes its logs to `logs/<UTC timestamp>/`
(`build.log`, `start.log`, `install.log`, `reinstall.log`, `checks.log`); any failure is
collected in `errors.log` there and the script exits non-zero. `logs/` is
git-ignored.

GitHub Actions (`.github/workflows/ci.yml`) runs `pre-commit run --all-files`
and `sh tests/run.sh` on every pull request and push to `main`, and uploads
`logs/` as the `test-logs` artifact. When both pass on `main`, it tags the
commit with the next [semantic version](https://semver.org) based on the
[Conventional Commits](https://www.conventionalcommits.org/) since the last
`v*` tag: a breaking change (`type!:` or `BREAKING CHANGE:`) bumps major,
`feat` bumps minor, and `fix` or `perf` bumps patch. Other commit types do not
create a tag.

To explore a bootstrapped container by hand:

```sh
docker build -t dotfiles .
docker run -d --name dots dotfiles
docker logs -f dots   # wait for bootstrap to finish
docker exec -it dots zsh -l
```

## Layout

| Path | Purpose |
| --- | --- |
| `mise.toml` | Bootstrap config: packages, dotfiles, private-value defaults, hooks |
| `.config/mise/config.toml` | Pinned tool versions |
| `.config/zsh/.zshrc` | Shell startup (mise activation + Starship) |
| `.config/sheldon/plugins.toml` | Zsh plugins (sheldon), pinned to release tags |
| `.config/starship/starship.toml` | Prompt theme |
| `.config/vim/.vimrc` | Vim config (vim-plug) |
| `.config/nvim/` | Neovim config (LazyVim) |
| `.config/git/config.tera` | Git config template (private values from `mise.local.toml`) |
| `.config/git/ignore` | Global gitignore (patterns ignored in every repo) |
| `install.sh` | Entry point that installs mise and runs bootstrap |
| `tests/` | End-to-end test runner (`run.sh`) and post-install checks (`checks.sh`) |
| `docs/` | Guides: private settings in `mise.local.toml`, `GITHUB_TOKEN` for the tests, Neovim shortcuts |
| `mise.local.toml.example` | Template to copy into the untracked `mise.local.toml` |
| `logs/` | Test run logs and `errors.log` (git-ignored) |
