# dotfiles

Personal dotfiles driven entirely by [mise](https://mise.jdx.dev). A single
`mise bootstrap` turns a clean machine into a fully configured environment:
system packages, pinned CLI tools, shell, prompt, editors, and fonts.

## What it sets up

- **System packages** (apt): `build-essential`, `curl`, `fontconfig`, `git`,
  `unzip`, `zsh`, and TLS roots.
- **Pinned tools** (mise `[tools]`): Neovim, Vim, Starship, and Node (which
  provides `npm` and `npx`). Every tool is pinned to an exact version for
  reproducibility.
- **Shell**: `zsh` with Starship as the prompt (Catppuccin Mocha).
- **Editors**: Vim with vim-plug (plugins installed headlessly) and a LazyVim
  based Neovim config.
- **Fonts**: Nerd Fonts (Hack, JetBrainsMono, FiraCode).

All of the above is declared in `mise.toml` (bootstrap) and
`.config/mise/config.toml` (tools), and deployed as symlinks into `$HOME`.

## Usage

On a clean machine, clone the repo and run the installer:

```sh
git clone https://github.com/aacecandev/dotfiles.git ~/dotfiles
cd ~/dotfiles
sh install.sh
```

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

## Testing

Run the end-to-end test suite (needs Docker):

```sh
sh tests/run.sh
```

It builds the image, runs `install.sh` twice in a fresh container (the second
run checks the bootstrap is idempotent), then runs `tests/checks.sh` inside it:
dotfile symlinks, tools on `PATH`, login shell, clean zsh startup, vim-plug,
and Nerd Fonts. Each run writes its logs to `logs/<UTC timestamp>/`
(`build.log`, `install.log`, `reinstall.log`, `checks.log`); any failure is
collected in `errors.log` there and the script exits non-zero. `logs/` is
git-ignored.

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
| `mise.toml` | Bootstrap config: packages, dotfile symlinks, hooks |
| `.config/mise/config.toml` | Pinned tool versions |
| `.config/zsh/.zshrc` | Shell startup (mise activation + Starship) |
| `.config/starship/starship.toml` | Prompt theme |
| `.config/vim/.vimrc` | Vim config (vim-plug) |
| `.config/nvim/` | Neovim config (LazyVim) |
| `install.sh` | Entry point that installs mise and runs bootstrap |
| `tests/` | End-to-end test runner (`run.sh`) and post-install checks (`checks.sh`) |
| `logs/` | Test run logs and `errors.log` (git-ignored) |
