# Managed by mise dotfiles. Deployed to ~/.zshrc.
# Because [dotfiles] covers this path, mise does not inject its own
# activation block — this file carries it directly.

# load zsh profiler
# zmodload zsh/zprof

# get zsh load time - START
# prefer gnu-date
_zsh_start="$(date +%s%3N)"

# zsh
export HISTFILE=~/.zsh_history
export HISTSIZE=13000
export SAVEHIST=10000
setopt APPEND_HISTORY          # append to history file
setopt EXTENDED_HISTORY        # Write the history file in the ':start:elapsed;command' format.
setopt HIST_EXPIRE_DUPS_FIRST  # Expire a duplicate event first when trimming history.
setopt HIST_FIND_NO_DUPS       # Do not display a previously found event.
setopt HIST_IGNORE_ALL_DUPS    # Delete an old recorded event if a new event is a duplicate.
setopt HIST_IGNORE_SPACE       # Do not record an event starting with a space.
setopt HIST_NO_FUNCTIONS       # don't store function definitions
setopt HIST_NO_STORE           # Don't store history commands
setopt HIST_REDUCE_BLANKS      # remove unnecessary blanks
setopt HIST_SAVE_NO_DUPS       # Do not write a duplicate event to the history file.
setopt HIST_VERIFY             # Do not execute immediately upon history expansion.
setopt SHARE_HISTORY           # Share history between all sessions.
unsetopt menu_complete         # do not autoselect the first completion entry
unsetopt flowcontrol
setopt auto_menu # show completion menu on successive tab press
setopt complete_in_word
setopt always_to_end
export ZSH_HIGHLIGHT_MAXLENGTH=300

# zsh-autocomplete config (plugins are loaded by sheldon, see .config/sheldon/plugins.toml)
# Real-time type-ahead: ON. Tab: fzf ** triggers → fallback to autocomplete's complete-word.
zstyle ':autocomplete:*' min-input 1

# Low-cost completion display tweaks. Do not override zsh-autocomplete's matcher-list.
zstyle ':completion:*' squeeze-slashes true
zstyle ':completion:*:messages' format ' %F{purple} -- %d --%f'
zstyle ':completion:*:warnings' format ' %F{red}-- no matches found --%f'

# keybindings: word navigation with Ctrl+Left/Right
bindkey '^[[1;5D' backward-word
bindkey '^[[1;5C' forward-word

# Export core paths before plugins: zsh-autocomplete runs compinit during plugin load.
export XDG_CACHE_HOME="${HOME}/.cache"
export XDG_CONFIG_HOME="${HOME}/.config"
export XDG_DATA_HOME="${HOME}/.local/share"

FPATH_DIRS=(
    "${HOME}/.zsh/completions"
)
for i in "${FPATH_DIRS[@]}"; do
    [ -d "${i}" ] && FPATH+=":${i}"
done

# >>> mise:activate >>> managed by mise — do not edit between markers
eval "$(mise activate zsh)"
# <<< mise:activate <<<

# load ~/.zshrc_base (setup)
[ -r "${HOME}/.zshrc_base" ] && source "${HOME}/.zshrc_base"

# load zsh plugins via sheldon (after ~/.zshrc_base, so syntax highlighting wraps every widget)
(type sheldon &>/dev/null) && eval "$(sheldon source)"

# load starship (after mise activation, so the mise-managed binary is on PATH)
export STARSHIP_CONFIG="${XDG_CONFIG_HOME}/starship/starship.toml"
(type starship &>/dev/null) && eval "$(starship init zsh)"

# get zsh load time - END
_zsh_end="$(date +%s%3N)"
printf " %.3f s\\n" "$((_zsh_end - _zsh_start))e-3"
unset _zsh_start _zsh_end

# unload zsh profiler
# zprof 2>&1 >~/.zsh.profiling
# zmodload -u zsh/zprof
