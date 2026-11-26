# Login shells only. Managed by mise dotfiles, deployed to $ZDOTDIR/.zprofile.
# mise shims so login (non-interactive) sessions find mise-managed tools;
# interactive shells get the full activation in .zshrc.
# See https://mise.jdx.dev/bootstrap/shell.html
# Keep it bash-compatible so ShellCheck (no zsh support) can lint it.
# shellcheck shell=bash
eval "$(mise activate zsh --shims)"
