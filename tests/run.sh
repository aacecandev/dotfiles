#!/usr/bin/env sh
# tests/run.sh — End-to-end test of the dotfiles in a disposable container.
#   1. Build the Docker image.
#   2. Run install.sh in a fresh container.
#   3. Run install.sh again (the bootstrap must be idempotent).
#   4. Run tests/checks.sh inside the container.
# Logs go to logs/<UTC timestamp>/; any failure is collected in errors.log.
# Usage:
#   sh tests/run.sh
set -u

root="$(cd "$(dirname "$0")/.." && pwd)"
image="dotfiles-test"
container="dotfiles-test-$$"
log_dir="$root/logs/$(date -u +%Y%m%dT%H%M%SZ)"
errors="$log_dir/errors.log"
mkdir -p "$log_dir"

cleanup() { docker rm -f "$container" >/dev/null 2>&1 || true; }
# On Ctrl-C or kill, stop the run (exit fires the EXIT trap) instead of
# carrying on with the remaining steps.
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

status=0
record() {
    printf '%s\n' "$1" >>"$errors"
    status=1
}

# Run one step, log its output, and record a failure if it exits non-zero or
# prints a mise error.
step() {
    name="$1"
    shift
    log="$log_dir/$name.log"
    printf '==> %s\n' "$name"
    "$@" >"$log" 2>&1
    rc=$?
    if [ "$rc" -ne 0 ]; then
        record "[$name] exited with $rc (see $name.log)"
    fi
    if grep -n 'mise ERROR' "$log" >/dev/null 2>&1; then
        record "[$name] mise errors:"
        grep -n 'mise ERROR' "$log" >>"$errors"
    fi
    return "$rc"
}

if step build docker build -t "$image" "$root"; then
    # tests/ is mounted read-only so the image itself stays unchanged.
    if step start docker run -d --name "$container" \
        -v "$root/tests:/home/test/dotfiles/tests:ro" \
        "$image" sleep infinity; then
        step install docker exec "$container" sh install.sh
        step reinstall docker exec "$container" sh install.sh
        if ! step checks docker exec "$container" sh tests/checks.sh; then
            grep '^FAIL' "$log_dir/checks.log" | sed 's/^/[checks] /' >>"$errors"
        fi
    fi
fi

if [ "$status" -eq 0 ]; then
    printf 'OK: all steps passed. Logs: %s\n' "$log_dir"
else
    printf 'FAILED: see %s\n' "$errors" >&2
    cat "$errors" >&2
fi
exit "$status"
