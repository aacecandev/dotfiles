#!/usr/bin/env sh
# tests/checks.sh — Post-install assertions. Runs INSIDE the test container
# after install.sh (see tests/run.sh); never run it on the host.
# Prints one PASS/FAIL line per check and exits non-zero if any check fails.
set -u

cd "$(dirname "$0")/.." || exit 1

# `docker exec` without -t leaves TERM unset; a real terminal always sets it,
# and zsh-autocomplete reads terminfo keys (e.g. kcbt) during startup.
export TERM="${TERM:-xterm-256color}"

failures=0
pass() { printf 'PASS %s\n' "$1"; }
fail() {
    printf 'FAIL %s\n' "$1"
    failures=$((failures + 1))
}
# Run a command; on failure, show its output (first 20 lines) under the FAIL
# line so the cause is visible without re-running it.
check() {
    desc="$1"
    shift
    if out="$("$@" 2>&1)"; then
        pass "$desc"
    else
        fail "$desc"
        printf '%s\n' "$out" | head -n 20 | sed 's/^/    /'
    fi
}

# Every [dotfiles] entry (symlinks, templates, edits) must be applied. mise
# reads mise.toml itself, so this never drifts from the config.
check 'every [dotfiles] entry is applied' mise dot status --missing

# ~/.zshenv moves zsh startup into ZDOTDIR; login shells get mise shims there.
check 'zsh ZDOTDIR is ~/.config/zsh' zsh -c 'test "$ZDOTDIR" = "$HOME/.config/zsh"'
check '$ZDOTDIR/.zprofile has the mise shims block' \
    grep -qF 'eval "$(mise activate zsh --shims)"' "$HOME/.config/zsh/.zprofile"

# Every tool pinned in .config/mise/config.toml must be installed.
missing="$(mise ls --missing 2>&1)"
if [ -z "$missing" ]; then
    pass 'every pinned mise tool is installed'
else
    fail 'every pinned mise tool is installed'
    printf '%s\n' "$missing" | sed 's/^/    /'
fi

# A few tools must be on PATH in a login + interactive zsh, as the user sees
# it: this proves the shims and activation work; the check above covers the
# rest of the pinned tools.
for tool in mise starship sheldon nvim vim node; do
    check "tool on PATH: $tool" zsh -lic "command -v $tool"
done

# Commands from the apt packages in [bootstrap.packages].
for tool in zsh git curl unzip fc-cache trash gcc make; do
    check "apt package command: $tool" command -v "$tool"
done

login_shell="$(getent passwd "$(id -un)" | cut -d: -f7)"
check "login shell is /usr/bin/zsh (got: $login_shell)" test "$login_shell" = /usr/bin/zsh

# zsh startup must not write anything to stderr (errors, missing files, ...).
startup_err="$(zsh -lic exit 2>&1 >/dev/null)"
if [ -z "$startup_err" ]; then
    pass 'zsh login startup has no stderr output'
else
    fail "zsh login startup has no stderr output: $startup_err"
fi

# sheldon loads every zsh plugin in an interactive shell (and zsh survives it).
check 'zsh plugins load (autocomplete, autosuggestions, syntax-highlighting)' zsh -lic \
    '(( $+functions[.autocomplete__main] )) && (( $+functions[_zsh_autosuggest_start] )) && (( $+functions[_zsh_highlight] ))'

# zsh-autocomplete defers compinit to the first prompt, so `zsh -c` cannot
# see _comps; assert the plugin's only effect: its src/ directory is on fpath.
check 'zsh-completions on fpath' zsh -lic '(( ${fpath[(I)*zsh-completions/src]} ))'

check 'vim-plug installed' test -f "$HOME/.vim/autoload/plug.vim"
check 'vim loads ~/.vimrc headless' zsh -lic 'vim -E -s -u ~/.vimrc +qall'

# Neovim starts headless and installs the plugins pinned in lazy-lock.json.
check 'nvim restores plugins from lazy-lock.json' zsh -lic 'nvim --headless "+Lazy! restore" +qa'

# The pre-dotfiles hook backs up a real ~/.config/nvim before symlinking it.
# tests/container.sh seeds that directory with a marker file before install.
check 'pre-dotfiles hook backed up an existing ~/.config/nvim' \
    test -f "$HOME/.config/nvim.bak/pre-existing"
check 'nvim config dir is a symlink after the backup' test -L "$HOME/.config/nvim"

for font in Hack JetBrainsMono FiraCode; do
    check "Nerd Font installed: $font" sh -c "ls \"\$HOME/.local/share/fonts/$font\"*.ttf"
done

# Git config is rendered from a template (a regular file, not a symlink) and
# carries no private values unless the untracked mise.local.toml sets them.
gitcfg="$HOME/.config/git/config"
# Read config the way git itself does (system + both global files). Do not
# use `git config --global`: it reads only ~/.gitconfig once that file exists.
# $HOME is not a repository, so no local config interferes.
gitget() { git -C "$HOME" config --get "$1"; }
check 'git config rendered as a regular file' sh -c "[ -f '$gitcfg' ] && [ ! -L '$gitcfg' ]"
check 'git config parses' git config --file "$gitcfg" --list
check 'git refuses a guessed identity' test "$(gitget user.useConfigOnly)" = true
check 'git config renders no identity without private vars' sh -c \
    "! git config --file '$gitcfg' --get user.email && ! git config --file '$gitcfg' --get commit.gpgsign"
check 'the ~/.gitconfig file is a real local file' sh -c '[ -f "$HOME/.gitconfig" ] && [ ! -L "$HOME/.gitconfig" ]'
check 'git uses the default global ignore path' test -z "$(gitget core.excludesfile)"
gitrepo="$(mktemp -d)"
check 'git applies the global ignore' sh -c "git -C '$gitrepo' init -q && git -C '$gitrepo' check-ignore -q .claude/settings.local.json"
rm -rf "$gitrepo"
# HTTPS clones must keep working: no broken or forced SSH rewrite. --get-url
# only expands insteadOf rules and never contacts the remote.
check 'git leaves https://gitlab.com URLs unchanged' \
    test "$(git -C "$HOME" ls-remote --get-url https://gitlab.com/group/repo.git)" = https://gitlab.com/group/repo.git

# The [bootstrap.hooks.post-dotfiles] notice points users without a git
# identity to the guide. `mise dot apply` runs the same hook as bootstrap.
notice='Set git_name and git_email in mise.local.toml'
check 'post-dotfiles hook (via mise dot apply) notes a missing git identity' \
    sh -c "mise dot apply '$gitcfg' 2>&1 | grep -qF '$notice'"

# Private [vars] in mise.local.toml must reach the template, and every value
# must survive characters git config treats specially (; # " \). Render once
# with dummy values, assert each var, then remove them and render again.
# Never touch a real mise.local.toml: if one exists, refuse to run the probe.
if [ -e mise.local.toml ]; then
    fail 'private-vars probe: mise.local.toml already exists, refusing to overwrite it'
else
    trap 'rm -f mise.local.toml' EXIT
    trap 'exit 130' INT
    trap 'exit 143' TERM
    cat >mise.local.toml <<'EOF'
[vars]
git_name = "Probe O'Brien; #1 \"Q\" \\"
git_email = "probe@example.invalid"
git_signingkey = "~/.ssh/probe.pub"
git_credential_url = "https://git.example.invalid"
EOF
    mise trust -y mise.local.toml >/dev/null 2>&1
    apply_out="$(mise dot apply "$gitcfg" 2>&1)"
    apply_status=$?
    check 'git config renders with private vars' test "$apply_status" -eq 0
    check 'git config with special characters parses' git config --file "$gitcfg" --list
    check 'post-dotfiles hook stays quiet once the git identity is set' \
        sh -c '! printf "%s\n" "$1" | grep -qF "$2"' _ "$apply_out" "$notice"
    check 'git renders git_name verbatim (; # " \ survive)' \
        test "$(gitget user.name)" = "Probe O'Brien; #1 \"Q\" \\"
    check 'git renders git_email' test "$(gitget user.email)" = probe@example.invalid
    check 'git renders git_signingkey' \
        test "$(git -C "$HOME" config --type=path --get user.signingkey)" = "$HOME/.ssh/probe.pub"
    check 'git signs commits when git_signingkey is set' test "$(gitget commit.gpgsign)" = true
    check 'git renders git_credential_url' \
        test "$(gitget credential.https://git.example.invalid.helper)" = store
    rm -f mise.local.toml
    trap - EXIT
    check 'git config re-renders without private vars' mise dot apply "$gitcfg"
    check 'git config drops private values once vars are gone' \
        sh -c "! git config --file '$gitcfg' --get user.email && ! git config --file '$gitcfg' --get user.name"
fi

printf '%s check(s) failed\n' "$failures"
[ "$failures" -eq 0 ]
