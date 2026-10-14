# Managed by mise dotfiles. Deployed to ~/.zshrc.
# Because [dotfiles] covers this path, mise does not inject its own
# activation block — this file carries it directly.

# load zsh profiler
# zmodload zsh/zprof

# get zsh load time - START
# prefer gnu-date
[[ "$(uname)" == "Darwin" ]] && (type gdate &>/dev/null) && alias date='gdate'
_zsh_start="$(date +%s%3N)"

# Export core paths before plugins: zsh-autocomplete runs compinit during plugin load.
export XDG_CACHE_HOME="${HOME}/.cache"
export XDG_CONFIG_HOME="${HOME}/.config"
export XDG_DATA_HOME="${HOME}/.local/share"

FPATH_DIRS=(
  "${HOME}/.completions"
  "${HOME}/.docker/completions"
  "${HOME}/.zsh/zsh-completions/src"
)
for i in "${FPATH_DIRS[@]}"; do
  [ -d "${i}" ] && FPATH+=":${i}"
done

# >>> mise:activate >>> managed by mise — do not edit between markers
eval "$(mise activate zsh)"
# <<< mise:activate <<<

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
