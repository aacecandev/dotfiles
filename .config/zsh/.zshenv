# Environment for every zsh (login, interactive, scripts). Managed by mise
# dotfiles, deployed to ~/.zshenv. Sourced, not executed: no shebang.
# Keep it bash-compatible so ShellCheck (no zsh support) can lint it.
# shellcheck shell=bash

# Export core paths before plugins: zsh-autocomplete runs compinit during plugin load.
export XDG_CACHE_HOME="${HOME}/.cache"
export XDG_CONFIG_HOME="${HOME}/.config"
export XDG_DATA_HOME="${HOME}/.local/share"

# Preferred editor for local and remote sessions
export EDITOR='nvim'
export VISUAL="${EDITOR}"

# zsh
export ZDOTDIR="$XDG_CONFIG_HOME/zsh"
export HISTFILE="$ZDOTDIR/.zhistory"    # History filepath
export HISTSIZE=10000                   # Maximum events for internal history
export SAVEHIST=10000                   # Maximum events in history file

# other software
export VIMCONFIG="$XDG_CONFIG_HOME/nvim"
export BUILDKIT_COLORS="run=light-blue:error=light-red:cancel=light-magenta:warning=light-yellow"
export DOTNET_CLI_TELEMETRY_OPTOUT=1

export ZSH_HIGHLIGHT_MAXLENGTH=300

# Man pages
export MANPAGER='nvim +Man!'
export MANPATH="/usr/local/man:${MANPATH}"

# You may need to manually set your language environment
export LANG=en_US.UTF-8

# less tweaks
export LESS='-asrRix8'
export LESSCHARSET='utf-8'

# color manpage
export LESS_TERMCAP_mb=$'\E[01;31m'       # begin blinking
export LESS_TERMCAP_md=$'\E[01;38;5;208m' # begin bold
export LESS_TERMCAP_me=$'\E[0m'           # end mode
export LESS_TERMCAP_se=$'\E[0m'           # end standout-mode
export LESS_TERMCAP_so=$'\E[38;07;246m'   # begin standout-mode - info box
export LESS_TERMCAP_ue=$'\E[0m'           # end underline
export LESS_TERMCAP_us=$'\E[04;38;5;111m' # begin underline

# Prepend user toolchains so they take precedence over system binaries.
# Build the prefix preserving the order below, then prepend it once.
PATH_DIRS=(
    "${HOME}/.atuin/bin"
    "${HOME}/.cargo/bin"
    "${HOME}/.docker/bin"
    "${HOME}/.krew/bin"
    "${HOME}/.local/bin"
    "${HOME}/.local/share/pnpm/bin"
    "${HOME}/.opencode/bin"
    "${HOME}/bin"
    "${HOME}/go/bin"
)
PATH_PREFIX=""
for i in "${PATH_DIRS[@]}"; do
    [ -d "${i}" ] && PATH_PREFIX="${PATH_PREFIX:+${PATH_PREFIX}:}${i}"
done
[ -n "${PATH_PREFIX}" ] && PATH="${PATH_PREFIX}:${PATH}"
export PATH="${PATH}"
unset PATH_DIRS PATH_PREFIX

# pnpm
[ -d "${HOME}/.local/share/pnpm" ] && export PNPM_HOME="${HOME}/.local/share/pnpm"

unset COLORTERM
