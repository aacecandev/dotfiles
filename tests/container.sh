#!/usr/bin/env sh
# tests/container.sh — Runs INSIDE the test container, started by tests/run.sh
# with `docker run -it`; never run it on the host.
#   1. Seed a pre-existing ~/.config/nvim, as on a machine being migrated.
#   2. Run install.sh, then snapshot the deployed state.
#   3. Run install.sh again and compare: the bootstrap must be idempotent.
#   4. Run tests/checks.sh.
# Every step streams its output live and also writes it to
# $LOG_DIR/<step>.log; failures are collected in $LOG_DIR/errors.log.
set -u

cd "$(dirname "$0")/.." || exit 1
log_dir="${LOG_DIR:?LOG_DIR must be set}"
errors="$log_dir/errors.log"
status=0

record() {
    printf '%s\n' "$1" >>"$errors"
    status=1
}

# Run one step, stream and log its output, and record a non-zero exit.
# The exit code goes through a file because a pipeline returns tee's status.
step() {
    name="$1"
    shift
    log="$log_dir/$name.log"
    rc_file="$log_dir/.$name.rc"
    printf '\n==> %s\n' "$name"
    {
        "$@"
        echo $? >"$rc_file"
    } 2>&1 | tee "$log"
    rc="$(cat "$rc_file")"
    rm -f "$rc_file"
    if [ "$rc" -ne 0 ]; then
        record "[$name] exited with $rc (see $name.log)"
    fi
    return "$rc"
}

# State a second bootstrap must not change: every [dotfiles] entry and its
# state, the rendered git config, the backups (*.bak), and the tool versions.
snapshot() {
    {
        mise dot status --no-truncate 2>&1
        sha256sum "$HOME/.config/git/config" 2>&1
        find "$HOME" -maxdepth 3 -name '*.bak' -not -path "$HOME/.local/share/mise/*" | sort
        mise ls --current --no-header 2>&1
    } >"$1"
}

# The pre-dotfiles hook must move this directory to ~/.config/nvim.bak
# (asserted in tests/checks.sh).
mkdir -p "$HOME/.config/nvim"
echo 'user config that must survive' >"$HOME/.config/nvim/pre-existing"

step install sh install.sh
snapshot "$log_dir/state.install"
step reinstall sh install.sh
snapshot "$log_dir/state.reinstall"
printf '\n==> idempotence\n'
if diff -u "$log_dir/state.install" "$log_dir/state.reinstall" >"$log_dir/idempotence.log"; then
    echo 'PASS reinstall left the deployed state unchanged'
else
    cat "$log_dir/idempotence.log"
    record '[idempotence] reinstall changed the deployed state (see idempotence.log)'
fi
if ! step checks sh tests/checks.sh; then
    grep '^FAIL' "$log_dir/checks.log" | sed 's/^/[checks] /' >>"$errors"
fi
exit "$status"
