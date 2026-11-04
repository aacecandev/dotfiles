#!/usr/bin/env sh
# tests/checks.sh — Post-install assertions. Runs INSIDE the test container
# after install.sh (see tests/run.sh); never run it on the host.
# Prints one PASS/FAIL line per check and exits non-zero if any check fails.
set -u

cd "$(dirname "$0")/.." || exit 1

failures=0
pass() { printf 'PASS %s\n' "$1"; }
fail() {
    printf 'FAIL %s\n' "$1"
    failures=$((failures + 1))
}
check() {
    desc="$1"
    shift
    if "$@" >/dev/null 2>&1; then pass "$desc"; else fail "$desc"; fi
}

# Every [dotfiles] symlink entry in mise.toml must exist in $HOME and resolve
# to its source in the repo. Entries are read from mise.toml so this list
# never drifts from the config.
entries="$(grep -E '^"~/[^"]+" = \{ *source *= *"' mise.toml |
    sed -E 's/^"~\/([^"]+)".*source *= *"([^"]+)".*/\1 \2/')"
if [ -z "$entries" ]; then
    fail 'mise.toml declares [dotfiles] symlinks'
fi
while read -r target source; do
    [ -n "$target" ] || continue
    link="$HOME/$target"
    if [ -L "$link" ] && [ "$(readlink -f "$link")" = "$(readlink -f "$source")" ]; then
        pass "symlink ~/$target -> $source"
    else
        fail "symlink ~/$target -> $source"
    fi
done <<EOF
$entries
EOF

# Tools must be on PATH in a login + interactive zsh, as the user sees it.
for tool in mise zsh git curl unzip fc-cache starship nvim vim node npm go k9s; do
    check "tool on PATH: $tool" zsh -lic "command -v $tool"
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

check 'vim-plug installed' test -f "$HOME/.vim/autoload/plug.vim"
check 'vim loads ~/.vimrc headless' zsh -lic 'vim -E -s -u ~/.vimrc +qall'

for font in Hack JetBrainsMono FiraCode; do
    check "Nerd Font installed: $font" sh -c "ls \"\$HOME/.local/share/fonts/$font\"*.ttf"
done

printf '%s check(s) failed\n' "$failures"
[ "$failures" -eq 0 ]
